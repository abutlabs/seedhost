---
name: audiobookshelf/setup-series
description: Set up a book series in Audiobookshelf with proper sequencing. Use when multiple books should be grouped as an ordered series (e.g., Harry Potter, Three-Body Problem).
---

# Set Up Audiobookshelf Series

## Steps

### 1. Find the book IDs
```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:15900/api/libraries/LIBRARY_ID/items?limit=100" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
for item in data.get('results', []):
    title = item.get('media', {}).get('metadata', {}).get('title', '')
    author = item.get('media', {}).get('metadata', {}).get('authorName', '')
    if 'SEARCH_TERM' in title or 'AUTHOR_NAME' in author:
        print(f'{item[\"id\"]} | {title}')
"
```

### 2. Set series on each book
```bash
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"metadata":{"series":[{"name":"Series Name","sequence":"1"}]}}' \
  "http://localhost:15900/api/items/ITEM_ID/media"
```

### 3. Verify
```bash
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:15900/api/items/ITEM_ID" | \
  python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('media', {}).get('metadata', {}).get('series', []))
"
```

## Examples from this library

### Remembrance of Earth's Past (Cixin Liu)
1. The Three-Body Problem
2. The Dark Forest
3. Death's End

### Children of Time (Adrian Tchaikovsky)
1. Children of Time
2. Children of Ruin
3. Children of Memory

### Harry Potter (J.K. Rowling)
1-7 in publication order

## Notes
- Series name must be consistent across all books (exact string match).
- Sequence is a string, not a number (allows "0.5" for prequels, etc.).
- ABS auto-creates the series entry when the first book is tagged.
- A book can belong to multiple series.
- The series page in ABS shows all series with their books in order.

## Key Constants
- ABS API: `http://localhost:15900`
- Library ID: `a0e4c58c-91a8-4aa7-9700-8438ca7ed765`
