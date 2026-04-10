# TEST-CASE.md — M2W 全量测试用例

## 1. 文档信息

| 项 | 值 |
|---|---|
| 项目 | M2W（公众号 Markdown 美化器） |
| PRD 版本 | v1.4 |
| 当前 Commit | a4f67a6 |
| 测试目标 URL | https://labradorsedsota.github.io/md2wechat/ |
| QA | Moss |
| 日期 | 2026-04-10 |
| 测试点总数 | 29（PRD §10：L1×5 + L2×19 + L3×5） |
| 测试用例总数 | 34（L2-12 拆分为 4 条 + BVA 2 条） |
| 执行规范 | mano-cua-execution-spec v1.6 |
| 设计规范 | test-case-design-spec v1.0 |

---

## 2. 测试环境

| 项 | 值 |
|---|---|
| 浏览器 | Google Chrome 90+ |
| 操作系统 | macOS (arm64) |
| 主执行工具 | mano-cua（GUI 自动化） |
| 辅助工具 | browser API（仅在 mano-cua 无法完成时使用，须注明原因） |
| 目标 URL | `https://labradorsedsota.github.io/md2wechat/` |

---

## 3. 约定

### 3.1 标准 Pre-flight（SEED）

每条 SEED 数据依赖的测试按以下步骤重置：

```bash
# 1. 数据隔离：清除 localStorage（条款 1c）
osascript -e 'tell application "Google Chrome" to tell active tab of front window to execute javascript "localStorage.removeItem(\"m2w_state\");"'

# 2. 打开目标页面（条款 1）
open -a "Google Chrome" "https://labradorsedsota.github.io/md2wechat/"
sleep 2

# 3. 最大化窗口（条款 1, v1.4）
osascript -e '
tell application "Finder"
    set _b to bounds of window of desktop
    tell application "Google Chrome"
        set bounds of front window to {0, 0, item 3 of _b, item 4 of _b}
    end tell
end tell'

# 4. 确认 URL 正确，编辑器显示默认示例文章（条款 2）
```

### 3.2 标准 Pre-flight（CUSTOM）

在标准 SEED 流程基础上增加 fixture 注入（条款 1b）：

```bash
# 1-3. 同 SEED 流程

# 4. 注入 fixture 内容（base64 编码避免引号/反引号问题）
CONTENT_B64=$(base64 < fixtures/md2wechat/<fixture-file>.md | tr -d '\n')
osascript -e "
tell application \"Google Chrome\"
    tell active tab of front window
        execute javascript \"
            var c = atob('${CONTENT_B64}');
            document.getElementById('editor').value = c;
            document.getElementById('editor').dispatchEvent(new Event('input'));
        \"
    end tell
end tell"

# 5. 截图确认 fixture 内容已注入，预览区已更新（条款 1b 校验）
```

**降级链（条款 1b-fallback）：** 若 AppleScript JS 权限关闭 → DevTools Console 注入 → 仍不可用则 BLOCKED + 强制诊断。

### 3.3 标准 Post-flight（条款 14）

```bash
osascript -e '
tell application "Google Chrome"
    set matchPath to "labradorsedsota.github.io/md2wechat"
    set closedCount to 0
    repeat with w in windows
        set tabList to tabs of w
        repeat with i from (count of tabList) to 1 by -1
            if URL of item i of tabList contains matchPath then
                delete item i of tabList
                set closedCount to closedCount + 1
            end if
        end repeat
    end repeat
    return closedCount
end tell'
# 校验 closedCount > 0，重扫确认无残留（条款 14a）
```

### 3.4 mosstid 命名规则

格式：`m2w-md2wechat-v1-{测试点}-{序号}`

示例：`m2w-md2wechat-v1-L1-01-001`

### 3.5 任务指令约束（条款 3）

所有 mano-cua 任务指令末尾统一追加：**"仅在当前页面操作，不要导航到其他网址。"**

---

## 4. Fixture 文件清单

| 文件 | 路径 | 用途 | 覆盖测试点 |
|------|------|------|-----------|
| headings.md | `fixtures/md2wechat/headings.md` | h1-h6 六级标题 + 正文对比 | L2-01 |
| text-formatting.md | `fixtures/md2wechat/text-formatting.md` | 加粗/斜体/删除线/加粗斜体 | L2-02 |
| lists.md | `fixtures/md2wechat/lists.md` | 无序列表 + 有序列表 | L2-03 |
| blockquote.md | `fixtures/md2wechat/blockquote.md` | 引用块 + 正文对比 | L2-04 |
| code-blocks.md | `fixtures/md2wechat/code-blocks.md` | JS + Python 代码块 | L2-05 |
| inline-code.md | `fixtures/md2wechat/inline-code.md` | 多处行内代码 | L2-06 |
| image.md | `fixtures/md2wechat/image.md` | 图片渲染 + placeholder | L2-07 |
| links.md | `fixtures/md2wechat/links.md` | 3 个链接（脚注化测试） | L2-08 |
| table.md | `fixtures/md2wechat/table.md` | 3 列 3 行表格 | L2-09 |
| realtime-input.md | `fixtures/md2wechat/realtime-input.md` | 实时预览输入参考内容 | L1-02 |

---

## 5. 冲突扫描结果（D2.4）

### 写操作用例清单

