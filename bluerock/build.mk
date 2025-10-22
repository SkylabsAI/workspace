BHV_DIR = bluerock/bhv
BHV_PYENV = ${BHV_DIR}/_pyenv

.PHONY: ast-prepare-bhv
ast-prepare-bhv:
ifeq ($(wildcard ${BHV_DIR}),${BHV_DIR})
ifneq ($(wildcard ${BHV_PYENV}),${BHV_PYENV})
	@echo "[ENV] ${BHV_PYENV}"
	$(Q)python3 -m venv ${BHV_PYENV}
endif
	@echo "[PIP] ${BHV_DIR}/python_requirements.txt"
	$(Q)env \
		VIRTUAL_ENV="$${PWD}/${BHV_PYENV}" \
		PATH="$${PWD}/${BHV_PYENV}/bin:$${PATH}" \
		pip install -r ${BHV_DIR}/python_requirements.txt
	@echo "[AST] ${BHV_DIR}"
	$(Q)env \
		GITLAB_URL="git@gitlab.com:skylabs_ai/FM/bluerock/" \
		VIRTUAL_ENV="$${PWD}/${BHV_PYENV}" \
		PATH="$${PWD}/${BHV_PYENV}/bin:$${PATH}" \
		${BHV_DIR}/fm-build.py -b
else
	@echo "Skipping AST generation for ${BHV_DIR} (not cloned)."
endif

NOVA_DIR = bluerock/NOVA

.PHONY: ast-prepare-NOVA
ast-prepare-NOVA:
ifeq ($(wildcard ${NOVA_DIR}),${NOVA_DIR})
	$(Q)dune build _build/install/default/bin/cpp2v
	$(Q)$(MAKE) -C ${NOVA_DIR} \
		FMS_DIR=../../fmdeps \
		PREFIX_NOVA=../../_build/default/bluerock/NOVA/build-proof \
		PREFIX_FM=../../_build/default/fmdeps \
		CPP2V=$${PWD}/_build/install/default/bin/cpp2v \
		dune-ast
else
	@echo "Skipping AST generation for ${NOVA_DIR} (not cloned)."
endif

.PHONY: ast-prepare-bluerock
ast-prepare-bluerock: ast-prepare-bhv ast-prepare-NOVA
