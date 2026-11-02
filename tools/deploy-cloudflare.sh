#!/bin/bash
# Publishes the committed repository to Cloudflare Pages (project bechou-repo): the site and APT files, plus
# functions/ that count package downloads into D1. Run it after committing; uncommitted changes are not sent.
# Usage: tools/deploy-cloudflare.sh
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd); cd "$root"
rm -rf .cf-dist && mkdir .cf-dist
git archive HEAD | tar -x -C .cf-dist
rm -rf .cf-dist/functions .cf-dist/migrations .cf-dist/tools .cf-dist/wrangler.toml .cf-dist/README.md .cf-dist/.gitignore
wrangler pages deploy .cf-dist --project-name bechou-repo --branch main --commit-hash "$(git rev-parse HEAD)" \
  --commit-message "$(git log -1 --format=%s)"
rm -rf .cf-dist
