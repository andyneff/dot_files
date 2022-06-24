#!/usr/bin/env python

import json
import sys
from pprint import pprint

class ItalicStr(str):
  def __repr__(self):
    r = super().__repr__()
    return r[0] + '\x1b[3m' + r[1:-1] + '\x1b[23m' + r[-1]


# def get_structure(data, key=None):
#   struct = {}

#   if isinstance(data, dict):
#     for key, value in data.items():
#       # if key == "bbox":
#       #   import pdb; pdb.set_trace()
#       if isinstance(value, str):
#         struct[key] = "string"
#       elif isinstance(value, (int, float)):
#         struct[key] = "number"
#       elif isinstance(value, dict):
#         struct[key] = get_structure(value)
#       elif isinstance(value, (tuple, list)):
#         struct[key] = get_structure(value, key)
#       else:
#         raise Exception('Oops')
#   elif isinstance(data, (list, tuple)):
#     all_items = set()
#     some_items = set()
#     for item in data:
#       i = get_structure(item, key)

#       if isinstance(item, dict):
#         if not all_items:
#           all_items = set(i.items())
#         elif all_items != i:
#           some_items.update(all_items ^ i.items())
#           all_items = all_items & i.items()
#       else:
#         if not all_items:
#           all_items = i
#         elif all_items != i:
#           some_items = all_items
#           all_items = set()

#     # some_items = {ItalicStr(i) if isinstance(i, str) else i for i in some_items}
#     # return all_items | some_items

#     if not some_items:
#       return tuple(all_items) # tuple because it needs to be hashable
#     return {"array_all": tuple(all_items), "array_some": tuple(some_items)}
#   elif isinstance(data, (int, float)):
#     return "number"
#   elif isinstance(data, str):
#     return "string"

#   return struct

class JsonList(dict):
  def __init__(self, *args, **kwargs):
    super().__init__(*args, **kwargs)
    self.some = None
    self.all = None
    self.other = []

  # def __init__(self, all, some):
  #   self.all = all
  #   self.some = some
  # def __str__(self):
  #   return str(all)
class JsonDict(dict):
  pass
class JsonPrimitive(str):
  pass

def get_structure(data, key=None):
  if isinstance(data, dict):
    struct = JsonDict()
    for key, value in data.items():
      struct[key] = get_structure(value)
    return struct
  elif isinstance(data, (list, tuple)):
    struct_all = None
    struct_some = None
    struct_other = []
    struct_list = None

    for value in data:
      this_struct = get_structure(value)
      if isinstance(this_struct, JsonDict):
        if struct_all is None:
          struct_all = this_struct
        else:
          pass
          # print('crap1')
          # recursive update/diff, I think I did that already
      elif isinstance(this_struct, (list, tuple, JsonList)):
        pass
        # print('crap2')
      elif this_struct not in struct_other:
        # handle other primative types
        struct_other.append(this_struct)

    #     elif struct_all != this_struct:
    #       if isinstance(this_struct, JsonDict):
    #         this_struct = set(this_struct.items())
    #         if isinstance(struct, JsonDict):
    #           #diff all and some
    #           pass
    #   elif isinstance(this_struct, JsonList):
    #     pass
    #   elif this_struct not in struct_other:
    #     # handle other primative types
    #     struct_other.append(this_struct)

    if struct_all is not None:
      return struct_all
    else:
      if struct_some is not None:
        return 222
      else:
        if struct_other:
          return struct_other
        else:
          return ["null"]


    return [struct_all, struct_some, struct_other]
  elif isinstance(data, bool):
    return JsonPrimitive("bool")
  elif isinstance(data, (int, float)):
    return JsonPrimitive("number")
  elif isinstance(data, str):
    return JsonPrimitive("string")
  elif data is None:
    return JsonPrimitive("null")
  else:
    raise Exception('Oops')

def print_structure(struct):
  pprint(struct)
  # print(json.dumps(struct, indent=2))

if __name__ == "__main__":
  with open(sys.argv[1], 'r') as fid:
    data = json.load(fid)

  struct = get_structure(data)

  print_structure(struct)
