BHV_DIR = bluerock/bhv
GITLAB_URL="${GITHUB_URL}SkyLabsAI/bluerock."
BHV_VENV = ${BHV_DIR}/.venv

.PHONY: ast-prepare-bhv
ast-prepare-bhv: ide-prepare
ifeq ($(wildcard ${BHV_DIR}),${BHV_DIR})
ifneq ($(wildcard ${BHV_VENV}),${BHV_VENV})
	@echo "[ENV] ${BHV_VENV}"
	$(Q)(cd ${BHV_DIR}; uv venv)
	$(Q)ls ${BHV_VENV} > /dev/null
endif
	@echo "[PIP] ${BHV_DIR}/python_requirements.txt"
	$(Q)(cd ${BHV_DIR}; uv pip install -r python_requirements.txt)
	@echo "[AST] ${BHV_DIR}"
	+$(Q)(cd ${BHV_DIR}; LLVM=1 BUILD_CACHING=0 SHALLOW=1 \
		GITLAB_URL=${GITLAB_URL} uv run -- ./fm-build.py -b)
else
	@echo "Skipping AST generation for ${BHV_DIR} (not cloned)."
endif

NOVA_DIR = bluerock/NOVA

.PHONY: ast-prepare-NOVA
ast-prepare-NOVA: ide-prepare
ifeq ($(wildcard ${NOVA_DIR}),${NOVA_DIR})
	$(Q)$(MAKE) -C ${NOVA_DIR} CPP2V=$${PWD}/${CPP2V} dune-ast
else
	@echo "Skipping AST generation for ${NOVA_DIR} (not cloned)."
endif

.PHONY: ast-prepare-bluerock
ast-prepare-bluerock: ast-prepare-bhv ast-prepare-NOVA
