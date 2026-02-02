# MyAWS

A **calm, reproducible AWS EC2 workflow** for research and development.

This repository documents and automates a simple idea:

> **EC2 instances are disposable. EBS volumes are long‑lived.**

We use:

* a **small root EBS** for the OS (recreated every time)
* a **persistent 100 GB EBS** as our personal workspace
* optional **Docker / Apptainer** stored on that persistent disk

This README is written for **future us and lab mates** who want something that:

* is easy to reason about
* avoids accidental data loss
* works equally well for EC2 dev and HPC deployment

---

## Mental Model (read this first)

* EC2 instances come and go
* One EBS volume is *your disk*
* You attach that disk to any EC2 you like
* You never re‑format it after the first time

Think of the EBS as a **portable hard drive**.

---

## Repository Contents

```text
MyAWS/
├── phase1a_create_scratch_ebs.sh      # MacBook: create + tag persistent EBS
├── phase1b_format_scratch_ebs.sh      # EC2: one-time filesystem setup
├── phase2a_launch_and_attach.sh       # MacBook: launch EC2 + attach EBS
├── phase2b_instance_setup.sh          # EC2: mount EBS, setup dirs, Docker, Apptainer
└── README.md                          # this file
```

---

## Storage Layout (final state)

Inside the EC2 instance, after setup:

```text
/home/ubuntu/scratch      ← persistent 100 GB EBS
├── repos/                ← git repos
├── datasets/             ← datasets
├── outputs/              ← experiment outputs
├── containers/           ← Apptainer .sif files
├── docker/               ← Docker data-root
└── apptainer-cache/      ← Apptainer cache
```

Optional (future use):

```text
/mnt/nvme                 ← instance NVMe SSD (ephemeral)
```

---

## Phase 1 — One-Time Bootstrap (create the disk)

> **You do this exactly once per persistent EBS.**

### Phase 1‑a (MacBook)

Launch a *temporary CPU EC2* and create the persistent 100 GB EBS.

```bash
bash phase1a_create_scratch_ebs.sh
```

What this script does:

* prompts you for a **volume tag** (e.g. `banglab-scratch-xiran`)
* launches a cheap CPU instance
* creates:

  * root EBS (small, disposable)
  * scratch EBS (100 GB, persistent)
* tags the scratch EBS
* **prints the Volume ID** (save this!)

You must remember or record the volume ID:

```text
vol-xxxxxxxxxxxxxxxxx
```

---

### Phase 1‑b (inside EC2)

SSH into the temporary instance, then:

```bash
bash phase1b_format_scratch_ebs.sh
```

What this script does:

* formats the scratch EBS with `ext4`

⚠️ **This script DESTROYS all data on the disk.**
⚠️ **Run it exactly once in the disk’s lifetime.**

After this:

* the disk has a filesystem
* it is ready forever

Then:

* detach the volume (or just terminate the instance)
* terminate the CPU instance

Phase 1 is now complete.

---

## Phase 2 — Daily Workflow (reuse the disk)

> **This is what you do every time you want to work.**

---

### Phase 2‑a (MacBook)

Launch a new EC2 instance and attach your existing scratch EBS.

```bash
bash phase2a_launch_and_attach.sh
```

What this script does:

* prompts you for the **Volume ID**
* launches a new EC2 (CPU or GPU)
* attaches the persistent EBS

After it finishes:

* SSH into the instance

---

### Phase 2‑b (inside EC2)

Inside the EC2 instance:

```bash
bash phase2b_instance_setup.sh
```

What this script does:

* mounts the persistent EBS at `/home/ubuntu/scratch`
* sets auto‑mount via `/etc/fstab`
* creates standard directories
* configures Docker to store images on the EBS
* configures Apptainer cache on the EBS
* mounts NVMe SSD if present (optional)

This script is **safe to run every time**.

---

## Docker Usage

Docker storage is redirected to:

```text
/home/ubuntu/scratch/docker
```

This means:

* Docker images persist across EC2 instances
* You don’t rebuild images every time

Example bind mount:

```bash
docker run -v /home/ubuntu/scratch/datasets:/data ...
```

---

## Apptainer Usage

Apptainer containers are just files.

Recommended location:

```text
/home/ubuntu/scratch/containers/motionlcm.sif
```

Example:

```bash
apptainer exec --nv \
  /home/ubuntu/scratch/containers/motionlcm.sif \
  python demo.py
```

This works identically on:

* EC2
* Compute Canada GPU clusters

---

## Typical Development Pattern

1. Develop & debug on EC2
2. Stabilize environment
3. Build Docker image
4. Push to DockerHub
5. Convert to Apptainer
6. Run large experiments on HPC

EC2 = development
Containers = reproducibility
HPC = scale

---

## Safety Rules (important)

```text
✔ Format (mkfs) → ONCE, EVER
✔ Mount → MANY TIMES
✔ /etc/fstab → PER INSTANCE
✘ Never re‑format a disk with data
```

If in doubt, **stop and check `lsblk`**.

---

## Final Notes

This workflow is intentionally:

* boring
* explicit
* human‑readable

It is designed so that:

* mistakes are hard to make
* recovery is always possible
* future you can understand it in 6 months

If something feels confusing, that’s a sign the script or README should be improved — not that you should memorize more commands.

Happy hacking 🚀
