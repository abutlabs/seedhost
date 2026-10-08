---
name: audiobookshelf/fix-metadata
description: Fix incorrect book metadata in Audiobookshelf - bad titles, wrong authors, incorrect years. Use when ABS parsed folder names or audio tags incorrectly.
---

# Fix Audiobookshelf Book Metadata

## Common Issues
- **Bad titles**: ABS parses titles from audio file tags which may have track numbers ("1", "3") or compilation names instead of book titles
- **Wrong authors**: Tags may contain narrator names, track numbers, or other garbage as the author
- **Wrong year**: Tags may have encoding year instead of publication year

## Diagnosis
Check what ABS thinks vs what the folder/files actually are:
```bash
# Check ABS metadata
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:15900/api/items/ITEM_ID" | \
  python3 -c "
import json, sys
d = json.load(sys.stdin)
m = d.get('media', {}).get('metadata', {})
print(f'title: {m.get(\"title\")}')
print(f'authors: {m.get(\"authors\")}')
print(f'year: {m.get(\"publishedYear\")}')
print(f'path: {d.get(\"path\")}')
"

# Check actual audio file tags
ssh seedhost "ffprobe -v quiet -print_format json -show_format 'PATH_TO_MP3'" | \
  python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('format',{}).get('tags',{}), indent=2))"
```

## Fix Steps

### Update title and/or year
```bash
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"metadata":{"title":"Correct Title","publishedYear":"1982"}}' \
  "http://localhost:15900/api/items/ITEM_ID/media"
```

### Update authors
```bash
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"metadata":{"authors":[{"name":"Correct Author Name"}]}}' \
  "http://localhost:15900/api/items/ITEM_ID/media"
```

### Update multiple fields at once
```bash
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"metadata":{"title":"Correct Title","authors":[{"name":"Author"}],"publishedYear":"1982"}}' \
  "http://localhost:15900/api/items/ITEM_ID/media"
```

## Metadata Precedence
ABS uses this priority order (configurable in library settings):
1. folderStructure
2. audioMetatags
3. nfoFile
4. txtFiles
5. opfFile
6. absMetadata

Manual API updates override all of these.

## Notes
- The PATCH response returns the old values (not the new ones). Verify with a GET after updating.
- When fixing authors, ABS will automatically create/link author entries. If the author already exists, it merges.
- Bogus author entries (like "12 The BFG") will persist until no books reference them. Fix the book metadata first, then the orphan author disappears.
- For books where the folder name is correct but tags are wrong, the folder structure metadata should be preferred. Check if `folderStructure` is first in the metadata precedence.

## Key Constants
- ABS API: `http://localhost:15900`
- Library ID: `a0e4c58c-91a8-4aa7-9700-8438ca7ed765`
