# Garden Linux Builder CI Workflows

## `build.yml`

Build container images on all branches.

For pushes on the `main` branch, tags based on the git sha are created and pushed to the container registry and a pseudo-release called `latest` is updated on GitHub.
This allows users to follow a rolling-release approach if they desire.

## `release.yml`

Tag container images and create GitHub Releases.
This workflow only runs on demand (workflow dispatch).
It should be run if a new release is desired.
The workflow dispatch needs a parameter `component` which specifies which version component should be increased.
This is either `minor` (the default) or `major`.
`major` should be picked in cases where the new version has breaking changes (for example between the `build` script and the container image).

## `differential-shellcheck.yml`

Finds new warnings using [shellcheck](https://www.shellcheck.net)
