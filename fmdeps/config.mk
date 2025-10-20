# Entries of the form <REPO_PATH>:<MAIN_BRANCH>:<FMDEPS_DIR>/ where:
# - REPO_PATH: GitHub repository path.
# - MAIN_BRANCH: main branch name.
# - FMDEPS_DIR: directory under fmdeps/ in which the repo is cloned.

# Auxiliary FM repositories.
FMDEPS += SkylabsAI/BRiCk:main:BRiCk/
FMDEPS += SkylabsAI/auto-docs:main:auto-docs/
FMDEPS += SkylabsAI/auto:main:auto/
FMDEPS += SkylabsAI/fm-tools:main:fm-tools/
FMDEPS += SkylabsAI/fm-website:main:website/
FMDEPS += SkylabsAI/skylabs-fm:main:skylabs-fm/

# Infrastructure / CI repositories.
FMDEPS += SkylabsAI/fm-ci:main:fm-ci/
FMDEPS += SkylabsAI/fm-workspace:main:fm-workspace/

# Vendored repositories.
FMDEPS += SkylabsAI/elpi:skylabs-master:vendored/elpi/
FMDEPS += SkylabsAI/rocq-elpi:skylabs-master:vendored/rocq-elpi/
FMDEPS += SkylabsAI/rocq-equations:skylabs-main:vendored/rocq-equations/
FMDEPS += SkylabsAI/rocq-ext-lib:skylabs-master:vendored/rocq-ext-lib/
FMDEPS += SkylabsAI/rocq-iris:skylabs-master:vendored/rocq-iris/
FMDEPS += SkylabsAI/rocq-lsp:skylabs-main:vendored/rocq-lsp/
FMDEPS += SkylabsAI/rocq-stdlib:skylabs-master:vendored/rocq-stdlib/
FMDEPS += SkylabsAI/rocq-stdpp:skylabs-master:vendored/rocq-stdpp/
FMDEPS += SkylabsAI/rocq:skylabs-master:vendored/rocq/
FMDEPS += SkylabsAI/vsrocq:skylabs-main:vendored/vsrocq/
