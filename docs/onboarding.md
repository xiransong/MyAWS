# Onboarding

## Configure The Lab Defaults

Copy the example config:

```bash
cp config/lab.env.example config/lab.env
```

Update these values in `config/lab.env`:
- `AWS_PROFILE`
- `AWS_REGION`
- `AWS_AVAILABILITY_ZONE`
- `AWS_KEY_NAME`
- `AWS_SECURITY_GROUP` or `AWS_SECURITY_GROUP_ID`
- `BOOTSTRAP_AMI_ID`
- `WORK_AMI_ID`

You should also review:
- `BOOTSTRAP_INSTANCE_TYPE`
- `WORK_INSTANCE_TYPE`
- `SCRATCH_SIZE_GB`
- `SCRATCH_MOUNT`
- `SCRATCH_LAYOUT_DIRS`

## What Runs Where

Run these from your laptop or admin machine:
- [scripts/local/create-scratch-ebs.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/local/create-scratch-ebs.sh)
- [scripts/local/launch-and-attach.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/local/launch-and-attach.sh)

Run these inside the EC2 instance:
- [scripts/instance/format-scratch-ebs.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/instance/format-scratch-ebs.sh)
- [scripts/instance/mount-scratch-ebs.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/instance/mount-scratch-ebs.sh)
- [scripts/instance/setup-shared-shell.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/instance/setup-shared-shell.sh)
- [scripts/instance/bootstrap-user-shell.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/instance/bootstrap-user-shell.sh)

Optional Codex setup lives under [scripts/extras/codex](/home/ubuntu/scratch/repos/MyAWS/scripts/extras/codex).

## Defaults To Keep Consistent Across The Lab

These are worth standardizing once instead of letting every user improvise:
- preferred CPU bootstrap AMI
- preferred GPU work AMI
- security group name or ID
- expected EC2 login user such as `ubuntu`
- scratch mount path
- standard workspace layout on the EBS

If your lab uses multiple AWS accounts or regions, keep one config per environment and select it with `MYAWS_CONFIG_FILE=/path/to/config bash ...`.
