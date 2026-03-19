#!/bin/bash
# Show movies sorted by cleanup priority.
# Read-only — does not modify anything on the server.
#
# Usage:
#   ./movies_by_size_and_age.sh              # default: sort by score (big + old first)
#   ./movies_by_size_and_age.sh --size       # sort by size (biggest first)
#   ./movies_by_size_and_age.sh --age        # sort by last access (oldest first)

SORT_MODE="${1:---score}"

ssh seedhost "find ~/media/library/movie -type f -size +100M -printf '%A@ %s %h\n' 2>/dev/null" | python3 -c "
import sys, os, time
from collections import defaultdict

sort_mode = '$SORT_MODE'

grouped = defaultdict(lambda: {'size': 0, 'atime': 0, 'count': 0})
for line in sys.stdin:
    parts = line.strip().split(' ', 2)
    if len(parts) < 3:
        continue
    atime = float(parts[0])
    size = int(parts[1])
    path = parts[2]
    rel = path.replace('/home/bittruck/media/library/movie/', '')
    movie = rel.split('/')[0] if '/' in rel else rel
    grouped[movie]['size'] += size
    grouped[movie]['atime'] = max(grouped[movie]['atime'], atime)
    grouped[movie]['count'] += 1

now = time.time()

def score(item):
    info = item[1]
    gb = info['size'] / (1024**3)
    days = (now - info['atime']) / 86400
    return gb * days

if sort_mode == '--size':
    ranked = sorted(grouped.items(), key=lambda x: x[1]['size'], reverse=True)
    label = 'Sorted by: size (biggest first)'
elif sort_mode == '--age':
    ranked = sorted(grouped.items(), key=lambda x: x[1]['atime'])
    label = 'Sorted by: last access (oldest first)'
else:
    ranked = sorted(grouped.items(), key=score, reverse=True)
    label = 'Sorted by: score (big + old first)'

print(label)
print()
fmt = '{:<55} {:>8} {:>12} {:>10}'
print(fmt.format('Movie', 'Size GB', 'Last Access', 'Score'))
print('-' * 90)
total = 0
for movie, info in ranked:
    gb = info['size'] / (1024**3)
    days = int((now - info['atime']) / 86400)
    s = gb * days
    total += gb
    print(fmt.format(movie[:54], '{:.1f}'.format(gb), '{} days'.format(days), '{:.0f}'.format(s)))

print('-' * 90)
print('Total: {:.0f} GB across {} movies'.format(total, len(ranked)))
"
