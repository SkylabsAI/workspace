# Entries of the form <REPO_PATH>:<MAIN_BRANCH>:<FMDEPS_DIR>/:<MODE> where:
# - REPO_PATH: GitHub repository path.
# - MAIN_BRANCH: main branch name.
# - FMDEPS_DIR: directory under fmdeps/ in which the repo is cloned.
# - MODE: either "upstream", "owned", or "downstream".

BRDEPS += SkyLabsAI/bluerock.NOVA:skylabs-proof:NOVA/:downstream
BRDEPS += SkyLabsAI/bluerock.bhv:skylabs-main:bhv/:downstream
