# Builder

Garden Linux images are produced by Builder, a dedicated build tool maintained
separately from the main
[gardenlinux/gardenlinux](https://github.com/gardenlinux/gardenlinux)
repository. This separation means the build infrastructure can evolve
independently of the distribution content.

The `./build` script in the `gardenlinux/gardenlinux` repository is the primary
entry point. It automatically fetches the correct builder container image, then
delegates all internal build steps to it. As a result, the only hard dependency
on the host system is a working container engine — no specific Linux
distribution, compiler toolchain, or package set is required on the build host.

If you want to use a modified builder docker image, you can edit your changes into the `Dockerfile` and run the image build with
```
cd gardenlinux
./build --container-image localhost/builder aws-gardener_prod
```

## SBOM Generation

After image build time a Software Bill of Materials (SBOM) is created in CycloneDX JSON-format. To produce the SBOM a tool called `syft` is downloaded during build container time. To verify the integrity the offloaded checksums file is included in the builder's directory. To update to a newer syft-release update the container ARG in the `Dockerfile` and update the checksums-file for this release as well.

## Documentation

For
[explanations](https://docs.gardenlinux.org/explanation/builder.html) on
the structure of our build system,
[references](https://docs.gardenlinux.org/reference/builder.html) of
builder's CLI interface and detailed
[how-to guides](https://docs.gardenlinux.org/how-to/building-images.html)
on how to build images for different
[flavors](https://docs.gardenlinux.org/explanation/flavors.html), visit
our [documentation](https://docs.gardenlinux.org/).

# Community

To stay up-to-date with recent news about Gardenlinux, subscribe to our mailing
list:

https://lists.neonephos.org/g/gardenlinux-discussion

For updates and statements regarding security issues, we have a security mailing
list for you:

https://lists.neonephos.org/g/gardenlinux-security

For embargoed security related topics, this list is for you:

https://lists.neonephos.org/g/gardenlinux-security-embargo

## Licensing

Copyright 2025 SAP SE or an SAP affiliate company and GardenLinux contributors.
Please see our [LICENSE](LICENSE.md) for copyright and license information.
Detailed information including third-party components and their
licensing/copyright information is available
[via the REUSE tool](https://reuse.software).

<p align="center">
  <img alt="Bundesministerium für Wirtschaft und Energie (BMWE)-EU funding logo" src="https://apeirora.eu/assets/img/BMWK-EU.png" width="400"/>
</p>
