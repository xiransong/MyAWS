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

1. Fork or clone this repo on your local machine.
2. Copy `config/lab.env.example` to `config/lab.env`.
3. Fill in your AWS profile, region, key pair, security group, and AMI IDs.
4. Read [docs/onboarding.md](docs/onboarding.md).

## Daily Workflow

The main path is documented in [docs/workflow.md](docs/workflow.md).

At a high level:
1. Create the persistent scratch EBS once with [scripts/local/create-scratch-ebs.sh](scripts/local/create-scratch-ebs.sh).
2. SSH to the bootstrap instance and format the new volume once with [scripts/instance/format-scratch-ebs.sh](scripts/instance/format-scratch-ebs.sh).
3. Launch work instances with [scripts/local/launch-and-attach.sh](scripts/local/launch-and-attach.sh).
4. Add the current public IP to your local `~/.ssh/config`, then `ssh` into the instance.
5. Inside EC2, clone this repo on the instance, run [scripts/instance/mount-scratch-ebs.sh](scripts/instance/mount-scratch-ebs.sh), then keep a copy under `~/scratch/repos` for reuse.
6. Bootstrap a shared shell with [scripts/instance/setup-shared-shell.sh](scripts/instance/setup-shared-shell.sh) and [scripts/instance/bootstrap-user-shell.sh](scripts/instance/bootstrap-user-shell.sh).

## Dotfiles Policy

This repo no longer backs up private SSH keys or blindly restores full personal dotfiles.

Instead:
- shared shell config lives on the persistent EBS
- each user opts into sourcing that shared config from their own `~/.bashrc`
- GitHub auth stays user-scoped via `gh auth login` or a user-managed SSH key

See [scripts/instance/setup-github-auth.sh](scripts/instance/setup-github-auth.sh) and [docs/troubleshooting.md](docs/troubleshooting.md).
