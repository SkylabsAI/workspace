# Use "make ... Q=" to show more commands.
Q=@

# Base repository URL (without organization name).
GITHUB_URL ?= git@github.com:

# Pick default bash on MacOS, even if it's installed with Homebrew.
SHELL := $(shell which bash)

.PHONY: all
all: _CoqProject stage1
	@dune build --display=short

.PHONY: stage1
stage1: ast-prepare-bluerock
	$(Q)dune build --display=short _build/install/default/bin/rocq

# Include the rules for development tools (deps checking, ...)
include dev/rules.mk

# Include the rules for managing the fmdeps sub-repositories.
include fmdeps/rules.mk

.PHONY: describe
describe: fmdeps-describe bluerock-describe
	@git log --pretty=tformat:'./: %H' -n 1
	@git diff HEAD --quiet || echo "./ is dirty"

# Include the rules for building docker images.
include docker/rules.mk

# Include the rules for the BlueRock repos (used for CI).
include bluerock/rules.mk

# Updating the OCaml / Coq FM dependencies.
update-br-fm-deps:
	$(Q)opam update
	$(Q)opam repo add --this-switch archive \
	  git+https://github.com/ocaml/opam-repository-archive
	$(Q)opam install fmdeps/fm-ci/fm-deps/br-fm-deps.opam

# Initialization of the repository.
.PHONY: init
init: fmdeps-clone

# Support for looping over cloned repositories (excluding bhv sub-repos).
# The LOOP_COMMAND variable must be set for these targets, and the passed
# command or script will be invoked with the following four arguments:
# 1) The path to the repository within our GitLab organization.
# 2) The GitLab URL of the repote (origin).
# 3) The name of our main branch for that repository.
# 4) The relative path to the repository from the root of the workspace.
ifneq ($(LOOP_COMMAND),)
WORKSPACE_ON_GITHUB = git@github.com:SkylabsAI/workspace.git

.PHONY: loop_workspace
loop_workspace:
	$(Q)$(LOOP_COMMAND) SkylabsAI/workspace ${WORKSPACE_ON_GITHUB} main ./

.PHONY: loop
loop: loop_workspace fmdeps-loop bluerock-loop

.PHONY: revloop
revloop: fmdeps-revloop bluerock-revloop
	$(Q)$(LOOP_COMMAND) SkylabsAI/workspace ${WORKSPACE_ON_GITHUB} main ./
endif

.PHONY: clone
clone: fmdeps-clone bluerock-clone

.PHONY: lightweight-clone
lightweight-clone: fmdeps-lightweight-clone bluerock-lightweight-clone

.PHONY: nuke
nuke: fmdeps-nuke bluerock-nuke

.PHONY: peek
peek: fmdeps-peek bluerock-peek

.PHONY: clean
clean:
	$(Q)rm -rf $(GENERATED_FILES)
	$(Q)dune clean
