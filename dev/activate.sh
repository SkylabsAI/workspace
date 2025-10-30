# Source this file to setup your shell.

if [[ -f ".venv/bin/activate" ]]; then
  source ".venv/bin/activate"
fi

eval $(opam env)
