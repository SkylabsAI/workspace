include dev/repos/config.mk

REPO_GROUPS = upstream owned downstream public private

define subrepo_targets
REPO_GROUP = $$(word 1,$$(subst :, ,$$1))
REPO_PATH = $$(word 2,$$(subst :, ,$$1))
REPO_DEFAULT = $$(word 3,$$(subst :, ,$$1))
REPO_DIR = $$(word 1,$$(subst :, ,$$1))/$$(word 4,$$(subst :, ,$$1))
REPO_MODE = $$(word 5,$$(subst :, ,$$1))
REPO_VIS = $$(word 6,$$(subst :, ,$$1))
REPO_URL = ${GITHUB_URL}$$(word 2,$$(subst :, ,$$1)).git
REPO_NAME = $$(word 2,$$(subst /, ,$$(word 2,$$(subst :, ,$$1))))
ifneq ($1,sentinel)

# Add REPO_GROUP to REPO_GROUPS but without dups
REPO_GROUPS += $(filter-out ${REPO_GROUPS},${REPO_GROUP})

CLONE_TARGETS += clone-${REPO_NAME}
${REPO_GROUP}_CLONE_TARGETS += clone-${REPO_NAME}
${REPO_VIS}_CLONE_TARGETS += clone-${REPO_NAME}
${REPO_MODE}_CLONE_TARGETS += clone-${REPO_NAME}
.PHONY: clone-${REPO_NAME}
clone-${REPO_NAME}:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Repo ${REPO_URL} seems already cloned in ${REPO_DIR}."
else
	@echo "Cloning ${REPO_URL} in ${REPO_DIR}"
	$(Q)$${CLONE_ENV_${REPO_NAME}} git clone ${CLONE_ARGS} \
		--branch ${REPO_DEFAULT} ${REPO_URL} ${REPO_DIR}
endif

LIGHTWEIGHT_CLONE_TARGETS += lightweight-clone-${REPO_NAME}
${REPO_GROUP}_LIGHTWEIGHT_CLONE_TARGETS += lightweight-clone-${REPO_NAME}
${REPO_VIS}_LIGHTWEIGHT_CLONE_TARGETS += lightweight-clone-${REPO_NAME}
${REPO_MODE}_LIGHTWEIGHT_CLONE_TARGETS += lightweight-clone-${REPO_NAME}
.PHONY: lightweight-clone-${REPO_NAME}
lightweight-clone-${REPO_NAME}:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Repo ${REPO_URL} seems already cloned in ${REPO_DIR}."
else
	@echo "Cloning ${REPO_URL} in ${REPO_DIR} (lightweight, no checkout)"
	$(Q)$${CLONE_ENV_${REPO_NAME}} git clone ${CLONE_ARGS} \
		--no-checkout --filter=tree:0 --quiet ${REPO_URL} ${REPO_DIR}
endif

NUKE_TARGETS += nuke-${REPO_NAME}
${REPO_GROUP}_NUKE_TARGETS += nuke-${REPO_NAME}
${REPO_VIS}_NUKE_TARGETS += nuke-${REPO_NAME}
${REPO_MODE}_NUKE_TARGETS += nuke-${REPO_NAME}
.PHONY: nuke-${REPO_NAME}
nuke-${REPO_NAME}:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
ifeq ($(CONFIRM),yes)
	@rm -rf ${REPO_DIR}
else
	@echo "Use CONFIRM=yes to really nuke ${REPO_NAME}."
endif
endif

SHOW_CONFIG_TARGETS += show-config-${REPO_NAME}
.PHONY: show-config-${REPO_NAME}
show-config-${REPO_NAME}:
	@echo "$(REPO_PATH) $(REPO_URL) $(REPO_DEFAULT) $(REPO_DIR) $(REPO_MODE)"

DESCRIBE_TARGETS += describe-${REPO_NAME}
${REPO_GROUP}_DESCRIBE_TARGETS += describe-${REPO_NAME}
${REPO_VIS}_DESCRIBE_TARGETS += describe-${REPO_NAME}
${REPO_MODE}_DESCRIBE_TARGETS += describe-${REPO_NAME}
.PHONY: describe-${REPO_NAME}
describe-${REPO_NAME}:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@git -C ${REPO_DIR} log --pretty=tformat:'${REPO_DIR}: %H' -n 1
	@git -C ${REPO_DIR} diff HEAD --quiet || echo "${REPO_DIR} is dirty"
else
	@echo "No repository in ${REPO_DIR}, cannot describe."
endif