| 测试点 | 写操作 | 影响范围 |
|--------|--------|----------|
| L1-02 | 编辑器输入内容 | localStorage 编辑内容 |
| L2-10 | 切换主题 | localStorage 主题设置 |
| L2-12-001~004 | 调整样式参数 | localStorage 样式参数 |
| L3-02 | 切换主题 + 刷新验证 | localStorage 主题设置 |
| L3-03 | 调整样式 + 刷新验证 | localStorage 样式参数 |
| L3-04 | 编辑内容 + 刷新验证 | localStorage 编辑内容 |

### 冲突对及缓解

| 冲突对 | 原因 | 缓解措施 |
|--------|------|----------|
| L2-10 → L3-02 | 主题写入可能污染 L3-02 初始状态 | L3-02 Pre-flight 强制清除 localStorage |
| L2-12 → L3-03 | 样式写入可能污染 L3-03 初始状态 | L3-03 Pre-flight 强制清除 localStorage |
| L1-02 → L3-04 | 内容写入可能污染 L3-04 初始状态 | L3-04 Pre-flight 强制清除 localStorage |
| 所有写操作 → L3-01 | 任何写操作可能改变默认状态 | L3-01 Pre-flight 强制清除 localStorage |

**结论：** 所有冲突均通过 Pre-flight 条款 1c（清除 localStorage + 重新加载）缓解。每条测试独立重置，无需调整执行顺序。

---

## 6. L1 — 核心流程

### L1-01 左右分栏布局正确显示

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L1-01-001` |
| 关联 AC | AC-F01-01 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED — 需要默认示例文章显示 |
| 冲突标记 | 无 |
| 前置策略 | 策略二（SEED 自动加载，无需额外操作） |
| fixture | 无（使用内置示例文章） |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"观察当前页面的整体布局。页面应当分为顶部工具栏、中间左右两栏（左侧 Markdown 编辑区、右侧预览区）、底部状态栏。确认左侧是一个文本编辑器（textarea），右侧是渲染后的预览内容。确认两栏之间有一条分隔线。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 页面顶部存在工具栏区域
2. 页面中间分为左右两栏
3. 左栏为 Markdown 文本编辑器（textarea，等宽字体）
4. 右栏为预览区，显示渲染后的富文本内容
5. 左右栏之间有一条垂直分隔线
6. 页面底部有状态栏（显示字数、主题名、存储状态）

---

### L1-02 Markdown 实时预览正常

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L1-02-001` |
| 关联 AC | AC-F01-02 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | ⚠ 修改编辑器内容，与 L3-04 冲突 |
| 前置策略 | 策略一（输入操作本身是被测功能） |
| fixture | realtime-input.md（参考内容） |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"在左侧编辑器中，将光标移动到文本末尾，输入以下内容：先换行，然后输入 '## 新增标题'，再换行输入 '这是新增的段落。'。输入完成后，观察右侧预览区是否实时更新，显示出刚才输入的标题和段落内容。预览更新延迟应在 300ms 以内（观感流畅无卡顿）。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 在左侧编辑器输入 Markdown 文本后，右侧预览区实时更新
2. 预览区显示渲染后的"新增标题"（h2 样式，加粗、字号约 20px）
3. 预览区显示渲染后的"这是新增的段落。"（正文样式）
4. 更新延迟 ≤ 300ms（观感流畅，无明显卡顿）

---

### L1-03 一键复制富文本成功

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L1-03-001` |
| 关联 AC | AC-F05-01 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略二（SEED 自动加载） |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"观察右侧预览区确认有渲染内容。然后点击工具栏右侧的'复制'按钮。观察按钮的状态变化和页面提示信息。点击复制后，按钮文字应变为'已复制 ✓'，背景色变为绿色（#16a34a），且页面应显示'复制成功'提示。约 1.5 秒后按钮应恢复为原始的'复制'状态和蓝色背景。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 预览区有渲染内容时，点击"复制"按钮可触发复制操作
2. 点击后按钮文字变为"已复制 ✓"
3. 按钮背景色变为绿色（成功状态 #16a34a）
4. 页面顶部显示"复制成功"的 toast 提示
5. 约 1.5 秒后按钮恢复为"复制"文字和蓝色背景（#2563eb）

---

### L1-04 粘贴到公众号编辑器格式正确 [BLOCKED]

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L1-04-001` |
| 关联 AC | AC-F05-02 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | N/A |
| 冲突标记 | 无 |
| 前置策略 | N/A |
| fixture | 无 |
| 执行方式 | BLOCKED |

**BLOCKED 诊断：**

**失败现象：** 无法执行。此测试点要求将复制的富文本粘贴到微信公众号编辑器（mp.weixin.qq.com），验证格式保持一致。

**根因判断：** 测试环境无微信公众号后台登录权限，mano-cua 无法在需要登录认证的外部 Web 应用中操作。

**解决方案：**

| 方案 | 描述 | Tradeoff | 预估时间 |
|------|------|----------|----------|
| 方案 A | 人工手动测试：在有公众号权限的设备上手动复制粘贴验证 | 最准确但不可自动化 | 15 分钟（人工） |
| 方案 B | 富文本编辑器模拟：创建包含 contenteditable div 的本地页面模拟粘贴 | 可自动化但无法完全模拟公众号 CSS 过滤行为 | 1 小时 |

**建议方案：** 方案 A。理由：公众号编辑器的 CSS 过滤规则是微信私有的，模拟无法保证准确性。建议由品鉴者在公众号后台进行一次人工粘贴验证。

@Pichai

---

