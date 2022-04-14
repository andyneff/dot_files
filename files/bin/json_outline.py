#!/usr/bin/env python

import json
import sys
from pprint import pprint

class ItalicStr(str):
  def __repr__(self):
    r = super().__repr__()
    return r[0] + '\x1b[3m' + r[1:-1] + '\x1b[23m' + r[-1]


def get_structure(data, key=None):
  struct = {}

  if isinstance(data, dict):
    for key, value in data.items():
      if isinstance(value, str):
        struct[key] = "string"
      elif isinstance(value, (int, float)):
        struct[key] = "number"
      elif isinstance(value, dict):
        struct[key] = get_structure(value)
      elif isinstance(value, list):
        struct[key] = get_structure(value, key)
      else:
        raise Exception('Oops')
  elif isinstance(data, list):
    all_items = set()
    some_items = set()
    for item in data:
      i = get_structure(item, key)

      if not all_items:
        all_items = set(i)
        set is wrong, values are lost
      elif all_items != i:
        some_items.update(all_items ^ i.keys())
        all_items = all_items & i.keys()

    # some_items = {ItalicStr(i) if isinstance(i, str) else i for i in some_items}
    # return all_items | some_items

    if not some_items:
      return list(all_items)
    return {"array_all": list(all_items), "array_some": list(some_items)}

  return struct

def print_structure(struct):
  # pprint(struct)
  print(json.dumps(struct, indent=2))

if __name__ == "__main__":
  with open(sys.argv[1], 'r') as fid:
    data = json.load(fid)

  struct = get_structure(data)

  print_structure(struct)
