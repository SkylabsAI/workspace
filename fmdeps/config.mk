# Entries of the form <REPO_PATH>:<MAIN_BRANCH>:<FMDEPS_DIR>/:<MODE> where:
# - REPO_PATH: GitHub repository path.
# - MAIN_BRANCH: main branch name.
# - FMDEPS_DIR: directory under fmdeps/ in which the repo is cloned.
# - MODE: either "upstream", "owned", or "downstream".

# Auxiliary FM repositories.
FMDEPS += SkyLabsAI/BRiCk:main:BRiCk/:owned
FMDEPS += SkyLabsAI/auto-docs:main:auto-docs/:owned
FMDEPS += SkyLabsAI/auto:main:auto/:owned
FMDEPS += SkyLabsAI/brick-libcpp:main:brick-libcpp/:owned
FMDEPS += SkyLabsAI/fm-tools:main:fm-tools/:owned
FMDEPS += SkyLabsAI/skylabs-fm:main:skylabs-fm/:owned

# Infrastructure / CI repositories.
FMDEPS += SkyLabsAI/fm-ci:main:fm-ci/:owned
FMDEPS += SkyLabsAI/ci:main:ci/:owned

# Vendored repositories.
FMDEPS += SkyLabsAI/elpi:skylabs-master:vendored/elpi/:upstream
FMDEPS += SkyLabsAI/rocq-elpi:skylabs-master:vendored/rocq-elpi/:upstream
FMDEPS += SkyLabsAI/rocq-equations:skylabs-main:vendored/rocq-equations/:upstream
FMDEPS += SkyLabsAI/rocq-ext-lib:skylabs-master:vendored/rocq-ext-lib/:upstream
FMDEPS += SkyLabsAI/rocq-iris:skylabs-master:vendored/rocq-iris/:upstream
FMDEPS += SkyLabsAI/rocq-lsp:skylabs-main:vendored/rocq-lsp/:upstream
FMDEPS += SkyLabsAI/rocq-stdlib:skylabs-master:vendored/rocq-stdlib/:upstream
FMDEPS += SkyLabsAI/rocq-stdpp:skylabs-master:vendored/rocq-stdpp/:upstream
FMDEPS += SkyLabsAI/rocq:skylabs-master:vendored/rocq/:upstream
FMDEPS += SkyLabsAI/vsrocq:skylabs-main:vendored/vsrocq/:upstream
