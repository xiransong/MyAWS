# MyAWS — Calm EC2 + Persistent EBS Workflow (v1)

This repository contains **battle-tested scripts** for a clean, safe, and reproducible AWS EC2 workflow built around one core idea:

> **EC2 instances are disposable. EBS volumes are long-lived.**

The workflow is intentionally boring, explicit, and calm — designed for research work where infrastructure should *disappear* once it’s correct.

---

## Mental Model (read first)

* You own **one persistent EBS volume** (your workspace)
* You can attach it to **any EC2 instance** (CPU or GPU)
* EC2 instances can be terminated freely
* You **never format the EBS again** after Phase 1

Think of the EBS as a **portable external hard drive** that follows you across machines.

---

## Repository Structure

```text
MyAWS/
├── phase1a_create_scratch_ebs_final.sh
├── phase1b_format_scratch_ebs_final.sh
├── phase2a_launch_and_attach_v2.sh
├── phase2b_instance_setup_final.sh
├── phase3a_install_docker_optional.sh
├── phase3b_enable_gpu_docker_optional.sh
└── README.md
```

---

## Recommended AMIs (IMPORTANT)

Choose the AMI based on **hardware**, not preference.

### CPU instances

Use a plain Ubuntu LTS:

* **Ubuntu Server 22.04 LTS (x86_64)**

Why:

* minimal
* fast boot
* no unnecessary GPU stack
* perfect for setup, debugging, and CPU-only work

---

### GPU instances (RECOMMENDED)

Use the AWS-maintained GPU AMI:

* **Deep Learning Base AMI with Single CUDA (Ubuntu 22.04, x86_64)**

Why this is ideal:

* NVIDIA driver + CUDA already installed
* `nvidia-smi` works out of the box
* minimal (no forced Conda environments)
* designed for Docker-first workflows
* avoids manual driver installation entirely

⚠️ **Do NOT use ARM64 AMIs** with `g4`, `g5`, `p4`, or `p5` instances.

---

## Final Storage Layout (inside EC2)

After Phase 2-b completes:

```text
/home/ubuntu/scratch        ← persistent 100GB EBS
├── repos/                  ← git repositories
├── datasets/               ← datasets
├── outputs/                ← experiment outputs
├── containers/             ← container files (.sif, etc.)
├── docker/                 ← Docker data-root
└── apptainer-cache/        ← (optional) Apptainer cache
```

---

## Phase 1 — One-Time Disk Bootstrap

> **Run exactly once per persistent EBS volume.**

### Phase 1-a — Create the persistent EBS

**(Run on your MacBook)**

```bash
bash phase1a_create_scratch_ebs_final.sh
```

What this script does:

* prompts for a **volume tag name**
* launches a cheap CPU EC2 instance
* creates:

  * a small root EBS (temporary)
  * a 100GB scratch EBS (**persistent**)
* tags the scratch EBS
* prints:

  * instance ID
  * public IPv4
  * **volume ID (SAVE THIS)**

Record the volume ID somewhere safe:

```text
vol-0xxxxxxxxxxxxxxxx
```

---

### Phase 1-b — Format the EBS (DANGEROUS)

**(Run inside the temporary EC2)**

```bash
bash phase1b_format_scratch_ebs_final.sh
```

What this script does:

* prompts for the **volume ID**
* resolves the real Linux device via `/dev/disk/by-id`
* shows a **dry-run confirmation**
* formats the volume as `ext4`

⚠️ **This DESTROYS all data on the volume.**
⚠️ **Run exactly once in the volume’s lifetime.**

After this step:

* detach the volume (or just terminate the instance)
* terminate the CPU instance

Phase 1 is now complete forever.

---

## Phase 2 — Daily Workflow (Reuse the Disk)

> **This is what you do every time you want to work.**

### Phase 2-a — Launch EC2 and attach EBS

**(Run on your MacBook)**

```bash
bash phase2a_launch_and_attach_v2.sh
```

What this script does:

* prompts for the **volume ID**
* launches a new EC2 instance (CPU or GPU)
* waits for it to be running
* attaches the EBS
* prints:

  * instance ID
  * public IPv4

Next:

```bash
ssh ubuntu@<PUBLIC_IP>
```

---

### Phase 2-b — Mount the EBS safely

**(Run inside EC2)**

```bash
bash phase2b_instance_setup_final.sh
```

What this script does:

* prompts for **volume ID**
* resolves the real block device via `/dev/disk/by-id`
* shows a **dry-run summary**
* mounts the EBS at `/home/ubuntu/scratch`
* adds `/etc/fstab` entry (UUID-based)
* fixes ownership
* creates standard directories

This script is **safe to re-run**.

---

## Phase 3 — Docker Tooling (OPTIONAL)

Phase 3 is **only for users who want Docker**.

### Phase 3-a — Docker (CPU)

Install Docker and move Docker storage onto the persistent EBS.

```bash
bash phase3a_install_docker_optional.sh
```

Use this when:

* you want Docker on CPU or GPU instances
* you want images to persist across EC2 restarts

---

### Phase 3-b — Docker (GPU)

Enable GPU support for Docker.

```bash
bash phase3b_enable_gpu_docker_optional.sh
```

Prerequisites:

* GPU EC2 instance
* GPU AMI (Deep Learning Base AMI)
* `nvidia-smi` works

If you only need CPU Docker, **do not run this step**.

---

## Safety Rules (memorize these)

```text
✔ Format (mkfs) → ONCE EVER
✔ Volume ID → single source of truth
✔ Mount via /dev/disk/by-id
✔ Dry-run before destructive actions
✘ Never trust nvmeXn1 numbering
✘ Never re-format a disk with data
```

---

## Why This Workflow Works

* EC2 instances are disposable
* EBS holds everything important
* CPU and GPU paths are explicit
* Docker is optional, not mandatory
* GPU enablement is isolated
* Nothing depends on hidden state

---

## Final Note

If something feels confusing:

* stop
* run `lsblk`
* read the dry-run output

Confusion is a signal to improve scripts — not to memorize more commands.

Happy hacking 🚀
