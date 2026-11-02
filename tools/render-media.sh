#!/bin/bash
# Draws the page's pictures with Lề's own code, natively on the Mac (Mac Catalyst), then makes the
# headline's sign loop. Usage: tools/render-media.sh <path to the Lề repository>
set -euo pipefail
le=${1:?path to the Lề repository}; site=$(cd "$(dirname "$0")/.." && pwd); work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
sdk=$(xcrun --sdk macosx --show-sdk-path)
xcrun --sdk macosx clang -target arm64-apple-ios15.0-macabi -isystem "$sdk/System/iOSSupport/usr/include" \
 -iframework "$sdk/System/iOSSupport/System/Library/Frameworks" -fobjc-arc -fblocks -Wall -Wextra -Werror -I"$le" \
 -framework UIKit -framework Foundation -framework CoreGraphics -framework QuartzCore \
 "$le/Core/traffic-bubble-view.m" "$le/Core/source-app-icon.m" "$le/Core/road-signs.m" "$le/Core/waze-signs.m" "$le/Core/waze-sign-names.m" \
 "$le/Core/lane-arrow.m" "$le/Core/traffic-bubble-content.m" "$le/Core/traffic-bubble-layout.m" "$le/Tweak/traffic-bubble-layout-store.m" \
 "$le/Tweak/owned-state-file.m" "$le/Runtime/Providers/Traffic/traffic-snapshot.m" "$site/tools/render-media.m" -o "$work/render-media"
"$work/render-media" "$work"
media="$site/le-traffic/media"; mkdir -p "$media/signs"
cp "$work"/signs/*.png "$media/signs/"
cp "$work/hero.png" "$media/hero.png"
# The loop: the strip panned left by one period (14 signs × 140 pt × 2 px) in 14 s, 30 fps, seamless.
ffmpeg -v error -y -loop 1 -i "$work/strip.png" -vf "crop=840:240:'mod(t*280,3920)':0,format=yuv420p" -t 14 -r 30 \
 -c:v libx264 -preset slow -crf 22 -movflags +faststart -an "$media/signs-loop.mp4"
ffmpeg -v error -y -loop 1 -i "$work/strip.png" -vf "crop=840:240:'mod(t*280,3920)':0,format=yuv420p" -t 14 -r 30 \
 -c:v libsvtav1 -crf 40 -preset 8 -an "$media/signs-loop.webm"
ffmpeg -v error -y -i "$work/strip.png" -vf "crop=840:240:0:0" "$media/signs-loop.png"
echo "media in $media"
