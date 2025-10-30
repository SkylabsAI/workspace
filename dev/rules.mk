# Checking the versions of dependencies.

define check_ver_target
DEV_CHECK_VER_TARGETS += dev-check-ver-$1
.PHONY: dev-check-ver-$1
dev-check-ver-$1: dev/check_ver/$1.sh
	$$(Q)./$$<
endef

DEV_PROGS = clang opam rust uv
$(foreach prog,$(DEV_PROGS),$(eval $(call check_ver_target,$(prog))))

.PHONY: dev-check-ver
dev-check-ver: $(DEV_CHECK_VER_TARGETS)

# Setting up the development environment.

.PHONY: dev-setup
dev-setup: dev-check-ver dev-setup-opam dev-setup-uv

.PHONY: dev-setup-opam
dev-setup-opam: dev/setup/opam.sh dev-check-ver-opam
	$(Q)./$<

.PHONY: dev-setup-uv
dev-setup-uv: dev/setup/uv.sh dev-check-ver-uv
	$(Q)./$<
