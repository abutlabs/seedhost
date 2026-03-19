#!/usr/bin/env python3
"""Read-only scan of rtorrent session files to inventory all torrents."""
import os, re, glob, time

def parse_rtorrent_state(data):
    info = {}
    for key in ["directory", "state", "complete", "total_uploaded", "total_downloaded",
                "timestamp.finished", "timestamp.started", "custom1", "priority"]:
        m = re.search(re.escape(key) + r"(\d+):", data)
        if m:
            length = int(m.group(1))
            start = m.end()
            info[key] = data[start:start+length]
        m2 = re.search(re.escape(key) + r"i(-?\d+)e", data)
        if m2:
            info[key] = int(m2.group(1))
    return info

session_dir = os.path.expanduser("~/.config/.session")
results = []
for f in sorted(glob.glob(os.path.join(session_dir, "*.torrent.rtorrent"))):
    with open(f, "r", errors="replace") as fh:
        data = fh.read()
    info = parse_rtorrent_state(data)
    dl = info.get("total_downloaded", 0)
    ul = info.get("total_uploaded", 0)
    ratio = ul / dl if dl > 0 else 0
    finished = info.get("timestamp.finished", 0)
    started = info.get("timestamp.started", 0)
    results.append({
        "dir": info.get("directory", "?"),
        "state": info.get("state", "?"),
        "complete": info.get("complete", "?"),
        "ratio": ratio,
        "dl_gb": dl / (1024**3),
        "ul_gb": ul / (1024**3),
        "finished": finished,
        "started": started,
        "category": info.get("custom1", "?"),
        "priority": info.get("priority", "?"),
    })

results.sort(key=lambda x: x["ratio"])
now = time.time()

fmt = "{:<20} {:<6} {:<5} {:<8} {:<10} {:<10} {}"
print(fmt.format("Category", "State", "Comp", "Ratio", "Size GB", "Age Days", "Directory"))
print("-" * 140)
for r in results:
    dirname = os.path.basename(r["dir"])[:50]
    age = int((now - r["started"]) / 86400) if r["started"] else "?"
    ratio_str = "{:.2f}".format(r["ratio"])
    size_str = "{:.1f}".format(r["dl_gb"])
    print(fmt.format(str(r["category"]), str(r["state"]), str(r["complete"]),
                     ratio_str, size_str, str(age), dirname))

print()
print("=== SUMMARY ===")
total_dl = sum(r["dl_gb"] for r in results)
active = sum(1 for r in results if r["state"] == 1)
stopped = sum(1 for r in results if r["state"] == 0)
print("Total: {} torrents, {:.0f} GB downloaded".format(len(results), total_dl))
print("Active (seeding): {}".format(active))
print("Stopped: {}".format(stopped))

# Category breakdown
cats = {}
for r in results:
    c = str(r["category"])
    if c not in cats:
        cats[c] = {"count": 0, "gb": 0}
    cats[c]["count"] += 1
    cats[c]["gb"] += r["dl_gb"]
print("\nBy category:")
for c in sorted(cats, key=lambda x: cats[x]["gb"], reverse=True):
    print("  {}: {} torrents, {:.0f} GB".format(c, cats[c]["count"], cats[c]["gb"]))
