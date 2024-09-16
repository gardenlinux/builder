# Features

Each feature must contain an `info.yaml` file that adheres to the following structure:

## `info.yaml` file structure:

- `description`: (*optional*) A string explaining the purpose or functionality of the feature.
- `type`: Can be one of the following:
  - `platform`
  - `element`
  - `flag`
  - While the builder does not make any technical distinctions between these feature types, it is recommended that each image uses only one `platform`, and `flag` should be used for minor changes without including other features.
- `features`: (*optional*) A sub-structure that contains related features.
	- `include`: (*optional*) A list of features that will automatically be included if this feature is selected.
	- `exclude`: (*optional*) A list of features that are incompatible with this feature. If any of these features were implicitly included from another feature, they will be removed from the feature set. If they were explicitly provided as part of the target, the build will fail.

Here's an example of an `info.yaml` file:

```yaml
description: Example platform feature
type: platform
features:
  include:
    - A
    - B
  exclude:
    - C
```

In addition to the `info.yaml` file, a feature may include the following options:

## `pkg.include`

A list of packages to be installed into the image.

## `pkg.exclude`

A list of packages to be ignored if they are provided by another feature's `pkg.include` option.

## `file.include`

A directory containing files to be copied into the target rootfs. This directory is recursively copied into the root directory. By default, only the executable bit of the file permissions is preserved during the copy process. The other permissions will be set to read/write for the owner and read-only for the group and others. The owner of all copied files will be root by default.

To override these defaults, refer to the `file.include.stat` option below.

## `file.include.stat`

A file that specifies the owner and permissions for files copied by `file.include`. Each line should follow the format:

```
user group permissions file
```

## `file.exclude`

A list of files/directories to be removed from the rootfs at the end of the configure stage. Wildcards in file paths are allowed.

## `exec.config`, `exec.early`, `exec.late`, `exec.post`

Scripts to be executed for image configuration. Script files need the executable bit set. All scripts except `exec.post` are executed within the rootfs of the system being built without any parameters. `exec.post` is executed within the builder container, and the path of the rootfs is provided as `argv[1]`.

The order of execution is as follows:

- Bootstrap (outside chroot)
- `exec.early`
- Package installation (from `pkg.include`)
- Copy files from `file.include` and set permissions according to `file.include.stat`
- `exec.config`
- `exec.late`
- Remove files according to `file.exclude`
- `exec.post` (outside chroot)

When building with multiple features, the execution steps of each feature are interleaved. For example, the `exec.config` step will run for all features before any features' `exec.late` step runs.

## `fstab`, `fstab.mod`

The partition layout of the build image can be defined in an fstab like format.
The format is:

```
<part identifier>    <mount point>    <fs type>    <mount options>    <advanced args>
```

- `<part identifier>`: can be either of the form `LABEL=<label>` or `UUID=<uuid>`
- `<mount point>`: where the partition will be mounted, it will automatically be initialized with the corresponding sub-tree of the rootfs during build.
- `<fs type>`: which file system to use for this partition. supported values: `ext4`, `vfat`, `swap`
- `<mount options>`: the same mount options as in a regular `/etc/fstab`
- `<advanced args>`: these are additional args parsed by `makepart`. supported options:
  - `type=<type>`: overwrite the default GPT partition type
  - `size=<size>`: instead of dynamically calculating the ideal size for the partition set it explicitly
  - `syslinux`: mark this as a partition on whith to install syslinux to the FAT32 boot sectors
  - `weight`: deprecated
  - `final_partition`: ensure this partition is placed at the end of the partition table regardless of default sorting. if you don't know why you'd need this you likely shouldn't use it!

The `fstab` can be defined with an equally named file in one and only one feature.
Additionally, other features can apply modifications to this base `fstab`.
For this features can define executable `fstab.mod` scripts.
These scripts are executed in the same order as regular config scripts, each recieving the output of the previous script as its input.
The first script in the series recieves the init `fstab` file.
The output of the final file will be used as the effective `fstab`.

> [!IMPORTANT]
> This pipeline design implies that it is the responsibility of every `fstab.mod` script to re-echo any entry they do not want to modify.
> Otherwise this is seen as the script dropping the entry.

## `image`, `image.<ext>`, `convert.<ext>`, `convert.<extA>~<extB>`

Alternative, or additionally, to the `fstab` mechanism the builder also offers more fine grained control over image creation via explicit image create and convert scripts.

The `image` and `image.<ext>` scripts are used to directly create an image given a rootfs tar.
They get a path to the rootfs tar as `argv[1]` and a path where the target image should be written as `argv[2]`.
The `image` script outputs a `.raw` artifact, the `image.<ext>` script does the same but for `.<ext>` artifacts.

The convert scripts instead convert an image artifact created by an imaging script to another image format. e.g. convert a raw image to a VM manager specific format.
Scripts of the form `convert.<ext>` get the raw image as input and produce a `.<ext>` output.
Scripts of the form `convert.<extA>~<extB>` get `.<extB>` as input and produces `.<extA>` as output.
The second form is only useful for advanced use cases, if you are not aware of one, you'll probably never need it!
