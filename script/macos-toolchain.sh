#!/bin/bash
# Source this file. Select tools only for this build, without sudo/xcode-select changes.
gpt_niang_prepare_toolchain() {
  local project="$1"
  local xcrun_cmd="${2:-/usr/bin/xcrun}"
  local select_cmd="${3:-/usr/bin/xcode-select}"
  if [ "${GPT_NIANG_TOOLCHAIN_READY:-}" = 1 ] && [ -x "${GPT_NIANG_SWIFT:-}" ] && [ -d "${GPT_NIANG_RESOLVED_SDK:-}" ]; then return 0; fi
  local selected compiler sdk fingerprint cache
  if [ -n "${GPT_NIANG_DEVELOPER_DIR:-}" ]; then
    export DEVELOPER_DIR="$GPT_NIANG_DEVELOPER_DIR"
  elif [ -z "${DEVELOPER_DIR:-}" ]; then
    selected="$("$select_cmd" -p 2>/dev/null || true)"
    if [ "$selected" = /Library/Developer/CommandLineTools ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
      export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    fi
  fi
  GPT_NIANG_SWIFT="$("$xcrun_cmd" --find swift)" || {
    echo "无法定位 Swift。请安装并完成 Xcode 首次初始化。" >&2; return 1;
  }
  compiler="$("$xcrun_cmd" --find swiftc)" || return 1
  sdk="${GPT_NIANG_SDK:-}"
  if [ -z "$sdk" ]; then sdk="$("$xcrun_cmd" --sdk macosx --show-sdk-path)" || return 1; fi
  if [ ! -d "$sdk" ] || [ "$(dirname "$compiler")" != "$(dirname "$GPT_NIANG_SWIFT")" ]; then
    echo "Swift、swiftc 或 SDK 来源不一致，已停止构建。" >&2; return 1
  fi
  fingerprint="$(printf '%s\n' "$GPT_NIANG_SWIFT" "$sdk" "$("$GPT_NIANG_SWIFT" --version)" | cksum)"
  fingerprint="${fingerprint%% *}"
  cache="${GPT_NIANG_BUILD_CACHE:-$project/macos/.build-cache}/toolchain-$fingerprint"
  mkdir -p "$cache/clang" "$cache/swiftpm" || return 1
  export GPT_NIANG_RESOLVED_SDK="$sdk" SDKROOT="$sdk"
  export GPT_NIANG_BUILD_CACHE="$cache"
  export CLANG_MODULE_CACHE_PATH="$cache/clang" SWIFTPM_MODULECACHE_OVERRIDE="$cache/clang"
  echo "Swift：$GPT_NIANG_SWIFT"
  echo "SDK：$sdk"
  if ! "$GPT_NIANG_SWIFT" package --package-path "$project/macos" --cache-path "$cache/swiftpm" \
      --scratch-path "$cache/manifest-probe" dump-package >"$cache/manifest.json" 2>"$cache/manifest.log"; then
    cat "$cache/manifest.log" >&2
    echo "Swift 包清单预检失败。应用尚未开始编译，安装未进行。" >&2
    echo "若出现 PackageDescription 未定义符号，请更新/修复 Command Line Tools，或安装并打开完整版 Xcode。" >&2
    echo "诊断日志：$cache/manifest.log" >&2
    return 1
  fi
  cat >"$cache/SwiftUIProbe.swift" <<'SWIFT'
import SwiftUI
struct ToolchainProbe: View {
    @State private var value = 0
    var body: some View { Text(String(value)) }
}
SWIFT
  if ! "$compiler" -typecheck -swift-version 5 -sdk "$sdk" -module-cache-path "$cache/clang" \
      "$cache/SwiftUIProbe.swift" >"$cache/swiftui.log" 2>&1; then
    cat "$cache/swiftui.log" >&2
    echo "SwiftUI SDK/宏插件预检失败。请选择完整 Xcode 或兼容的 SDK；安装未进行。" >&2
    return 1
  fi
  export GPT_NIANG_SWIFT GPT_NIANG_TOOLCHAIN_READY=1
}
