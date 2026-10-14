#!/usr/bin/env python3
"""Builds the browser stand-in (PD-023) as one self-contained HTML file.

The page is web/standin.template.html with web/engine.js and the bundled Sichuan
content inlined, so it always plays the same content the app ships.

usage: scripts/build-web-standin.py <output.html>
"""
import json
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
content_dir = root / "Sources/PantryScoring/Resources/sichuan"


def load(name):
    return json.loads((content_dir / name).read_text(encoding="utf-8"))


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    dishes = load("dishes.json")["dishes"]
    for dish in dishes:
        dish.pop("notes", None)  # internal source notes; never shown to players
    cuisine = load("cuisine.json")
    cuisine.pop("notes", None)
    content = {"cuisine": cuisine, "ingredients": load("ingredients.json")["ingredients"], "dishes": dishes,
               "cards": load("cards.json")["cards"]}
    blob = json.dumps(content, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    page = (root / "web/standin.template.html").read_text(encoding="utf-8")
    engine = (root / "web/engine.js").read_text(encoding="utf-8")
    for marker in ("/*__ENGINE__*/", "/*__CONTENT__*/null"):
        if page.count(marker) != 1:
            sys.exit(f"template must contain {marker} exactly once")
    page = page.replace("/*__ENGINE__*/", engine).replace("/*__CONTENT__*/null", blob)
    out = pathlib.Path(sys.argv[1])
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(page, encoding="utf-8")
    print(f"wrote {out} ({len(page.encode('utf-8')) // 1024} KB)")


if __name__ == "__main__":
    main()
