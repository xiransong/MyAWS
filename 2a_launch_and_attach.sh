#!/usr/bin/env bash
set -e

# ========= CONFIG =========
AWS_PROFILE=xiran-ec2
AWS_REGION=us-east-1
AVAILABILITY_ZONE=us-east-1a

# AMI_ID=ami-0030e4319cbf4dbf2     # Ubuntu 22.04 (ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20251212)
AMI_ID=ami-0252d9c82e6b8fa85     # Deep Learning Base AMI with Single CUDA (Ubuntu 22.04) 20260130

INSTANCE_TYPE=g4dn.xlarge  # T4 GPU (16GB)
KEY_NAME=banglab
SECURITY_GROUP=banglab

ROOT_SIZE_GB=100
# ==========================

echo "Enter the persistent EBS Volume ID (e.g. vol-0abc123...):"
read -r VOLUME_ID

if [[ -z "${VOLUME_ID}" ]]; then
  echo "ERROR: Volume ID cannot be empty."
  exit 1
fi

echo
echo "Launching EC2 instance..."
echo

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
    }
  ]" \
  --tag-specifications "[
    {
      \"ResourceType\": \"instance\",
      \"Tags\": [{\"Key\": \"Name\", \"Value\": \"phase2-work-instance\"}]
    }
  ]" \
  --profile ${AWS_PROFILE})

INSTANCE_ID=$(echo "${INSTANCE_JSON}" | jq -r '.Instances[0].InstanceId')

echo "Instance ID: ${INSTANCE_ID}"

echo "Waiting for instance to be running..."
aws ec2 wait instance-running \
  --instance-ids ${INSTANCE_ID} \
  --region ${AWS_REGION} \
  --profile ${AWS_PROFILE}

echo "Attaching volume ${VOLUME_ID} ..."

aws ec2 attach-volume \
  --region ${AWS_REGION} \
  --volume-id ${VOLUME_ID} \
  --instance-id ${INSTANCE_ID} \
  --device /dev/sdf \
  --profile ${AWS_PROFILE}

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids ${INSTANCE_ID} \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text \
  --region ${AWS_REGION} \
  --profile ${AWS_PROFILE})

echo
echo "======================================"
echo "PHASE 2-A COMPLETE"
echo
echo "Instance ID : ${INSTANCE_ID}"
echo "Public IPv4 : ${PUBLIC_IP}"
echo
echo "Next:"
echo "  ssh to instance"
echo "  run phase2b_instance_setup_v2.sh"
echo "======================================"
