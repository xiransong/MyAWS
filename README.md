# MyAWS

Reusable EC2 + EBS workflow for lab members who need disposable compute with a persistent workspace.

The core model is simple:
- EC2 instances are disposable.
- One EBS volume holds the persistent workspace.
- Lab-specific AWS settings live in `config/lab.env`, not inside scripts.

## Repo Layout

```text
config/                Lab-specific settings (copy from lab.env.example)
docs/                  Onboarding and workflow docs
lib/                   Shared shell helpers
scripts/local/         Run from your laptop or admin machine
scripts/instance/      Run inside the EC2 instance
scripts/extras/codex/  Optional Codex setup on the persistent EBS
```

## First-Time Setup

1. Copy `config/lab.env.example` to `config/lab.env`.
2. Fill in your AWS profile, region, key pair, security group, and AMI IDs.
3. Read [docs/onboarding.md](/home/ubuntu/scratch/repos/MyAWS/docs/onboarding.md).

## Daily Workflow

The main path is documented in [docs/workflow.md](/home/ubuntu/scratch/repos/MyAWS/docs/workflow.md).

At a high level:
1. Create the persistent scratch EBS once with [scripts/local/create-scratch-ebs.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/local/create-scratch-ebs.sh).
2. Format it once from inside the bootstrap instance with [scripts/instance/format-scratch-ebs.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/instance/format-scratch-ebs.sh).
3. Launch work instances with [scripts/local/launch-and-attach.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/local/launch-and-attach.sh).
4. Mount the scratch volume inside EC2 with [scripts/instance/mount-scratch-ebs.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/instance/mount-scratch-ebs.sh).
5. Bootstrap a shared shell with [scripts/instance/setup-shared-shell.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/instance/setup-shared-shell.sh) and [scripts/instance/bootstrap-user-shell.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/instance/bootstrap-user-shell.sh).

## Dotfiles Policy

This repo no longer backs up private SSH keys or blindly restores full personal dotfiles.

Instead:
- shared shell config lives on the persistent EBS
- each user opts into sourcing that shared config from their own `~/.bashrc`
- GitHub auth stays user-scoped via `gh auth login` or a user-managed SSH key

See [scripts/instance/setup-github-auth.sh](/home/ubuntu/scratch/repos/MyAWS/scripts/instance/setup-github-auth.sh) and [docs/troubleshooting.md](/home/ubuntu/scratch/repos/MyAWS/docs/troubleshooting.md).
