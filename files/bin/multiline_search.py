#!/usr/bin/python

# find . -path ./docs/_build -prune -o -not -name \*.txt -not -name \*.js -not -name \*.html -not -name \*.rst -not -name \*.auto -not -name \*.auto.\* -not -name \*.py -not -name *.awk -not -name \*.bat -not -name \*.ps1  -not -name \*.pyc -type f -not -name \*.json -print | xargs multiline_search.py -p '\$[0-9]' -n '^ *#' -n '^ *[-a-z_]*\) *#.*' -n "awk (?:-F '[^']*' )?'.*'"

import sys
import re
import shlex
import argparse


def line_matches(line, patterns, npatterns):
  for pattern in patterns:
    if not pattern.search(line):
      return False
  for npattern in npatterns:
    if npattern.search(line):
      return False
  return True


def scan_bash_file(filename, patterns, npatterns):
  printed = False
  with open(filename, 'r') as fid:
    lines = fid.readlines()

  line = ''
  while lines:
    line += lines.pop(0)
    try:
      split = shlex.split(line, comments=True)
    except ValueError:
      continue
    # Support bash \
    if line.endswith('\\\n'):
      continue

    if line_matches(line, patterns, npatterns):
      for pattern in patterns:
        line = pattern.sub('\x1b[31m\\1\x1b[0m', line)
      if not printed:
        print(f'\x1b[32m{filename}\x1b[0m:')
        printed = True
      print(line.rstrip())
    line=''

  if line_matches(line, patterns, npatterns):
    for pattern in patterns:
      line = pattern.sub('\x1b[31m\\1\x1b[0m', line)
    if not printed:
      print(f'\x1b[32m{filename}\x1b[0m:')
      printed = True
    print(line.rstrip())

def get_parser():
  parser = argparse.ArgumentParser()
  aa = parser.add_argument
  aa('files', nargs='+', help="Filenames to search")
  aa('-p', dest='patterns', required=True, action='append',
     help="Regex pattern to match")
  aa('-n', dest='npatterns', default=[], required=False, action='append',
     help="Regex negative patterns to not match")
  aa('-i', dest='insensitive', default=False, action='store_true',
     help="Perform case insensitive search")
  return parser


if __name__ == '__main__':
  args = get_parser().parse_args(sys.argv[1:])

  patterns = []
  npatterns = []
  for pattern in args.patterns:
    patterns.append(re.compile('('+pattern+')', flags=re.MULTILINE + \
        (args.insensitive * re.IGNORECASE)))
  for npattern in args.npatterns:
    npatterns.append(re.compile(npattern, flags=re.MULTILINE + \
        (args.insensitive * re.IGNORECASE)))

  for filename in args.files:
    scan_bash_file(filename, patterns, npatterns)
