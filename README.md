SkyLabs AI Workspace
====================

Quick Install
-------------

Run the following commands:
```sh
make dev-check-ver                      # Check system deps.
opam switch create --empty skylabs-fm   # Create a new opam switch.
eval $(opam env ...)                    # As suggested by previous command (to adapt).
make fmdeps-clone -j8                   # Clones all the BlueRock FM dependencies.
make update-br-fm-deps                  # Install necessary dependencies.
make stage1                             # Prepare for a minimal build.
dune build @install                     # Build for installation.
dune install                            # Install everything in the switch.
```

Quick Development Setup
-----------------------

Run the following commands:
```sh
make dev-setup           # Check system deps, setup environment.
source dev/activate.sh   # Setup your shell, need to be run in all shells.
make fmdeps-clone -j8    # Clones all the BlueRock FM dependencies.
make update-br-fm-deps   # Installs necessary dependencies.
make                     # Builds everything.
```

System Dependencies
-------------------

To build and install the FM toolchain, you need to install:
- The [OCaml Package Manager (OPAM)](https://opam.ocaml.org/doc/Install.html)
  version 2.2.1 at least.
- Version 19 of the Clang compiler and LLVM toolchain (version 18 and 20 are
  also supported).

To check that you have everything correctly installed, you can run:
```sh
make dev-check-ver
```
Ensure that this command succeeds before continuing.

Development Environment Setup
-----------------------------

To setup your development environment, you can run:
```
make dev-setup
```
This will create a local opam switch, as well as a Python virtual environment.

To set up your shell, you need to run:
```
source dev/activate.sh
```
This will ensure that the OCaml and Python environments are accessible.

BlueRock FM Dependencies
------------------------

The `fmdeps` folder gathers sub-repositories corresponding to all the BlueRock
FM dependencies (including BRiCk, the proof automation, Coq, ...).

To quickly get started, run `make fmdeps-clone -j8`. This will clone all the
necessary BlueRock repositories under the `fmdeps` folder.

Generally, the `fmdeps` sub-repositories are managed using `Makefile` targets:
- `make fmdeps-show-config` shows the configuration for the sub-repositories.
- `make fmdeps-clone` initializes all the sub-repositories.
- `make fmdeps-fetch` runs `git fetch --all` in all the sub-repositories.
- `make fmdeps-pull` runs `git pull --rebase` in all the sub-repositories.
- `make fmdeps-peek` runs `git status` in all the sub-repositories.
- `make fmdeps-describe` shows the commit hash of each sub-repositories.

There are more, but these can be dangerous:
- `make fmdeps-gitclean` runs `git clean -xfd` in all the sub-repositories.
- `make fmdeps-checkout-main` resets all the repositories to our main branch.

Docker Image
------------

Note that the docker generation uses the current state of the repository, so
it is your responsibility to make sure that your workspace is in a clean state
before building the docker image.

The following `Makefile` targets are provided for the Docker image setup:
- `make docker-build` builds our docker image.
- `make docker-run` runs our docker image.
