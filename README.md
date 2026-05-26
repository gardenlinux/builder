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

## Documentation

For
[explanations](https://gardenlinux-docs.netlify.app/explanation/builder.html) on
the structure of our build system,
[references](https://gardenlinux-docs.netlify.app/reference/builder.html) of
builder's CLI interface and detailed
[how-to guides](https://gardenlinux-docs.netlify.app/how-to/building-images.html)
on how to build images for different
[flavors](https://gardenlinux-docs.netlify.app/explanation/flavors.html), visit
our [documentation](https://gardenlinux-docs.netlify.app/).

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
