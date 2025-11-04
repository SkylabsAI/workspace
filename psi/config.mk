# Entries of the form <REPO_PATH>:<MAIN_BRANCH>:<FMDEPS_DIR>/:<MODE> where:
# - REPO_PATH: GitHub repository path.
# - MAIN_BRANCH: main branch name.
# - FMDEPS_DIR: directory under fmdeps/ in which the repo is cloned.
# - MODE: either "upstream", "owned", or "downstream".

PSIDEPS += SkylabsAI/protos:main:protos/:owned
PSIDEPS += SkylabsAI/psi-verifier:main:backend/:owned
PSIDEPS += SkylabsAI/psi-verifier-ide:main:ide/:owned
PSIDEPS += SkylabsAI/psi_PROVER.data:main:data/:owned
