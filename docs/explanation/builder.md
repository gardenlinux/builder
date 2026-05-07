---
title: "Builder"
description: "Conceptual overview of the Garden Linux Builder build system, architecture and design philosophy"
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
github_source_path: docs/explanation/builder.md
github_target_path: docs/explanation/builder.md
---

# How the Build System Works

## The Builder

Garden Linux images are produced by [gardenlinux/builder](https://github.com/gardenlinux/builder),
a dedicated build tool maintained separately from the main
[gardenlinux/gardenlinux](https://github.com/gardenlinux/gardenlinux) repository. This separation
means the build infrastructure can evolve independently of the distribution content.

The `./build` script in the `gardenlinux/gardenlinux` repository is the primary entry point. It
automatically fetches the correct builder container image, then delegates all internal build steps
to it. As a result, the only hard dependency on the host system is a working container engine —
no specific Linux distribution, compiler toolchain, or package set is required on the build host.

## Design Philosophy

The build system is designed around three principles:

- **Minimal host dependencies** — The build runs entirely inside a container. Apart from the
  container engine itself, the host needs no build tools.
- **Composability** — Images are assembled from reusable [features](/explanation/flavors#feature-based-design)
  rather than hand-crafted for each target. The same feature definition is reused across all
  platforms that include it.
- **Reproducibility** — The builder container is versioned and pinned, so a given combination
  of source code and feature set should produce the same image regardless of when or where it
  is built.

## Flavor Names as Build Inputs

The build command takes a *flavor name* as its argument. A flavor name directly encodes what
will be built:

```
<platform>-<feature1>-<feature2>_<feature3>-<arch>
```

For example, `aws-gardener_prod-amd64` tells the builder to produce an AWS image (`aws`) with
the [`gardener`](/reference/features/gardener) and [`_prod`](/reference/features/_prod) features for the `amd64` architecture. The build script parses this
name and assembles the image by combining the specified platform and features.

For a full explanation of how flavors and features compose, including the [CNAME system](/explanation/flavors#the-cname-system) and how
features are joined, see [Flavors](/explanation/flavors).

## Cross-Architecture Builds

By default, the builder targets the native architecture of the build host. Building for a
different architecture (for example, building `arm64` images on an `amd64` host) requires
the host to be able to execute foreign binaries.

The standard mechanism for this on Linux is
[binfmt_misc](https://docs.kernel.org/admin-guide/binfmt-misc.html), a kernel feature that
registers handlers for non-native executable formats. When combined with QEMU user-mode
emulation (`qemu-user-static`), the kernel transparently invokes the correct QEMU binary
whenever the builder attempts to run an `arm64` binary inside the container.

Cross-architecture builds are slower than native builds because every foreign-architecture
instruction goes through QEMU emulation.

## Certificates for Secure Boot and Trusted Boot

Images that use the [`_trustedboot`](/reference/features/_trustedboot),
[`_tpm2`](/reference/features/_tpm2), or [`_secureboot`](/reference/features/_secureboot)
features must be signed with a custom certificate chain. This is because UEFI Secure Boot
validates the bootloader and kernel against enrolled certificates before execution — without
a valid signature, the firmware refuses to boot the image.

The `./cert/build` script generates this certificate chain (Platform Key, Key Exchange Key,
and Signature Database) inside a container, keeping the same minimal-dependency model as the
main build. The private keys are stored locally in the `cert/` directory by default, or in
AWS Key Management Service (KMS) when the `--kms` flag is used.

For the conceptual background on why signing is required and how Secure Boot and Trusted Boot
interact with the USI boot mode, see
[Boot Modes](/explanation/boot-modes) and
[Secure Boot and Trusted Boot](/explanation/secure-boot).

For step-by-step build and deployment instructions, see
[Building Images](/how-to/building-images) and
[Deploying Secure Boot Images](/how-to/secure-boot).

## Related Topics

<RelatedTopics />
