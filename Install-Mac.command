#!/bin/bash
set -euo pipefail
umask 077
cd "$(dirname "$0")"
if [ "$(/usr/bin/uname -s)" != Darwin ]; then
  echo "此安装器必须在你的 Mac 本机运行。"
  exit 2
fi
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
echo "先编译并运行测试。通过前不会替换已安装应用。"
bash Build-Mac.command --no-open
widget_source="$PWD/dist/GPTNiangMac.app"
widget_parent="$HOME/Applications"
if [ -d /Applications/GPTNiangMac.app ] && [ -w /Applications ]; then widget_parent=/Applications; fi
mkdir -p "$widget_parent"
widget_parent="$(cd "$widget_parent" && pwd -P)"
widget_target="$widget_parent/GPTNiangMac.app"
if [ -L "$widget_target" ]; then echo "目标是符号链接，已停止安装。"; exit 1; fi
if [ -e "$widget_target" ]; then
  widget_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$widget_target/Contents/Info.plist")
  if [ "$widget_id" != io.github.t7moris.GPTNiangMac ]; then echo "目标存在其他应用，已停止安装。"; exit 1; fi
fi
widget_job="$(mktemp -d "$widget_parent/.gpt-niang-deploy.XXXXXXXX")"
widget_stage="$widget_job/GPTNiangMac.app"
widget_backup="$widget_job/previous.app"
widget_health="$widget_job/health.json"
widget_previous=0
widget_installed=0
widget_committed=0
widget_stopped=0
widget_running_paths=()
stop_widget() {
  local candidate executable bundle identifier attempt
  local remember="${1:-0}"
  for candidate in $(/usr/bin/pgrep -u "$(/usr/bin/id -u)" -x GPTNiangMac || true); do
    executable=$(/bin/ps -ww -p "$candidate" -o comm= 2>/dev/null || true)
    case "$executable" in
      */GPTNiangMac.app/Contents/MacOS/GPTNiangMac)
        bundle="${executable%/Contents/MacOS/GPTNiangMac}"
        identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$bundle/Contents/Info.plist" 2>/dev/null || true)
        if [ "$identifier" = io.github.t7moris.GPTNiangMac ]; then
          if [ "$remember" -eq 1 ]; then widget_running_paths+=("$bundle"); widget_stopped=1; fi
          kill -TERM "$candidate" 2>/dev/null || true
          for attempt in {1..50}; do
            if ! kill -0 "$candidate" 2>/dev/null; then break; fi
            /bin/sleep 0.1
          done
          if kill -0 "$candidate" 2>/dev/null; then echo "旧挂件未退出，已保留原文件。"; return 1; fi
        fi
        ;;
    esac
  done
}
finish_install() {
  local result=$?
  trap - EXIT
  if [ "$widget_committed" -eq 0 ]; then
    if [ "$widget_installed" -eq 1 ]; then
      if ! stop_widget; then
        echo "未能停止新版；原版备份保留在 $widget_backup。"
        exit 1
      fi
      /bin/mv "$widget_target" "$widget_job/failed.app" || exit 1
    fi
    if [ "$widget_previous" -eq 1 ]; then
      /bin/mv "$widget_backup" "$widget_target" || exit 1
    fi
    if [ "$widget_stopped" -eq 1 ]; then
      for previous_app in "${widget_running_paths[@]}"; do
        if [ -d "$previous_app" ]; then /usr/bin/open "$previous_app" || true; fi
      done
    fi
    echo "安装未完成。诊断目录：$widget_job"
  fi
  exit "$result"
}
trap finish_install EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
/usr/bin/ditto "$widget_source" "$widget_stage"
/usr/bin/codesign --verify --deep --strict "$widget_stage"
/usr/bin/lipo "$widget_stage/Contents/MacOS/GPTNiangMac" -verify_arch "$(/usr/bin/uname -m)"
stop_widget 1
if [ -d "$widget_target" ]; then
  /bin/mv "$widget_target" "$widget_backup"
  widget_previous=1
fi
/bin/mv "$widget_stage" "$widget_target"
widget_installed=1
/usr/bin/open -n "$widget_target" --args --deployment-health "$widget_health"
node scripts/deployment-health.mjs "$widget_health" "$widget_target"
widget_committed=1
echo "安装完成：$widget_target"
if [ "$widget_previous" -eq 1 ]; then echo "旧版备份：$widget_backup"; fi
