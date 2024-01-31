# Getting Started: Creating a Custom Linux Image with Builder

This tutorial will walk you through the process of creating a custom Linux image using the Builder tool.
We will start with the Builder example repository and build a *feature* to add an [`nginx` HTTP server](https://nginx.org/en/) to our image.

Let's begin by creating a new GitHub repository based on the Builder example repository using this link:

https://github.com/new?template_name=builder_example&template_owner=gardenlinux

This repo has a GitHub Actions workflow enabled, so it will already start building the image on GitHub's hosted runners.

To customize the image, clone the repo locally:

```shell
git clone https://github.com/your_username/my_linux_image
cd my_linux_image
```

To ensure that your local Podman installation is working correctly, you can test it by running the following command:

```shell
./build base
```

This command will create a bootable Debian Trixie disk image at `.build/base-amd64-trixie-6f72b564.raw` (note that the commit may have changed since the time of writing).
You can test run the image using [QEMU](https://www.qemu.org):

```shell
qemu-system-x86_64 -m 2048 -nodefaults -display none -serial mon:stdio -drive if=pflash,unit=0,readonly=on,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=virtio,format=raw,file=.build/base-amd64-trixie-6f72b564.raw
```

Now that we have verified that everything is working correctly, let's proceed to build our own feature.

## Creating the Nginx Feature

1. Create a directory called `nginx` inside the `features` directory:

```shell
mkdir features/nginx
```

> This is where our nginx feature will live.
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

> The `info.yaml` file is required for each feature by the builder.
We'll specify that our `nginx` feature includes the `base` feature.
This makes sense because the `nginx` feature on its own does not contain a full operating system, so to get a bootable image we include the debian system as it is defined in `base`.
See [features.md](./features.md) for detailed information on the structure of features.

1. Create a file named `pkg.include` inside `features/nginx` with the following content:

```
nginx
```


> `pkg.include` is a list of packages this feature needs, each feature on a new line.

4. Create a file named `exec.config` inside `features/nginx` with the following content:

```shell
#!/usr/bin/env bash

set -eufo pipefail

systemctl enable nginx
```


> `exec.config` is a shell script we can use to customize our image.
In this case, we [enable the systemd unit for nginx](https://www.freedesktop.org/software/systemd/man/latest/systemctl.html#enable%20UNIT…) which makes nginx start on boot.

5. Make the `exec.config` file executable:

```shell
chmod +x features/nginx/exec.config
```

6. Create a directory named `/var/www/html` inside the `file.include` directory of Nginx:

```shell
mkdir -p features/nginx/file.include/var/www/html
```


> The `file.include` directory allows us to merge files and directories into the root filesystem of our image.

7. Create a dummy `index.html` file inside `features/nginx/file.include/var/www/html` with content like the following (or customize it as desired):

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
./build nginx
```

You can then run the image with QEMU using the following command:

```shell
qemu-system-x86_64 -m 2048 -nodefaults -display none -serial mon:stdio -drive if=pflash,unit=0,readonly=on,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=virtio,format=raw,file=.build/nginx-amd64-trixie-local.raw -netdev user,id=net0,hostfwd=tcp::8080-:80 -device virtio-net-pci,netdev=net0
```

If everything worked as intended, you should see the system boot up. Once the system is booted, opening http://localhost:8080 in a browser should display the "Hello World!" message.

To also build the new image on GitHub Actions, we'll need to modify the `.github/workflows/build.yml` file.

Let's change the *build* step to include the `nginx` feature we just created, and let's upload our built image to GitHub's artifact storage:

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
+      - uses: actions/upload-artifact@v3
+        with:
+          name: my-linux-image
+          path: .build/
```

Now commit and push your changes and GitHub will build the image for you.

Congratulations! You have successfully created your first feature for the Builder and setup a CI Pipeline to build the image. :tada:
