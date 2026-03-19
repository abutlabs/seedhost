#!/bin/bash
# Show TV shows sorted by cleanup priority.
# Read-only — does not modify anything on the server.
#
# Usage:
#   ./tv_by_size_and_age.sh              # default: sort by score (big + old first)
#   ./tv_by_size_and_age.sh --size       # sort by size (biggest first)
#   ./tv_by_size_and_age.sh --age        # sort by last access (oldest first)

SORT_MODE="${1:---score}"

ssh seedhost "find ~/media/library/tv -type f -size +100M -printf '%A@ %s %h\n' 2>/dev/null" | python3 -c "
import sys, os, time
from collections import defaultdict

sort_mode = '$SORT_MODE'

shows = defaultdict(lambda: {'size': 0, 'count': 0, 'oldest_access': float('inf'), 'newest_access': 0})

for line in sys.stdin:
    parts = line.strip().split(' ', 2)
    if len(parts) < 3:
        continue
    atime = float(parts[0])
    size = int(parts[1])
    path = parts[2]
    rel = path.replace('/home/bittruck/media/library/tv/', '')
    show = rel.split('/')[0] if '/' in rel else rel

    shows[show]['size'] += size
    shows[show]['count'] += 1
    shows[show]['oldest_access'] = min(shows[show]['oldest_access'], atime)
    shows[show]['newest_access'] = max(shows[show]['newest_access'], atime)

now = time.time()

def score(item):
    info = item[1]
    gb = info['size'] / (1024**3)
    days = (now - info['newest_access']) / 86400
    return gb * days

if sort_mode == '--size':
    ranked = sorted(shows.items(), key=lambda x: x[1]['size'], reverse=True)
    label = 'Sorted by: size (biggest first)'
elif sort_mode == '--age':
    ranked = sorted(shows.items(), key=lambda x: x[1]['newest_access'])
    label = 'Sorted by: last access (oldest first)'
else:
    ranked = sorted(shows.items(), key=score, reverse=True)
    label = 'Sorted by: score (big + old first)'

print(label)
print()
fmt = '{:<45} {:>8} {:>6} {:>12} {:>10}'
print(fmt.format('Show', 'Size GB', 'Files', 'Last Access', 'Score'))
print('-' * 90)
total = 0
for show, info in ranked:
    gb = info['size'] / (1024**3)
    days = int((now - info['newest_access']) / 86400)
    s = gb * days
    total += gb
    print(fmt.format(show[:44], '{:.1f}'.format(gb), str(info['count']), '{} days'.format(days), '{:.0f}'.format(s)))

print('-' * 90)
print('Total: {:.0f} GB across {} shows'.format(total, len(ranked)))
"
