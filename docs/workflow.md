# Workflow

## One-Time Per Scratch Volume

1. Create a new persistent EBS volume from your local machine:

```bash
bash scripts/local/create-scratch-ebs.sh
```

2. Add the printed bootstrap instance IP to your local `~/.ssh/config`:

```sshconfig
Host ec2-bootstrap
  HostName <bootstrap-public-ip>
  User ubuntu
  IdentityFile ~/.ssh/your-key
```

3. SSH into the bootstrap instance:

```bash
ssh ec2-bootstrap
```

4. Clone this repo inside EC2 if needed, then format the attached scratch volume once:

```bash
git clone <your-fork-url>
cd <repo-dir>
bash scripts/instance/format-scratch-ebs.sh
```

5. Detach the volume and terminate the bootstrap instance when done.

## Per Work Session

1. Launch a work instance and attach the persistent EBS:

```bash
bash scripts/local/launch-and-attach.sh
```

2. Update your local `~/.ssh/config` for the work instance:

```sshconfig
Host ec2-work
  HostName <work-public-ip>
  User ubuntu
  IdentityFile ~/.ssh/your-key
```

3. SSH into the new instance:

```bash
ssh ec2-work
```

4. Clone this repo on the instance so you can run the mount script:

```bash
git clone <your-fork-url>
cd <repo-dir>
```

5. Mount the scratch volume:

```bash
bash scripts/instance/mount-scratch-ebs.sh
```

6. If the repo is not already on the scratch volume, clone it there for persistence:

```bash
mkdir -p ~/scratch/repos
cd ~/scratch/repos
git clone <your-fork-url>
cd <repo-dir>
```

7. Set up the shared shell once per user account on that EBS:

```bash
bash scripts/instance/setup-shared-shell.sh
bash scripts/instance/bootstrap-user-shell.sh
source ~/.bashrc
```

## Optional Environment Add-Ons

Micromamba:

```bash
bash scripts/instance/install-micromamba.sh
source ~/.bashrc
```

Codex persistence:

```bash
bash scripts/extras/codex/setup-persistence.sh
bash scripts/extras/codex/install-node.sh
bash scripts/extras/codex/install-codex.sh
source ~/.bashrc
```

Daily Codex restore on a fresh instance:

```bash
bash scripts/extras/codex/restore-codex-env.sh
source ~/.bashrc
```
