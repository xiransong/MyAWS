#!/usr/bin/env bash
set -e

# ========= CONFIG =========
AWS_PROFILE=xiran-ec2
AWS_REGION=us-east-1
AVAILABILITY_ZONE=us-east-1a

AMI_ID=ami-0030e4319cbf4dbf2   # Ubuntu 22.04
INSTANCE_TYPE=t3.small        # cheap CPU instance
KEY_NAME=banglab
SECURITY_GROUP=banglab

SCRATCH_SIZE_GB=100
# ==========================

echo "Enter a tag name for the persistent scratch EBS (e.g. banglab-scratch-xiran):"
read -r SCRATCH_TAG_NAME

if [[ -z "${SCRATCH_TAG_NAME}" ]]; then
  echo "ERROR: Tag name cannot be empty."
  exit 1
fi

echo "Using volume tag: ${SCRATCH_TAG_NAME}"
echo

echo "=== Launching temporary CPU EC2 ==="

INSTANCE_JSON=$(aws ec2 run-instances \
  --region ${AWS_REGION} \
  --placement AvailabilityZone=${AVAILABILITY_ZONE} \
  --image-id ${AMI_ID} \
  --instance-type ${INSTANCE_TYPE} \
  --key-name ${KEY_NAME} \
  --security-groups ${SECURITY_GROUP} \
  --block-device-mappings "[
    {
      \"DeviceName\": \"/dev/sda1\",
      \"Ebs\": {
        \"VolumeSize\": 20,
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
      \"Tags\": [{\"Key\": \"Name\", \"Value\": \"phase1-scratch-bootstrap\"}]
    }
  ]" \
  --profile ${AWS_PROFILE})

INSTANCE_ID=$(echo "${INSTANCE_JSON}" | jq -r '.Instances[0].InstanceId')

echo "Instance ID: ${INSTANCE_ID}"
sleep 5

echo "=== Locating scratch EBS ==="
VOLUME_ID=$(aws ec2 describe-volumes \
  --region ${AWS_REGION} \
  --filters Name=attachment.instance-id,Values=${INSTANCE_ID} \
  --query "Volumes[?Size==\`${SCRATCH_SIZE_GB}\` && Attachments[0].DeleteOnTermination==\`false\`].VolumeId" \
  --output text \
  --profile ${AWS_PROFILE})

if [[ -z "${VOLUME_ID}" ]]; then
  echo "ERROR: Could not find scratch volume."
  exit 1
fi

echo "Scratch Volume ID: ${VOLUME_ID}"

echo "=== Tagging scratch volume ==="
aws ec2 create-tags \
  --resources ${VOLUME_ID} \
  --tags Key=Name,Value=${SCRATCH_TAG_NAME} \
  --region ${AWS_REGION} \
  --profile ${AWS_PROFILE}

echo
echo "======================================"
echo "PHASE 1-A DONE"
echo "SAVE THIS VOLUME ID:"
echo "  ${VOLUME_ID}"
echo "======================================"
