#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

load_lab_config
require_command aws
require_command jq
require_var AWS_REGION
require_var AWS_AVAILABILITY_ZONE
require_var AWS_KEY_NAME
require_var BOOTSTRAP_AMI_ID
require_var BOOTSTRAP_INSTANCE_TYPE
require_var BOOTSTRAP_ROOT_SIZE_GB
require_var BOOTSTRAP_INSTANCE_NAME
require_var SCRATCH_SIZE_GB

SCRATCH_TAG_PREFIX="${SCRATCH_TAG_PREFIX:-myaws-scratch}"

AWS_PROFILE_ARGS=()
SECURITY_GROUP_ARGS=()
if [[ -n "${AWS_PROFILE:-}" ]]; then
  AWS_PROFILE_ARGS=(--profile "${AWS_PROFILE}")
fi
IFS=$'\0' read -r -d '' -a SECURITY_GROUP_ARGS < <(aws_security_group_args && printf '\0')

echo
echo "Enter a tag name for the persistent scratch EBS"
echo "(press enter to use ${SCRATCH_TAG_PREFIX}-$(whoami)):"
read -r SCRATCH_TAG_NAME

if [[ -z "${SCRATCH_TAG_NAME}" ]]; then
  SCRATCH_TAG_NAME="${SCRATCH_TAG_PREFIX}-$(whoami)"
fi

log_info "Using volume tag: ${SCRATCH_TAG_NAME}"
log_info "Launching temporary bootstrap EC2 instance"

INSTANCE_JSON="$(
  aws ec2 run-instances \
    --region "${AWS_REGION}" \
    --placement "AvailabilityZone=${AWS_AVAILABILITY_ZONE}" \
    --image-id "${BOOTSTRAP_AMI_ID}" \
    --instance-type "${BOOTSTRAP_INSTANCE_TYPE}" \
    --key-name "${AWS_KEY_NAME}" \
    "${SECURITY_GROUP_ARGS[@]}" \
    --block-device-mappings "[
      {
        \"DeviceName\": \"/dev/sda1\",
        \"Ebs\": {
          \"VolumeSize\": ${BOOTSTRAP_ROOT_SIZE_GB},
          \"VolumeType\": \"gp3\",
          \"DeleteOnTermination\": true
        }
      },
      {
        \"DeviceName\": \"/dev/sdf\",
        \"Ebs\": {
          \"VolumeSize\": ${SCRATCH_SIZE_GB},
          \"VolumeType\": \"gp3\",
          \"DeleteOnTermination\": false
        }
      }
    ]" \
    --tag-specifications "[
      {
        \"ResourceType\": \"instance\",
        \"Tags\": [{\"Key\": \"Name\", \"Value\": \"${BOOTSTRAP_INSTANCE_NAME}\"}]
      }
    ]" \
    "${AWS_PROFILE_ARGS[@]}"
)"

INSTANCE_ID="$(jq -r '.Instances[0].InstanceId' <<<"${INSTANCE_JSON}")"
log_info "Instance ID: ${INSTANCE_ID}"
log_info "Waiting for instance to enter RUNNING state"

aws ec2 wait instance-running \
  --instance-ids "${INSTANCE_ID}" \
  --region "${AWS_REGION}" \
  "${AWS_PROFILE_ARGS[@]}"

PUBLIC_IP="$(
  aws ec2 describe-instances \
    --instance-ids "${INSTANCE_ID}" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region "${AWS_REGION}" \
    "${AWS_PROFILE_ARGS[@]}"
)"

log_info "Locating persistent scratch EBS"
VOLUME_ID="$(
  aws ec2 describe-volumes \
    --region "${AWS_REGION}" \
    --filters "Name=attachment.instance-id,Values=${INSTANCE_ID}" \
    --query "Volumes[?Size==\`${SCRATCH_SIZE_GB}\` && Attachments[0].DeleteOnTermination==\`false\`].VolumeId" \
    --output text \
    "${AWS_PROFILE_ARGS[@]}"
)"

[[ -n "${VOLUME_ID}" ]] || die "Could not find the new scratch EBS volume"

aws ec2 create-tags \
  --resources "${VOLUME_ID}" \
  --tags "Key=Name,Value=${SCRATCH_TAG_NAME}" \
  --region "${AWS_REGION}" \
  "${AWS_PROFILE_ARGS[@]}"

cat <<EOF

======================================
Scratch volume created

Instance ID : ${INSTANCE_ID}
Public IPv4 : ${PUBLIC_IP}
Volume ID   : ${VOLUME_ID}
Tag         : ${SCRATCH_TAG_NAME}

Next steps:
  1. ssh ${EC2_DEFAULT_USER:-ubuntu}@${PUBLIC_IP}
  2. bash scripts/instance/format-scratch-ebs.sh
======================================
EOF
