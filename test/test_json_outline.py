from unittest import TestCase

import os
import sys
sys.path.append(os.path.join(os.path.dirname(__name__), '..', 'files', 'bin'))

from json_outline import get_structure, JsonPrimitive, JsonDict, JsonList

class TestJsonOutline(TestCase):
  def ezEqual(self, value, ans):
    self.assertEqual(get_structure(value), ans)

  def test_primatives(self):
    self.ezEqual(True, "bool")
    self.ezEqual(1, "number")
    self.ezEqual(-2.2, "number")
    self.ezEqual("foo", "string")
    self.ezEqual(None, "null")

    self.assertIsInstance(get_structure([]), JsonList)
    self.assertIsInstance(get_structure({}), JsonDict)

  def test_dict(self):
    self.ezEqual({'a': 15}, {"a": "number"})