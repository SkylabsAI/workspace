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

# Updating the OCaml / Coq FM dependencies.
update-br-fm-deps:
	$(Q)opam update
	$(Q)opam repo add --this-switch archive \
	  git+https://github.com/ocaml/opam-repository-archive
	$(Q)opam install fmdeps/fm-ci/fm-deps/br-fm-deps.opam

# Include the rules for development tools (deps checking, ...)
include dev/rules.mk

# Include the rules for building docker images.
include docker/rules.mk

# Include the rules for managing the fmdeps sub-repositories.
include fmdeps/rules.mk

# Include the rules for managing the psi sub-repositories.
include psi/rules.mk

# Include the rules for the BlueRock repos (used for CI).
include bluerock/rules.mk

.PHONY: describe
describe: fmdeps-describe psi-describe bluerock-describe
	@git log --pretty=tformat:'./: %H' -n 1
	@git diff HEAD --quiet || echo "./ is dirty"

# Generating common targets for the various sub-repository directories.
SUBREPO_DIRS = fmdeps psi bluerock
define common_target
.PHONY: $1
$1: $(patsubst %,%-$1,${SUBREPO_DIRS})
endef

COMMON_TARGETS = clone lightweight-clone nuke peek
$(foreach t,$(COMMON_TARGETS),$(eval $(call common_target,$(t))))

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
loop: loop_workspace $(patsubst %,%-loop,${SUBREPO_DIRS})

.PHONY: revloop
revloop: $(patsubst %,%-revloop,${SUBREPO_DIRS})
	$(Q)$(LOOP_COMMAND) SkylabsAI/workspace ${WORKSPACE_ON_GITHUB} main ./
endif

.PHONY: clean
clean:
	$(Q)rm -rf $(GENERATED_FILES)
	$(Q)dune clean

_CoqProject:
	./fmdeps/BRiCk/scripts/coq_project_gen/gen-_CoqProject-dune.sh > _CoqProject
