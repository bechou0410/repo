# repo.bechou.dev

The APT repository for bechou's tweaks (rootless, iOS 15 to 26), served by GitHub Pages at https://repo.bechou.dev/.

| Path | What |
|---|---|
| `Packages*`, `Release` | The index, built by `tools/build-index.py` from `pool/`. |
| `pool/` | The packages. |
| `index.html` | The repository's page: its address and its packages. |
| `le-traffic/` | Lề's page (the package's `Depiction`) and `depiction.json` (its `SileoDepiction`). |
| `assets/` | The shared stylesheet, the Saira typeface (SIL OFL, `assets/fonts/OFL.txt`) and icons. |

## Publish a package

1. Build the release in its own repository (for Lề: `make package FINALPACKAGE=1`, then `scripts/verify-package.py`).
2. Copy the `.deb` into `pool/` (keep earlier versions there if Sileo should offer them).
3. Add the package's extra fields to `tools/packages-extra.json` if it has a depiction of its own.
4. Run `python3 tools/build-index.py`, commit and push.

## Lề's pictures

Every picture on Lề's page is drawn by Lề's own code: the bubble view and its road-sign painter, built for Mac Catalyst. `tools/render-media.sh <path to the Lề repository>` draws them again into `le-traffic/media/` (it needs Xcode and ffmpeg with libx264 and libsvtav1).
