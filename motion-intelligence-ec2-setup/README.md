# MyAWS — Minimal EC2 GPU Workflow

This repository documents a **simple, robust AWS EC2 workflow** for research and experimentation.
The goal is to make infrastructure *disappear* so you can focus on actual work.

> **EC2 instances are disposable. One EBS volume is persistent.**

---

## Mental Model

* You own **one persistent EBS volume** (your workspace)
* EC2 instances (CPU or GPU) can be launched and terminated freely
* All important state lives on the EBS
* GPU support is provided by the AMI, not by manual driver installs

---

## Recommended AMIs

### CPU instances

* **Ubuntu Server 22.04 LTS (x86_64)**

Use this for:

* setup

---

### GPU instances (recommended)

* **Deep Learning Base AMI with Single CUDA (Ubuntu 22.04, x86_64)**

Why:

* NVIDIA driver preinstalled
* CUDA ready
* Docker preinstalled

---

## Storage Layout (inside EC2)

After setup:

```text
/home/ubuntu/scratch        ← persistent EBS
├── repos/
├── data/
├── outputs/
└── transfer/
```

---

## Phase 1 — One-Time Disk Setup

> **Run once per EBS volume. Never again.**

### Phase 1-a: Create the persistent EBS (local laptop)

```bash
bash 1a_create_scratch_ebs.sh
```

* Creates a persistent EBS
* Tags it
* Prints the **volume ID** (save it)

---

### Phase 1-b: Format the EBS (inside EC2)

```bash
bash 1b_format_scratch_ebs.sh
```

⚠️ **Destroys all data on the volume.**
Run exactly once in the volume’s lifetime.

---

## Phase 2 — Daily Workflow (Reuse the Disk)

### Phase 2-a: Launch EC2 and attach EBS (local laptop)

```bash
bash 2a_launch_and_attach.sh
```

* Launches EC2
* Attaches the EBS
* Prints public IPv4

---

### Phase 2-b: Mount the EBS safely (inside EC2)

```bash
bash 2b_instance_ebs_setup.sh
```

* Resolves device via `/dev/disk/by-id`
* Shows a dry-run
* Mounts at `/home/ubuntu/scratch`
* Adds `/etc/fstab` entry

Safe to re-run.

---

### Phase 2-c: Do this ONCE for your EBS! Install micromamba

```bash
bash 2c_one-time_install_micromamba.sh
```

* Installed at `/home/ubuntu/scratch/micromamba`

---

## Design Principles

* Format disks once
* Use volume ID as the source of truth
* Mount via `/dev/disk/by-id`
* Trust GPU AMIs
* Do not manually install NVIDIA drivers

---

## Phase 3 — Codex on Persistent EBS

### Phase 3-a: One-time persistent Codex setup (inside EC2)

```bash
bash 3a_one-time_setup_codex_persistence.sh
```

This creates persistent locations under `/home/ubuntu/scratch` and wires shell init:

* `CODEX_HOME=/home/ubuntu/scratch/.codex`
* persistent bin paths on `PATH`
* shared shell config at `/home/ubuntu/scratch/dotfiles/bashrc_shared`

### Phase 3-b: One-time Codex CLI install (inside EC2)

If Node.js/npm are not available, install Node.js persistently on EBS first:

```bash
bash 3aa_one-time_install_node_on_ebs.sh
source ~/.bashrc
node -v
npm -v
```

Then install Codex CLI:

```bash
bash 3b_one-time_install_codex_cli.sh
```

Notes:

* Default npm package is `@openai/codex`
* Override package if needed:

```bash
CODEX_NPM_PACKAGE="<package-name>" bash 3b_one-time_install_codex_cli.sh
```
* Reinstall/update an existing Codex CLI:

```bash
CODEX_FORCE_INSTALL=1 bash 3b_one-time_install_codex_cli.sh
```
* Or use the update helper:

```bash
bash 3bb_update_codex_cli.sh
```

### Phase 3-c: Daily Codex env restore (inside EC2)

```bash
bash 3c_daily_restore_codex_env.sh
source ~/.bashrc
codex --version
```
