BHV_DIR = bluerock/bhv
GITLAB_URL="${GITHUB_URL}SkyLabsAI/bluerock."

.PHONY: ast-prepare-bhv
ast-prepare-bhv: ide-prepare
ifeq ($(wildcard ${BHV_DIR}),${BHV_DIR})
	@echo "[AST] ${BHV_DIR}"
	+$(Q)(LLVM=1 BUILD_CACHING=0 SHALLOW=1 \
		GITLAB_URL=${GITLAB_URL} \
		uv --directory ${BHV_DIR} run \
		   --with-requirements python_requirements.txt \
		   --no-project --isolated -- ./fm-build.py -b)
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
