#! /usr/bin/env python3

import yaml
import os
import os.path
import sys
import argparse
import sexpdata

def replace_extension(fn, is_alias):
    (name, ext) = os.path.splitext(fn)
    if is_alias:
        if ext == '.t':
            return name
        else:
            return fn
    elif ext == '.v':
        # name = os.path.join('_build',  name)
        return name + ".vo"
    elif ext in ['.cpp','.hpp']:
        # name = os.path.join('_build', name)
        return name + '_' + ext[1:] + '.vo'
    else:
        return fn

def node(tag, args):
    return [sexpdata.Symbol(tag)] + args

def parse_target(fn):
    tgt_type = False
    (_, ext) = os.path.splitext(fn)
    if fn.startswith('@@'):
        fn = fn[2:]
        tgt_type = '@@'
    elif fn.startswith('@'):
        fn = fn[1:]
        tgt_type = '@'
    elif '*' in fn:
        tgt_type = 'pattern'
    else:
        tgt_type = 'file'
    return (tgt_type, os.path.realpath(fn))

def make_alias_target(tgt_name, tgts, relative_to):
    deps = []
    tgts = tgts or []
    for init_tgt in tgts:
        (tgt_type, tgt) = parse_target(init_tgt)
        pwd = os.path.realpath('.')
        tgt = replace_extension(tgt, is_alias=tgt_type in ['@','@@'])
        tgt_rel_path = os.path.relpath(tgt, relative_to)
        if tgt_type in ['@', '@@']:
            deps.append(node('alias', [alias + tgt_rel_path]))
        elif tgt_type == 'pattern':
            tgt = os.path.join(tgt, '*')
            deps.append(node('glob_files_rec', [tgt_rel_path]))
        else:
            deps.append(node('file', [tgt_rel_path]))

    name = node('name', [tgt_name])
    deps = node('deps', deps)
    return node('alias', [name, deps])

def find_root(path):
    """Find the dune workspace that `path` resides in."""
    parent = os.path.dirname(path)
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
    parser.add_argument('-o', '--output', type=str)
    parser.add_argument('--relative-to', type=str,
                        help='Specify target path relative to this path. Default: .')
    parser.add_argument('-C', '--root', type=str,
                        help='Specify the root of dune workspace. If omitted, find the closest dominating \'dune-workspace\' file')
    return parser

def parse_args():
    parser = make_arg_parser()
    args = parser.parse_args()

    args.filename = [ os.path.realpath(fn) for fn in args.filename ]
    error = False
    for fn in args.filename:
        if not os.path.isfile(fn):
            print(f'File not found: {fn}')
            error = True
    if not args.root:
        if len(args.filename) > 0:
            args.root = find_root(args.filename[0])
            print(f'args.root: {args.root} (calculated)')
        else:
            args.root = os.path.realpath('.')
            print(f'args.root: {args.root} (.)')
    else:
        args.root = os.path.realpath(args.root)

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
    if args.relative_to:
        args.relative_to = os.path.realpath(args.relative_to)
        rel_dir = os.path.dirname(args.relative_to)
        if not os.path.isdir(rel_dir):
            print('Directory does not exist: {rel_dir}')
            error = True
    if error:
        sys.exit(-1)
    return args

def main():
    args = parse_args()
    os.chdir(args.root)

    targets = []
    for fn in args.filename:
        (target_name, _) = os.path.splitext(os.path.basename(fn))
        with open(fn, 'r') as file_in:
            data = yaml.load(file_in, Loader=yaml.SafeLoader)
            alias = make_alias_target(target_name, data, relative_to=args.relative_to)
            targets.append(alias)

    with open(args.output, 'w') as file_out:
        for alias in targets:
            sexpdata.dump(alias, file_out, pretty_print=True)
            file_out.write('\n')

if __name__ == '__main__':
    main()
