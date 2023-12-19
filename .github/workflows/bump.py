#!/usr/bin/python

"""
Determine next version number for versions of a schema like v1.0
based on existing git tags and which component to bump (minor/major).
"""

import subprocess
import re
import sys
import os


def convert_version_to_sortable_int(major, minor):
    return major * 1000 + minor


def determine_most_recent_existing_version():
    tags = subprocess.run(["git", "tag"], capture_output=True).stdout.splitlines()

    versions = []

    for t in tags:
        tag = t.decode()
        if re.match(r"v[0-9]+.[0-9]+", tag):
            tag_without_prefix = tag[1:]
            components = tag_without_prefix.split(".")
            assert len(components) == 2
            major_int = int(components[0])
            minor_int = int(components[1])
            versions.append(
                {
                    "tag": tag,
                    "sortNumber": convert_version_to_sortable_int(major_int, minor_int),
                    "major": major_int,
                    "minor": minor_int,
                }
            )

    if len(versions) == 0:
        print("No existing versions found")
        return {
            "tag": "v0.0",
            "sortNumber": convert_version_to_sortable_int(0, 0),
            "major": 0,
            "minor": 0,
        }

    def keyToSortVersions(v):
        return v["sortNumber"]

    versions.sort(key=keyToSortVersions, reverse=True)
    print(f"Sorted list of versions: {versions}")
    highest_existing_version_number = versions[0]

    return highest_existing_version_number


def bump(most_recent_version, component_to_bump):
    new_version = ""

    if component_to_bump == "major":
        new_major = most_recent_version["major"] + 1
        new_version = f"v{new_major}.0"
    elif component_to_bump == "minor":
        new_minor = most_recent_version["minor"] + 1
        major = most_recent_version["major"]
        new_version = f"v{major}.{new_minor}"
    else:
        raise (
            f"Invalid component provided: {component_to_bump}, only major or minor are supported."
        )

    return new_version


def determine_component_to_bump():
    if sys.argv[1] not in ["major", "minor"]:
        raise ("Usage: bump.py (major|minor)")
    return sys.argv[1]


def main():
    component_to_bump = determine_component_to_bump()
    most_recent_version = determine_most_recent_existing_version()
    new_version = bump(most_recent_version, component_to_bump)

    if os.getenv("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as file_handle:
            print(f"newVersion={new_version}", file=file_handle)
    else:
        print(f"No GitHub env found. New version is {new_version}")


if __name__ == "__main__":
    main()
