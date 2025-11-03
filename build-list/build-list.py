#! /usr/bin/env python3

import yaml
import os
import os.path
import sys
import argparse

# cd = os.path.join(os.getenv('HOME'), 'Skylabs/worktree-simon-template-spec')

def replace_extension(fn):
    (name, ext) = os.path.splitext(fn)
    if ext == '.v':
        # name = os.path.join('_build',  name)
        return name + ".vo"
    elif ext in ['.cpp','.hpp']:
        # name = os.path.join('_build', name)
        return name + '_' + ext[1:] + '.vo'
    elif '@' in name:
        return name
    elif os.path.isdir(name):
        return name

def print_sexp(sexp, out=None, indent=0):
    out = out or sys.stdout
    margin = indent * ' '
    if isinstance(sexp, str):
        out.write(margin + sexp)
    else:
        (hd, args) = sexp
        out.write(margin + '(' + hd)
        if not isinstance(args, list):
            args = [args]
        if len(args) == 1 and isinstance(args[0], str):
            out.write(' ' + args[0])
        else:
            for a in args:
                out.write('\n')
                print_sexp(a, out, indent=indent+1)
        out.write(')')

def node(tag, args):
    return (tag, args)

def make_alias_target(tgt_name, tgts):
    deps = []
    tgts = tgts or []
    for tgt in tgts:
        tgt = os.path.join('..', tgt)
        tgt = replace_extension(tgt)
        if tgt:
            if os.path.isdir(tgt):
                tgt = os.path.join(tgt, '*')
                deps.append(node('glob_files_rec', [tgt]))
            else:
                deps.append(node('file', [tgt]))

    name = node('name', [tgt_name])
    deps = node('deps', deps)
    return node('alias', [name, deps])

def find_root(path):
    parent = os.path.dirname(path)
    root = None
    while parent != path and not os.path.isfile(os.path.join(path, 'dune-workspace')):
        path = parent
        parent = os.path.dirname(path)
    return path

def make_arg_parser():
    parser = argparse.ArgumentParser(
        prog='build-list.py',
        description=("Takes in a list of Rocq or C++ source files in a yaml" +
                     "file and output a dune specification of an alias target that" +
                     "causes the specification to be compiled"))

    parser.add_argument('filename', nargs='*')
    parser.add_argument('-o', '--output')
    return parser

parser = make_arg_parser()

args = parser.parse_args()

args.filename = [ os.path.realpath(fn) for fn in args.filename ]
error = False
for fn in args.filename:
    if not os.path.isfile(fn):
        print(f'File not found: {fn}')
        error = True
if args.output:
    args.output = os.path.realpath(args.output)
    out_dir = os.path.dirname(args.output)
    if not os.path.isdir(out_dir):
        print('Directory does not exist: {out_dir}')
        error = True
elif len(args.filename) == 1:
    args.output = os.path.join(os.path.dirname(args.filename[0]), "dune.inc")
else:
    print("Missing: output file name")
    error = True

if error:
    sys.exit(-1)

cwd = find_root(args.output)

print(f'workspace: {cwd}')
print(f'')
targets = []
for fn in args.filename:
    rel_fn = os.path.relpath(fn, start=cwd)
    print(f'read: {rel_fn}')
    (target_name, _) = os.path.splitext(os.path.basename(fn))
    with open(fn, 'r') as file_in:
        data = yaml.load(file_in, Loader=yaml.SafeLoader)
        alias = make_alias_target(target_name, data)
        targets.append(alias)

rel_out = os.path.relpath(args.output, start=cwd)
print(f'write: {rel_out}')

with open(args.output, 'w') as file_out:
    for alias in targets:
        print_sexp(alias, file_out)
        file_out.write('\n')