### L1-05 内联 CSS 确保公众号兼容

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L1-05-001` |
| 关联 AC | AC-F05-03 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略二（SEED 自动加载） |
| fixture | 无 |
| 执行方式 | browser API（原因：需检查 HTML 源码中的 style/class 属性，mano-cua 无法读取 DOM innerHTML） |

**Pre-flight：** 标准 SEED 流程（§3.1）

**Browser API 执行脚本：**
```javascript
var html = document.getElementById('preview').innerHTML;
// 检查1：是否包含 class 属性（公众号会过滤 class）
var hasClass = /<[^>]+\sclass=/i.test(html);
// 检查2：布局元素是否使用 inline style
var layoutTags = html.match(/<(h[1-6]|p|blockquote|pre|table|th|td|tr|ul|ol|li|img|hr|section)\b[^>]*>/gi) || [];
var withoutStyle = layoutTags.filter(function(tag) { return !/style=/i.test(tag); });
JSON.stringify({
    hasClassAttribute: hasClass,
    totalLayoutElements: layoutTags.length,
    elementsWithoutInlineStyle: withoutStyle.length,
    sampleMissing: withoutStyle.slice(0, 5)
});
```

**Expected Results（逐条）：**
1. 预览区 HTML 中不包含 class 属性（hasClassAttribute = false）
2. 所有布局元素（h1-h6、p、blockquote、pre、table、ul、ol、li、img 等）均使用 inline style
3. 样式以 `style="..."` 属性形式内联，非外部 CSS class

---

## 7. L2 — 主要功能

### L2-01 标题 h1-h6 渲染正确

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-01-001` |
| 关联 AC | AC-F02-01 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | CUSTOM — 注入 headings.md |
| 冲突标记 | 无 |
| 前置策略 | 策略二（注入 fixture，mano-cua 仅验证渲染） |
| fixture | `fixtures/md2wechat/headings.md` |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 CUSTOM 流程（§3.2），注入 `headings.md`

**任务描述：**
"观察右侧预览区的内容。预览区应显示六级标题（一级标题到六级标题），每级标题的字号应逐级递减，样式清晰区分。一级标题字号最大（约 24px），二级标题次之（约 20px），三级标题约 18px，四级标题约 16px，五级标题约 14px，六级标题最小约 13px。标题文字应为加粗或半粗体。标题下方有一行正文段落，用于对比标题与正文的样式差异。确认各级标题符合当前主题风格。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 预览区显示 h1（一级标题），字号最大，加粗
2. 预览区显示 h2（二级标题），字号次之，加粗
3. 预览区显示 h3（三级标题），字号再次之，加粗
4. 预览区显示 h4（四级标题），字号中等
5. 预览区显示 h5（五级标题），字号较小
6. 预览区显示 h6（六级标题），字号最小
7. 各级标题样式清晰区分，与正文段落有明显视觉差异
8. 标题符合当前主题风格（颜色与主题一致）

---

### L2-02 加粗/斜体/删除线正确

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-02-001` |
| 关联 AC | AC-F02-02 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | CUSTOM — 注入 text-formatting.md |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | `fixtures/md2wechat/text-formatting.md` |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 CUSTOM 流程（§3.2），注入 `text-formatting.md`

**任务描述：**
"观察右侧预览区的内容。预览区应显示以下文本样式：(1) '加粗文本'应为粗体显示（font-weight: bold），(2) '斜体文本'应为斜体显示（font-style: italic），(3) '删除线文本'应有删除线（text-decoration: line-through），(4) '加粗斜体'应同时具有粗体和斜体样式。还有一行普通正文用于对比。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. "加粗文本"显示为粗体（bold）
2. "斜体文本"显示为斜体（italic）
3. "删除线文本"显示为删除线效果（line-through）
4. "加粗斜体"同时具有粗体和斜体效果
5. 普通正文无额外样式，与上述格式形成对比

---

### L2-03 列表渲染正确

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-03-001` |
| 关联 AC | AC-F02-03 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | CUSTOM — 注入 lists.md |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | `fixtures/md2wechat/lists.md` |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 CUSTOM 流程（§3.2），注入 `lists.md`

**任务描述：**
"观察右侧预览区的内容。预览区应显示两组列表：(1) 无序列表——三个项目（苹果、香蕉、橘子），每项前有圆点符号（disc），缩进正确；(2) 有序列表——三个项目（第一步、第二步、第三步），每项前有数字序号（1. 2. 3.），缩进正确。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 无序列表显示三个项目，每项前有圆点符号（disc）
2. 无序列表缩进正确（有 padding-left）
3. 有序列表显示三个项目，每项前有数字序号
4. 有序列表序号按 1、2、3 顺序递增
5. 有序列表缩进正确

---

### L2-04 引用块渲染正确

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-04-001` |
| 关联 AC | AC-F02-04 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | CUSTOM — 注入 blockquote.md |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | `fixtures/md2wechat/blockquote.md` |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 CUSTOM 流程（§3.2），注入 `blockquote.md`

**任务描述：**
"观察右侧预览区的内容。预览区应显示一个引用块（blockquote），具有以下视觉特征：(1) 左侧有彩色边框（border-left），(2) 有区别于正文的背景色，(3) 引用文字颜色与正文不同。引用块下方有一个正文段落用于对比。引用块样式应符合当前主题风格。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 引用块有左侧边框（border-left）
2. 引用块有背景色，与正文背景不同
3. 引用文字颜色与正文有区分
4. 引用块与后续正文段落有明显视觉差异
5. 引用块样式符合当前主题风格

---

### L2-05 代码块 + 语法高亮

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-05-001` |
| 关联 AC | AC-F02-05 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | CUSTOM — 注入 code-blocks.md |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | `fixtures/md2wechat/code-blocks.md` |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 CUSTOM 流程（§3.2），注入 `code-blocks.md`

