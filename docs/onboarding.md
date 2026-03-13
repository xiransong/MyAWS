# Onboarding

## Configure The Lab Defaults

Fork or clone this repo on your local machine, then copy the example config:

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
- [scripts/local/create-scratch-ebs.sh](../scripts/local/create-scratch-ebs.sh)
- [scripts/local/launch-and-attach.sh](../scripts/local/launch-and-attach.sh)

Run these inside the EC2 instance:
- [scripts/instance/format-scratch-ebs.sh](../scripts/instance/format-scratch-ebs.sh)
- [scripts/instance/mount-scratch-ebs.sh](../scripts/instance/mount-scratch-ebs.sh)
- [scripts/instance/setup-shared-shell.sh](../scripts/instance/setup-shared-shell.sh)
- [scripts/instance/bootstrap-user-shell.sh](../scripts/instance/bootstrap-user-shell.sh)

Optional Codex setup lives under [scripts/extras/codex](../scripts/extras/codex).

## Suggested New User Flow

1. Fork or clone this repo on your local machine.
2. Copy `config/lab.env.example` to `config/lab.env` and update the lab-specific values.
3. Run `bash scripts/local/create-scratch-ebs.sh`.
4. Add the printed bootstrap instance IP to your local `~/.ssh/config`, for example:

```sshconfig
Host ec2-bootstrap
  HostName 44.203.223.155
  User ubuntu
  IdentityFile ~/.ssh/your-key
```

5. `ssh ec2-bootstrap`
6. Clone your fork of this repo inside EC2 if needed, then run `bash scripts/instance/format-scratch-ebs.sh`
7. Detach the scratch volume and terminate the bootstrap instance.
8. Run `bash scripts/local/launch-and-attach.sh`
9. Update your local `~/.ssh/config` with the new work-instance IP, for example:

```sshconfig
Host ec2-work
  HostName 44.203.223.155
  User ubuntu
  IdentityFile ~/.ssh/your-key
```

10. `ssh ec2-work`
11. Run `bash scripts/instance/mount-scratch-ebs.sh`
12. Clone this repo into the persistent workspace if this is your first session on that EBS:

```bash
mkdir -p ~/scratch/repos
cd ~/scratch/repos
git clone <your-fork-url>
```

13. Run the remaining in-instance setup scripts from that persistent clone.

## Defaults To Keep Consistent Across The Lab

These are worth standardizing once instead of letting every user improvise:
- preferred CPU bootstrap AMI
- preferred GPU work AMI
- security group name or ID
- expected EC2 login user such as `ubuntu`
- scratch mount path
- standard workspace layout on the EBS

If your lab uses multiple AWS accounts or regions, keep one config per environment and select it with `MYAWS_CONFIG_FILE=/path/to/config bash ...`.
