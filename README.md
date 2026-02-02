# MyAWS — Minimal, Calm EC2 + GPU Docker Workflow

This repository documents a **simple, robust AWS EC2 workflow** for research and experimentation.
The goal is to make infrastructure *disappear* so you can focus on actual work.

> **EC2 instances are disposable. One EBS volume is persistent.**

---

## Mental Model

* You own **one persistent EBS volume** (your workspace)
* EC2 instances (CPU or GPU) can be launched and terminated freely
* All important state lives on the EBS
* Docker uses the EBS for storage
* GPU support is provided by the AMI, not by manual driver installs

---

## Recommended AMIs

### CPU instances

* **Ubuntu Server 22.04 LTS (x86_64)**

Use this for:

* setup
* debugging
* CPU-only development

---

### GPU instances (recommended)

* **Deep Learning Base AMI with Single CUDA (Ubuntu 22.04, x86_64)**

Why:

* NVIDIA driver preinstalled
* CUDA ready
* Docker preinstalled
* `nvidia-smi` works out of the box
* No manual driver installation

⚠️ Do **not** use ARM64 AMIs with GPU instances.

---

## Storage Layout (inside EC2)

After setup:

```text
/home/ubuntu/scratch        ← persistent EBS
├── repos/                  ← source code
├── datasets/               ← datasets
├── outputs/                ← experiment outputs
└── docker/                 ← Docker data-root (root-owned)
```

---

## Phase 1 — One-Time Disk Setup

> **Run once per EBS volume. Never again.**

### Phase 1-a: Create the persistent EBS (MacBook)

```bash
bash phase1a_create_scratch_ebs_final.sh
```

* Creates a persistent EBS
* Tags it
* Prints the **volume ID** (save it)

---

### Phase 1-b: Format the EBS (inside EC2)

```bash
bash phase1b_format_scratch_ebs_final.sh
```

⚠️ **Destroys all data on the volume.**
Run exactly once in the volume’s lifetime.

---

## Phase 2 — Daily Workflow (Reuse the Disk)

### Phase 2-a: Launch EC2 and attach EBS (MacBook)

```bash
bash phase2a_launch_and_attach_v2.sh
```

* Launches EC2
* Attaches the EBS
* Prints public IPv4

---

### Phase 2-b: Mount the EBS safely (inside EC2)

```bash
bash phase2b_instance_setup_final.sh
```

* Resolves device via `/dev/disk/by-id`
* Shows a dry-run
* Mounts at `/home/ubuntu/scratch`
* Adds `/etc/fstab` entry

Safe to re-run.

---

## Phase 3 — Docker (GPU AMI)

> Assumes Docker and GPU support are already present (GPU AMI).

### Phase 3: Configure Docker paths

```bash
bash phase3_configure_docker_paths.sh
```

* Moves Docker data-root to `/home/ubuntu/scratch/docker`
* Restarts Docker

Verification:

```bash
docker info --format '{{.DockerRootDir}}'
```

Expected:

```text
/home/ubuntu/scratch/docker
```

---

## GPU Docker Verification

Run once per instance:

```bash
docker run --rm --gpus all \
  nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

If this works, **GPU Docker is fully functional**.

---

## Design Principles (Important)

* Format disks once
* Use volume ID as the source of truth
* Mount via `/dev/disk/by-id`
* Trust GPU AMIs
* Do not manually install NVIDIA drivers
* Do not change Docker directory permissions

---

## Final Note

Once GPU Docker works, **stop touching infrastructure**.
Build images, run experiments, push artifacts, terminate EC2.

Happy hacking 🚀