**任务描述：**
"观察右侧预览区的内容。预览区应显示两个代码块：一个 JavaScript 代码块和一个 Python 代码块。每个代码块应具有以下特征：(1) 有背景色（与正文背景不同），(2) 使用等宽字体（monospace），(3) 代码中的关键字（如 JavaScript 的 function、const、return，Python 的 def、return）应有语法高亮（用不同颜色区分）。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. JavaScript 代码块有背景色（与正文背景区分）
2. JavaScript 代码块使用等宽字体（monospace）
3. JavaScript 代码块中的关键字（function、const、return）有语法高亮颜色
4. Python 代码块有背景色
5. Python 代码块使用等宽字体
6. Python 代码块中的关键字（def、return）有语法高亮颜色

---

### L2-06 行内代码渲染正确

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-06-001` |
| 关联 AC | AC-F02-06 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | CUSTOM — 注入 inline-code.md |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | `fixtures/md2wechat/inline-code.md` |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 CUSTOM 流程（§3.2），注入 `inline-code.md`

**任务描述：**
"观察右侧预览区的内容。预览区应显示包含行内代码的段落。行内代码（如'行内代码'、'console.log()'、'const a = 1'）应具有以下特征：(1) 有背景色（与正文背景不同），(2) 使用等宽字体（monospace），(3) 字号略小于正文（约 0.9em）。行内代码嵌入在正文句子中，不单独成块。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 行内代码有背景色（与正文背景区分）
2. 行内代码使用等宽字体（monospace）
3. 行内代码嵌入在正文句子中（非独立代码块）
4. 多处行内代码样式一致

---

### L2-07 图片渲染正确

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-07-001` |
| 关联 AC | AC-F02-07 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | CUSTOM — 注入 image.md |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | `fixtures/md2wechat/image.md` |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 CUSTOM 流程（§3.2），注入 `image.md`

**任务描述：**
"观察右侧预览区的内容。预览区应显示一张图片（img 元素）。图片应具有以下特征：(1) 正确加载并显示（非破损图标），(2) 居中显示（display: block, margin: auto），(3) 自适应宽度（max-width: 100%，未超出容器）。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 图片正确加载并显示（非破损图标或 alt 文本替代）
2. 图片居中显示
3. 图片自适应宽度，未超出预览区容器

---

### L2-08 链接脚注化渲染

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-08-001` |
| 关联 AC | AC-F02-08 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | CUSTOM — 注入 links.md |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | `fixtures/md2wechat/links.md` |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 CUSTOM 流程（§3.2），注入 `links.md`

**任务描述：**
"观察右侧预览区的内容。由于公众号不支持外链，链接应按脚注样式渲染：(1) 正文中链接文字（如'Markdown 指南'、'GitHub 文档'、'MDN Web Docs'）带有特殊颜色标记，(2) 链接文字后有上标序号（如 [1]、[2]、[3]），(3) 页面底部有'参考链接'区域，列出各链接的序号和完整 URL。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 链接文字（如"Markdown 指南"）带有特殊颜色标记（主题色）
2. 链接文字后有上标数字序号（如 [1]）
3. 页面底部有"参考链接"区域
4. 参考链接区域列出每个链接的序号和完整 URL
5. 序号在正文和参考链接区域一一对应（共 3 个链接 → [1][2][3]）

---

### L2-09 表格渲染正确

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-09-001` |
| 关联 AC | AC-F02-09 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | CUSTOM — 注入 table.md |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | `fixtures/md2wechat/table.md` |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 CUSTOM 流程（§3.2），注入 `table.md`

**任务描述：**
"观察右侧预览区的内容。预览区应显示一个表格，包含表头行（姓名、年龄、城市）和三行数据（Alice/30/北京、Bob/25/上海、Charlie/35/广州）。表格应具有以下特征：(1) 有边框，(2) 表头行有背景色区分，(3) 数据行有斑马纹效果（交替背景色），(4) 样式符合当前主题风格。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 表格正确显示，包含 3 列（姓名、年龄、城市）和 3 行数据
2. 表头行有背景色区分
3. 数据行有斑马纹效果（交替背景色）
4. 表格有边框
5. 表格样式符合当前主题风格

---

### L2-10 主题切换生效

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-10-001` |
| 关联 AC | AC-F03-02 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | ⚠ 写入主题设置，与 L3-02 冲突 |
| 前置策略 | 策略一（主题切换操作本身是被测功能） |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"当前页面默认显示'简约'主题。点击工具栏中的主题选择器下拉框，从下拉菜单中选择'科技'主题。选择后观察右侧预览区：标题颜色应变为蓝色系（深蓝 #0d47a1），引用块背景色应变为浅蓝色（#e3f2fd），整体配色切换为蓝色调的科技风格。确认预览区立即切换为'科技'主题的样式。底部状态栏的主题名也应更新。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 点击主题选择器后，下拉菜单展开
2. 选择"科技"主题后，下拉菜单关闭
3. 预览区立即切换为"科技"主题样式
4. 标题颜色变为蓝色系
5. 引用块背景色变为浅蓝色
6. 底部状态栏显示当前主题名更新为"科技"

---

### L2-11 至少 5 套预设主题

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-11-001` |
| 关联 AC | AC-F03-01 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略二（SEED 自动加载） |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"点击工具栏中的主题选择器下拉框，展开下拉菜单。数一数菜单中有多少个主题选项。PRD 要求至少 5 套预设主题：简约、科技、文艺、二次元、商务。确认每个主题选项都显示主题名称和一句描述文字。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 主题选择器下拉菜单中至少有 5 个主题选项
2. 包含"简约"主题
3. 包含"科技"主题
4. 包含"文艺"主题
5. 包含"二次元"主题
6. 包含"商务"主题
7. 每个选项显示主题名称和一句话描述

