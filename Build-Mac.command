#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
. script/macos-toolchain.sh
gpt_niang_prepare_toolchain "$PWD"
if ! command -v node >/dev/null 2>&1; then
  export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
fi
node -e "if(Number(process.versions.node.split('.')[0])<20)process.exit(1)" || {
  echo "需要 Node.js 20 或更高版本。"; exit 1;
}
node --test gpt-niang-usage/tests/web-widget.test.mjs gpt-niang-usage/tests/deployment-health.test.mjs gpt-niang-usage/tests/macos-toolchain.test.mjs
"$GPT_NIANG_SWIFT" test --package-path macos --sdk "$GPT_NIANG_RESOLVED_SDK" --cache-path "$GPT_NIANG_BUILD_CACHE/swiftpm" --scratch-path "${GPT_NIANG_SCRATCH_PATH:-$PWD/macos/.build}"
GPT_NIANG_BUILD_CONFIGURATION=release bash script/build_and_run.sh --build-only
/usr/bin/codesign --verify --deep --strict dist/XiaoBaiLongNiangMac.app
echo "已生成 dist/XiaoBaiLongNiangMac.app。可移入应用程序目录。"
if [ "${1:-}" != "--no-open" ]; then /usr/bin/open dist; fi
