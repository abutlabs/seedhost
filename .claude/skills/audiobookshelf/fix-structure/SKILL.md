---
name: audiobookshelf/fix-structure
description: Fix audiobook directory structure for Audiobookshelf. Use when ABS treats an author folder as a single book, or when loose audio files exist directly in an author directory instead of book subdirectories.
---

# Fix Audiobookshelf Directory Structure

## Problem
Audiobookshelf expects `Author/Book Title/audiofiles`. When audio files (mp3, m4b, m4a) exist directly in an author folder, ABS treats the entire author directory as a single book item instead of recognizing individual books inside it.

## Diagnosis
1. SSH into seedhost and check the author directory:
   ```
   ssh seedhost "ls -la '/home/bittruck/media/library/audiobook/AUTHOR_NAME/'"
   ```
2. Look for audio files at the author level (not inside book subdirectories)
3. Check ABS scan logs for confirmation:
   ```
   ssh seedhost "cat /home/bittruck/.config/audiobookshelf/metadata/logs/scans/*.txt" | grep "AUTHOR_NAME"
   ```
   If the log shows `Library item "AUTHOR_NAME"` instead of `Library item "AUTHOR_NAME/Book Title"`, the structure is broken.

## Fix Steps
1. **Identify loose files** at the author level (files not inside book subdirectories)
2. **Create book subdirectories** with clean names for each loose file/group:
   ```
   mkdir -p "AUTHOR/Book Title"
   mv "AUTHOR/loose_file.mp3" "AUTHOR/Book Title/Book Title.mp3"
   ```
3. **For collections with audiobook + ebook**, put both in the same folder:
   ```
   AUTHOR/Book Title/
     audiofile.mp3
     book.epub
   ```
4. **For nested directories too deep** (e.g., `Author/Collection/Book/files`), flatten to `Author/Book/files`:
   ```
   mv "AUTHOR/Collection/Book Title" "AUTHOR/Book Title"
   rm -rf "AUTHOR/Collection"
   ```
5. **After fixing**, delete the broken ABS item via API and rescan:
   ```
   curl -X DELETE -H "Authorization: Bearer $TOKEN" "http://localhost:15900/api/items/ITEM_ID"
   curl -X POST -H "Authorization: Bearer $TOKEN" "http://localhost:15900/api/libraries/LIBRARY_ID/scan"
   ```

## Key Constants
- SSH alias: `ssh seedhost`
- Audiobook library path: `/home/bittruck/media/library/audiobook`
- ABS API: `http://localhost:15900`
- Library ID: `a0e4c58c-91a8-4aa7-9700-8438ca7ed765`
- ABS config: `/home/bittruck/.config/audiobookshelf`

## Multiple Narrations Rule
When multiple narrations of the same title exist, **always** create separate narrator-specific folders:
```
AUTHOR/Title (Narrator A)/file.mp3
AUTHOR/Title (Narrator B)/file.mp3
```
ABS has no built-in way to manage alternate narrations within a single book item — each narration must be its own library item in its own folder. This is the **default behavior** whenever duplicate titles with different narrators are detected.

For single-narration titles, use just the title:
```
AUTHOR/Title/file.mp3
```

## Common Patterns
- Single MP3 files (short stories/novellas) sitting in author dir → create a book subfolder
- M4B files directly in author dir → move into book subfolder
- ZIP files uploaded to audiobook dir → unzip into `Author/Book/` structure, then delete zip
- Torrent folders with complex names like `2006 - Title (Narrator) 64k 14.37.53 {414mb}` → ABS can parse these, no rename needed unless they contain loose files at the author level
- Multiple narrations of the same title → split into narrator-specific folders (see rule above)
