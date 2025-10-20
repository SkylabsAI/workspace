include bluerock/config.mk
include bluerock/build.mk

define subrepo_targets
REPO_NAME = $$(basename $$(word 1,$$(subst :, ,$$1)))
REPO_URL = ${GITLAB_URL}/$$(word 1,$$(subst :, ,$$1)).git
REPO_BRANCH = $$(word 2,$$(subst :, ,$$1))
REPO_DIR = bluerock/$$(word 3,$$(subst :, ,$$1))
ifneq ($1,sentinel)

BLUEROCK_SHOW_CONFIG_TARGETS += bluerock-${REPO_NAME}-show-config
.PHONY: bluerock-${REPO_NAME}-show-config
bluerock-${REPO_NAME}-show-config:
	@echo "Repo ${REPO_URL}#${REPO_BRANCH} cloned in ${REPO_DIR}."

BLUEROCK_CLONE_TARGETS += bluerock-${REPO_NAME}-clone
.PHONY: bluerock-${REPO_NAME}-clone
bluerock-${REPO_NAME}-clone:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Repo ${REPO_URL} seems already cloned in ${REPO_DIR}."
else
	@echo "Cloning ${REPO_URL} in ${REPO_DIR}"
	$(Q)git clone --branch ${REPO_BRANCH} ${REPO_URL} ${REPO_DIR}
endif

BLUEROCK_FETCH_TARGETS += bluerock-${REPO_NAME}-fetch
.PHONY: bluerock-${REPO_NAME}-fetch
bluerock-${REPO_NAME}-fetch:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Fetching in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} fetch --all --quiet
else
	@echo "No repository in ${REPO_DIR}, cannot fetch."
endif

BLUEROCK_PULL_TARGETS += bluerock-${REPO_NAME}-pull
.PHONY: bluerock-${REPO_NAME}-pull
bluerock-${REPO_NAME}-pull:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Pulling in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} pull --rebase
else
	@echo "No repository in ${REPO_DIR}, cannot pull."
endif

BLUEROCK_PUSH_TARGETS += bluerock-${REPO_NAME}-push
.PHONY: bluerock-${REPO_NAME}-push
bluerock-${REPO_NAME}-push:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Pushing in ${REPO_DIR}."
	$(Q)git -C ${REPO_DIR} push
else
	@echo "No repository in ${REPO_DIR}, cannot push."
endif

BLUEROCK_PEEK_TARGETS += bluerock-${REPO_NAME}-peek
.PHONY: bluerock-${REPO_NAME}-peek
bluerock-${REPO_NAME}-peek:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Peeking into ${REPO_DIR}:"
	@git -C ${REPO_DIR} status --short --branch --untracked-files=normal
else
	@echo "No repository in ${REPO_DIR}, cannot peek."
endif

BLUEROCK_DESCRIBE_TARGETS += bluerock-${REPO_NAME}-describe
.PHONY: bluerock-${REPO_NAME}-describe
bluerock-${REPO_NAME}-describe:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@git -C ${REPO_DIR} log --pretty=tformat:'${REPO_DIR}: %H' -n 1
	@git -C ${REPO_DIR} diff HEAD --quiet || echo "${REPO_DIR} is dirty"
else
	@echo "No repository in ${REPO_DIR}, cannot describe."
endif

BLUEROCK_GITCLEAN_TARGETS += bluerock-${REPO_NAME}-gitclean
.PHONY: bluerock-${REPO_NAME}-gitclean
bluerock-${REPO_NAME}-gitclean:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Cleaning ${REPO_DIR}:"
	$(Q)git -C ${REPO_DIR} clean -xfd
else
	@echo "No repository in ${REPO_DIR}, cannot clean."
endif

BLUEROCK_CHECKOUT_MAIN_TARGETS += bluerock-${REPO_NAME}-checkout-main
.PHONY: bluerock-${REPO_NAME}-checkout-main
bluerock-${REPO_NAME}-checkout-main:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Resetting ${REPO_DIR} to ${REPO_BRANCH}:"
	$(Q)git -C ${REPO_DIR} checkout ${REPO_BRANCH}
else
	@echo "No repository in ${REPO_DIR}, cannot checkout."
endif

ifneq ($(LOOP_COMMAND),)
BLUEROCK_LOOP_TARGETS += bluerock-${REPO_NAME}-loop
.PHONY: bluerock-${REPO_NAME}-loop
bluerock-${REPO_NAME}-loop: | loop_skylabs_fm
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Looping on ${REPO_NAME} with \"${LOOP_COMMAND}\""
	$(Q)$(LOOP_COMMAND) $(REPO_NAME) $(REPO_URL) $(REPO_BRANCH) $(REPO_DIR)
endif

BLUEROCK_REVLOOP_TARGETS += bluerock-${REPO_NAME}-revloop
.PHONY: bluerock-${REPO_NAME}-revloop
bluerock-${REPO_NAME}-revloop:
ifeq ($(wildcard ${REPO_DIR}),${REPO_DIR})
	@echo "Looping on ${REPO_NAME} with \"${LOOP_COMMAND}\""
	$(Q)$(LOOP_COMMAND) $(REPO_NAME) $(REPO_URL) $(REPO_BRANCH) $(REPO_DIR)
endif
endif

endif
endef

$(foreach dep,sentinel $(BRDEPS),$(eval $(call subrepo_targets,$(dep))))
unexport REPO_NAME
unexport REPO_URL
unexport REPO_BRANCH
unexport REPO_DIR

.PHONY: bluerock-show-config
bluerock-show-config: $(BLUEROCK_SHOW_CONFIG_TARGETS)

.PHONY: bluerock-clone
bluerock-clone: $(BLUEROCK_CLONE_TARGETS)

.PHONY: bluerock-fetch
bluerock-fetch: $(BLUEROCK_FETCH_TARGETS)

.PHONY: bluerock-pull
bluerock-pull: $(BLUEROCK_PULL_TARGETS)

.PHONY: bluerock-push
bluerock-push: $(BLUEROCK_PUSH_TARGETS)

.PHONY: bluerock-peek
bluerock-peek: $(BLUEROCK_PEEK_TARGETS)

.PHONY: bluerock-describe
bluerock-describe: $(BLUEROCK_DESCRIBE_TARGETS)

.PHONY: bluerock-gitclean
bluerock-gitclean: $(BLUEROCK_GITCLEAN_TARGETS)

.PHONY: bluerock-checkout-main
bluerock-checkout-main: $(BLUEROCK_CHECKOUT_MAIN_TARGETS)

.PHONY: bluerock-loop
bluerock-loop: $(BLUEROCK_LOOP_TARGETS)

.PHONY: bluerock-revloop
bluerock-revloop: $(BLUEROCK_REVLOOP_TARGETS)
