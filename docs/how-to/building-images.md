---
title: "Building Images"
description: "Step-by-step guide to building Garden Linux images locally with the Builder"
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
github_source_path: "docs/how-to/building-images.md"
github_target_path: "docs/how-to/building-images.md"
---

# Building Images

This guide walks you through building Garden Linux images locally. For conceptual background on
how the build system works, see [Builder Explanation](/explanation/builder).

## Prerequisites

:::warning
Provide at least **8 GiB of RAM** to the container runtime or the virtual machine hosting it
(in Podman Desktop or Docker Desktop). The build may fail silently if memory is insufficient.
:::

You need a working container engine. Three options are supported:

- **Rootless Podman** (recommended) — See the
  [Podman rootless setup guide](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)
  for setup instructions.
- **Sudo Podman** — Use Podman with `sudo` for elevated privileges.
- **Docker** — Use Docker.

:::info
See [Builder Command-Line Reference](/reference/builder#options) how to pass the container engine.
:::

## Build an Image

Run the build script with the target flavor name:

```bash
./build ${platform}-${feature1}-${feature2}-${arch}
```

Where:

- `${platform}` — the target platform (e.g. `kvm`, `metal`, `aws`); must be the first component.
- `${featureX}` — one or more features from the `features/` directory, separated by `-`
  (or `_` for features whose names begin with `_`).
- `${arch}` — optional target architecture (`amd64` or `arm64`); must be the last component.

Examples:

```bash
./build kvm-python_dev
./build aws-gardener_prod-amd64
```

For a full list of build script options, see the
[Builder Command-Line Reference](/reference/builder).

For help choosing a flavor name, see [Choosing Flavors](/how-to/choosing-flavors).

## Run Parallel Builds

To build multiple targets simultaneously, use the `-j` flag:

```bash
./build -j 4 kvm-amd64 kvm-arm64 aws-gardener_prod-amd64 aws-gardener_prod-arm64
```

:::warning
Parallel builds multiply memory usage. Allow at least **8 GiB per thread**. There are no
safeguards against memory exhaustion; builds may fail silently if memory runs out.
:::

## Build for a Different Architecture

Append the target architecture to the flavor name:

```bash
./build kvm-amd64 kvm-arm64
```

:::info
[Cross-architecture builds](/explanation/builder#cross-architecture-builds) require
[binfmt_misc](https://docs.kernel.org/admin-guide/binfmt-misc.html) handlers and QEMU
user-mode emulation (`qemu-user-static`) on the build host.

```bash
apt install qemu-user-static
```
:::


## Build Secureboot / Trustedboot / TPM2 Images

Before building any image with the `_tpm2`, `_trustedboot`, or `_secureboot` feature, generate
the signing certificates:

```bash
./cert/build
```

:::tip
Do not use the `Makefile` in `cert/` directly. Always use `./cert/build`.
If `./cert/build` fails, try running `./cert/build clean` first.
:::

By default, private keys are stored locally in the `cert/` directory. To use AWS Key Management
Service instead, pass the `--kms` flag (valid AWS credentials must be configured via the standard
AWS environment variables):

```bash
./cert/build --kms
```

After generating certificates, build the image as normal:

```bash
./build kvm-trustedboot
./build aws-trustedboot_tpm2
```

For conceptual background on these features, see [Boot Modes](/explanation/boot-modes) and
[Secure Boot and Trusted Boot](/explanation/secure-boot). For cloud deployment steps, see
[Deploying Secure Boot Images](/how-to/secure-boot).

## Troubleshooting

If you encounter build failures, refer to the
[Garden Linux builder troubleshooting section](https://github.com/gardenlinux/builder#troubleshooting).

## Related Topics

<RelatedTopics />
