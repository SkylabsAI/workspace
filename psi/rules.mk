include psi/config.mk

define subrepo_targets
REPO_NAME = $$(word 1,$$(subst :, ,$$1))
REPO_URL = ${GITHUB_URL}$$(word 1,$$(subst :, ,$$1)).git
REPO_BRANCH = $$(word 2,$$(subst :, ,$$1))
REPO_DIR = psi/$$(word 3,$$(subst :, ,$$1))
REPO_MODE = $$(word 4,$$(subst :, ,$$1))
ifneq ($1,sentinel)

PSI_SHOW_CONFIG_TARGETS += psi-${REPO_NAME}-show-config
.PHONY: psi-${REPO_NAME}-show-config
psi-${REPO_NAME}-show-config:
	@echo "$(REPO_NAME) $(REPO_URL) $(REPO_BRANCH) $(REPO_DIR) $(REPO_MODE)"

PSI_CLONE_TARGETS += psi-${REPO_NAME}-clone
.PHONY: psi-${REPO_NAME}-clone
psi-${REPO_NAME}-clone:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Repo ${REPO_URL} seems already cloned in ${REPO_DIR}."
else
	@echo "Cloning ${REPO_URL} in ${REPO_DIR}"
	$(Q)git clone ${CLONE_ARGS} --branch ${REPO_BRANCH} ${REPO_URL} ${REPO_DIR}
endif

PSI_LIGHTWEIGHT_CLONE_TARGETS += psi-${REPO_NAME}-lightweight-clone
.PHONY: psi-${REPO_NAME}-lightweight-clone
psi-${REPO_NAME}-lightweight-clone:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Repo ${REPO_URL} seems already cloned in ${REPO_DIR}."
else
	@echo "Cloning ${REPO_URL} in ${REPO_DIR} (lightweight, no checkout)"
	$(Q)git clone --no-checkout --filter=tree:0 --quiet ${REPO_URL} ${REPO_DIR}
endif

PSI_NUKE_TARGETS += psi-${REPO_NAME}-nuke
.PHONY: psi-${REPO_NAME}-nuke
psi-${REPO_NAME}-nuke:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
ifeq ($(CONFIRM),yes)
	@rm -rf ${REPO_DIR}
else
	@echo "Use CONFIRM=yes to really nuke ${REPO_NAME}."
endif
endif

PSI_FETCH_TARGETS += psi-${REPO_NAME}-fetch
.PHONY: psi-${REPO_NAME}-fetch
psi-${REPO_NAME}-fetch:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Fetching in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} fetch --all --quiet
else
	@echo "No repository in ${REPO_DIR}, cannot fetch."
endif

PSI_PULL_TARGETS += psi-${REPO_NAME}-pull
.PHONY: psi-${REPO_NAME}-pull
psi-${REPO_NAME}-pull:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Pulling in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} pull --rebase
else
	@echo "No repository in ${REPO_DIR}, cannot pull."
endif

PSI_PUSH_TARGETS += psi-${REPO_NAME}-push
.PHONY: psi-${REPO_NAME}-push
psi-${REPO_NAME}-push:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Pushing in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} push
else
	@echo "No repository in ${REPO_DIR}, cannot push."
endif

PSI_PEEK_TARGETS += psi-${REPO_NAME}-peek
.PHONY: psi-${REPO_NAME}-peek
psi-${REPO_NAME}-peek:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Peeking into ${REPO_DIR}:"
	@git -C ${REPO_DIR} status --short --branch --untracked-files=normal
else
	@echo "No repository in ${REPO_DIR}, cannot peek."
endif

PSI_DESCRIBE_TARGETS += psi-${REPO_NAME}-describe
.PHONY: psi-${REPO_NAME}-describe
psi-${REPO_NAME}-describe:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@git -C ${REPO_DIR} log --pretty=tformat:'${REPO_DIR}: %H' -n 1
	@git -C ${REPO_DIR} diff HEAD --quiet || echo "${REPO_DIR} is dirty"
else
	@echo "No repository in ${REPO_DIR}, cannot describe."
endif

PSI_GITCLEAN_TARGETS += psi-${REPO_NAME}-gitclean
.PHONY: psi-${REPO_NAME}-gitclean
psi-${REPO_NAME}-gitclean:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Cleaning ${REPO_DIR}:"
	$(Q)git -C ${REPO_DIR} clean -xfd
else
	@echo "No repository in ${REPO_DIR}, cannot clean."
endif

PSI_CHECKOUT_MAIN_TARGETS += psi-${REPO_NAME}-checkout-main
.PHONY: psi-${REPO_NAME}-checkout-main
psi-${REPO_NAME}-checkout-main:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Resetting ${REPO_DIR} to ${REPO_BRANCH}:"
	$(Q)git -C ${REPO_DIR} checkout ${REPO_BRANCH}
else
	@echo "No repository in ${REPO_DIR}, cannot checkout."
endif

ifneq ($(LOOP_COMMAND),)
PSI_LOOP_TARGETS += psi-${REPO_NAME}-loop
.PHONY: psi-${REPO_NAME}-loop
psi-${REPO_NAME}-loop: | loop-workspace
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	$(Q)$(LOOP_COMMAND) \
		$(REPO_NAME) $(REPO_URL) $(REPO_BRANCH) $(REPO_DIR) $(REPO_MODE)
endif

PSI_REVLOOP_TARGETS += psi-${REPO_NAME}-revloop
.PHONY: psi-${REPO_NAME}-revloop
psi-${REPO_NAME}-revloop:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	$(Q)$(LOOP_COMMAND) \
		$(REPO_NAME) $(REPO_URL) $(REPO_BRANCH) $(REPO_DIR) $(REPO_MODE)
endif
endif

endif
endef

$(foreach dep,sentinel $(PSIDEPS),$(eval $(call subrepo_targets,$(dep))))
unexport REPO_NAME
unexport REPO_URL
unexport REPO_BRANCH
unexport REPO_DIR

.PHONY: psi-show-config
psi-show-config: $(PSI_SHOW_CONFIG_TARGETS)

.PHONY: psi-clone
psi-clone: $(PSI_CLONE_TARGETS)

.PHONY: psi-lightweight-clone
psi-lightweight-clone: $(PSI_LIGHTWEIGHT_CLONE_TARGETS)

.PHONY: psi-nuke
psi-nuke: ${PSI_NUKE_TARGETS}

.PHONY: psi-fetch
psi-fetch: $(PSI_FETCH_TARGETS)

.PHONY: psi-pull
psi-pull: $(PSI_PULL_TARGETS)

.PHONY: psi-push
psi-push: $(PSI_PUSH_TARGETS)

.PHONY: psi-peek
psi-peek: $(PSI_PEEK_TARGETS)

.PHONY: psi-describe
psi-describe: $(PSI_DESCRIBE_TARGETS)

.PHONY: psi-gitclean
psi-gitclean: $(PSI_GITCLEAN_TARGETS)

.PHONY: psi-checkout-main
psi-checkout-main: $(PSI_CHECKOUT_MAIN_TARGETS)

.PHONY: psi-loop
psi-loop: $(PSI_LOOP_TARGETS)

.PHONY: psi-revloop
psi-revloop: $(PSI_REVLOOP_TARGETS)