---

### L2-12-001 样式微调 — 正文字号

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-12-001` |
| 关联 AC | AC-F04-01 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | ⚠ 写入样式参数，与 L3-03 冲突 |
| 前置策略 | 策略一（调整操作本身是被测功能） |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"点击工具栏右侧的设置按钮（⚙ 图标），打开样式微调面板。在面板中找到'正文字号'滑块（range 控件），将其拖动调整到一个不同的值（如 15px 或 17px）。观察右侧预览区的正文文字大小是否实时变化。滑块旁应显示当前数值（如'15px'）。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 点击 ⚙ 按钮后，样式微调面板从右侧滑出
2. 面板中存在"正文字号"滑块控件
3. 拖动滑块后，预览区正文字号实时变化
4. 滑块旁显示当前数值（如"15px"）

---

### L2-12-002 样式微调 — 行间距

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-12-002` |
| 关联 AC | AC-F04-02 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | ⚠ 写入样式参数，与 L3-03 冲突 |
| 前置策略 | 策略一 |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"点击工具栏右侧的设置按钮（⚙ 图标），打开样式微调面板。在面板中找到'行间距'滑块，将其拖动到一个不同的值（如 2.0）。观察右侧预览区的行间距是否实时变化（文字行之间间距变大或变小）。滑块旁应显示当前数值。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 面板中存在"行间距"滑块控件
2. 拖动滑块后，预览区行间距实时变化
3. 滑块旁显示当前数值（如"2.00"）

---

### L2-12-003 样式微调 — 主题色

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-12-003` |
| 关联 AC | AC-F04-03 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | ⚠ 写入样式参数，与 L3-03 冲突 |
| 前置策略 | 策略一 |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"点击工具栏右侧的设置按钮（⚙ 图标），打开样式微调面板。在面板中找到'主题色'颜色选择器（color input），点击它并选择一个明显不同的颜色（如红色）。观察右侧预览区的标题、链接脚注等元素的颜色是否实时变化为新选择的颜色。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 面板中存在"主题色"颜色选择器控件
2. 选择新颜色后，预览区标题颜色实时变化
3. 预览区链接/脚注颜色实时变化
4. 颜色变化与所选颜色一致

---

### L2-12-004 样式微调 — 代码块配色

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-12-004` |
| 关联 AC | AC-F04-04 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | ⚠ 写入样式参数，与 L3-03 冲突 |
| 前置策略 | 策略一 |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"点击工具栏右侧的设置按钮（⚙ 图标），打开样式微调面板。在面板中找到'代码块配色'下拉选择（select 控件）。当前默认应为'浅色'，切换为'深色'。观察右侧预览区中代码块的背景色和文字颜色是否实时变化（应变为深色背景 #282c34 + 浅色文字 #abb2bf）。再切换为'Monokai'，观察代码块配色是否再次变化（背景 #272822）。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 面板中存在"代码块配色"下拉选择控件（浅色/深色/Monokai）
2. 切换为"深色"后，代码块背景变为深色
3. 代码块文字变为浅色
4. 切换为"Monokai"后，代码块配色再次变化
5. 配色变化实时生效，无需手动刷新

---

### L2-12-005 [BVA] 正文字号边界值

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-12-005` |
| 关联 AC | AC-F04-01 |
| 设计技术 | BVA — 正文字号字段边界 |
| 目标边界 | 最小有效值 14px、最大有效值 18px |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略一 |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"点击设置按钮（⚙）打开样式微调面板。将'正文字号'滑块拖到最左端（最小值），确认数值显示'14px'，观察预览区字号变化——字号应变小但内容仍可读。然后将滑块拖到最右端（最大值），确认数值显示'18px'，观察预览区字号变化——字号应变大。确认滑块无法拖出 14-18 的范围。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 滑块最小值为 14px，数值显示"14px"
2. 在 14px 时，预览区正文正常渲染（字号较小但可读）
3. 滑块最大值为 18px，数值显示"18px"
4. 在 18px 时，预览区正文正常渲染（字号较大）
5. 滑块无法拖出 14-18 范围

---

### L2-12-006 [BVA] 行间距边界值

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-12-006` |
| 关联 AC | AC-F04-02 |
| 设计技术 | BVA — 行间距字段边界 |
| 目标边界 | 最小有效值 1.5、最大有效值 2.5 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略一 |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"点击设置按钮（⚙）打开样式微调面板。将'行间距'滑块拖到最左端（最小值），确认数值显示'1.50'，观察预览区行间距——行距应变紧凑但可读。然后将滑块拖到最右端（最大值），确认数值显示'2.50'，观察预览区行间距——行距应变疏松。确认滑块无法拖出 1.5-2.5 的范围。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 滑块最小值为 1.5，数值显示"1.50"
2. 在 1.5 时，预览区行间距较紧凑但可读
3. 滑块最大值为 2.5，数值显示"2.50"
4. 在 2.5 时，预览区行间距较疏松
5. 滑块无法拖出 1.5-2.5 范围

