#!/usr/bin/env python3
# scripts/generate-leaderboard.py
import os, sys, datetime, requests
from collections import Counter

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
REPO = os.environ.get("REPO", "yourorg/yourrepo")
DAYS = int(os.environ.get("DAYS", "7"))

if not GITHUB_TOKEN:
    print("GITHUB_TOKEN required", file=sys.stderr); sys.exit(1)

headers = {"Authorization": f"token {GITHUB_TOKEN}", "Accept": "application/vnd.github.v3+json"}
since = (datetime.datetime.utcnow() - datetime.timedelta(days=DAYS)).isoformat() + "Z"

query = f"repo:{REPO} is:pr is:merged merged:>={since}"
url = "https://api.github.com/search/issues"
params = {"q": query, "per_page": 100}

contributors = Counter()
page = 1
while True:
    params["page"] = page
    r = requests.get(url, headers=headers, params=params)
    r.raise_for_status()
    data = r.json()
    for item in data.get("items", []):
        user = item.get("user", {}).get("login", "unknown")
        contributors[user] += 1
    if "next" not in r.links:
        break
    page += 1

# Write markdown
out_dir = "docs/leaderboard"
os.makedirs(out_dir, exist_ok=True)
out_file = os.path.join(out_dir, "leaderboard.md")
with open(out_file, "w") as f:
    f.write(f"# Weekly Leaderboard\n\n")
    f.write(f"Generated: {datetime.datetime.utcnow().isoformat()}Z\n\n")
    f.write("| Rank | Contributor | Merged PRs |\n")
    f.write("|---:|---|---:|\n")
    for i, (user, count) in enumerate(contributors.most_common(), start=1):
        f.write(f"| {i} | @{user} | {count} |\n")

print("Wrote", out_file)
