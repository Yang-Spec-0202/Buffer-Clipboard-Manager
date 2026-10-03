#!/usr/bin/env python3
"""Check all source localization keys and format arguments in both resource tables."""
import json
import re
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent.parent
tables = {}
for language in ("en", "zh-Hans"):
    path = root / "Resources" / (language + ".lproj") / "Localizable.strings"
    tables[language] = json.loads(subprocess.check_output(
        ["plutil", "-convert", "json", "-o", "-", str(path)]))
assert tables["en"].keys() == tables["zh-Hans"].keys(), "Language keys differ"
specifiers = re.compile(r"%(?:\d+\$)?(?:\.\d+)?[d@f]")
for key in tables["en"]:
    assert specifiers.findall(tables["en"][key]) == specifiers.findall(tables["zh-Hans"][key]), key
for path in [root / "AppDelegate.swift", *root.glob("Models/*.swift"),
             *root.glob("Services/*.swift"), *root.glob("Views/*.swift")]:
    for match in re.finditer(r'L10n\.(?:tr|format)\("((?:\\.|[^"\\])*)"', path.read_text()):
        key = json.loads('"' + match.group(1) + '"')
        assert key in tables["en"], f"Missing key {key!r} in {path}"
print(f"PASS: {len(tables['en'])} bilingual keys and their format arguments")
