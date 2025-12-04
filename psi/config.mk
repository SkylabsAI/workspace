# Entries of the form <REPO_PATH>:<MAIN_BRANCH>:<FMDEPS_DIR>/:<MODE> where:
# - REPO_PATH: GitHub repository path.
# - MAIN_BRANCH: main branch name.
# - FMDEPS_DIR: directory under fmdeps/ in which the repo is cloned.
# - MODE: either "upstream", "owned", or "downstream".

PSIDEPS += SkyLabsAI/protos:main:protos/:owned
PSIDEPS += SkyLabsAI/psi-verifier:main:backend/:owned
PSIDEPS += SkyLabsAI/psi-verifier-ide:main:ide/:owned
PSIDEPS += SkyLabsAI/psi_PROVER.data:main:data/:owned
