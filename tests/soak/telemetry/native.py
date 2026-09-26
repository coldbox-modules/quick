"""Parse Linux cgroup memory categories without confusing subcategories with totals."""


def parse_memory_stat(value, version):
    result = {}
    for line in value.splitlines():
        key, count = line.split()
        count = int(count)
        if count < 0 or key in result:
            raise ValueError('Invalid cgroup memory statistic')
        result[key] = count
    required = {'anon', 'file', 'kernel', 'shmem'} if version == '2' else {'rss', 'cache', 'mapped_file'}
    if version not in ('1', '2') or not required <= result.keys():
        raise ValueError('Cgroup memory categories are incomplete')
    return {'version': version, 'bytesAndCounters': result}
