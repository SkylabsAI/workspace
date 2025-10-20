# Checking the versions of dependencies.

.PHONY: dev-check-ver
dev-check-ver: dev-check-ver-opam dev-check-ver-clang dev-check-ver-rust

.PHONY: dev-check-ver-opam
dev-check-ver-opam: dev/check_ver/opam.sh
	$(Q)./$<

.PHONY: dev-check-ver-clang
dev-check-ver-clang: dev/check_ver/clang.sh
	$(Q)./$<

.PHONY: dev-check-ver-rust
dev-check-ver-rust: dev/check_ver/rust.sh
	$(Q)./$<

# Setting up the development environment.

.PHONY: dev-setup
dev-setup: dev-check-ver dev-setup-opam

.PHONY: dev-setup-opam
dev-setup-opam: dev/setup/opam.sh dev-check-ver-opam
	$(Q)./$<
