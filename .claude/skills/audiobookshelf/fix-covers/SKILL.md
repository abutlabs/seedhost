---
name: audiobookshelf/fix-covers
description: Find and set missing cover art for Audiobookshelf books. Use when books display without cover images or with incorrect covers.
---

# Fix Audiobookshelf Cover Art

## Diagnosis
Find all books missing covers:
```python
# Via ABS API
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:15900/api/libraries/LIBRARY_ID/items?limit=100" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
for item in data.get('results', []):
    title = item.get('media', {}).get('metadata', {}).get('title', '')
    has_cover = bool(item.get('media', {}).get('coverPath'))
    if not has_cover:
        print(f'{item[\"id\"]} | {title}')
"
```

## Fix Steps

### 1. Search for cover art
Try Audible first (best audiobook covers), then OpenLibrary as fallback:

```bash
# Audible (preferred - higher quality audiobook-specific covers)
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:15900/api/search/books?title=TITLE&author=AUTHOR&provider=audible"

# OpenLibrary (fallback)
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:15900/api/search/books?title=TITLE&author=AUTHOR&provider=openlibrary"
```

### 2. Set cover from URL
```bash
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"url":"COVER_IMAGE_URL"}' \
  "http://localhost:15900/api/items/ITEM_ID/cover"
```
Response: `{"success":true,"cover":"/metadata/items/ITEM_ID/cover.jpg"}`

### 3. For replacing incorrect covers
Same process - the POST to `/cover` endpoint will overwrite any existing cover.

## Batch Processing
When fixing multiple books, search for all covers first, collect URLs, then set them in a loop. This is faster than doing search+set one at a time.

## Notes
- Some books have covers embedded in audio file metadata (MP3 ID3 tags, M4B). ABS extracts these automatically on scan.
- If the embedded cover is wrong (e.g., pulled from a compilation album tag), set a new one via the API to override it.
- Audible search uses `+` for spaces in query params.
- The `provider` parameter can be `audible` or `openlibrary`.

## Key Constants
- ABS API: `http://localhost:15900`
- Library ID: `a0e4c58c-91a8-4aa7-9700-8438ca7ed765`
