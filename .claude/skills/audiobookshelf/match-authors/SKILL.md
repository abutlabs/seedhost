---
name: audiobookshelf/match-authors
description: Match Audiobookshelf authors with photos and bios from Audible. Use when author entries are missing profile images or descriptions.
---

# Match Audiobookshelf Authors

## Diagnosis
List all authors and their metadata status:
```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:15900/api/libraries/LIBRARY_ID/authors" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
for a in sorted(data.get('authors', []), key=lambda x: x['name']):
    has_img = 'YES' if a.get('imagePath') else 'NO'
    desc = len(a.get('description', '') or '')
    print(f'{a[\"id\"]} | {a[\"name\"]:30s} | img={has_img} | desc={desc} chars')
"
```

## Fix Steps

### Match a single author (auto-search Audible)
```bash
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"q":"Author Name"}' \
  "http://localhost:15900/api/authors/AUTHOR_ID/match"
```
This searches Audible for the author and pulls in:
- Profile image
- Biography/description
- ASIN identifier

### Match with specific ASIN (when auto-search picks wrong person)
```bash
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"q":"Author Name","asin":"B001IGFHW6"}' \
  "http://localhost:15900/api/authors/AUTHOR_ID/match"
```

### Set author image manually (when match doesn't find an image)
First search for the image URL:
```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:15900/api/search/authors?q=Author+Name"
```
Then set it:
```bash
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"url":"IMAGE_URL"}' \
  "http://localhost:15900/api/authors/AUTHOR_ID/image"
```

### Batch match all unmatched authors
```bash
# Get all authors missing images, then match each one
for author in $(get_unmatched_authors); do
  curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d "{\"q\":\"$author_name\"}" \
    "http://localhost:15900/api/authors/$author_id/match"
done
```

## Notes
- The match endpoint returns `{"updated": false}` even when it successfully sets data on first call. Verify with a GET.
- Some authors (like "various" or "BBC") are not real people and won't match. Skip these.
- If the match returns an image but it's wrong, use the manual image endpoint to override.
- Author entries are auto-created when books reference them. Orphan authors (0 books) are cleaned up automatically.

## Key Constants
- ABS API: `http://localhost:15900`
- Library ID: `a0e4c58c-91a8-4aa7-9700-8438ca7ed765`
