#!/bin/bash
# Show TV shows sorted by cleanup priority.
# Read-only — does not modify anything on the server.
#
# "Last watched" comes from Plex watch history (any user). File access times
# can't be used: /home is mounted noatime, so atime never changes after download.
# Shows never played in Plex fall back to days since their first file was added.
#
# Usage:
#   ./tv_by_size_and_age.sh              # default: sort by score (big + stale first)
#   ./tv_by_size_and_age.sh --size       # sort by size (biggest first)
#   ./tv_by_size_and_age.sh --age        # sort by last watched (stalest first)

SORT_MODE="${1:---score}"

REMOTE=$(cat <<'EOF'
find ~/media/library/tv -type f -size +100M -printf 'F\t%T@\t%s\t%p\n' 2>/dev/null
"/usr/lib/plexmediaserver/Plex SQLite" "file:$HOME/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db?mode=ro" <<'SQL'
.mode list
.separator "\t"
SELECT 'W', MAX(s.last_viewed_at), mp.file
FROM media_parts mp
JOIN media_items mi ON mi.id = mp.media_item_id
JOIN metadata_items e ON e.id = mi.metadata_item_id
JOIN metadata_item_settings s ON s.guid = e.guid
WHERE mp.file LIKE '/home/bittruck/media/library/tv/%' AND s.last_viewed_at IS NOT NULL
GROUP BY mp.file;
SQL
EOF
)

ssh seedhost "$REMOTE" | python3 -c "
import sys, time
from collections import defaultdict

sort_mode = '$SORT_MODE'

files = {}    # path -> (mtime, size)
watched = {}  # path -> last_viewed_at
for line in sys.stdin:
    parts = line.rstrip('\n').split('\t')
    if parts[0] == 'F' and len(parts) == 4:
        files[parts[3]] = (float(parts[1]), int(parts[2]))
    elif parts[0] == 'W' and len(parts) == 3 and parts[1]:
        watched[parts[2]] = int(parts[1])

shows = defaultdict(lambda: {'size': 0, 'count': 0, 'first_added': float('inf'), 'last_watched': 0})

for path, (mtime, size) in files.items():
    rel = path.replace('/home/bittruck/media/library/tv/', '')
    show = rel.split('/')[0] if '/' in rel else rel

    shows[show]['size'] += size
    shows[show]['count'] += 1
    shows[show]['first_added'] = min(shows[show]['first_added'], mtime)
    shows[show]['last_watched'] = max(shows[show]['last_watched'], watched.get(path, 0))

now = time.time()

def stale_days(info):
    # Days since anyone watched it, or since it was added if never watched
    return (now - (info['last_watched'] or info['first_added'])) / 86400

def score(item):
    info = item[1]
    gb = info['size'] / (1024**3)
    return gb * stale_days(info)

if sort_mode == '--size':
    ranked = sorted(shows.items(), key=lambda x: x[1]['size'], reverse=True)
    label = 'Sorted by: size (biggest first)'
elif sort_mode == '--age':
    ranked = sorted(shows.items(), key=lambda x: stale_days(x[1]), reverse=True)
    label = 'Sorted by: last watched (stalest first)'
else:
    ranked = sorted(shows.items(), key=score, reverse=True)
    label = 'Sorted by: score (big + stale first)'

print(label)
print()
fmt = '{:<45} {:>8} {:>6} {:>13} {:>10} {:>10}'
print(fmt.format('Show', 'Size GB', 'Files', 'Last Watched', 'Added', 'Score'))
print('-' * 97)
total = 0
for show, info in ranked:
    gb = info['size'] / (1024**3)
    days = int(stale_days(info))
    added = int((now - info['first_added']) / 86400)
    last = '{} days'.format(days) if info['last_watched'] else 'never'
    s = gb * days
    total += gb
    print(fmt.format(show[:44], '{:.1f}'.format(gb), str(info['count']), last, '{} days'.format(added), '{:.0f}'.format(s)))

print('-' * 97)
print('Total: {:.0f} GB across {} shows'.format(total, len(ranked)))
"
