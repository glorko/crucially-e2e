#!/usr/bin/env python3
"""Strip HTML tags and images from downloaded docs, keep text only."""
import os, re, html

DOCS_DIR = os.path.join(os.path.dirname(__file__), "maestro")

for fname in sorted(os.listdir(DOCS_DIR)):
    if not fname.endswith(".md"):
        continue
    path = os.path.join(DOCS_DIR, fname)
    with open(path, "r") as f:
        raw = f.read()
    # Remove img/svg/picture tags and their content
    text = re.sub(r'<(img|svg|picture)[^>]*?>.*?</\1>', '', raw, flags=re.DOTALL)
    text = re.sub(r'<(img|svg|picture)[^>]*?/?\s*>', '', text)
    # Remove style/script blocks
    text = re.sub(r'<(style|script)[^>]*?>.*?</\1>', '', text, flags=re.DOTALL)
    # Remove all HTML tags
    text = re.sub(r'<[^>]+>', '', text)
    # Decode HTML entities
    text = html.unescape(text)
    # Collapse blank lines
    text = re.sub(r'\n{3,}', '\n\n', text)
    text = text.strip() + '\n'
    with open(path, "w") as f:
        f.write(text)
    print(f"{fname}: {len(raw)} -> {len(text)} bytes")
