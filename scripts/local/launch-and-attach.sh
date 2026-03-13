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
require_var WORK_AMI_ID
require_var WORK_INSTANCE_TYPE
require_var WORK_ROOT_SIZE_GB
require_var WORK_INSTANCE_NAME

AWS_PROFILE_ARGS=()
SECURITY_GROUP_ARGS=()
if [[ -n "${AWS_PROFILE:-}" ]]; then
  AWS_PROFILE_ARGS=(--profile "${AWS_PROFILE}")
fi
IFS=$'\0' read -r -d '' -a SECURITY_GROUP_ARGS < <(aws_security_group_args && printf '\0')

echo "Enter the persistent EBS Volume ID (e.g. vol-0abc123...):"
read -r VOLUME_ID
[[ -n "${VOLUME_ID}" ]] || die "Volume ID cannot be empty"

log_info "Launching work EC2 instance"
INSTANCE_JSON="$(
  aws ec2 run-instances \
    --region "${AWS_REGION}" \
    --placement "AvailabilityZone=${AWS_AVAILABILITY_ZONE}" \
    --image-id "${WORK_AMI_ID}" \
    --instance-type "${WORK_INSTANCE_TYPE}" \
    --key-name "${AWS_KEY_NAME}" \
    "${SECURITY_GROUP_ARGS[@]}" \
    --block-device-mappings "[
      {
        \"DeviceName\": \"/dev/sda1\",
        \"Ebs\": {
          \"VolumeSize\": ${WORK_ROOT_SIZE_GB},
          \"VolumeType\": \"gp3\",
          \"DeleteOnTermination\": true
        }
      }
    ]" \
    --tag-specifications "[
      {
        \"ResourceType\": \"instance\",
        \"Tags\": [{\"Key\": \"Name\", \"Value\": \"${WORK_INSTANCE_NAME}\"}]
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

log_info "Attaching volume ${VOLUME_ID}"
aws ec2 attach-volume \
  --region "${AWS_REGION}" \
  --volume-id "${VOLUME_ID}" \
  --instance-id "${INSTANCE_ID}" \
  --device /dev/sdf \
  "${AWS_PROFILE_ARGS[@]}"

PUBLIC_IP="$(
  aws ec2 describe-instances \
    --instance-ids "${INSTANCE_ID}" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region "${AWS_REGION}" \
    "${AWS_PROFILE_ARGS[@]}"
)"

cat <<EOF

======================================
Work instance ready

Instance ID : ${INSTANCE_ID}
Public IPv4 : ${PUBLIC_IP}
Volume ID   : ${VOLUME_ID}

Next steps:
  1. ssh ${EC2_DEFAULT_USER:-ubuntu}@${PUBLIC_IP}
  2. bash scripts/instance/mount-scratch-ebs.sh
======================================
EOF
