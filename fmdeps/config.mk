# Entries of the form <REPO_PATH>:<MAIN_BRANCH>:<FMDEPS_DIR>/:<MODE> where:
# - REPO_PATH: GitHub repository path.
# - MAIN_BRANCH: main branch name.
# - FMDEPS_DIR: directory under fmdeps/ in which the repo is cloned.
# - MODE: either "upstream", "owned", or "downstream".

# Auxiliary FM repositories.
FMDEPS += SkylabsAI/BRiCk:main:BRiCk/:owned
FMDEPS += SkylabsAI/auto-docs:main:auto-docs/:owned
FMDEPS += SkylabsAI/auto:main:auto/:owned
FMDEPS += SkylabsAI/fm-tools:main:fm-tools/:owned
FMDEPS += SkylabsAI/fm-website:main:website/:owned
FMDEPS += SkylabsAI/skylabs-fm:main:skylabs-fm/:owned

# Infrastructure / CI repositories.
FMDEPS += SkylabsAI/fm-ci:main:fm-ci/:owned
FMDEPS += SkylabsAI/fm-workspace:main:fm-workspace/:owned

# Vendored repositories.
FMDEPS += SkylabsAI/elpi:skylabs-master:vendored/elpi/:upstream
FMDEPS += SkylabsAI/rocq-elpi:skylabs-master:vendored/rocq-elpi/:upstream
FMDEPS += SkylabsAI/rocq-equations:skylabs-main:vendored/rocq-equations/:upstream
FMDEPS += SkylabsAI/rocq-ext-lib:skylabs-master:vendored/rocq-ext-lib/:upstream
FMDEPS += SkylabsAI/rocq-iris:skylabs-master:vendored/rocq-iris/:upstream
FMDEPS += SkylabsAI/rocq-lsp:skylabs-main:vendored/rocq-lsp/:upstream
FMDEPS += SkylabsAI/rocq-stdlib:skylabs-master:vendored/rocq-stdlib/:upstream
FMDEPS += SkylabsAI/rocq-stdpp:skylabs-master:vendored/rocq-stdpp/:upstream
FMDEPS += SkylabsAI/rocq:skylabs-master:vendored/rocq/:upstream
FMDEPS += SkylabsAI/vsrocq:skylabs-main:vendored/vsrocq/:upstream
