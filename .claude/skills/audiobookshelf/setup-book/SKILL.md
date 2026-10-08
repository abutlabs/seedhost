---
name: audiobookshelf/setup-book
description: Full setup workflow for a new audiobook in Audiobookshelf - directory structure, library scan, metadata, cover art, author matching, and optional series setup. Use when a new audiobook has been uploaded to the seedbox.
---

# Full Audiobook Setup Workflow

## Complete checklist for a new audiobook:
1. Fix directory structure
2. Trigger library scan
3. Fix metadata (title, author, year)
4. Set cover art
5. Match author (photo + bio)
6. Set up series (if applicable)
7. Clean up (delete zips, remove stale items)

## Step-by-Step

### 1. Check and fix directory structure
```bash
ssh seedhost "ls -la '/home/bittruck/media/library/audiobook/AUTHOR/'"
```
Ensure structure is `Author/Book Title/audiofiles`. See skill `audiobookshelf/fix-structure` for details.

For audiobook + ebook combos, put both formats in the same book folder:
```
Author/Book Title/
  audiofile.m4b
  book.epub
```

### 2. Trigger library scan
```bash
curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  "http://localhost:15900/api/libraries/a0e4c58c-91a8-4aa7-9700-8438ca7ed765/scan"
```
Wait 5-10 seconds, then verify the new items appeared.

### 3. Find the new item(s)
```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:15900/api/libraries/LIBRARY_ID/items?limit=100" | \
  python3 -c "
import json, sys
for item in json.load(sys.stdin).get('results', []):
    m = item.get('media', {}).get('metadata', {})
    if 'SEARCH' in m.get('title', '') or 'SEARCH' in m.get('authorName', ''):
        print(f'{item[\"id\"]} | {m.get(\"title\")} | {m.get(\"authorName\")} | cover={bool(item.get(\"media\",{}).get(\"coverPath\"))}')
"
```

### 4. Fix metadata if needed
See skill `audiobookshelf/fix-metadata`.

### 5. Set cover art
See skill `audiobookshelf/fix-covers`. Search Audible first, OpenLibrary as fallback.

### 6. Match author
See skill `audiobookshelf/match-authors`. Only needed for new authors not already in the library.

### 7. Set up series (optional)
See skill `audiobookshelf/setup-series`.

### 8. Clean up
- Delete stale/duplicate items: `curl -X DELETE ... /api/items/ITEM_ID`
- Remove uploaded zip files: `ssh seedhost "rm 'path/to/file.zip'"`
- Delete empty directories: `ssh seedhost "rmdir 'path/to/empty/dir'"`

## Handling ZIP uploads
```bash
# Check contents
ssh seedhost "unzip -l '/path/to/audiobook.zip' | head -30"

# Create proper structure and extract
ssh seedhost "mkdir -p '/home/bittruck/media/library/audiobook/Author/Book Title'"
ssh seedhost "unzip -j 'audiobook.zip' '*.mp3' -d 'Author/Book Title/'"

# Clean up
ssh seedhost "rm 'audiobook.zip'"
```

## Handling duplicate items
When restructuring files, ABS may create duplicate items from the old and new paths. Check for these:
```bash
# Find duplicates (same title, one missing)
# Delete the stale ones (isMissing=true)
curl -X DELETE -H "Authorization: Bearer $TOKEN" "http://localhost:15900/api/items/STALE_ITEM_ID"
```

## Key Constants
- SSH: `ssh seedhost`
- Audiobook path: `/home/bittruck/media/library/audiobook`
- ABS API: `http://localhost:15900`
- Library ID: `a0e4c58c-91a8-4aa7-9700-8438ca7ed765`
