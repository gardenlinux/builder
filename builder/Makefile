SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eufo pipefail -c
export BASH_ENV := make_bash_env

.SILENT:
.SECONDEXPANSION:
.SECONDARY:
.DELETE_ON_ERROR:

MAKEFLAGS += --no-builtin-rules

cname_parts = $(subst _,  , $(subst -,  , $1))
cname_gl_commit = $(lastword $(call cname_parts,$1))
gl_version = $(lastword $(filter-out $(call cname_gl_commit,$1), $(call cname_parts,$1)))
cname_gl_version = $(call gl_version,$1)-$(call cname_gl_commit,$1)
cname_arch = $(lastword $(filter-out $(call gl_version,$1) $(call cname_gl_commit,$1), $(call cname_parts,$1)))

define require_var =
ifndef $1
$$(error '$1 undefined')
endif
endef

required_vars := REPO COMMIT TIMESTAMP DEFAULT_VERSION TEMPFS_SIZE
$(foreach var,$(required_vars),$(eval $(call require_var,$(var))))

GL_ALLOW_FRANKENSTEIN :=
ifdef ALLOW_FRANKENSTEIN
GL_ALLOW_FRANKENSTEIN := true
endif

export GL_ALLOW_FRANKENSTEIN

SHORT_COMMIT := $(shell head -c 8 <<< '$(COMMIT)')

DEFAULT_ARCH := $(shell dpkg --print-architecture)

export AWS_DEFAULT_REGION AWS_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

.PHONY: clean

clean:
	find .build -mindepth 1 -delete

.build/%.sentinel:
	true

.build/bootstrap-%.tar: $$(shell ./make_repo_sentinel $$(REPO) $$(call gl_version,$$*))
	target '$@'
	info 'bootstrapping $*'
	arch='$(call cname_arch,$*)'
	version='$(call gl_version,$*)'
	./bootstrap "$$arch" "$$version" '$(REPO)' keyring.gpg '$@'

.build/%.tar: .build/bootstrap-$$(call cname_arch,$$*)-$$(call cname_gl_version,$$*).tar $(shell ./make_directory_sentinel features) $(shell ./make_directory_sentinel cert)
	target '$@' '$<'
	info 'configuring rootfs $*-$(SHORT_COMMIT)'
	features="$$(gl-features-parse --feature-dir features --default-arch '$$(DEFAULT_ARCH)' --cname '$*' features)"
	features_platforms="$$(gl-features-parse --feature-dir features --default-arch '$$(DEFAULT_ARCH)' --cname '$*'platforms)"
	features_elements="$$(gl-features-parse --feature-dir features --default-arch '$$(DEFAULT_ARCH)' --cname '$*'elements)"
	features_flags="$$(gl-features-parse --feature-dir features --default-arch '$$(DEFAULT_ARCH)' --cname '$*'flags)"
	BUILDER_CNAME='$*'
	BUILDER_VERSION='$(call gl_version,$*)'
	BUILDER_ARCH='$(call cname_arch,$*)'
	BUILDER_TIMESTAMP='$(TIMESTAMP)'
	BUILDER_COMMIT='$(COMMIT)'
	BUILDER_FEATURES="$$features"
	BUILDER_FEATURES_PLATFORMS="$$features_platforms"
	BUILDER_FEATURES_ELEMENTS="$$features_elements"
	BUILDER_FEATURES_FLAGS="$$features_flags"
	export BUILDER_CNAME BUILDER_VERSION BUILDER_ARCH BUILDER_TIMESTAMP BUILDER_COMMIT BUILDER_FEATURES BUILDER_FEATURES_PLATFORMS BUILDER_FEATURES_ELEMENTS BUILDER_FEATURES_FLAGS
	./configure '$(word 1,$^)' '$@'

define artifact_template =
.build/%.$1: $$$$(shell COMMIT=$(SHORT_COMMIT) ./make_get_image_dependencies '$$$$@') $$(shell ./make_directory_sentinel features) $$(shell ./make_directory_sentinel cert)
	script='$$(word 1,$$^)'
	input='$$(word 2,$$^)'
	target '$$@' "$$$$input"
	info 'building $1 image $$*'
	features="$$$$(gl-features-parse --feature-dir features --default-arch '$$(DEFAULT_ARCH)' --cname '$$*' features)"
	features_platforms="$$$$(gl-features-parse --feature-dir features --default-arch '$$(DEFAULT_ARCH)' --cname '$$*' platforms)"
	features_elements="$$$$(gl-features-parse --feature-dir features --default-arch '$$(DEFAULT_ARCH)' --cname '$$*' elements)"
	features_flags="$$$$(gl-features-parse --feature-dir features --default-arch '$$(DEFAULT_ARCH)' --cname '$$*' flags)"
	BUILDER_CNAME='$$*'
	BUILDER_VERSION='$$(call gl_version,$$*)'
	BUILDER_ARCH='$$(call cname_arch,$$*)'
	BUILDER_TIMESTAMP='$$(TIMESTAMP)'
	BUILDER_COMMIT='$$(COMMIT)'
	BUILDER_FEATURES="$$$$features"
	BUILDER_FEATURES_PLATFORMS="$$$$features_platforms"
	BUILDER_FEATURES_ELEMENTS="$$$$features_elements"
	BUILDER_FEATURES_FLAGS="$$$$features_flags"
	export BUILDER_CNAME BUILDER_VERSION BUILDER_ARCH BUILDER_TIMESTAMP BUILDER_COMMIT BUILDER_FEATURES BUILDER_FEATURES_PLATFORMS BUILDER_FEATURES_ELEMENTS BUILDER_FEATURES_FLAGS
	"./$$$$script" "$$$$input" '$$@'
endef

$(foreach artifact_rule,$(shell ./make_get_artifact_rules),$(eval $(call artifact_template,$(artifact_rule))))

.build/%.artifacts: $$(shell COMMIT=$(SHORT_COMMIT) DEFAULT_VERSION=$(DEFAULT_VERSION) NATIVE_ARCH=$(NATIVE_ARCH) ./make_list_build_artifacts '$$*')
	target '$@'
	echo -n > '$@'
	for f in $^; do
		basename "$$f" | tee -a '$@'
		echo "$$(basename "$$f").log" | tee -a '$@'
	done

%: .build/$$(shell gl-features-parse --feature-dir features --default-arch '$$(DEFAULT_ARCH)' --default-version '$$(DEFAULT_VERSION)-$$(SHORT_COMMIT)' --cname '$$*').artifacts
	ln -f -s -r '$<' '.build/$*'

# prevents match anything rule from applying to Makefile and image/convert scripts
Makefile image image.release image.manifest image.requirements $(shell find features -name 'convert.*' -o -name image -o -name 'image.*'):
	true