FETCH_TARGETS += fetch-${REPO_NAME}
${REPO_GROUP}_FETCH_TARGETS += fetch-${REPO_NAME}
${REPO_VIS}_FETCH_TARGETS += fetch-${REPO_NAME}
${REPO_MODE}_FETCH_TARGETS += fetch-${REPO_NAME}
.PHONY: fetch-${REPO_NAME}
fetch-${REPO_NAME}:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Fetching in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} fetch --all --quiet
else
	@echo "No repository in ${REPO_DIR}, cannot fetch."
endif

PULL_TARGETS += pull-${REPO_NAME}
${REPO_GROUP}_PULL_TARGETS += pull-${REPO_NAME}
${REPO_VIS}_PULL_TARGETS += pull-${REPO_NAME}
${REPO_MODE}_PULL_TARGETS += pull-${REPO_NAME}
.PHONY: pull-${REPO_NAME}
pull-${REPO_NAME}:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Pulling in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} pull --rebase
else
	@echo "No repository in ${REPO_DIR}, cannot pull."
endif

PUSH_TARGETS += push-${REPO_NAME}
${REPO_GROUP}_PUSH_TARGETS += push-${REPO_NAME}
${REPO_VIS}_PUSH_TARGETS += push-${REPO_NAME}
${REPO_MODE}_PUSH_TARGETS += push-${REPO_NAME}
.PHONY: push-${REPO_NAME}
push-${REPO_NAME}:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Pushing in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} push
else
	@echo "No repository in ${REPO_DIR}, cannot push."
endif

PEEK_TARGETS += peek-${REPO_NAME}
${REPO_GROUP}_PEEK_TARGETS += peek-${REPO_NAME}
${REPO_VIS}_PEEK_TARGETS += peek-${REPO_NAME}
${REPO_MODE}_PEEK_TARGETS += peek-${REPO_NAME}
.PHONY: peek-${REPO_NAME}
peek-${REPO_NAME}:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Peeking into ${REPO_DIR}:"
	@git -C ${REPO_DIR} status --short --branch --untracked-files=normal
else
	@echo "No repository in ${REPO_DIR}, cannot peek."
endif

GITCLEAN_TARGETS += gitclean-${REPO_NAME}
${REPO_GROUP}_GITCLEAN_TARGETS += gitclean-${REPO_NAME}
${REPO_VIS}_GITCLEAN_TARGETS += gitclean-${REPO_NAME}
${REPO_MODE}_GITCLEAN_TARGETS += gitclean-${REPO_NAME}
.PHONY: gitclean-${REPO_NAME}
gitclean-${REPO_NAME}:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Cleaning ${REPO_DIR}:"
	$(Q)git -C ${REPO_DIR} clean -xfd
else
	@echo "No repository in ${REPO_DIR}, cannot clean."
endif

CHECKOUT_MAIN_TARGETS += checkout-main-${REPO_NAME}
${REPO_GROUP}_CHECKOUT_MAIN_TARGETS += checkout-main-${REPO_NAME}
${REPO_VIS}_CHECKOUT_MAIN_TARGETS += checkout-main-${REPO_NAME}
${REPO_MODE}_CHECKOUT_MAIN_TARGETS += checkout-main-${REPO_NAME}
.PHONY: checkout-main-${REPO_NAME}
checkout-main-${REPO_NAME}:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Checking out branch ${REPO_DEFAULT} in ${REPO_DIR}:"
	$(Q)git -C ${REPO_DIR} checkout ${REPO_DEFAULT}
else
	@echo "No repository in ${REPO_DIR}, cannot checkout."
endif

ifneq ($(LOOP_COMMAND),)
LOOP_TARGETS += loop-${REPO_NAME}
.PHONY: loop-${REPO_NAME}
loop-${REPO_NAME}: | loop-workspace
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	$(Q)$(LOOP_COMMAND) \
		$(REPO_PATH) $(REPO_URL) $(REPO_DEFAULT) $(REPO_DIR) $(REPO_MODE)
endif

REVLOOP_TARGETS += revloop-${REPO_NAME}
.PHONY: revloop-${REPO_NAME}
revloop-${REPO_NAME}:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	$(Q)$(LOOP_COMMAND) \
		$(REPO_PATH) $(REPO_URL) $(REPO_DEFAULT) $(REPO_DIR) $(REPO_MODE)
endif
endif

endif
endef # end subrepo_targets

$(foreach dep,sentinel $(REPOS),$(eval $(call subrepo_targets,$(dep))))
unexport REPO_GROUP
unexport REPO_PATH
unexport REPO_DEFAULT
unexport REPO_DIR
unexport REPO_MODE
unexport REPO_VIS
unexport REPO_URL
unexport REPO_NAME

