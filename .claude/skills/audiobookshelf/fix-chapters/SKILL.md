---
name: audiobookshelf/fix-chapters
description: Fix or rebuild chapter metadata in Audiobookshelf. Use when chapters show wrong names, are missing, or don't match the actual audio tracks.
---

# Fix Audiobookshelf Chapters

## Common Issues
- Chapters named after filenames instead of actual content
- Only partial chapters (from an earlier scan with fewer files)
- Chapters from audio tags that are generic/wrong

## Rebuild Chapters from Tracks

### 1. Get track data
```bash
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:15900/api/items/ITEM_ID" > /tmp/item.json

python3 << 'PYEOF'
import json
with open('/tmp/item.json') as f:
    data = json.load(f)
tracks = sorted(data.get('media', {}).get('audioFiles', []), key=lambda x: x.get('index', 0))
chapters = []
start = 0
for i, t in enumerate(tracks):
    dur = t.get('duration', 0)
    fname = t.get('metadata', {}).get('filename', '')
    # Customize title extraction based on filename pattern
    title = f'Chapter {i + 1}'
    chapters.append({
        'id': i,
        'start': round(start, 3),
        'end': round(start + dur, 3),
        'title': title
    })
    start += dur
with open('/tmp/chapters.json', 'w') as f:
    json.dump(chapters, f)
print(f'{len(chapters)} chapters built')
PYEOF
```

### 2. Upload chapters
When the JSON contains special characters (apostrophes, dashes), avoid passing it inline. Instead:

```bash
# Upload JSON file to server
scp /tmp/chapters.json seedhost:/tmp/chapters.json

# Build payload on server and POST
ssh seedhost "python3 -c \"
import json
with open('/tmp/chapters.json') as f:
    chapters = json.load(f)
with open('/tmp/payload.json', 'w') as f:
    json.dump({'chapters': chapters}, f)
\""

ssh seedhost "curl -s -X POST -H 'Authorization: Bearer $TOKEN' -H 'Content-Type: application/json' \
  -d @/tmp/payload.json \
  'http://localhost:15900/api/items/ITEM_ID/chapters'"
```

### 3. Verify
```bash
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:15900/api/items/ITEM_ID" | \
  python3 -c "
import json, sys
d = json.load(sys.stdin)
chapters = d.get('media', {}).get('chapters', [])
print(f'{len(chapters)} chapters')
for c in chapters[:3]: print(f'  {c[\"title\"]}')
"
```

## Custom Chapter Names (e.g., BBC Collection)
For anthology/collection audiobooks where each track is a different story:
1. Find the track listing (Audible page, liner notes, web search)
2. Map track numbers to story titles
3. Handle multi-part collections where parts have different track counts:
   ```python
   # Example: Part 1 = 30 tracks (stories 1-30), Part 2 = 33 tracks (stories 31-63), etc.
   part_offsets = {1: 0, 2: 30, 3: 63}
   story_idx = part_offsets[part] + track_num - 1
   ```
4. Chapter titles should include story name and author for collections:
   `"42. The Garden Party - Katherine Mansfield"`

## Shell Escaping Gotcha
ABS chapter titles with special characters (apostrophes, em dashes) will break if passed via shell interpolation. Always use the file-based approach:
1. Build JSON in Python locally
2. SCP to server
3. Use `curl -d @file.json` on server

## Key Constants
- ABS API: `http://localhost:15900`
- Library ID: `a0e4c58c-91a8-4aa7-9700-8438ca7ed765`
