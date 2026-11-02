#!/bin/bash
# Draws the sign search's pictures with Lề's own road-sign painter, natively on the Mac (Mac Catalyst).
# Usage: tools/render-media.sh <path to the Lề repository>
set -euo pipefail
le=${1:?path to the Lề repository}; site=$(cd "$(dirname "$0")/.." && pwd); work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
sdk=$(xcrun --sdk macosx --show-sdk-path)
xcrun --sdk macosx clang -target arm64-apple-ios15.0-macabi -isystem "$sdk/System/iOSSupport/usr/include" \
 -iframework "$sdk/System/iOSSupport/System/Library/Frameworks" -fobjc-arc -fblocks -Wall -Wextra -Werror -I"$le" \
 -framework UIKit -framework Foundation -framework CoreGraphics -framework QuartzCore \
 "$le/Core/road-signs.m" "$site/tools/render-media.m" -o "$work/render-media"
"$work/render-media" "$work"
media="$site/le-traffic/media"; mkdir -p "$media/signs"
cp "$work"/signs/*.png "$media/signs/"
echo "media in $media"
