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
dev-check-ver: $(DEV_CHECK_VER_TARGETS) dev-check-ver-sed

.PHONY: dev-check-ver-sed
# Reject systems where `sed` is not GNU `sed` and `gsed` is not available.
# On accepted systems, `SED` can be found via `(which gsed || which sed) 2> /dev/null`,
# which is what we use in most places.
dev-check-ver-sed:
	@source fmdeps/BRiCk/scripts/locate-sed.inc.sh; echo "Found GNU sed as $${SED}"

# Setting up the development environment.

.PHONY: dev-setup
dev-setup: dev-check-ver dev-setup-opam

.PHONY: dev-setup-opam
dev-setup-opam: dev/setup/opam.sh dev-check-ver-opam
	$(Q)./$<

# Updating the OCaml / Rocq dependencies.
update-opam-deps:
	$(Q)opam update
	$(Q)opam repo add --this-switch archive \
	  git+https://github.com/ocaml/opam-repository-archive
	$(Q)opam install dev/opam-deps/skylabs-deps.opam