---

### L2-13 视觉：工具栏白底 + 细线分隔

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-13-001` |
| 关联 AC | §8.2 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略二（SEED 自动加载） |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"观察页面顶部的工具栏区域。工具栏应具有以下特征：(1) 白色背景（纯白 #ffffff），无渐变、无毛玻璃效果，(2) 底部有一条细线分隔（灰色），(3) 高度约 48px，(4) 左侧显示产品名纯文字'Markdown 美化器'（不是 logo 图标），(5) 右侧有设置按钮（⚙）和复制按钮。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 工具栏为白色背景，无渐变效果
2. 工具栏无毛玻璃（backdrop-filter）效果
3. 工具栏底部有细线分隔
4. 工具栏左侧显示纯文字产品名"Markdown 美化器"（无 logo 图标）
5. 工具栏右侧有设置按钮（⚙）和复制按钮

---

### L2-14 视觉：主题选择器自定义下拉

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-14-001` |
| 关联 AC | §8.3 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"观察工具栏中的主题选择器。它应是一个自定义样式的下拉框（不是浏览器原生 select 元素）。点击展开下拉菜单，观察每个选项：(1) 左侧有一个小色点（8px 圆形，颜色对应主题色），(2) 显示主题名称和一句描述文字（如'简约 — 黑白灰，干净清爽'），(3) 当前选中的选项左侧有 ✓ 标记，文字为蓝色（#2563eb）。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 主题选择器是自定义样式下拉框（非原生 select）
2. 点击后展开下拉菜单，有白色背景和圆角
3. 每个选项前有小色点（对应主题色）
4. 每个选项显示主题名称
5. 每个选项显示描述文字
6. 当前选中项有 ✓ 标记
7. 选中项文字为蓝色（#2563eb）

---

### L2-15 视觉：预览卡片

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-15-001` |
| 关联 AC | §8.5 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"观察右侧预览区。预览内容应显示在一张白色卡片内。卡片应具有以下特征：(1) 白色背景 #ffffff，(2) 圆角约 8px，(3) 有柔和的阴影效果，(4) 卡片外围区域为浅灰色背景 #f8f9fa。不应出现仿微信文章外壳（如公众号名称、头像、日期、点赞/分享/在看按钮等装饰）。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 预览内容在白色卡片中显示
2. 卡片有圆角效果（约 8px）
3. 卡片有柔和阴影
4. 卡片外背景为浅灰色
5. 无微信文章外壳装饰（无公众号名/头像/日期/互动栏）

---

### L2-16 视觉：复制按钮状态

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-16-001` |
| 关联 AC | §8.8 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"观察工具栏右侧的'复制'按钮。按钮默认应为：(1) 蓝色实色背景 #2563eb，无渐变，(2) 白色文字'复制'，(3) 圆角约 8px。将鼠标悬停在按钮上，观察 hover 效果——背景色应变深。点击按钮后观察：背景色变为绿色 #16a34a，文字变为'已复制 ✓'。等待约 1.5 秒后，按钮应恢复蓝色背景和'复制'文字。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 按钮默认为蓝色实色背景（#2563eb），无渐变
2. 按钮文字为白色"复制"
3. hover 时背景色变深
4. 点击后背景色变为绿色（成功态 #16a34a）
5. 点击后文字变为"已复制 ✓"
6. 约 1.5 秒后恢复原始蓝色背景和"复制"文字

---

### L2-17 视觉：全局唯一点缀色 #2563eb

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-17-001` |
| 关联 AC | §8.1 颜色系统 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"观察整个页面的 UI 配色（不含预览区内主题渲染的文章内容）。工具栏、按钮、状态栏等 UI 元素中，唯一的彩色应为蓝色 #2563eb，其余 UI 元素应全部为黑白灰色调。点击设置按钮打开样式微调面板，确认面板中的控件高亮色也是蓝色（accent-color），其余为灰色。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 复制按钮为蓝色（#2563eb），是 UI 中唯一的彩色按钮
2. 工具栏文字和边框为黑白灰色调
3. 设置面板中滑块高亮色为蓝色
4. 除蓝色外，UI 元素无其他彩色（无红、绿、橙等装饰色）
5. 状态栏为灰色文字

---

### L2-18 视觉：圆角统一 8px + 间距 8 倍数

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-18-001` |
| 关联 AC | §8.1 设计系统 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | 无 |
| 执行方式 | browser API（原因：需精确测量 CSS computed values，mano-cua 截图无法精确判断 7px 与 8px 的差异） |

**Pre-flight：** 标准 SEED 流程（§3.1）

