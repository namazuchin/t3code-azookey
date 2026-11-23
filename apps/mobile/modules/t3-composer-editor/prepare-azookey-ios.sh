#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../../../.." && pwd)
destination="$root/.t3/azookey-ios"
revision=8278b6b76e534f1a08e4db2a11602f499d754327
original_sha=b2721b6e9d7b055fc35677c5063cc877fb7cbeeb8e6dd631b065145751e0944e
if [ -f "$destination/.t3-quiet-azookey" ]; then
  test "$(cat "$destination/.t3-quiet-azookey")" = "$revision"
  test "$(git -C "$destination" rev-parse HEAD)" = "$revision"
  ! grep -q '#if DEBUG' "$destination/Sources/SwiftUtils/Debug.swift"
  exit
fi
mkdir -p "$root/.t3"
staging=$(mktemp -d "$root/.t3/azookey-ios.XXXXXX")
trap 'rm -rf "$staging"' EXIT
git -c protocol.file.allow=never clone --branch v0.8.5 --depth 1 --recurse-submodules --shallow-submodules \
  https://github.com/azooKey/AzooKeyKanaKanjiConverter.git "$staging"
test "$(git -C "$staging" rev-parse HEAD)" = "$revision"
file="$staging/Sources/SwiftUtils/Debug.swift"
printf '%s  %s\n' "$original_sha" "$file" | shasum -a 256 -c
# Upstream DEBUG prints can include draft keystrokes. Never opt into those logs.
sed 's/#if DEBUG/#if T3_AZOOKEY_INPUT_LOGGING_NEVER_ENABLED/g' "$file" > "$file.quiet"
mv "$file.quiet" "$file"
printf '%s\n' "$revision" > "$staging/.t3-quiet-azookey"
test ! -e "$destination"
mv "$staging" "$destination"
