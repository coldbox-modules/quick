import unittest
from native import parse_memory_stat


class NativeMemoryTests(unittest.TestCase):
    def test_v2_preserves_overlapping_categories_without_summing_them(self):
        result = parse_memory_stat('anon 100\nfile 400\nkernel 50\nshmem 300\nfile_mapped 250\npgfault 1234\n', '2')
        self.assertEqual(result['bytesAndCounters']['file'], 400)
        self.assertEqual(result['bytesAndCounters']['shmem'], 300)
        self.assertEqual(result['bytesAndCounters']['pgfault'], 1234)

    def test_missing_duplicate_negative_or_unknown_categories_do_not_become_zero(self):
        for raw, version in [('anon 100\n', '2'), ('anon 1\nfile 1\nkernel 1\nshmem -1\n', '2'),
                             ('rss 1\ncache 1\nmapped_file 1\nrss 2\n', '1'), ('rss 1\ncache 1\nmapped_file 1\n', '3')]:
            with self.subTest(raw=raw, version=version):
                with self.assertRaises(ValueError):
                    parse_memory_stat(raw, version)

    def test_v1_categories_remain_identified_as_v1(self):
        result = parse_memory_stat('rss 100\ncache 20\nmapped_file 10\n', '1')
        self.assertEqual(result['version'], '1')
        self.assertEqual(result['bytesAndCounters']['rss'], 100)
