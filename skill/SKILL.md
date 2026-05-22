---
name: celia-statusline
description: 安装、自定义、卸载 Celia 版 Claude Code 状态栏（双行，金色标题 + 📌、5h 配额进度 ⏳、上下文进度 🧠、总耗时 ⏱、上次输入回显）。当用户说"安装 celia 状态栏 / 装个 statusline / 用 celia 的状态栏 / 卸载状态栏"时使用。
---

# celia-statusline — Celia 版 Claude Code 状态栏

把 Celia 调教过的两行 statusline 装到当前用户的 Claude Code。

## 效果预览

```
📌 安装状态栏           ⏳ █░░░░░ 10% (↻ pm 3:50) | 🧠 █░░░░░ 13% | ⏱ 45m 11s
» 上一次你说的话…
```

**第一行（左→右）**
- 📌 对话标题（金色 `#FFD700`，CC `/rename` 后的名字；未命名时灰色 `(未命名)`）
- ⏳ 5 小时滚动配额进度条 + 百分比 + 重置时间（暗绿，`(↻ pm 3:50)` 显示本地重置时刻）
- 🧠 上下文窗口已用进度条 + 百分比（暗蓝）
- ⏱ 本对话累计耗时（白）
- 三个段之间用灰色 `|` 分隔
- 任一进度 ≥ 80% 强制红色覆盖主色作为临界警示

**第二行**
- » 上次用户真实输入回显（灰色，单行截 60 字超长打 `…`），多窗口切回来一眼想起进度

## 安装步骤（AI 执行）

> 前提：用户已运行 Claude Code 至少一次（即存在 `~/.claude/settings.json`）。Windows + PowerShell 7 环境。

**Step 1 — 探测环境**
- 用 Bash/PowerShell 拿到用户 `$HOME` 绝对路径（Windows 即 `C:\Users\<name>`）
- 确认 `pwsh -v` 可用（PowerShell 7+）；不可用时停止并指引用户先装 PowerShell 7
- 确认 `~/.claude/skills/celia-statusline/assets/statusline.ps1` 存在（这个文件随 skill 一起到位的）

**Step 2 — 备份并 patch `~/.claude/settings.json`**

读 `~/.claude/settings.json`，把 `statusLine` 字段设为：

```json
"statusLine": {
  "type": "command",
  "command": "pwsh -NoProfile -File <绝对路径>/.claude/skills/celia-statusline/assets/statusline.ps1"
}
```

`<绝对路径>` 替换为用户实际 `$HOME` 的正斜杠形式（如 `C:/Users/<your_name>`）。

**关键纪律**：
- 用 Read 工具读现有 settings.json，用 Edit 工具替换 `statusLine` 字段
- 不要覆盖其他字段（hooks/env/model/permissions 等都保留）
- 如果 settings.json 没有 `statusLine` 字段，直接在 JSON 末尾插入（注意逗号语法）
- patch 前提示用户："即将修改 settings.json 的 statusLine 字段，其他字段保留"

**Step 3 — 验证**

执行：

```powershell
echo '{"context_window":{"used_percentage":13},"rate_limits":{"five_hour":{"used_percentage":10,"resets_at":1779436200}},"cost":{"total_duration_ms":2711335},"session_name":"测试","terminal":{"width":120},"model":{"id":"claude-opus-4-7"}}' | pwsh -NoProfile -File <绝对路径>/.claude/skills/celia-statusline/assets/statusline.ps1
```

应输出两行带 ANSI 颜色的状态栏。无报错即成功，下次 CC turn 自动刷新生效。

## 自定义

打开 `~/.claude/skills/celia-statusline/assets/statusline.ps1`，搜以下 token 改：

| 想改什么 | 搜 | 改成 |
|------|-----|------|
| 标题颜色 | `$gold = "$esc[38;2;255;215;0m"` | RGB 三元组改成你要的（如银色 `192;192;192`） |
| 5h 配额主色 | `$dark_green = "$esc[0;32m"` | 任何 ANSI 颜色码 |
| ctx 主色 | `$dark_blue = "$esc[0;34m"` | 同上 |
| icon | `⏳ / 🧠 / 📌 / ⏱` | 任意 emoji |
| 上次输入截断长度 | `Substring(0, 60)` | 改 60 为别的 |
| 右部 padding 微调 | `$term_width - $left_w - $right_w - 10` | 改 `10` 为别的 |
| 临界红色阈值 | `if ($pct -ge 80)` | 改 80 |

## 已知限制

- **Windows + PowerShell 7 only**：依赖 `pwsh` 二进制。Mac/Linux 用户需要自己改写成 bash + jq 版本。
- **按 Claude Max + Opus 1M 配置**：`rate_limits.five_hour` 字段仅 Max 订阅有；非 Max 用户 ⏳ 那块会自动消失（脚本判 null 跳过）。
- **CC statusline 是事件驱动刷新**，不是定时——所以 ⏱ 总耗时实际是 turn 完成时的快照，离开期间不会自己涨。这是 CC TUI 框架限制，不是 bug。
- **上次输入回显需要 `transcript_path`** 字段（CC v2.1+ 默认带）；老版本 CC 不会有第二行。
- **金色 `#FFD700` 用 truecolor `\e[38;2;...m`**，老终端可能 fallback 成黄色。Windows Terminal / CC TUI 都支持。

## 卸载步骤

1. 删 `~/.claude/skills/celia-statusline/` 整个目录
2. Edit `~/.claude/settings.json`，删除 `statusLine` 字段（连同它的逗号）

不会留任何残留——脚本自包含在 skill 目录里。

## 触发场景示例

| 用户说 | AI 执行 |
|------|------|
| "装个 celia 状态栏" / "安装 celia statusline" | 走完整安装流程 |
| "状态栏长啥样" / "celia statusline 是什么" | 给"效果预览"段落 |
| "我想改进度条颜色" | 给"自定义"段落对应行 |
| "卸载状态栏" / "去掉这个状态栏" | 走卸载步骤 |
