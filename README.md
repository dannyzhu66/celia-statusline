# celia-statusline — Claude Code 双行状态栏

Celia 调教过的 Claude Code statusline，金色标题 + 进度条配额 + 上次输入回显，多窗操作切回来一眼想起进度。

## 效果

```
📌 对话标题           ⏳ █░░░░░ 10% (↻ pm 3:50) | 🧠 █░░░░░ 13% | ⏱ 45m 11s
» 上一次你说的话…
```

- 📌 标题（金色）
- ⏳ 5h 滚动配额（暗绿 + 重置时间）
- 🧠 上下文窗口（暗蓝）
- ⏱ 本对话累计耗时
- » 第二行：上次用户真实输入截 60 字

## 安装

```powershell
git clone https://github.com/dannyzhu66/celia-statusline.git
cd celia-statusline
.\INSTALL.ps1
```

跑完 skill 文件就位，但 statusline **还未启用**（CC 不会自动 patch 你的 settings.json）。
跟 Claude Code 说："启用 celia statusline" / "装个状态栏" → AI 按 skill 内 SKILL.md 走完最后一步（改 settings.json statusLine 字段）。

## 自定义

跑装包后，改 `~/.claude/skills/celia-statusline/assets/statusline.ps1` 里的颜色/icon/截断长度——具体改哪行见 skill SKILL.md「自定义」段。

## 卸载

1. `~/.claude/skills/celia-statusline/` 整个删
2. 改 `~/.claude/settings.json` 删 `statusLine` 字段（连同逗号）

## 已知限制

- **Windows + PowerShell 7 only**（依赖 `pwsh`）
- **按 Claude Max 订阅配置**：`rate_limits.five_hour` 字段仅 Max 订阅返回，非 Max 用户 ⏳ 那段自动消失
- **CC statusline 是事件驱动刷新**（turn 完成时），⏱ 总耗时实际是 turn 结束时快照，离开期间不会自己涨——CC TUI 框架限制

## 维护

- **维护者**：Celia
- 改动需 bump VERSION.txt + 加 CHANGELOG 条目
- 源守护：维护者本机跑 INSTALL.ps1 会拦截，强制装传 `-ForceSourceOwner`
