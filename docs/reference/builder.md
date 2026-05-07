---
title: "Builder - Command-Line Interface"
description: "Reference for Builder's ./build and ./cert/build script options, supported architectures, and container engines"
related_topics:
  - /explanation/builder
  - /explanation/flavors
  - /explanation/boot-modes
  - /explanation/secure-boot
  - /reference/builder
  - /how-to/secure-boot
  - /how-to/choosing-flavors
  - /how-to/getting-images
migration_status: "done"
migration_issue: "https://github.com/gardenlinux/gardenlinux/issues/4627"
migration_stakeholder: "@tmang0ld, @yeoldegrove, @ByteOtter"
migration_approved: false
github_org: gardenlinux
github_repo: builder
github_source_path: docs/reference/builder.md
github_target_path: docs/reference/builder.md
---

# Build Script Reference

This page is a reference for the options accepted by the `./build` and `./cert/build` scripts.
For step-by-step instructions, see [Building Images](/how-to/building-images). For conceptual
background, see [Builder](/explanation/builder).

## `./build`

### Synopsis

```
./build [OPTIONS] <flavor> [<flavor> ...]
```

Remaining arguments after all options are consumed are forwarded directly to `make` inside the
builder container. This means standard `make` flags such as `-j` are valid here.

### Options

| Option | Argument | Default | Description |
|---|---|---|---|
| `--container-engine` | `podman` \| `sudo podman` \| `docker` | `podman` | Container engine used to launch the builder container. See [Supported Container Engines](#supported-container-engines). |
| `--container-image` | `<image>` | Pinned `ghcr.io/gardenlinux/builder:<sha>` | Overrides the builder container image. Pass `localhost/builder` to build and use a local builder image from the repository. |
| `--container-run-opts` | `<opts>` | Security and memory defaults | Replaces the entire set of container run options with a custom shell-quoted string. This overrides the default memory limit, seccomp, AppArmor, and label settings. Use with care. |
| `--target` | `<dir>` | `.build` | Directory where build artifacts are written. Created automatically if it does not exist. |
| `--privileged` | *(none)* | Off | Runs the builder container with `--privileged` and passes `--second-stage` to the container entrypoint. Required for two-stage builds that need elevated privileges inside the container. |
| `--kms` | *(none)* | Off | Forwards AWS credential environment variables (`AWS_DEFAULT_REGION`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) into the build. Required when Secure Boot key operations during the build use AWS Key Management Service. |
| `--allow-frankenstein` | *(none)* | Off | Disables the [single-platform enforcement](/reference/adr/0020-enforce-single-platform-by-default-in-builder) by passing `ALLOW_FRANKENSTEIN=1` to the build. Allows composing a flavor from multiple platform features. See [ADR 0020](/reference/adr/0020-enforce-single-platform-by-default-in-builder) for the rationale. |
| `--resolve-cname` | *(none)* | Off | Resolves the given flavor argument to its full canonical name (CNAME) including the 8-character commit hash, prints it to stdout, and exits. Requires exactly one flavor argument. Useful for generating reproducible artifact names in scripts. |
| `--print-container-image` | *(none)* | Off | Prints the pinned builder container image reference to stdout and exits immediately. Useful for scripts that need to pull or inspect the builder image independently of running a build. |
| `--apparmor-profile` | `<profile>` | Auto-detected | Applies the named AppArmor profile to the builder container, replacing the default `apparmor=unconfined`. If not set and Docker is used on a host with `kernel.apparmor_restrict_unprivileged_userns = 1`, the script detects the restriction and offers to create a `builder` profile at `/etc/apparmor.d/builder` automatically. |

### `make` flags

Any argument not consumed by the option parser above is forwarded to `make` inside the builder
container. The most commonly used `make` flag is:

| Flag | Argument | Description |
|---|---|---|
| `-j` | `<number>` | Number of flavors to build in parallel. Each parallel thread requires at least 8 GiB of RAM. There are no safeguards against memory exhaustion. |

### Flavor Syntax

```
<platform>[-<feature>...]-[<arch>]
```

| Component | Position | Required | Description |
|---|---|---|---|
| `<platform>` | First | Yes | Target platform. See [Supported Platforms](#supported-platforms). |
| `<feature>` | Middle | No | One or more features from the `features/` directory, separated by `-`. Features whose names begin with `_` are appended directly without a preceding `-`. |
| `<arch>` | Last | No | Target CPU architecture. Defaults to the native host architecture. See [Supported Architectures](#supported-architectures). |

### Supported Architectures

| Value | Description |
|---|---|
| `amd64` | 64-bit x86 |
| `arm64` | 64-bit Arm (AArch64) |

:::info
[Cross-architecture builds](/explanation/builder#cross-architecture-builds) require
[binfmt_misc](https://docs.kernel.org/admin-guide/binfmt-misc.html) handlers and QEMU
user-mode emulation (`qemu-user-static`) on the build host.
:::

### Supported Platforms

| Platform | Category | Description |
|---|---|---|
| [`ali`](/reference/features/ali) | Public cloud | Alibaba Cloud |
| [`aws`](/reference/features/aws) | Public cloud | Amazon Web Services |
| [`azure`](/reference/features/azure) | Public cloud | Microsoft Azure |
| [`bare`](/reference/features/bare) | Container | Bare (distroless) container base image |
| [`container`](/reference/features/container) | Container | Full container base image |
| [`gcp`](/reference/features/gcp) | Public cloud | Google Cloud Platform |
| [`gdch`](/reference/features/gdch) | Public cloud | Google Distributed Cloud Hosted |
| [`kvm`](/reference/features/kvm) | Hypervisor | KVM/QEMU virtualization |
| [`baremetal`](/reference/features/baremetal) | Bare metal | Physical server deployment |
| [`openstack`](/reference/features/openstack) | Private cloud | OpenStack |
| [`vmware`](/reference/features/vmware) | Hypervisor | VMware vSphere/ESXi |
| [`lima`](/reference/features/lima) | Local dev | Lima for macOS and Linux |

### Supported Container Engines

| Value | Description |
|---|---|
| `podman` | Rootless Podman (recommended). Requires a working rootless Podman setup. See the [Podman rootless setup guide](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md). |
| `sudo podman` | Podman with `sudo` for elevated privileges. |
| `docker` | Docker Engine. On systems where `kernel.apparmor_restrict_unprivileged_userns = 1`, an AppArmor profile is required (see `--apparmor-profile` above). |

### `build.config` File

If a `build.config` file exists in the working directory, it is sourced by `./build` before the
container is launched. It can override build variables that are otherwise set to their defaults.

| Variable | Default | Description |
|---|---|---|
| `tempfs_size` | `2G` | Size of the temporary filesystem used during the build, passed to the builder as `TEMPFS_SIZE`. Increase this if builds fail due to insufficient temporary space. |

---

## `./cert/build`

The `./cert/build` script generates the Secure Boot certificate chain required for
[`_trustedboot`](/reference/features/_trustedboot), [`_tpm2`](/reference/features/_tpm2),
and [`_secureboot`](/reference/features/_secureboot) images.

### Synopsis

```
./cert/build [OPTIONS] [clean]
```

### Options

| Option / Argument | Description |
|---|---|
| `--kms` | Store private keys in AWS Key Management Service instead of local files. Requires valid AWS credentials via standard AWS environment variables. |
| `clean` | Remove previously generated certificate files before regenerating. Use this if a previous `./cert/build` run failed or produced incomplete output. |

### Output Files

After a successful run, the `cert/` directory contains:

| File | Format | Purpose |
|---|---|---|
| `secureboot.pk.esl` | ESL | AWS external enrollment — Platform Key |
| `secureboot.kek.esl` | ESL | AWS external enrollment — Key Exchange Key |
| `secureboot.db.esl` | ESL | AWS external enrollment — Signature Database |
| `secureboot.pk.der` | DER | GCP, Azure — Platform Key |
| `secureboot.kek.der` | DER | GCP, Azure — Key Exchange Key |
| `secureboot.db.der` | DER | GCP, Azure — Signature Database |
| `secureboot.db.crt` | PEM | Image signing during build |
| `secureboot.aws-efivars` | Binary blob | Pre-filled AWS UEFI variable store for external Secure Boot enrollment |

For cloud-provider-specific enrollment steps, see [Deploying Secure Boot Images](/how-to/secure-boot).

## Related Topics

<RelatedTopics />
