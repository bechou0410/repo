# repo.bechou.dev

The APT repository for bechou's tweaks (rootless, iOS 15 to 26), served by GitHub Pages at https://repo.bechou.dev/.

| Path | What |
|---|---|
| `Packages*`, `Release` | The index, built by `tools/build-index.py` from `pool/`. |
| `pool/` | The packages. |
| `index.html` | The repository's page: its address, how to add it, and one row per package (`<li class="pkg">`; a new package is one more row). |
| `le-traffic/` | Lề's page (the package's `Depiction`) and `depiction.json` (its `SileoDepiction`). |
| `assets/` | What every page shares: `tokens.css` (colours, type, spacing) and `base.css`, the Saira typeface (SIL OFL, `assets/fonts/OFL.txt`), icons and the home's `home.css` and share image. |

## Publish a package

1. Build the release in its own repository (for Lề: `make package FINALPACKAGE=1`, then `scripts/verify-package.py`).
2. Copy the `.deb` into `pool/` (keep earlier versions there if Sileo should offer them).
3. Add the package's extra fields to `tools/packages-extra.json` if it has a depiction of its own.
4. Run `python3 tools/build-index.py`, commit and push.

## Lề's pictures

Every CarPlay picture and recording on Lề's page is a capture from the iPhone, taken while VietMap Live ran a simulated route: the stills and the hero loop at 800 × 480, the intro clip from the CarPlay Simulator window beside Settings › Lề. The iPhone screens in the install steps are screenshots of the phone. The sign search's pictures are drawn by Lề's own road-sign painter: `tools/render-media.sh <path to the Lề repository>` draws them again into `le-traffic/media/signs/` (it needs Xcode).
