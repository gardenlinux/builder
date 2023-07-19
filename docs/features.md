# Features

Each feature must at least contain an `info.yaml` file

The `info.yaml` file has the following structure fields:

- `description`: (*optional*) a string explaining what this feature does / what it is used for.
- `type`: can be any of `platform`, `element`, or `flag`. The builder does not make any technical distinction between each type of feature, however it is strongly encouraged that each image uses exactly one platform and flags should only perform minor changes and not include any other features.
- `features`: (*optional*) sub-structure containing related features
	- `include`: (*optional*) list of features that will automatically be included as well if this feature gets included
	- `exclude`: (*optional*) list of features that are incompatible with this feature. If any of these features were included implicitly from another they will be removed from the feature set. If they were explicitly provided as part of the target the build will fail.

An example `info.yaml` looks as follows:

```yaml
description: example platform feature
type: platform
features:
  include:
    - A
    - B
  exclude:
    - C
```

Additionally a feature may contain any of the following:

## `pkg.include`

A list of packages to be installed into the image.

## `pkg.exclude`

A list of packages to be ignored if provided by another features `pkg.include`

## `file.include`

A directory containing files to copy into the target rootfs.
This directory is copied recursively into the root directory.
By default only the executable bit of the files permission will be preserved when copying.
The other permissions will be set to read write for owner and read for group and other.
The owner of all copied files will be root by default.

To overwrite these defaults see `file.include.stat` below

## `file.include.stat`

A file to assign owner and permissions to files copied by `file.include`.
Each line should contain an entry of the form:

```
user group permissions file
```

## `file.exclude`

A list of files / directories to remove from the rootfs at the end of the configure stage.
Wildcard in file paths are allowed.

## `exec.config` `exec.early` `exec.late` `exec.post`

Scripts to be executed to configure the image.
All scripts except `exec.post` are executed inside the rootfs of the system being build without any parameters.
`exec.post` is executed inside the builder container with the path of the rootfs provided as `argv[1]`.

The order of exectution is as follows:

- bootstrap (outside chroot)
- `exec.early`
- package install (from `pkg.include`)
- copy files from `file.include` and set permissions according to `file.stat`
- `exec.config`
- `exec.late`
- remove files according to `file.exclude`
- `exec.post` (outside chroot)

When building with multiple features the execution steps of each feature are interleaved; so for example the `exec.config` step will run for all features before any features `exec.late` runs.