**Browser API 执行脚本：**
```javascript
var results = {};
// 圆角一致性检查
var roundedEls = [
    {name:'copy-btn', el:document.querySelector('.btn-copy')},
    {name:'settings-btn', el:document.querySelector('.btn-settings')},
    {name:'theme-trigger', el:document.querySelector('.theme-dropdown-trigger')},
    {name:'preview-wrapper', el:document.querySelector('.preview-wrapper')},
    {name:'toast', el:document.querySelector('.toast')}
];
results.borderRadius = roundedEls.map(function(item){
    return {name:item.name, borderRadius:window.getComputedStyle(item.el).borderRadius};
});
// 间距检查（8 的倍数）
var spacingEls = [
    {name:'toolbar-paddingLeft', el:document.querySelector('.toolbar'), prop:'paddingLeft'},
    {name:'editor-padding', el:document.querySelector('#editor'), prop:'padding'},
    {name:'preview-content-padding', el:document.querySelector('.preview-content'), prop:'padding'},
    {name:'statusbar-paddingLeft', el:document.querySelector('.statusbar'), prop:'paddingLeft'}
];
results.spacing = spacingEls.map(function(item){
    var val = window.getComputedStyle(item.el)[item.prop];
    return {name:item.name, value:val};
});
JSON.stringify(results, null, 2);
```

**Expected Results（逐条）：**
1. 所有圆角元素的 border-radius 统一为 8px
2. 工具栏 padding 为 8 的倍数（24px）
3. 编辑器 padding 为 8 的倍数（24px）
4. 预览卡片内边距为 8 的倍数（32px）
5. 状态栏 padding 为 8 的倍数（24px）

---

### L2-19 视觉：字体层级不超过 4 种字号

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L2-19-001` |
| 关联 AC | §8.1 字体层级 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略二 |
| fixture | 无 |
| 执行方式 | browser API（原因：需精确提取 UI 元素的 computed font-size，mano-cua 截图无法区分 12px 与 13px） |

**Pre-flight：** 标准 SEED 流程（§3.1）

**Browser API 执行脚本：**
```javascript
// 采集 UI 元素（非预览区）的字号
var uiSelectors = ['.toolbar', '.statusbar', '.theme-dropdown'];
var fontSizes = new Set();
uiSelectors.forEach(function(sel){
    document.querySelectorAll(sel + ' *').forEach(function(el){
        var cs = window.getComputedStyle(el);
        if(cs.display !== 'none' && el.textContent.trim()){
            fontSizes.add(Math.round(parseFloat(cs.fontSize)));
        }
    });
});
// 单独检查按钮
['.btn-copy','.btn-settings'].forEach(function(sel){
    var el = document.querySelector(sel);
    if(el) fontSizes.add(Math.round(parseFloat(window.getComputedStyle(el).fontSize)));
});
JSON.stringify({
    uniqueFontSizes: Array.from(fontSizes).sort(function(a,b){return a-b}),
    count: fontSizes.size,
    expected: [12, 13, 14, 16],
    pass: fontSizes.size <= 4
});
```

**Expected Results（逐条）：**
1. UI 元素（非预览区）使用的字号不超过 4 种
2. 使用的字号应为 16px、14px、13px、12px 中的子集
3. 无 11px、15px、17px 等非规范字号

---

## 8. L3 — 辅助功能

### L3-01 内置示例文章正确显示

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L3-01-001` |
| 关联 AC | AC-F06-01, AC-F06-02 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED — 清除 localStorage 触发示例文章加载 |
| 冲突标记 | ⚠ 依赖默认状态，所有写操作后需重置 |
| 前置策略 | 策略二（清除 localStorage 后自动加载示例文章） |
| fixture | 无（使用内置示例文章） |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1），确保 localStorage 已清除

**任务描述：**
"观察当前页面。左侧编辑器应显示一篇内置的示例 Markdown 文章（非空白）。右侧预览区应显示该示例文章的渲染效果。示例文章应涵盖多种 Markdown 语法元素：多级标题、加粗/斜体/删除线、有序/无序列表、代码块（带语法高亮）、引用块、表格、图片、链接。确认预览区能看到所有这些元素的渲染效果。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 首次打开（无 localStorage）时，编辑器自动加载示例文章（非空白）
2. 预览区显示标题（至少包含 h1、h2、h3）
3. 预览区显示加粗/斜体/删除线文本
4. 预览区显示有序和无序列表
5. 预览区显示代码块（带语法高亮）
6. 预览区显示引用块（带左边框和背景色）
7. 预览区显示表格（带边框和表头）
8. 预览区显示图片
9. 预览区显示链接（脚注样式）

---

### L3-02 主题选择 localStorage 持久化

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L3-02-001` |
| 关联 AC | AC-F03-03 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED — 清除 localStorage 从默认状态开始 |
| 冲突标记 | ⚠ 与 L2-10（主题切换）冲突，必须先重置 |
| 前置策略 | 策略一（切换主题 + 刷新验证，操作本身是被测功能） |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"当前页面默认显示'简约'主题。点击主题选择器，切换到'文艺'主题。确认预览区样式已变为暖色调文艺风格。然后刷新页面（按 Cmd+R 或 F5）。刷新完成后观察：(1) 主题选择器应仍然显示'文艺'，(2) 预览区应仍然是文艺主题的暖色调样式，(3) 底部状态栏显示'文艺'。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 切换到"文艺"主题后，预览区样式变为暖色调
2. 刷新页面后，主题选择器仍显示"文艺"
3. 刷新页面后，预览区仍为文艺主题暖色调样式
4. 底部状态栏仍显示"文艺"

---

### L3-03 样式参数 localStorage 持久化

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L3-03-001` |
| 关联 AC | AC-F04-05 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | ⚠ 与 L2-12（样式微调）冲突，必须先重置 |
| 前置策略 | 策略一 |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"点击设置按钮（⚙）打开样式微调面板。将正文字号调整为 18px，行间距调整为 2.0。关闭设置面板。然后刷新页面（Cmd+R）。刷新完成后重新打开设置面板，确认：(1) 正文字号仍为 18px，(2) 行间距仍为 2.0。同时观察预览区的字号和行间距应与刷新前一致。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 调整字号为 18px 后，预览区字号变大
2. 调整行间距为 2.0 后，预览区行间距变大
3. 刷新页面后，设置面板中字号仍为 18px
4. 刷新页面后，设置面板中行间距仍为 2.0
5. 刷新页面后，预览区字号和行间距与刷新前一致

