#!/bin/bash
set -euo pipefail
resources="$1"
cache="$2"
version=v24.22.1
mkdir -p "$resources" "$cache"
architectures=("$(uname -m)")
if [ "${GPT_NIANG_BUILD_UNIVERSAL:-0}" = 1 ]; then architectures=(arm64 x86_64); fi
binaries=()
: > "$cache/provenance-current.txt"
for architecture in "${architectures[@]}"; do
  case "$architecture" in arm64) node_arch=arm64 ;; x86_64) node_arch=x64 ;; *) echo "Unsupported Node architecture: $architecture" >&2; exit 1 ;; esac
  name="node-$version-darwin-$node_arch"
  archive="$cache/$name.tar.gz"
  sums="$cache/$name-SHASUMS256.txt"
  /usr/bin/curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
    "https://nodejs.org/dist/$version/SHASUMS256.txt" -o "$sums"
  expected="$(awk -v archive="$name.tar.gz" '$2 == archive {print $1}' "$sums")"
  if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then echo "Missing official Node checksum" >&2; exit 1; fi
  if [ ! -f "$archive" ] || [ "$(shasum -a 256 "$archive" | awk '{print $1}')" != "$expected" ]; then
    /usr/bin/curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
      "https://nodejs.org/dist/$version/$name.tar.gz" -o "$archive"
  fi
  if [ "$(shasum -a 256 "$archive" | awk '{print $1}')" != "$expected" ]; then echo "Node checksum mismatch" >&2; exit 1; fi
  /usr/bin/tar -xzf "$archive" -C "$cache" "$name/bin/node" "$name/LICENSE"
  /usr/bin/lipo "$cache/$name/bin/node" -verify_arch "$architecture"
  binaries+=("$cache/$name/bin/node")
  cp "$cache/$name/LICENSE" "$resources/Node-LICENSE.txt"
  printf '%s  %s\n' "$expected" "https://nodejs.org/dist/$version/$name.tar.gz" >> "$cache/provenance-current.txt"
done
if [ "${#binaries[@]}" -eq 1 ]; then cp "${binaries[0]}" "$resources/node"; else /usr/bin/lipo -create "${binaries[@]}" -output "$resources/node"; fi
chmod 755 "$resources/node"
cp "$cache/provenance-current.txt" "$resources/Node-SOURCE.txt"
rm "$cache/provenance-current.txt"
"$resources/node" --version
