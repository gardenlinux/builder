---
title: Features
description: Feature types, dependency graph resolution, and composition rules in Garden Linux
order: 121
related_topics:
  - /explanation/flavors.md
  - /reference/flavors.md
  - /reference/features/
  - /reference/adr/0034-feature-terminology.md
  - /reference/adr/0020-enforce-single-platform-by-default-in-builder.md
github_org: gardenlinux
github_repo: builder
github_source_path: docs/explanation/features.md
github_target_path: docs/explanation/features.md
---

# Features

## What Is a Feature?

A **feature** is the atomic building block of a Garden Linux image. Each feature is a named directory inside the `features/` tree of the Garden Linux repository containing at minimum an `info.yaml` file that declares its type and dependencies.

Features are not independent. They form a **directed acyclic graph (DAG)** where each feature may declare:

- `features.include` — Other features that are automatically pulled in when this feature is selected
- `features.exclude` — Other features that are removed from the build if they were only transitively included

The DAG is resolved and validated at build time. Explicitly including an excluded feature is a hard build error.

A feature is not just a package list, but a complete configuration unit that may include:

- **Packages** — APT packages to install
- **Configuration files** — System configuration with appropriate defaults
- **Scripts** — Setup and lifecycle scripts
- **Dependencies** — A list of other features to include or exclude

For example, the [`gardener`](/reference/features/gardener) element feature does not just install `containerd` — it also configures systemd services and includes other features such as [`log`](/reference/features/log) to set up logging.

## Feature Types

Every feature has exactly one type, declared in its `info.yaml` file. The type is primarily a descriptive and user-facing classification; it does not change how the feature participates in the DAG or how its content is applied during the build.

The three feature types are defined in [ADR 0034](/reference/adr/0034-feature-terminology):

| Type         | Description                                                                                                                                                                                                                     | Examples                                                  |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| **platform** | Represents the deployment target — the combination of hardware, firmware, and cloud or hypervisor environment the image is intended to run on.                                                                                  | [`aws`](/reference/features/aws), [`azure`](/reference/features/azure), [`gcp`](/reference/features/gcp), [`kvm`](/reference/features/kvm), [`baremetal`](/reference/features/baremetal), [`container`](/reference/features/container)    |
| **element**  | Represents a functional component or capability added on top of the platform. Elements are composable: multiple elements may be present in a single build.                                                                      | [`gardener`](/reference/features/gardener), [`server`](/reference/features/server), [`cloud`](/reference/features/cloud), [`cis`](/reference/features/cis), [`firewall`](/reference/features/firewall), [`metal`](/reference/features/metal) |
| **flag**     | Represents a lightweight modifier. Flags are identified by a leading underscore (`_`) in their name. Flags are intended for minor behavioural changes that do not warrant a full element and should not include other features. | [`_prod`](/reference/features/_prod), [`_fips`](/reference/features/_fips), [`_trustedboot`](/reference/features/_trustedboot), [`_usi`](/reference/features/_usi)                  |

:::tip
A complete list of features can be seen in the [Features Reference](/reference/features/).
:::

## Include/Exclude Semantics and DAG Resolution

When you specify features for a build, the builder resolves the complete feature set by following the DAG:

1. Validate that all available features form a valid DAG (no cycles) — this check runs on the full, unfiltered feature graph before any resolution begins
2. Start with the explicitly requested features
3. Recursively include all features listed in each feature's `features.include` list
4. Remove any features listed in `features.exclude` lists (but only if they were transitively included); attempting to exclude a feature that was explicitly requested is a hard build error

For example, if you request [`aws`](/reference/features/aws) and [`gardener`](/reference/features/gardener):

- The [`aws`](/reference/features/aws) platform feature includes dependencies for cloud-init, kernel modules, etc.
- The [`gardener`](/reference/features/gardener) element feature includes the [`log`](/reference/features/log) feature for logging configuration
- Both features exclude certain features that are incompatible with their use case
- The builder resolves the complete set and validates there are no conflicts

:::tip
For the precise mechanics of how feature content (package lists, file overlays, build-time scripts) is applied during the build, see the [builder reference documentation for features](/reference/features/).
:::

## Single-Platform Rule as Design Decision

Each Garden Linux build enforces exactly one platform feature by default. Specifying zero or multiple platforms causes the build to fail, preventing silent misconfigurations where multiple platforms could produce unpublished or broken images.

This enforcement was introduced to prevent regressions like the `openstackbaremetal` incident where a misconfigured feature set caused images to be silently skipped during publication. See [ADR 0020](/reference/adr/0020-enforce-single-platform-by-default-in-builder) for the full rationale.

If you need to create a build with zero or multiple platforms (a **frankenstein image**), you must explicitly opt in via the `--allow-frankenstein` builder flag. Frankenstein images are not considered a supported configuration.

:::info
When a frankenstein build is created, the `GARDENLINUX_PLATFORM` value in `/etc/os-release` is set to the literal string `frankenstein` instead of a single platform identifier.
:::

## Feature Resolution in `/etc/os-release`

The builder exposes the resolved feature set via `GARDENLINUX_*` keys written into `/etc/os-release` by the `base` feature. For the complete key table, see [Feature resolution in `/etc/os-release`](/reference/features/#feature-resolution-in-etcos-release).

## Further Reading

For information about how features combine to define flavors, see [Flavors](/explanation/flavors).

For the complete file format specification of features (`info.yaml`, `pkg.*`, `file.*`, `exec.*`, etc.), see the [builder features reference](/reference/features/).

For a catalog of all individual features, see the [Features Reference](/reference/features/).

## Related Topics

<RelatedTopics />
