---
name: audiobookshelf/audit
description: Audit the entire Audiobookshelf library for issues - missing covers, bad titles, wrong authors, missing files, duplicate items. Run this to get a health check of the library.
---

# Audiobookshelf Library Audit

## Full Library Audit Script
```bash
TOKEN="YOUR_ABS_API_TOKEN"
LIBRARY_ID="a0e4c58c-91a8-4aa7-9700-8438ca7ed765"

curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:15900/api/libraries/$LIBRARY_ID/items?limit=100" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
items = data.get('results', [])

ok = 0
issues = 0
for item in sorted(items, key=lambda x: x.get('media',{}).get('metadata',{}).get('title','')):
    m = item.get('media', {}).get('metadata', {})
    title = m.get('title', '')
    author = m.get('authorName', '')
    has_cover = bool(item.get('media', {}).get('coverPath'))
    missing = item.get('isMissing', False)

    problems = []
    if not has_cover: problems.append('NO COVER')
    if not title or title.isdigit(): problems.append(f'BAD TITLE \"{title}\"')
    if not author: problems.append('NO AUTHOR')
    if missing: problems.append('MISSING FILES')

    if problems:
        issues += 1
        print(f'!! {title:50s} | {author:25s} | {\"  \".join(problems)}')
        print(f'   id={item[\"id\"]} path={item.get(\"path\",\"\")}')
    else:
        ok += 1

print(f'\n{ok} OK / {issues} issues / {len(items)} total')
"
```

## Author Audit
```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:15900/api/libraries/$LIBRARY_ID/authors" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
for a in sorted(data.get('authors', []), key=lambda x: x['name']):
    has_img = 'YES' if a.get('imagePath') else 'NO'
    desc = len(a.get('description', '') or '')
    status = 'OK' if has_img == 'YES' and desc > 0 else '!!'
    print(f'{status} {a[\"id\"]} | {a[\"name\"]:30s} | img={has_img} | desc={desc} chars')
"
```

## Directory Structure Audit
Check for loose audio files at the author level:
```bash
ssh seedhost "find /home/bittruck/media/library/audiobook -maxdepth 2 -type f \( -name '*.mp3' -o -name '*.m4b' -o -name '*.m4a' \) | sort"
```
Any files at depth 2 (author level) are problematic and need to be moved into book subdirectories.

## Common Issues Found in Audits
1. **Loose files in author dirs** → Use `audiobookshelf/fix-structure`
2. **Missing covers** → Use `audiobookshelf/fix-covers`
3. **Bad titles from audio tags** → Use `audiobookshelf/fix-metadata`
4. **Unmatched authors** → Use `audiobookshelf/match-authors`
5. **Duplicate items** (from restructuring) → Delete the stale/missing one via API
6. **Empty author dirs** → Remove with `rmdir`

## Key Constants
- SSH: `ssh seedhost`
- Audiobook path: `/home/bittruck/media/library/audiobook`
- ABS API: `http://localhost:15900`
- Library ID: `a0e4c58c-91a8-4aa7-9700-8438ca7ed765`
