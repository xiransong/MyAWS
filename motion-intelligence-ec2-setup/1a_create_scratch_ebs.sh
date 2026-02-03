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

ROOT_SIZE_GB=20
SCRATCH_SIZE_GB=100
# ==========================

echo
echo "Enter a tag name for the persistent scratch EBS"
echo "(e.g. banglab-scratch-xiran):"
read -r SCRATCH_TAG_NAME

if [[ -z "${SCRATCH_TAG_NAME}" ]]; then
  echo "ERROR: Tag name cannot be empty."
  exit 1
fi

echo
echo "Using volume tag: ${SCRATCH_TAG_NAME}"
echo
echo "Launching temporary CPU EC2 instance..."
echo

# --------------------------------------------------
# 1. Launch instance with root + scratch EBS
# --------------------------------------------------
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
        \"VolumeSize\": ${ROOT_SIZE_GB},
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
echo "Waiting for instance to enter RUNNING state..."

aws ec2 wait instance-running \
  --instance-ids ${INSTANCE_ID} \
  --region ${AWS_REGION} \
  --profile ${AWS_PROFILE}

# --------------------------------------------------
# 2. Retrieve public IPv4
# --------------------------------------------------
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids ${INSTANCE_ID} \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text \
  --region ${AWS_REGION} \
  --profile ${AWS_PROFILE})

# --------------------------------------------------
# 3. Locate scratch EBS volume
# --------------------------------------------------
echo
echo "Locating persistent scratch EBS..."

VOLUME_ID=$(aws ec2 describe-volumes \
  --region ${AWS_REGION} \
  --filters Name=attachment.instance-id,Values=${INSTANCE_ID} \
  --query "Volumes[?Size==\`${SCRATCH_SIZE_GB}\` && Attachments[0].DeleteOnTermination==\`false\`].VolumeId" \
  --output text \
  --profile ${AWS_PROFILE})

if [[ -z "${VOLUME_ID}" ]]; then
  echo "ERROR: Could not find scratch EBS volume."
  exit 1
fi

# --------------------------------------------------
# 4. Tag scratch EBS
# --------------------------------------------------
aws ec2 create-tags \
  --resources ${VOLUME_ID} \
  --tags Key=Name,Value=${SCRATCH_TAG_NAME} \
  --region ${AWS_REGION} \
  --profile ${AWS_PROFILE}

# --------------------------------------------------
# Done
# --------------------------------------------------
echo
echo "======================================"
echo "PHASE 1-A COMPLETE"
echo
echo "Instance ID : ${INSTANCE_ID}"
echo "Public IPv4 : ${PUBLIC_IP}"
echo
echo "Persistent EBS:"
echo "  Volume ID : ${VOLUME_ID}"
echo "  Tag       : ${SCRATCH_TAG_NAME}"
echo
echo "Next steps:"
echo "  ssh to instance"
echo "  run phase1b_format_scratch_ebs_final.sh"
echo "======================================"
