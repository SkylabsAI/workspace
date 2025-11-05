# Use "make ... Q=" to show more commands.
Q=@

# Base repository URL (without organization name).
GITHUB_URL ?= git@github.com:

# URL for the workspace repository (this repository).
WORKSPACE_ON_GITHUB = ${GITHUB_URL}SkylabsAI/workspace.git

# Pick default bash on MacOS, even if it's installed with Homebrew.
SHELL := $(shell which bash)

.PHONY: all
all: _CoqProject stage1
	$(Q)dune build --display=short

.PHONY: ide-prepare
ide-prepare: _CoqProject
	$(Q)dune build --display=short @fmdeps/vendored/rocq/install

.PHONY: FORCE
FORCE:

_CoqProject: fmdeps/BRiCk/scripts/coq_project_gen/gen-_CoqProject-dune.sh FORCE
	$(Q)uv run --with sexpdata --python 3.11 --quiet -- $< > $@ \
		|| { rm -f $@; exit 1; }

.PHONY: stage1
stage1: ide-prepare | ast-prepare-bluerock

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

.PHONY: workspace-fetch
workspace-fetch:
	@echo "Fetching at the workspace root."
	$(Q)git fetch --all --quiet

.PHONY: fetch
fetch: workspace-fetch $(patsubst %,%-fetch,${SUBREPO_DIRS})

.PHONY: workspace-pull
workspace-pull:
	@echo "Pulling at the workspace root."
	$(Q)git pull --rebase

.PHONY: pull
pull: workspace-pull
	+$(Q)$(MAKE) --no-print-directory $(patsubst %,%-pull,${SUBREPO_DIRS})

.PHONY: workspace-show-config
workspace-show-config:
	@echo "SkylabsAI/workspace ${WORKSPACE_ON_GITHUB} main ./ owned"

.PHONY: show-config
show-config: workspace-show-config $(patsubst %,%-show-config,${SUBREPO_DIRS})

# Support for looping over cloned repositories (excluding bhv sub-repos).
# The LOOP_COMMAND variable must be set for these targets, and the passed
# command or script will be invoked with the following four arguments:
# 1) The path to the repository within our GitLab organization.
# 2) The GitLab URL of the repote (origin).
# 3) The name of our main branch for that repository.
# 4) The relative path to the repository from the root of the workspace.
ifneq ($(LOOP_COMMAND),)
.PHONY: loop-workspace
loop-workspace:
	$(Q)$(LOOP_COMMAND) \
		SkylabsAI/workspace ${WORKSPACE_ON_GITHUB} main ./ owned

.PHONY: loop-subrepos
loop-subrepos: $(patsubst %,%-revloop,${SUBREPO_DIRS})

.PHONY: loop
loop: loop-workspace $(patsubst %,%-loop,${SUBREPO_DIRS})

.PHONY: revloop
revloop: loop-subrepos
	$(Q)$(LOOP_COMMAND) \
		SkylabsAI/workspace ${WORKSPACE_ON_GITHUB} main ./ owned
endif

.PHONY: clean
clean:
	$(Q)rm -rf $(GENERATED_FILES)
	$(Q)dune clean
