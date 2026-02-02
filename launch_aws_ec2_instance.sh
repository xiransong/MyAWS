# Ubuntu 22.04 LTS
AMI_ID=ami-0030e4319cbf4dbf2

INSTANCE_TYPE=g4dn.2xlarge  # T4 GPU (16GB)
# INSTANCE_TYPE=t3.small  # CPU

aws ec2 run-instances \
  --region us-east-1 \
  --image-id ${AMI_ID} \
  --instance-type ${INSTANCE_TYPE} \
  --key-name banglab \
  --security-groups banglab \
  --block-device-mappings '[
    {
      "DeviceName": "/dev/sda1",
      "Ebs": {
        "VolumeSize": 100,
        "VolumeType": "gp3",
        "DeleteOnTermination": false
      }
    }
  ]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=dev-motion-gen-motionlcm}]' \
  --profile xiran-ec2
