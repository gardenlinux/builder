# Builder

The Builder is a powerful tool for effortlessly building Linux system images based on config directories. It serves as the primary build tooling for the [gardenlinux](https://github.com/gardenlinux/gardenlinux) project.

By default, the Builder runs inside rootless Podman, enabling building without requiring elevated permissions.

## Requirements

The Builder has minimal dependencies and only requires a working container engine. We recommend using rootless Podman. Please refer to the [Podman rootless setup guide](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md) for instructions on setting it up.

## Usage

To utilize the Builder, follow these steps:

1. Download the latest version of the [build script](https://github.com/gardenlinux/builder/releases/download/latest/build).
2. Run the build script within a config directory.

```shell
wget https://github.com/gardenlinux/builder/releases/download/latest/build
./build ${target}
```

By default, the Builder uses `podman` as the container engine. If you prefer using a different container engine, you can specify it using the `--container-engine` option.

## Config Directory

A config directory serves as the input for the Builder and is used to create a Linux system image. It consists of the following components:

- **`features` directory**: Contains sub-directories for each feature. You can create your own features by referring to the example in [gardenlinux/features/example](https://github.com/gardenlinux/gardenlinux/tree/main/features/example).

- **`cert` directory** (optional): If you plan to use secure boot, include a `cert` directory.

In addition to the above components, your configuration directory must include the following configuration scripts:

- `get_commit`: This script should output the Git commit used to tag the build artifacts.
- `get_repo`: This script should output the apt package repository to use.
- `get_timestamp`: This script should output the timestamp to be used instead of the real system time, ensuring reproducibility of builds.
- `get_version`: This script should output the version of the package repository to use. For example, use `bookworm` for Debian or `today` for Garden Linux.
- `keyring.gpg`: The PGP key used to validate the package repository. For Debian, you can obtain this key from the [debian-archive-keyring](https://packages.debian.org/bookworm/debian-archive-keyring) package.

### Example Config Directory

If you're new to configuring the Builder, you can find a minimal example config directory at [gardenlinux/builder_example](https://github.com/gardenlinux/builder_example). For a more comprehensive example, refer to the main [gardenlinux](https://github.com/gardenlinux/gardenlinux) repository.

Feel free to explore these examples to gain a better understanding of how to effectively structure your own config directory.
