# Workflow

## One-Time Per Scratch Volume

1. Create a new persistent EBS volume from your local machine:

```bash
bash scripts/local/create-scratch-ebs.sh
```

2. SSH into the bootstrap instance printed by the script.

3. Format the attached scratch volume once:

```bash
bash scripts/instance/format-scratch-ebs.sh
```

4. Detach the volume and terminate the bootstrap instance when done.

## Per Work Session

1. Launch a work instance and attach the persistent EBS:

```bash
bash scripts/local/launch-and-attach.sh
```

2. SSH into the new instance.

3. Mount the scratch volume:

```bash
bash scripts/instance/mount-scratch-ebs.sh
```

4. Set up the shared shell once per user account on that EBS:

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
