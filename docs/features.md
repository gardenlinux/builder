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
