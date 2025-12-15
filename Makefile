# Use "make ... Q=" to show more commands.
Q=@

# Pick default bash on MacOS, even if it's installed with Homebrew.
SHELL := $(shell which bash)

.PHONY: all
all: _CoqProject stage1
	$(Q)dune build --display=short

CPP2V = _build/install/default/bin/cpp2v
.PHONY: ide-prepare
ide-prepare: _CoqProject
	$(Q)dune build --display=short @fmdeps/vendored/rocq/install ${CPP2V}

.PHONY: FORCE
FORCE:

_CoqProject: fmdeps/BRiCk/scripts/coq_project_gen/gen-_CoqProject-dune.sh FORCE
	$(Q)$< > $@ || { rm -f $@; exit 1; }

.PHONY: stage1
stage1: ide-prepare ast-prepare-bluerock

# Updating the OCaml / Coq FM dependencies.
update-br-fm-deps:
	$(Q)opam update
	$(Q)opam repo add --this-switch archive \
	  git+https://github.com/ocaml/opam-repository-archive
	$(Q)opam install fmdeps/fm-ci/fm-deps/br-fm-deps.opam

# Include the rules for development tools (deps checking, ...)
include dev/rules.mk

# Include the rules for managing the workspace and sub-repositories.
include dev/repos/rules.mk

# AST generation of BlueRock repos.
include bluerock/build.mk

.PHONY: clean
clean:
	$(Q)rm -rf $(GENERATED_FILES)
	$(Q)dune clean
