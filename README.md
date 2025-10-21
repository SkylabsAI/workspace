SkyLabs AI Workspace
====================

This repository provides infrastructure for cloning and working on the various
SkyLabs AI repositories, within a single workspace. For now, only the FM repos
are included, but the aim is to incorporate all active repositories.

This repository also hosts infrastructure for CI and docker images.

Getting Started
---------------

This section gives detailed instructions for setting up a local workspace. The
instructions assume that the workspace is cloned in a directory that will hold
potentially many copies of the workspace, in the form of `git` work-trees.

### Setting Up The Workspace

First, you need to clone the workspace repository.
```sh
mkdir -p $HOME/dev && cd $HOME/dev                # Pick a suitable directory.
git clone git@github.com:SkylabsAI/workspace.git  # Clone the workspace.
cd workspace                                      # Move to the workspace.
```

### Cloning Sub-Repositories

You can then optionally clone sub-repositories within it.
```sh
make fmdeps-clone -j    # Clonning FM sub-repos.
make bluerock-clone -j  # Clonning BlueRock sub-repos, mostly for CI.
```

### Setting Up FM Dependencies

```sh
make dev-check-ver      # Check system deps.
make dev-setup-opam     # Sets up a suitable opam switch.
make update-br-fm-deps  # Install necessary dependencies.
```

Note that you might need to run either of the following commands to enable the
correct opam switch locally.
```sh
source dev/activate.sh  # Enable the development environment.
eval $(opam env)        # Subsumed by the above, adapt if necessary.
```

### Building

To start building, you can run the following.
```sh
make stage1             # Prepare for a minimal build.
dune build              # Build for installation.
```

Sub-Repository Control
----------------------

The following folders gather sub-repositories:
- `fmdeps` (all the core FM repositories),
- `bluerock` (all the BlueRock repositories used by FM CI).

These directories contain a file called `config.mk`, which defines set set of
repositories to be cloned. Special `Makefile` targets can be used to run batch
operations on all such repositories. Note that different targets are used for
different directories, and they are all prefixed by the directory name.

Available `Makefile` targets for the `fmdeps` directory are:
- `make fmdeps-show-config` shows the configuration for the sub-repositories.
- `make fmdeps-clone` initializes all the sub-repositories.
- `make fmdeps-fetch` runs `git fetch --all` in all the sub-repositories.
- `make fmdeps-pull` runs `git pull --rebase` in all the sub-repositories.
- `make fmdeps-peek` runs `git status` in all the sub-repositories.
- `make fmdeps-describe` shows the commit hash of each sub-repositories.

There are more, but these can be dangerous:
- `make fmdeps-gitclean` runs `git clean -xfd` in all the sub-repositories.
- `make fmdeps-checkout-main` resets all the repositories to our main branch.

Similar targets are available for other sub-repository directories.
