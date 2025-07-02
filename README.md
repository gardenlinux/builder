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

If you decide to use `docker` on a system restricting unprivileged user namespaces with apparmor (e.g. Ubuntu 23.10 or newer) an apparmor profile allowing `userns` is required. This can be automatically created and selected by the Builder by opting in to the permanent system change. You can avoid this by:

- Using `podman`
- Passing a custom profile using the `--apparmor-profile` option
- Using a system not restricting unprivileged user namespaces

## Config Directory

A config directory serves as the input for the Builder and is used to create a Linux system image. It consists of the following components:

- **`features` directory**: Contains sub-directories for each feature. You can create your own features by referring to [features.md](docs/features.md).

- **`cert` directory** (optional): If you plan to use secure boot, include a `cert` directory.

In addition to the above components, your configuration directory must include the following configuration scripts:

- `get_commit`: This script should output the Git commit used to tag the build artifacts.
- `get_repo`: This script should output the apt package repository to use.
- `get_timestamp`: This script should output the timestamp to be used instead of the real system time, ensuring reproducibility of builds.
- `get_version`: This script should output the version of the package repository to use. For example, use `trixie` for Debian or `today` for Garden Linux.
- `keyring.gpg`: The PGP key used to validate the package repository. For Debian, you can obtain this key from the [debian-archive-keyring](https://packages.debian.org/trixie/debian-archive-keyring) package.

For a quick start guide on setting up your own config directory with your own features checkout [getting_started.md](docs/getting_started.md).

### Example Config Directory

If you're new to configuring the Builder, you can find a minimal example config directory at [gardenlinux/builder_example](https://github.com/gardenlinux/builder_example). For a more comprehensive example, refer to the main [gardenlinux](https://github.com/gardenlinux/gardenlinux) repository.

Feel free to explore these examples to gain a better understanding of how to effectively structure your own config directory.


## Local Development

To test changes made to the builder locally you can simply create a symlink to the build script inside the builder directory inside a config directory. This will automatically be detected by the build script and the builder re-build iff necessary.

e.g.: if you have the gardenlinux and builder repos both inside the same parent directory and you want to work on the builder you would do the following:

```
cd gardenlinux
ln -f -s ../builder/build build
```

Now you can make your modifications inside the builder directory and running `./build ${target}` inside the gardenlinux repo will use the local builder, rebuilding the build container if necessary.
