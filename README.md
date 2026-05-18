# Builder

The Builder is a powerful tool for effortlessly building Linux system images
based on config directories. It serves as the primary build tooling for the
[gardenlinux](https://github.com/gardenlinux/gardenlinux) project.

By default, the Builder runs inside rootless Podman, enabling building without
requiring elevated permissions.

## Documentation

To learn how to use or contribute to Builder, refer to our
[Documentation](https://gardenlinux-docs.netlify.app/reference/supporting_tools/builder.html)

# Community

To stay up-to-date with recent news about Gardenlinux, subscribe to our mailing
list:

https://lists.neonephos.org/g/gardenlinux-discussion

For updates and statements regarding security issues, we have a security mailing
list for you:

https://lists.neonephos.org/g/gardenlinux-security

For embargoed security related topics, this list is for you:

https://lists.neonephos.org/g/gardenlinux-security-embargo


If you want to use a modified builder docker image, you can edit your changes into the `Dockerfile` and run the image build with
```
cd gardenlinux
./build --container-image localhost/builder aws-gardener_prod
```

## SBOM Generation

After image build time a Software Bill of Materials (SBOM) is created in CycloneDX JSON-format. To produce the SBOM a tool called `syft` is downloaded during build container time. To verify the integrity the offloaded checksums file is included in the builder's directory. To update to a newer syft-release update the container ARG in the `Dockerfile` and update the checksums-file for this release as well.

## Licensing

Copyright 2025 SAP SE or an SAP affiliate company and GardenLinux contributors.
Please see our [LICENSE](LICENSE.md) for copyright and license information.
Detailed information including third-party components and their
licensing/copyright information is available
[via the REUSE tool](https://reuse.software).

<p align="center">
  <img alt="Bundesministerium für Wirtschaft und Energie (BMWE)-EU funding logo" src="https://apeirora.eu/assets/img/BMWK-EU.png" width="400"/>
</p>