# Targets that only make sense for sub-repositories.
SUBREPOS_TARGET_BASES = clone lightweight-clone nuke

# Targets that make sense for sub-repositories and for the workspace.
COMMON_TARGET_BASES = describe fetch pull push peek gitclean checkout-main

VAR_OF_TARGET_BASE = $(shell echo "$(1)" | tr '[:lower:]-' '[:upper:]_')

define group_target
.PHONY: $1-$2
$1-$2: $$($2_$(call VAR_OF_TARGET_BASE,$1)_TARGETS)
endef

$(foreach b,$(SUBREPOS_TARGET_BASES) $(COMMON_TARGET_BASES),\
	$(foreach g,$(REPO_GROUPS),\
		$(eval $(call group_target,$(b),$(g)))))

define subrepo_target
.PHONY: $1
$1: $$($(call VAR_OF_TARGET_BASE,$1)_TARGETS)
endef

$(foreach b,$(SUBREPOS_TARGET_BASES),\
  $(eval $(call subrepo_target,$(b))))

# NOTE: we might be able to generate targets for the workspace repository with
# $(call subrepo_targets,workspace:SkyLabsAI/workspace:main:./:owned:public)",
# but that would require a rework of "subrepo_targets". The problem is that it
# does not make sense to "clone", "lightweight-clone", or "nuke" the workspace
# repository. Also, the looping logic currently hard-codes the workspace.

# NOTE: we manually write the main targets since shell auto-complete generally
# does not work well with generated targets.

.PHONY: show-config-workspace
show-config-workspace:
	@echo "${WORKSPACE_PATH} ${WORKSPACE_ON_GITHUB} main ./ owned"

.PHONY: show-config
show-config: show-config-workspace $(SHOW_CONFIG_TARGETS)

.PHONY: describe-workspace
describe-workspace:
	@git log --pretty=tformat:'./: %H' -n 1
	@git diff HEAD --quiet || echo "./ is dirty"

.PHONY: describe
describe: describe-workspace ${DESCRIBE_TARGETS}

.PHONY: fetch-workspace
fetch-workspace:
	@echo "Fetching at the workspace root."
	$(Q)git fetch --all --quiet

.PHONY: fetch
fetch: fetch-workspace ${FETCH_TARGETS}

.PHONY: pull-workspace
pull-workspace:
	@echo "Pulling at the workspace root."
	$(Q)git pull --rebase

.PHONY: pull
pull: pull-workspace
	+$(Q)$(MAKE) --no-print-directory ${PULL_TARGETS}

.PHONY: push-workspace
push-workspace:
	@echo "Pushing at the workspace root."
	$(Q)git push

.PHONY: push
push: push-workspace ${PUSH_TARGETS}

.PHONY: peek-workspace
peek-workspace:
	@echo "Peeking into ./"
	@git status --short --branch --untracked-files=normal

.PHONY: peek
peek: peek-workspace ${PEEK_TARGETS}

.PHONY: gitclean-workspace
gitclean-workspace:
	@echo "Cleaning ./:"
	$(Q)git clean -xfd

.PHONY: gitclean
gitclean: gitclean-workspace ${GITCLEAN_TARGETS}

.PHONY: checkout-main-workspace
checkout-main-workspace:
	@echo "Checking out branch main in ./:"
	$(Q)git checkout main

.PHONY: checkout-main
checkout-main: checkout-main-workspace ${CHECKOUT_MAIN_TARGETS}

# Support for looping over cloned repositories (excluding bhv sub-repos).
# The LOOP_COMMAND variable must be set for these targets, and the passed
# command or script will be invoked with the following four arguments:
# 1) The path to the repository within our GitHub organization.
# 2) The GitHub URL of the remote (origin).
# 3) The name of our main branch for that repository.
# 4) The relative path to the repository from the root of the workspace.
# 5) The mode of the repository (upstream, owned or downstream).
ifneq ($(LOOP_COMMAND),)
.PHONY: loop-workspace
loop-workspace:
	$(Q)$(LOOP_COMMAND) $(WORKSPACE_PATH) ${WORKSPACE_ON_GITHUB} main ./ owned

.PHONY: loop
loop: loop-workspace ${LOOP_TARGETS}

.PHONY: loop-subrepos
loop-subrepos: ${REVLOOP_TARGETS}

.PHONY: revloop
revloop: loop-subrepos
	$(Q)$(LOOP_COMMAND) $(WORKSPACE_PATH) ${WORKSPACE_ON_GITHUB} main ./ owned
endif
