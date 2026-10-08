# Seedhost Project

Management scripts and Audiobookshelf skills for a seedhost.eu dedicated server.

## Server Connection
- SSH alias: `ssh seedhost` (host: ds32211.seedhost.eu, user: bittruck)
- All scripts and skills run from the local Mac over SSH

## Scripts (manual, read-only)
- `movies_by_size_and_age.sh` — Rank movies by size * age for cleanup candidates
- `tv_by_size_and_age.sh` — Same for TV shows
- `scan_torrents.py` — Inventory active/stopped torrents with ratio, size, age

## Audiobookshelf (ABS)

### Connection Details
- ABS URL: `bittruck-abs.ds32211.seedhost.eu`
- ABS internal API: `http://localhost:15900` (on seedhost)
- Audiobook Library ID: `a0e4c58c-91a8-4aa7-9700-8438ca7ed765`
- Podcast Library ID: `5f305ab7-258f-4371-b568-9b672f116730`

### Directory Structure
```
/home/bittruck/media/library/
  audiobook/          # ABS audiobook library root
    Author Name/
      Book Title/
        audiofile.mp3
        book.epub     # optional - ABS shows both formats together
  podcast/            # ABS podcast library root
    Podcast Name/
      episode.mp3
```

### ABS API Authentication
User generates short-lived API keys from the ABS web UI. Always test with `/api/me` before bulk operations. Keys expire — ask for a new one if you get `Unauthorized`.

### Critical Rule: No Loose Files in Author Directories
Audio files directly in an author folder cause ABS to treat the entire author directory as a single book. Always ensure audio files are inside `Author/Book/` subdirectories.

### Skills (`.claude/skills/audiobookshelf/`)
| Skill | Purpose |
|-------|---------|
| `audiobookshelf/fix-structure` | Fix loose files breaking author hierarchy |
| `audiobookshelf/fix-covers` | Find and set missing cover art from Audible/OpenLibrary |
| `audiobookshelf/fix-metadata` | Fix bad titles, wrong authors, incorrect years |
| `audiobookshelf/match-authors` | Match authors with photos and bios |
| `audiobookshelf/setup-series` | Set up book series with proper sequencing |
| `audiobookshelf/setup-book` | Full end-to-end workflow for new audiobooks |
| `audiobookshelf/audit` | Library-wide health check |
| `audiobookshelf/fix-chapters` | Rebuild chapter metadata from tracks |

### Tools Available on Seedhost
- `ffmpeg` / `ffprobe` — audio analysis and conversion
- `unzip` — archive extraction
- `python3` — data processing
- `sqlite3` (v3.37.2 — too old for ABS database, use API instead)
