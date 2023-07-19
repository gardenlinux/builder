# Getting Started: Creating a Custom Linux Image with Builder

This tutorial will walk you through the process of creating a custom Linux image using the Builder tool. We will start with the Builder example repository and build a feature to add an `nginx` HTTP server to our image.

Let's begin by cloning the Builder example repository:

```shell
git clone https://github.com/gardenlinux/builder_example
cd builder_example
```

To ensure that your local Podman installation is working correctly, you can test it by running the following command:

```shell
./build base
```

This command will create a bootable Debian Bookworm disk image at `.build/base-amd64-bookworm-6f72b564.raw` (note that the commit may have changed since the time of writing). You can test run the image using QEMU:

```shell
qemu-system-x86_64 -m 2048 -nodefaults -display none -serial mon:stdio -drive if=pflash,unit=0,readonly=on,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=virtio,format=raw,file=.build/base-amd64-bookworm-6f72b564.raw
```

Now that we have verified that everything is working correctly, let's proceed to build our own feature.

## Creating the Nginx Feature

1. Create a directory called `nginx` inside the `features` directory:

```shell
mkdir features/nginx
```

2. Create a file named `info.yaml` inside `features/nginx` and edit it with the content below:

```yaml
description: HTTP server using Nginx
type: element
```

3. Create a file named `pkg.include` inside `features/nginx` with the following content:

```
nginx
```

4. Create a file named `exec.config` inside `features/nginx` with the following content:

```shell
#!/usr/bin/env bash

set -eufo pipefail

systemctl enable nginx
```

5. Make the `exec.config` file executable:

```shell
chmod +x features/nginx/exec.config
```

6. Create a directory named `/var/www/html` inside the `file.include` directory of Nginx:

```shell
mkdir -p features/nginx/file.include/var/www/html
```

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
./build base-nginx
```

You can then run the image with QEMU using the following command:

```shell
qemu-system-x86_64 -m 2048 -nodefaults -display none -serial mon:stdio -drive if=pflash,unit=0,readonly=on,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=virtio,format=raw,file=.build/base-nginx-amd64-bookworm-local.raw -netdev user,id=net0,hostfwd=tcp::8080-:80 -device virtio-net-pci,netdev=net0
```

If everything worked as intended, you should see the system boot up. Once the system is booted, opening http://localhost:8080 in a browser should display the "Hello World!" message.

Congratulations! You have successfully created your first feature for the Builder. :tada:
