# Getting started

These instructions will guide you through how to create a custom linux image using the builder.
We will start from the builder example repo, and build our own feature on top to add an `nginx` http server.

First clone the builder example repo:

```shell
git clone https://github.com/gardenlinux/builder_example
cd builder_example
```

At this point you can test, that your local podman install works by running `./build base`.
This should create a bootable debian bookworm disk image at `.build/base-amd64-bookworm-6f72b564.raw` (the commit may have changed since the time of writing).
You can test run the image with

```shell
qemu-system-x86_64 -m 2048 -nodefaults -display none -serial mon:stdio -drive if=pflash,unit=0,readonly=on,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=virtio,format=raw,file=.build/base-amd64-bookworm-6f72b564.raw
```

Now that we know all local tooling works, let's start building our own feature.

1. Create a feature directory called `nginx`.

```shell
mkdir features/nginx
```

2. create a file `features/nginx/info.yaml` and edit it using the editor of your choice to have the following content:

```yaml
description: http server using nginx
type: element
```

3. create a file `features/nginx/pkg.include` with the following content:

```
nginx
```

4. create a file `features/nginx/exec.config` with the following content:

```shell
#!/usr/bin/env bash

set -eufo pipefail

systemctl enable nginx
```

5. make this executable `chmod +x features/nginx/exec.config`

6. create a `/var/www/html` directory inside the nginx `file.include` directory

```shell
mkdir -p features/nginx/file.include/var/www/html
```

7. create a dummy `index.html` file inside `features/nginx/file.include/var/www/html` with content like the following or whatever you like:

```html
<!DOCTYPE html>
<html>
	<body>
		<p>Hello World!</p>
	</body>
</html>
```

With this we have created our own first feature for the builder.
Test it by building with

```shell
./build base-nginx
```

and running with

```shell
qemu-system-x86_64 -m 2048 -nodefaults -display none -serial mon:stdio -drive if=pflash,unit=0,readonly=on,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=virtio,format=raw,file=.build/base-nginx-amd64-bookworm-local.raw -netdev user,id=net0,hostfwd=tcp::8080-:80 -device virtio-net-pci,netdev=net0
```

if everything worked as intended you should see the system boot up and once booted opening http://localhost:8080 in a browser should display the hello world message.

Congrats, you have just successfully created a feature for the builder :tada:
