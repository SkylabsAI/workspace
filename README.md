SkyLabs AI Workspace
====================

This repository provides infrastructure for cloning and working on the various
SkyLabs AI repositories (public of private), within a single workspace.

Getting Started
---------------

This section gives detailed instructions for setting up a local workspace. The
instructions assume that the workspace is cloned in a directory that will hold
potentially many copies of the workspace, some containing `git` work-trees.

### Setting Up The Workspace

First, you need to clone the workspace repository.
```sh
mkdir -p $HOME/dev && cd $HOME/dev                # Pick a suitable directory.
git clone git@github.com:SkyLabsAI/workspace.git  # Clone the workspace.
cd workspace                                      # Move to the workspace.
```

### Cloning Sub-Repositories

You can then optionally clone sub-repositories within it.
```sh
make clone -j          # Cloning everything (including private repos).
make clone-public -j   # Cloning only the publicly-accessible repos.
make clone-vendored -j # Cloning only the (public) vendored repositories.
make clone-fmdeps -j   # Cloning (mostly public) repos of fmdeps/.
make clone-psi -j      # Cloning (private) repos of psi/.
make clone-bluerock -j # Cloning (private) repos of bluerock/ (used in CI).
```

### Setting Up FM Dependencies

```sh
make dev-check-ver    # Check system deps.
make dev-setup        # Setup the dev environment (opam switch, ...).
make update-opam-deps # Install necessary dependencies.
```

Note that you might need to run either of the following commands to enable the
correct development environment locally (opam switch, ...).
```sh
source dev/activate.sh  # Enable the development environment.
```

### Building

To start building, you can run the following.
```sh
make ide-prepare        # Prepare for a minimal build.
make -j$(nproc) stage1  # Build ASTs of client projects.
dune build              # Build for installation.
```

Sub-Repository Control
----------------------

The configuration for sub-repositories is found in `dev/repos/config.mk`. This
file controls what repos get clone in the workspace, and where. At the moment,
repositories are gatherd into the followig directories:
- `fmdeps/` (all the core FM repositories),
- `psi/` (all other SkyLabs AI repositories),
- `bluerock/` (all the BlueRock repositories used by FM CI).

Custom `Makefile` targets are provided to run batch operations on repositories
of the workspace, either all of them, or a group of them (corresponding to the
directories listed above, and also to special groups like `upstream`, `owned`,
`dowstream`, `public`, or `private`). Here is a list of often useful targets:
- `make show-config` shows the configuration for the sub-repositories.
- `make clone` initializes all the sub-repositories.
- `make fetch` runs `git fetch --all` in all the sub-repositories.
- `make pull` runs `git pull --rebase` in all the sub-repositories.
- `make peek` runs `git status` in all the sub-repositories.
- `make describe` shows the commit hash of each sub-repositories.

There are more, but these can be dangerous:
- `make gitclean` runs `git clean -xfd` in all the sub-repositories.
- `make checkout-main` resets all the repositories to our main branch.
- `make nuke` deletes all the sub-repositories.

Similar targets are available for groups of repos. For example:
- `make clone-fmdeps` only clones the sub-repos of the `fmdeps/` directory.
- `make peek-psi` runs `git status` in sub-repos of the `psi/` directory.
- `make nuke-bluerock` deletes all sub-repositories in `bluerock/`.
- `make peek-public` runs `git status` in all the public repos.

Targets are also provided per-repo. For example:
- `make clone-BRiCk` only clones `BRiCk` in `fmdeps/BRiCk`.
- `make nuke-bhv` deletes the sub-repo in `bluerock/bhv`.

Worktree Support
----------------

See [here](./dev/worktrees/README-worktree.md) for worktree support.
