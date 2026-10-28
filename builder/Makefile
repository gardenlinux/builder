SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eufo pipefail -c
export BASH_ENV := make_bash_env

.SILENT:
.SECONDEXPANSION:
.SECONDARY:
.DELETE_ON_ERROR:

MAKEFLAGS += --no-builtin-rules

lastword = $(word $(words $1),$1)
prelastword = $(word $(words $1),_ $1)
extract_version = $(call lastword,$(subst -, ,$1))
extract_arch = $(call prelastword,$(subst -, ,$1))

define require_var =
ifndef $1
$$(error '$1 undefined')
endif
endef

required_vars := REPO COMMIT TIMESTAMP DEFAULT_VERSION TEMPFS_SIZE
$(foreach var,$(required_vars),$(eval $(call require_var,$(var))))

PARSE_FEATURES_ARGS :=
ifdef ALLOW_FRANKENSTEIN
PARSE_FEATURES_ARGS := --allow-frankenstein
endif

SHORT_COMMIT := $(shell head -c 8 <<< '$(COMMIT)')

DEFAULT_ARCH := $(shell dpkg --print-architecture)

export AWS_DEFAULT_REGION AWS_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

.PHONY: clean

clean:
	find .build -mindepth 1 -delete

.build/%.sentinel:
	true

.build/bootstrap-%-$(SHORT_COMMIT).tar: $$(shell ./make_repo_sentinel $$(REPO) $$(call extract_version,$$*))
	target '$@'
	info 'bootstrapping $*-$(SHORT_COMMIT)'
	arch='$(call extract_arch,$*)'
	version='$(call extract_version,$*)'
	./bootstrap "$$arch" "$$version" '$(REPO)' keyring.gpg '$@'

.build/%-$(SHORT_COMMIT).tar: .build/bootstrap-$$(call extract_arch,$$*)-$$(call extract_version,$$*)-$(SHORT_COMMIT).tar $(shell ./make_directory_sentinel features) $(shell ./make_directory_sentinel cert)
	target '$@' '$<'
	info 'configuring rootfs $*-$(SHORT_COMMIT)'
	features="$$(./parse_features $(PARSE_FEATURES_ARGS) --feature-dir features --target '$*' features)"
	features_platforms="$$(./parse_features $(PARSE_FEATURES_ARGS) --feature-dir features --target '$*' platforms)"
	features_elements="$$(./parse_features $(PARSE_FEATURES_ARGS) --feature-dir features --target '$*' elements)"
	features_flags="$$(./parse_features $(PARSE_FEATURES_ARGS) --feature-dir features --target '$*' flags)"
	cname="$$(./parse_features $(PARSE_FEATURES_ARGS) --feature-dir features --target '$*' cname)"
	BUILDER_CNAME="$$cname"
	BUILDER_FLAVOR="$$cname-$(call extract_arch,$*)"
	BUILDER_VERSIONED_FLAVOR='$*'
	BUILDER_ARTIFACT_BASE='$*-$(SHORT_COMMIT)'
	BUILDER_VERSION='$(call extract_version,$*)'
	BUILDER_ARCH='$(call extract_arch,$*)'
	BUILDER_TIMESTAMP='$(TIMESTAMP)'
	BUILDER_COMMIT='$(COMMIT)'
	BUILDER_FEATURES="$$features"
	BUILDER_FEATURES_PLATFORMS="$$features_platforms"
	BUILDER_FEATURES_ELEMENTS="$$features_elements"
	BUILDER_FEATURES_FLAGS="$$features_flags"
	export BUILDER_CNAME BUILDER_FLAVOR BUILDER_VERSIONED_FLAVOR BUILDER_ARTIFACT_BASE BUILDER_VERSION BUILDER_ARCH BUILDER_TIMESTAMP BUILDER_COMMIT BUILDER_FEATURES BUILDER_FEATURES_PLATFORMS BUILDER_FEATURES_ELEMENTS BUILDER_FEATURES_FLAGS
	./configure '$(word 1,$^)' '$@'

define artifact_template =
.build/%-$(SHORT_COMMIT).$1: $$$$(shell COMMIT=$(SHORT_COMMIT) ./make_get_image_dependencies '$$$$@') $$(shell ./make_directory_sentinel features) $$(shell ./make_directory_sentinel cert)
	script='$$(word 1,$$^)'
	input='$$(word 2,$$^)'
	target '$$@' "$$$$input"
	info 'building $1 image $$*'
	features="$$$$(./parse_features $(PARSE_FEATURES_ARGS) --feature-dir features --target '$$*' features)"
	features_platforms="$$$$(./parse_features $(PARSE_FEATURES_ARGS) --feature-dir features --target '$$*' platforms)"
	features_elements="$$$$(./parse_features $(PARSE_FEATURES_ARGS) --feature-dir features --target '$$*' elements)"
	features_flags="$$$$(./parse_features $(PARSE_FEATURES_ARGS) --feature-dir features --target '$$*' flags)"
	cname="$$$$(./parse_features $(PARSE_FEATURES_ARGS) --feature-dir features --target '$$*' cname)"
	BUILDER_CNAME="$$$$cname"
	BUILDER_FLAVOR="$$$$cname-$$(call extract_arch,$$*)"
	BUILDER_VERSIONED_FLAVOR='$$*'
	BUILDER_ARTIFACT_BASE='$$*-$(SHORT_COMMIT)'
	BUILDER_VERSION='$$(call extract_version,$$*)'
	BUILDER_ARCH='$$(call extract_arch,$$*)'
	BUILDER_TIMESTAMP='$$(TIMESTAMP)'
	BUILDER_COMMIT='$$(COMMIT)'
	BUILDER_FEATURES="$$$$features"
	BUILDER_FEATURES_PLATFORMS="$$$$features_platforms"
	BUILDER_FEATURES_ELEMENTS="$$$$features_elements"
	BUILDER_FEATURES_FLAGS="$$$$features_flags"
	export BUILDER_CNAME BUILDER_FLAVOR BUILDER_VERSIONED_FLAVOR BUILDER_ARTIFACT_BASE BUILDER_VERSION BUILDER_ARCH BUILDER_TIMESTAMP BUILDER_COMMIT BUILDER_FEATURES BUILDER_FEATURES_PLATFORMS BUILDER_FEATURES_ELEMENTS BUILDER_FEATURES_FLAGS
	"./$$$$script" "$$$$input" '$$@'
endef

$(foreach artifact_rule,$(shell ./make_get_artifact_rules),$(eval $(call artifact_template,$(artifact_rule))))

.build/%-$(SHORT_COMMIT).artifacts: $$(shell COMMIT=$(SHORT_COMMIT) ./make_list_build_artifacts '$$*')
	target '$@'
	echo -n > '$@'
	for f in $^; do
		basename "$$f" | tee -a '$@'
		echo "$$(basename "$$f").log" | tee -a '$@'
	done

%: .build/$$(shell ./parse_features $(PARSE_FEATURES_ARGS) --feature-dir features --default-arch '$$(DEFAULT_ARCH)' --default-version '$$(DEFAULT_VERSION)' --target '$$*')-$(SHORT_COMMIT).artifacts
	ln -f -s -r '$<' '.build/$*'

# prevents match anything rule from applying to Makefile and image/convert scripts
Makefile image image.release image.manifest image.sbom image.requirements $(shell find features -name 'convert.*' -o -name image -o -name 'image.*'):
	true
