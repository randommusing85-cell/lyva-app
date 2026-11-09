import struct
import unittest
from check_android_elf import load_alignments

def elf(alignment, offset=0, virtual=0):
    data = bytearray(120)
    data[:6] = b'\x7fELF\x02\x01'
    struct.pack_into('<Q', data, 32, 64)
    struct.pack_into('<HH', data, 54, 56, 1)
    struct.pack_into('<IIQQQQQQ', data, 64, 1, 0, offset, virtual, 0, 0, 0, alignment)
    return data

class ElfTests(unittest.TestCase):
    def test_old_and_new_alignment(self):
        self.assertEqual(load_alignments(elf(4096))[0]['alignment'], 4096)
        self.assertEqual(load_alignments(elf(16384))[0]['alignment'], 16384)
    def test_congruence(self):
        self.assertFalse(load_alignments(elf(16384, 4096, 0))[0]['congruent_16k'])
    def test_malformed_rejected(self):
        for data in [b'', b'not elf', elf(16384)[:70]]:
            with self.assertRaises(ValueError): load_alignments(data)
    def test_no_load_rejected(self):
        data = elf(16384); struct.pack_into('<I', data, 64, 2)
        with self.assertRaises(ValueError): load_alignments(data)

if __name__ == '__main__': unittest.main()
