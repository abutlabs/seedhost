# Seedhost Management Scripts

Read-only scripts for analyzing disk usage on the seedhost server. All run from your local Mac over SSH.

## Prerequisites

These scripts connect via an SSH alias called `seedhost`. If you haven't set it up yet:

**1. Generate an SSH key (skip if you already have one):**

```bash
ssh-keygen -t ed25519
```

**2. Copy it to the server:**

```bash
ssh-copy-id -o IdentitiesOnly=yes -o PreferredAuthentications=password -i ~/.ssh/id_ed25519.pub YOUR_USERNAME@YOUR_SERVER.seedhost.eu
```

**3. Add the alias to `~/.ssh/config`:**

```
Host seedhost
    HostName YOUR_SERVER.seedhost.eu
    User YOUR_USERNAME
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

**4. Verify it works:**

```bash
ssh seedhost "echo connected"
```

## Scripts

### TV Shows by Size & Age

```bash
./tv_by_size_and_age.sh            # default: sort by score (big + stale first)
./tv_by_size_and_age.sh --size     # sort by size (biggest first)
./tv_by_size_and_age.sh --age      # sort by last watched (stalest first)
```

Lists all TV shows in the Plex library with size, when anyone last watched them (from Plex watch history, read-only), when they were added, and a cleanup score. The default `--score` sort ranks by `size_gb * days_since_watched` (or days since added, for shows never played) — the best candidates for freeing space are big shows nobody has watched in a long time.

### Movies by Size & Age

```bash
./movies_by_size_and_age.sh            # default: sort by score (big + old first)
./movies_by_size_and_age.sh --size     # sort by size (biggest first)
./movies_by_size_and_age.sh --age      # sort by last access (oldest first)
```

Same as above but for movies.

### Torrent Inventory

```bash
cat scan_torrents.py | ssh seedhost "python3 -"
```

Parses rtorrent session files and shows all active/stopped torrents with ratio, size, age, and category.

## Notes

- All scripts are **read-only** — nothing is modified on the server.
- Data comes from filesystem access times and rtorrent session files.
- Results are sorted oldest-first to help identify cleanup candidates.