---

### L3-04 编辑内容 localStorage 持久化

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L3-04-001` |
| 关联 AC | AC-F01-03 |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | ⚠ 与 L1-02（实时预览输入）冲突 |
| 前置策略 | 策略一 |
| fixture | 无 |
| 执行方式 | mano-cua |

**Pre-flight：** 标准 SEED 流程（§3.1）

**任务描述：**
"在左侧编辑器中，将光标移到文本最开头，输入一行独特文字：'PERSISTENCE_TEST_12345'（直接输入，无需 Markdown 语法）。确认编辑器显示该文字且预览区也渲染了它。然后刷新页面（Cmd+R）。刷新完成后观察：(1) 左侧编辑器中仍包含'PERSISTENCE_TEST_12345'，(2) 右侧预览区仍显示该文字。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 输入独特文字后，编辑器显示该文字
2. 预览区渲染显示该文字
3. 刷新页面后，编辑器仍包含该文字
4. 刷新页面后，预览区仍显示该文字
5. 底部状态栏显示"已保存"

---

### L3-05 剪贴板降级处理

| 项 | 值 |
|---|---|
| mosstid | `m2w-md2wechat-v1-L3-05-001` |
| 关联 AC | 异常设计（§6 剪贴板 API 不可用） |
| 设计技术 | PRD 追溯 |
| 数据依赖 | SEED |
| 冲突标记 | 无 |
| 前置策略 | 策略二（Pre-flight 禁用剪贴板 API，mano-cua 验证降级行为） |
| fixture | 无 |
| 执行方式 | mano-cua + Pre-flight browser API |

**Pre-flight：**
1. 标准 SEED 流程（§3.1）
2. 禁用剪贴板 API + execCommand（AppleScript JS 注入）：
```javascript
// 禁用 Clipboard API 和 execCommand 以触发完全降级
delete window.ClipboardItem;
if(navigator.clipboard) navigator.clipboard.write = undefined;
document.execCommand = function() { throw new Error('disabled'); };
```

**任务描述：**
"点击工具栏右侧的'复制'按钮。由于剪贴板 API 不可用，应触发降级处理：页面应显示提示信息引导用户手动复制（如'请手动 Ctrl+C / Cmd+C 复制'）。复制按钮应显示失败态（红色背景 #dc2626，文字'复制失败'）。确认页面不崩溃、不报错。仅在当前页面操作，不要导航到其他网址。"

**Expected Results（逐条）：**
1. 点击复制按钮后，页面不崩溃、不报错
2. 页面显示提示信息（toast："请手动 Ctrl+C / Cmd+C 复制"）
3. 复制按钮显示失败态（红色背景 #dc2626）
4. 复制按钮文字变为"复制失败"
5. 约 1.5 秒后按钮恢复原始状态

---

## 9. 测试统计

| 层级 | 测试点数（PRD） | 测试用例数 | BLOCKED |
|------|----------------|-----------|---------|
| L1 | 5 | 5 | 1（L1-04） |
| L2 | 19 | 24（含 L2-12 拆分 6 条） | 0 |
| L3 | 5 | 5 | 0 |
| **合计** | **29** | **34** | **1** |

### 执行方式分布

| 方式 | 用例数 | 测试点 |
|------|--------|--------|
| mano-cua | 28 | L1-01~03, L2-01~17, L3-01~04 |
| browser API | 3 | L1-05, L2-18, L2-19 |
| mano-cua + Pre-flight browser API | 1 | L3-05 |
| BLOCKED | 1 | L1-04 |
| 不含 L1-04 的可执行用例 | **33** | — |

### BVA 用例统计（D1 覆盖率）

| 字段 | BVA 用例数 | mosstid |
|------|-----------|---------|
| 正文字号（14-18px） | 1 | L2-12-005 |
| 行间距（1.5-2.5） | 1 | L2-12-006 |

> **说明：** range slider 由 HTML min/max 属性约束，无法通过 UI 输入超出范围的值，因此无效边界 BVA 不适用。每条 BVA 用例在一次 session 中同时测试 min 和 max 有效边界。

---

## 10. 文件目录

```
test/
├── TEST-CASE.md                          ← 本文档
├── fixtures/
│   └── md2wechat/
│       ├── headings.md                   ← h1-h6 标题
│       ├── text-formatting.md            ← 加粗/斜体/删除线
│       ├── lists.md                      ← 有序/无序列表
│       ├── blockquote.md                 ← 引用块
│       ├── code-blocks.md                ← 代码块（JS + Python）
│       ├── inline-code.md                ← 行内代码
│       ├── image.md                      ← 图片
│       ├── links.md                      ← 链接（脚注化）
│       ├── table.md                      ← 表格
│       └── realtime-input.md             ← 实时预览参考内容
└── scripts/
    ├── inject-fixture.sh                 ← fixture 注入脚本
    └── clear-state.sh                    ← localStorage 清除脚本
```
