include fmdeps/config.mk

define subrepo_targets
REPO_NAME = $$(word 1,$$(subst :, ,$$1))
REPO_URL = ${GITHUB_URL}$$(word 1,$$(subst :, ,$$1)).git
REPO_BRANCH = $$(word 2,$$(subst :, ,$$1))
REPO_DIR = fmdeps/$$(word 3,$$(subst :, ,$$1))
REPO_MODE = $$(word 4,$$(subst :, ,$$1))
ifneq ($1,sentinel)

FMDEPS_SHOW_CONFIG_TARGETS += fmdeps-${REPO_NAME}-show-config
.PHONY: fmdeps-${REPO_NAME}-show-config
fmdeps-${REPO_NAME}-show-config:
	@echo "$(REPO_NAME) $(REPO_URL) $(REPO_BRANCH) $(REPO_DIR) $(REPO_MODE)"

FMDEPS_CLONE_TARGETS += fmdeps-${REPO_NAME}-clone
.PHONY: fmdeps-${REPO_NAME}-clone
fmdeps-${REPO_NAME}-clone:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Repo ${REPO_URL} seems already cloned in ${REPO_DIR}."
else
	@echo "Cloning ${REPO_URL} in ${REPO_DIR}"
ifeq (${REPO_CACHE_DIR},)
	$(Q)git clone ${CLONE_ARGS} \
		--branch ${REPO_BRANCH} ${REPO_URL} ${REPO_DIR}
else
	$(Q)git clone ${CLONE_ARGS} \
		--reference-if-able ${REPO_CACHE_DIR}/${REPO_NAME} \
		--branch ${REPO_BRANCH} ${REPO_URL} ${REPO_DIR}
endif
endif

FMDEPS_LIGHTWEIGHT_CLONE_TARGETS += fmdeps-${REPO_NAME}-lightweight-clone
.PHONY: fmdeps-${REPO_NAME}-lightweight-clone
fmdeps-${REPO_NAME}-lightweight-clone:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Repo ${REPO_URL} seems already cloned in ${REPO_DIR}."
else
	@echo "Cloning ${REPO_URL} in ${REPO_DIR} (lightweight, no checkout)"
ifeq (${REPO_CACHE_DIR},)
	$(Q)git clone ${CLONE_ARGS} --no-checkout --filter=tree:0 --quiet \
		${REPO_URL} ${REPO_DIR}
else
	$(Q)git clone ${CLONE_ARGS} --no-checkout --filter=tree:0 --quiet \
		--reference-if-able ${REPO_CACHE_DIR}/${REPO_NAME} \
		${REPO_URL} ${REPO_DIR}
endif
endif

FMDEPS_NUKE_TARGETS += fmdeps-${REPO_NAME}-nuke
.PHONY: fmdeps-${REPO_NAME}-nuke
fmdeps-${REPO_NAME}-nuke:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
ifeq ($(CONFIRM),yes)
	@rm -rf ${REPO_DIR}
else
	@echo "Use CONFIRM=yes to really nuke ${REPO_NAME}."
endif
endif

FMDEPS_FETCH_TARGETS += fmdeps-${REPO_NAME}-fetch
.PHONY: fmdeps-${REPO_NAME}-fetch
fmdeps-${REPO_NAME}-fetch:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Fetching in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} fetch --all --quiet
else
	@echo "No repository in ${REPO_DIR}, cannot fetch."
endif

FMDEPS_PULL_TARGETS += fmdeps-${REPO_NAME}-pull
.PHONY: fmdeps-${REPO_NAME}-pull
fmdeps-${REPO_NAME}-pull:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Pulling in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} pull --rebase
else
	@echo "No repository in ${REPO_DIR}, cannot pull."
endif

FMDEPS_PUSH_TARGETS += fmdeps-${REPO_NAME}-push
.PHONY: fmdeps-${REPO_NAME}-push
fmdeps-${REPO_NAME}-push:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Pushing in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} push
else
	@echo "No repository in ${REPO_DIR}, cannot push."
endif

FMDEPS_PEEK_TARGETS += fmdeps-${REPO_NAME}-peek
.PHONY: fmdeps-${REPO_NAME}-peek
fmdeps-${REPO_NAME}-peek:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Peeking into ${REPO_DIR}:"
	@git -C ${REPO_DIR} status --short --branch --untracked-files=normal
