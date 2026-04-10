#!/bin/bash
# inject-fixture.sh — 将 fixture 文件内容注入 md2wechat 编辑器
# Usage: ./inject-fixture.sh <fixture-file-path>
# 前置条件：Chrome 已打开 md2wechat 页面且为当前活动标签页

set -euo pipefail

FIXTURE_PATH="$1"
if [ ! -f "$FIXTURE_PATH" ]; then
    echo "Error: fixture file not found: $FIXTURE_PATH"
    exit 1
fi

# 读取 fixture 内容并 base64 编码（避免引号/反引号转义问题）
CONTENT_B64=$(base64 < "$FIXTURE_PATH" | tr -d '\n')

osascript -e "
tell application \"Google Chrome\"
    tell active tab of front window
        execute javascript \"
            var content = atob('${CONTENT_B64}');
            document.getElementById('editor').value = content;
            document.getElementById('editor').dispatchEvent(new Event('input'));
        \"
    end tell
end tell"

echo "OK: fixture injected from $FIXTURE_PATH"
