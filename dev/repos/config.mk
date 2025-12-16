# Base of the GitHub URL used for repositories (without organization name). It
# can be overridden, e.g., to clone using https instead of ssh.
GITHUB_URL ?= git@github.com:

# GitHub repository path (including the organization) on GitHub.
WORKSPACE_PATH = SkyLabsAI/workspace

# GitHub URL of the workspace repository (this repository).
WORKSPACE_ON_GITHUB = ${GITHUB_URL}${WORKSPACE_PATH}.git

# Variable REPOS controls the set of sub-repositories managed by the workspace
# (this repository). Repositories are configured with an entry of the form:
#   REPOS += <GROUP>:<PATH>:<DEFAULT>:<DIR>/:<MODE>:<VIS>
# where:
# - GROUP is a repository group, corresponding to top-level directory.
# - PATH is the GitHub repository path.
# - DEFAULT is the repository's default branch (usually "main").
# - DIR is the directory under the group into which the repo is cloned.
# - MODE is either "upstream", "owned", or "downstream".
# - VIS (visibility) is either "public" or "private".
#
# Note that common Makefile targets are generated to control all repositories.
# Such targets are also produced for groups of repositories.

# Auxiliary FM repositories.
REPOS += fmdeps:SkyLabsAI/BRiCk:main:BRiCk/:owned:public
REPOS += fmdeps:SkyLabsAI/auto-docs:main:auto-docs/:owned:public
REPOS += fmdeps:SkyLabsAI/auto:main:auto/:owned:private
REPOS += fmdeps:SkyLabsAI/brick-libcpp:main:brick-libcpp/:owned:public
REPOS += fmdeps:SkyLabsAI/fm-tools:main:fm-tools/:owned:private
REPOS += fmdeps:SkyLabsAI/skylabs-fm:main:skylabs-fm/:owned:private
REPOS += fmdeps:SkyLabsAI/rocq-agent-toolkit:main:rocq-agent-toolkit/:owned:private

# Infrastructure / CI repositories.
REPOS += fmdeps:SkyLabsAI/fm-ci:main:fm-ci/:owned:public
REPOS += fmdeps:SkyLabsAI/ci:main:ci/:owned:private

# Vendored repositories.
REPOS += fmdeps:SkyLabsAI/elpi:skylabs-master:vendored/elpi/:upstream:public
REPOS += fmdeps:SkyLabsAI/rocq-elpi:skylabs-master:vendored/rocq-elpi/:upstream:public
REPOS += fmdeps:SkyLabsAI/rocq-equations:skylabs-main:vendored/rocq-equations/:upstream:public
REPOS += fmdeps:SkyLabsAI/rocq-ext-lib:skylabs-master:vendored/rocq-ext-lib/:upstream:public
REPOS += fmdeps:SkyLabsAI/rocq-iris:skylabs-master:vendored/rocq-iris/:upstream:public
REPOS += fmdeps:SkyLabsAI/rocq-lsp:skylabs-main:vendored/rocq-lsp/:upstream:public
REPOS += fmdeps:SkyLabsAI/rocq-stdlib:skylabs-master:vendored/rocq-stdlib/:upstream:public
REPOS += fmdeps:SkyLabsAI/rocq-stdpp:skylabs-master:vendored/rocq-stdpp/:upstream:public
REPOS += fmdeps:SkyLabsAI/rocq:skylabs-master:vendored/rocq/:upstream:public
REPOS += fmdeps:SkyLabsAI/vsrocq:skylabs-main:vendored/vsrocq/:upstream:public

# BlueRock repositories.
REPOS += bluerock:SkyLabsAI/bluerock.NOVA:skylabs-proof:NOVA/:downstream:private
REPOS += bluerock:SkyLabsAI/bluerock.bhv:skylabs-main:bhv/:downstream:private

# PSI repositories.
REPOS += psi:SkyLabsAI/protos:main:protos/:owned:private
REPOS += psi:SkyLabsAI/psi-verifier:main:backend/:owned:private
REPOS += psi:SkyLabsAI/psi-verifier-ide:main:ide/:owned:private
REPOS += psi:SkyLabsAI/psi_PROVER.data:main:data/:owned:private

# Variable CLONE_ENV_<REPO_NAME>, where REPO_NAME is a GitHub repo name (i.e.,
# the REPO_PATH without the leading organization), can be used to add variable
# assignment to the cloning commands for the corresponding repo.

# Avoid pulling in git-lfs files for bhv.
CLONE_ENV_bluerock.bhv = GIT_LFS_SKIP_SMUDGE=1
