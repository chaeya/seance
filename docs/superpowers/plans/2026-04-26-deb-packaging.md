# Debian Packaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a repository-local script that builds a Debian package for `seance` and a verification script that installs the package and checks the installed binary.

**Architecture:** The build script will run the existing Zig build, stage the installed files into a temporary package root, generate a minimal Debian control file, and emit a `.deb` artifact in a caller-selected output directory. A separate verification script will install the built package with `dpkg -i`, exercise `seance --help` and `seance ctl help`, and then remove the package so the host is left clean.

**Tech Stack:** POSIX shell, `zig build`, `dpkg-deb`, `dpkg`, `sudo`

---

### Task 1: Build Script

**Files:**
- Create: `scripts/build-deb.sh`

- [ ] **Step 1: Write the failing test**

```bash
./scripts/build-deb.sh --output-dir /tmp/seance-deb
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/build-deb.sh --output-dir /tmp/seance-deb`
Expected: fail because the script does not exist yet.

- [ ] **Step 3: Write minimal implementation**

```sh
#!/bin/sh
set -eu

out_dir="${1:-./dist/deb}"
mkdir -p "$out_dir"
zig build
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./scripts/build-deb.sh --output-dir /tmp/seance-deb`
Expected: creates a `.deb` file in `/tmp/seance-deb`.

- [ ] **Step 5: Commit**

```bash
git add scripts/build-deb.sh
git commit -m "feat: add deb packaging script"
```

### Task 2: Install Verification

**Files:**
- Create: `scripts/verify-deb-install.sh`

- [ ] **Step 1: Write the failing test**

```bash
./scripts/verify-deb-install.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/verify-deb-install.sh`
Expected: fail until the build script and package artifact exist.

- [ ] **Step 3: Write minimal implementation**

```sh
#!/bin/sh
set -eu

deb_path="$(./scripts/build-deb.sh)"
sudo dpkg -i "$deb_path"
seance --help
seance ctl help
sudo dpkg -r seance
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./scripts/verify-deb-install.sh`
Expected: package installs, `seance --help` prints usage, `seance ctl help` prints CLI help, and the package is removed afterward.

- [ ] **Step 5: Commit**

```bash
git add scripts/verify-deb-install.sh
git commit -m "test: add deb install verification"
```
