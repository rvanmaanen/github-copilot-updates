import os
import re

# Directories to process
DIRS = ["_news", "_posts", "_videos"]

# For each directory, process all .md files
for d in DIRS:
    if not os.path.isdir(d):
        continue
    for fname in os.listdir(d):
        if not fname.endswith(".md"):
            continue
        fpath = os.path.join(d, fname)
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()
        # Find all occurrences of '---' (YAML frontmatter)
        matches = [m.start() for m in re.finditer(r'^---\s*$', content, re.MULTILINE)]
        if len(matches) < 2:
            print(f"Skipping {fpath}: less than 2 frontmatter blocks found.")
            continue
        # Insert new frontmatter before the second '---'
        insert_pos = matches[1]
        base = os.path.splitext(fname)[0]
        permalink = f"permalink: /{base}.html"
        new_content = (
            content[:insert_pos]
            + f"{permalink}\n"
            + content[insert_pos:]
        )
        with open(fpath, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Updated {fpath}")
