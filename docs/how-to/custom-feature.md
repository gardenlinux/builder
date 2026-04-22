---
title: "Building a custom Feature"
description: Create a custom Feature and build an image with the Builder
related_topics:
  - /reference/supporting_tools/builder.md
  - /reference/features/
  - /how-to/custom-feature
migration_status: "done"
migration_issue: "https://github.com/gardenlinux/gardenlinux/issues/4628"
migration_stakeholder: "@tmangold, @yeoldegrove, @ByteOtter"
migration_approved: false
github_org: gardenlinux
github_repo: builder
github_source_path: docs/how-to/custom-feature.md
github_target_path: docs/how-to/custom-feature.md
---

# Create a custom Feature and build an image with the Builder

The [Builder](https://github.com/gardenlinux/builder) is a generic, containerized tool for building Linux system images from config directories. It is reusable by any project that needs to create customized Linux distributions.

This guide covers two scenarios:

1. **Creating a custom feature for a [Debian-based builder project](#debian-based-builder-project)** — using the Builder standalone with your own config directory.
2. **Creating a custom feature for the [Garden Linux Distribution](#garden-linux-distribution)** — adding a feature to the Garden Linux distribution.

Both scenarios will work with the [Creating a custom Feature](#creating-a-custom-feature) guide.

---

## Debian-based builder project

This section walks you through creating a custom feature in a standalone Builder project, such as one created from the [builder_example](https://github.com/gardenlinux/builder_example) template.

Let's begin by creating a new GitHub repository based on the Builder example repository using this link:

https://github.com/new?template_name=builder_example&template_owner=gardenlinux

This repo has a GitHub Actions workflow enabled, so it will already start building the image on GitHub's hosted runners.

### Customizing the image

To customize the image, clone the repo locally:

```shell
git clone https://github.com/your_username/my_linux_image
cd my_linux_image
```

To ensure that your local Podman installation is working correctly, you can test it by running the following command:

```shell
./build base
```

This command will create a bootable Debian Forky disk image at `.build/base-amd64-forky-6f72b564.raw` (note that the commit may have changed since the time of writing).
You can test run the image using [QEMU](https://www.qemu.org):

```shell
qemu-system-x86_64 -m 2048 -nodefaults -display none -serial mon:stdio -drive if=pflash,unit=0,readonly=on,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=virtio,format=raw,file=.build/base-amd64-forky-6f72b564.raw
```

Now that you have verified that everything is working correctly, proceed to [creating a custom feature](#creating-a-custom-feature).

## Garden Linux Distribution

This section covers adding a custom feature to the [Garden Linux](https://github.com/gardenlinux/gardenlinux) distribution. Garden Linux uses the Builder as its build engine but adds a rich set of platform and element features.

### Key difference: platform requirement

Garden Linux enforces exactly one `platform` feature per build (see [ADR 0020](../reference/adr/0020-enforce-single-platform-by-default-in-builder.md)). This means:

- Running `./build base` **fails** because `base` is an `element`, not a `platform`.
- Running `./build myfeature` **fails** unless `myfeature` is a platform.
- You must always specify a platform: `./build kvm-myfeature-amd64`

:::warning
Garden Linux requires exactly one platform feature per build. Running `./build base` or `./build myfeature` without a platform fails. Always include a platform, for example: `./build kvm-myfeature-amd64`.
:::

### Feature types in Garden Linux

Garden Linux features follow the same structure as vanilla builder features, but use three types:

- **`platform`** — target platform such as `kvm`, `aws`, `azure`, `metal`, `gcp`. Rarely created by users.
- **`element`** — significant feature that may include/exclude other features, e.g., `server`, `cloud`, `cis`, `fedramp`.
- **`flag`** — minor toggles, conventionally prefixed with `_`, e.g., `_prod`, `_slim`, `_selinux`.

### Customizing the image

To customize the image, clone the repo locally:

1. Clone the Garden Linux repository:

```shell
git clone https://github.com/gardenlinux/gardenlinux
cd gardenlinux
```

To ensure that your local Podman installation is working correctly, you can test it by running the following command:

```shell
./build kvm-base
```

This command will create a bootable Garden Linux disk image at `.build/kvm-base-amd64-today-6f72b564.raw` (note that the commit may have changed since the time of writing).
You can test run the image using [QEMU](https://www.qemu.org):

```shell
qemu-system-x86_64 -m 2048 -nodefaults -display none -serial mon:stdio -drive if=pflash,unit=0,readonly=on,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=virtio,format=raw,file=.build/kvm-base-amd64-today-6f72b564.raw
```

Now that you have verified that everything is working correctly, proceed to [creating a custom feature](#creating-a-custom-feature).

## Creating a custom feature

We will create a custom feature (an element in the Garden Linux structure) and deploy a Nginx Webserver as an example.

1. Create a directory called `nginx` inside the `features` directory:

```shell
mkdir features/nginx
```

This is where our nginx feature will live.
Features are a concept of the builder that allows us to build variants of images.
For example, if we wanted to add an alternative HTTP server later, we could add an `apacheHttpd` feature.
At image build time, we could pick if we want the `nginx` or the `apacheHttpd` feature.

2. Create a file named `info.yaml` inside `features/nginx` and edit it with the content below:

```yaml
description: HTTP server using Nginx
type: element
features:
  include:
    - base
```

The `info.yaml` file is required for each feature by the builder.
We specify that our `nginx` feature includes the `base` feature.
This makes sense because the `nginx` feature on its own does not contain a full operating system, so to get a bootable image we include the debian system as it is defined in `base`.
See the [features documentation](/reference/features/) for detailed information on the structure of features.

3. Create a file named `pkg.include` inside `features/nginx` with the following content:

```
nginx
```

`pkg.include` is a list of packages this feature needs, each on a new line.

4. Create a file named `exec.config` inside `features/nginx` with the following content:

```shell
#!/usr/bin/env bash

set -eufo pipefail

systemctl enable nginx
```

`exec.config` is a shell script we can use to customize our image.
In this case, we [enable the systemd unit for nginx](https://www.freedesktop.org/software/systemd/man/latest/systemctl.html#enable%20UNIT…) which makes nginx start on boot.

5. Make the `exec.config` file executable:

```shell
chmod +x features/nginx/exec.config
```

6. Create a directory named `/var/www/html` inside the `file.include` directory of Nginx:

```shell
mkdir -p features/nginx/file.include/var/www/html
```

The `file.include` directory allows us to merge files and directories into the root filesystem of our image.

7. Create a dummy `index.html` file inside `features/nginx/file.include/var/www/html` with content like the following:

```html
<!DOCTYPE html>
<html>
  <body>
    <p>Hello World!</p>
  </body>
</html>
```

To test your feature, build the image using the following command:

```shell
# vanilla builder
./build nginx
# builder inside gardenlinux repo
./build kvm-nginx
```

You can then run the image with QEMU using the following command:

```shell
# vanilla builder
qemu-system-x86_64 -m 2048 -nodefaults -display none -serial mon:stdio -drive if=pflash,unit=0,readonly=on,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=virtio,format=raw,file=.build/nginx-amd64-forky-local.raw -netdev user,id=net0,hostfwd=tcp::8080-:80 -device virtio-net-pci,netdev=net0
# builder inside gardenlinux repo
qemu-system-x86_64 -m 2048 -nodefaults -display none -serial mon:stdio -drive if=pflash,unit=0,readonly=on,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=virtio,format=raw,file=.build/kvm-nginx-amd64-today-local.raw -netdev user,id=net0,hostfwd=tcp::8080-:80 -device virtio-net-pci,netdev=net0
```

If everything worked as intended, you should see the system boot up. Once the system is booted, opening http://localhost:8080 in a browser should display the "Hello World!" message.

To also build the new image on GitHub Actions, modify the `.github/workflows/build.yml` file.

Change the _build_ step to include the `nginx` feature you just created, and upload the built image to GitHub's artifact storage:

```diff
diff --git a/.github/workflows/build.yml b/.github/workflows/build.yml
index 181a646..9e4261e 100644
--- a/.github/workflows/build.yml
+++ b/.github/workflows/build.yml
@@ -13,4 +13,8 @@ jobs:
     steps:
       - uses: actions/checkout@v3
       - name: Build the image
-        run: ./build base
+        run: ./build nginx
+      - uses: actions/upload-artifact@v4
+        with:
+          name: my-linux-image
+          path: .build/
```

Commit and push your changes and GitHub will build the image for you.

You have successfully created your first feature with the Builder and set up a CI pipeline to build the image.

## Related Topics

<RelatedTopics />
