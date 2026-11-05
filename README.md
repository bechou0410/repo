# repo.bechou.dev

The APT repository for bechou's tweaks (rootless and roothide, iOS 15 to 26) at https://repo.bechou.dev/.

| Path | What |
|---|---|
| `Packages*`, `Release` | The index, built by `tools/build-index.py` from `pool/`. |
| `pool/` | The packages. |
| `beta/` | The beta source, https://repo.bechou.dev/beta/, for a small group of testers: its own `pool/`, `Packages*`, `Release` (Origin and Label `bechou beta`), `CydiaIcon.png` and a page with how to add it. Nothing on the site links to it. |
| `index.html` | The repository's page: its address, how to add it, and one row per package (`<li class="pkg">`; a new package is one more row). |
| `le-traffic/` | Lề's page (the package's `Depiction`) and `depiction.json` (its `SileoDepiction`). |
| `assets/` | What every page shares: `tokens.css` (colours, type, spacing) and `base.css`, the Saira typeface (SIL OFL, `assets/fonts/OFL.txt`), icons and the home's `home.css` and share image. |
| `functions/`, `migrations/`, `wrangler.toml` | Cloudflare Pages only: `functions/pool/[file].js` counts each `.deb` download into D1, `functions/api/downloads.js` serves the counts. |
| `404.html` | The not-found page; it also keeps Cloudflare Pages from answering missing APT files with the home page. |

## Hosting and download counts

The site runs on Cloudflare Pages, project `bechou-repo`, with the custom domain `repo.bechou.dev` (a CNAME at Fastmail to `bechou-repo.pages.dev`). GitHub Pages still publishes the same repository from `main` and can take the domain back by pointing the CNAME at `bechou0410.github.io`.

APT, Sileo and Zebra fetch a package at `pool/<file>.deb`, relative to the source. On Cloudflare that path runs `functions/pool/[file].js`, which serves the file and adds one to the count for its package, version and package manager (named from the User-Agent: Sileo, Zebra, Cydia, Installer, APT, a browser, or other). Only a request for the whole file or its first bytes counts. No address or device detail is stored. The counts live in the D1 database `bechou-repo-downloads` (`migrations/0001_downloads.sql`). `GET /api/downloads` returns them as `{packages: {<id>: {total, clients}}}`, and `assets/downloads.js` shows them on the pages once a package has been downloaded at least once.

Deploy after committing: `tools/deploy-cloudflare.sh` (it sends the committed tree; it needs `wrangler` logged in to the Cloudflare account). Read the counts with `wrangler d1 execute bechou-repo-downloads --remote --command "SELECT * FROM downloads"`.

## Publish a package

1. Build the release in its own repository (for Lề: `make package FINALPACKAGE=1`, then `scripts/verify-package.py`).
2. Copy the `.deb` into `pool/` (keep earlier versions there if Sileo should offer them).
3. Add the package's extra fields to `tools/packages-extra.json` if it has a depiction of its own.
4. Run `python3 tools/build-index.py`, commit and push, then run `tools/deploy-cloudflare.sh`.

## Publish a beta

A beta goes to `beta/` only, so testers get it before everyone else:

1. In the package's repository, set a version that sorts before the release it leads to, for example `0.2.4~beta1` (Debian sorts `~` first: `0.2.3 < 0.2.4~beta1 < 0.2.4`). Build and verify it as for a release.
2. Copy the `.deb`s into `beta/pool/` (removing the previous beta's), update "Đang thử" in `beta/index.html`, run `python3 tools/build-index.py beta`, commit and push.
3. Testers add https://repo.bechou.dev/beta/ beside the main source. Sileo and Zebra install the higher version, so they get the beta now and the release once it is in `pool/`.

The beta is unlisted, not private: this repository is public, so anyone who finds the address can install it.

## Lề's pictures

Every CarPlay picture and recording on Lề's page is a capture from the iPhone, taken while VietMap Live ran a simulated route: the stills and the hero loop at 800 × 480, the intro clip from the CarPlay Simulator window beside Settings › Lề. The iPhone screens in the install steps are screenshots of the phone. The sign search's pictures are drawn by Lề's own road-sign painter: `tools/render-media.sh <path to the Lề repository>` draws them again into `le-traffic/media/signs/` (it needs Xcode).
