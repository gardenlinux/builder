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
cname_version = $(call lastword,$(subst -, ,$1))
cname_arch = $(call prelastword,$(subst -, ,$1))

define require_var =
ifndef $1
$$(error '$1 undefined')
endif
endef

required_vars := REPO COMMIT TIMESTAMP DEFAULT_VERSION
$(foreach var,$(required_vars),$(eval $(call require_var,$(var))))

NATIVE_ARCH := $(shell dpkg --print-architecture)
NATIVE_PKGS := bash dash dpkg grep mawk openssh-client policycoreutils sed tar util-linux gzip xz-utils

export AWS_DEFAULT_REGION AWS_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

.PHONY: clean

clean:
	find .build -mindepth 1 -delete

.build/%.sentinel:
	true

.build/bootstrap-%-$(COMMIT).tar: $$(shell ./make_repo_sentinel $$(REPO) $$(call cname_version,$$*))
	target '$@'
	info 'bootstrapping $*-$(COMMIT)'
	arch='$(call cname_arch,$*)'
	version='$(call cname_version,$*)'
	./bootstrap "$$arch" "$$version" '$(REPO)' keyring.gpg '$@'

.build/native_bin-%-$(COMMIT).tar: .build/bootstrap-$(NATIVE_ARCH)-%-$(COMMIT).tar
	target '$@'
	info 'configuring native_bin'
	./configure_nativetools '$<' '$@' $(NATIVE_PKGS)

.build/%-$(COMMIT).tar: .build/bootstrap-$$(call cname_arch,$$*)-$$(call cname_version,$$*)-$(COMMIT).tar .build/native_bin-$$(call cname_version,$$*)-$(COMMIT).tar $(shell ./make_directory_sentinel features) $(shell ./make_directory_sentinel cert)
	target '$@' '$<'
	info 'configuring rootfs $*-$(COMMIT)'
	features="$$(./parse_features --feature-dir features --cname '$*' features)"
	BUILDER_CNAME='$*'
	BUILDER_VERSION='$(call cname_version,$*)'
	BUILDER_ARCH='$(call cname_arch,$*)'
	BUILDER_TIMESTAMP='$(TIMESTAMP)'
	BUILDER_COMMIT='$(COMMIT)'
	BUILDER_FEATURES="$$features"
	export BUILDER_CNAME BUILDER_VERSION BUILDER_ARCH BUILDER_TIMESTAMP BUILDER_COMMIT BUILDER_FEATURES
	./configure '$(word 1,$^)' '$(word 2,$^)' '$@'

define artifact_template =
.build/%-$(COMMIT).$1: $$$$(shell COMMIT=$(COMMIT) ./make_get_image_dependencies '$$$$@') $$(shell ./make_directory_sentinel features) $$(shell ./make_directory_sentinel cert)
	script='$$(word 1,$$^)'
	input='$$(word 2,$$^)'
	target '$$@' "$$$$input"
	info 'building $1 image $$*'
	features="$$$$(./parse_features --feature-dir features --cname '$$*' features)"
	BUILDER_CNAME='$$*'
	BUILDER_VERSION='$$(call cname_version,$$*)'
	BUILDER_ARCH='$$(call cname_arch,$$*)'
	BUILDER_TIMESTAMP='$$(TIMESTAMP)'
	BUILDER_COMMIT='$$(COMMIT)'
	BUILDER_FEATURES="$$$$features"
	export BUILDER_CNAME BUILDER_VERSION BUILDER_ARCH BUILDER_TIMESTAMP BUILDER_COMMIT BUILDER_FEATURES
	"./$$$$script" "$$$$input" '$$@'
endef

$(foreach artifact_rule,$(shell ./make_get_artifact_rules),$(eval $(call artifact_template,$(artifact_rule))))

.build/%-$(COMMIT).artifacts: $$(shell COMMIT=$(COMMIT) ./make_list_build_artifacts '$$*')
	target '$@'
	echo -n > '$@'
	for f in $^; do
		basename "$$f" | tee -a '$@'
		echo "$$(basename "$$f").log" | tee -a '$@'
	done

%: .build/$$(shell ./parse_features --feature-dir features --default-arch '$$(NATIVE_ARCH)' --default-version '$$(DEFAULT_VERSION)' --cname '$$*')-$(COMMIT).artifacts
	ln -f -s -r '$<' '.build/$*'

# prevents match anything rule from applying to Makefile and image/convert scripts
Makefile image image.release $(shell find features -name 'convert.*' -o -name 'image.*'):
	true