else
	@echo "No repository in ${REPO_DIR}, cannot peek."
endif

FMDEPS_DESCRIBE_TARGETS += fmdeps-${REPO_NAME}-describe
.PHONY: fmdeps-${REPO_NAME}-describe
fmdeps-${REPO_NAME}-describe:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@git -C ${REPO_DIR} log --pretty=tformat:'${REPO_DIR}: %H' -n 1
	@git -C ${REPO_DIR} diff HEAD --quiet || echo "${REPO_DIR} is dirty"
else
	@echo "No repository in ${REPO_DIR}, cannot describe."
endif

FMDEPS_GITCLEAN_TARGETS += fmdeps-${REPO_NAME}-gitclean
.PHONY: fmdeps-${REPO_NAME}-gitclean
fmdeps-${REPO_NAME}-gitclean:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Cleaning ${REPO_DIR}:"
	$(Q)git -C ${REPO_DIR} clean -xfd
else
	@echo "No repository in ${REPO_DIR}, cannot clean."
endif

FMDEPS_CHECKOUT_MAIN_TARGETS += fmdeps-${REPO_NAME}-checkout-main
.PHONY: fmdeps-${REPO_NAME}-checkout-main
fmdeps-${REPO_NAME}-checkout-main:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Resetting ${REPO_DIR} to ${REPO_BRANCH}:"
	$(Q)git -C ${REPO_DIR} checkout ${REPO_BRANCH}
else
	@echo "No repository in ${REPO_DIR}, cannot checkout."
endif

ifneq ($(LOOP_COMMAND),)
FMDEPS_LOOP_TARGETS += fmdeps-${REPO_NAME}-loop
.PHONY: fmdeps-${REPO_NAME}-loop
fmdeps-${REPO_NAME}-loop: | loop-workspace
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	$(Q)$(LOOP_COMMAND) \
		$(REPO_NAME) $(REPO_URL) $(REPO_BRANCH) $(REPO_DIR) $(REPO_MODE)
endif

FMDEPS_REVLOOP_TARGETS += fmdeps-${REPO_NAME}-revloop
.PHONY: fmdeps-${REPO_NAME}-revloop
fmdeps-${REPO_NAME}-revloop:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	$(Q)$(LOOP_COMMAND) $(REPO_NAME) $(REPO_URL) $(REPO_BRANCH) \
		$(REPO_DIR) $(REPO_MODE)
endif
endif

endif
endef

$(foreach dep,sentinel $(FMDEPS),$(eval $(call subrepo_targets,$(dep))))
unexport REPO_NAME
unexport REPO_URL
unexport REPO_BRANCH
unexport REPO_DIR

.PHONY: fmdeps-show-config
fmdeps-show-config: $(FMDEPS_SHOW_CONFIG_TARGETS)

.PHONY: fmdeps-clone
fmdeps-clone: $(FMDEPS_CLONE_TARGETS)

.PHONY: fmdeps-lightweight-clone
fmdeps-lightweight-clone: $(FMDEPS_LIGHTWEIGHT_CLONE_TARGETS)

.PHONY: fmdeps-nuke
fmdeps-nuke: ${FMDEPS_NUKE_TARGETS}

.PHONY: fmdeps-fetch
fmdeps-fetch: $(FMDEPS_FETCH_TARGETS)

.PHONY: fmdeps-pull
fmdeps-pull: $(FMDEPS_PULL_TARGETS)

.PHONY: fmdeps-push
fmdeps-push: $(FMDEPS_PUSH_TARGETS)

.PHONY: fmdeps-peek
fmdeps-peek: $(FMDEPS_PEEK_TARGETS)

.PHONY: fmdeps-describe
fmdeps-describe: $(FMDEPS_DESCRIBE_TARGETS)

.PHONY: fmdeps-gitclean
fmdeps-gitclean: $(FMDEPS_GITCLEAN_TARGETS)

.PHONY: fmdeps-checkout-main
fmdeps-checkout-main: $(FMDEPS_CHECKOUT_MAIN_TARGETS)

.PHONY: fmdeps-loop
fmdeps-loop: $(FMDEPS_LOOP_TARGETS)

.PHONY: fmdeps-revloop
fmdeps-revloop: $(FMDEPS_REVLOOP_TARGETS)
