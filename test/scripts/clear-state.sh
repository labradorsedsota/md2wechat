#!/bin/bash
# clear-state.sh — 清除 md2wechat localStorage 状态
# Usage: ./clear-state.sh
# 前置条件：Chrome 已打开 md2wechat 页面

set -euo pipefail

osascript -e '
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "localStorage.removeItem('"'"'m2w_state'"'"');"
    end tell
end tell'

echo "OK: m2w_state cleared from localStorage"
