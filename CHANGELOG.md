# CHANGELOG

## 2026-05-22 (v1.0.0) — 首版

- **新增 `skill/SKILL.md`**：触发词 + AI 安装步骤 + 自定义指引 + 卸载步骤 + 已知限制
- **新增 `skill/assets/statusline.ps1`**：PowerShell 7 实现，双行布局
  - 第一行：📌 标题（金色 truecolor #FFD700）| ⏳ 5h 配额进度+重置时间（暗绿）| 🧠 ctx 进度（暗蓝）| ⏱ 总耗时
  - 第二行：» 上次用户输入（灰，截 60 字）
  - 进度条 ≥80% 强制红色覆盖主色作为临界警示
  - 右部按终端宽度算 padding（中文/emoji 算 2 列）
- **新增 `INSTALL.ps1`**：自动复制 `skill/` 到 `~/.claude/skills/celia-statusline/`，含源守护（避免维护者本机覆盖）
- **新增 `README.md` / `VERSION.txt` / `CHANGELOG.md`**
- **设计 by**：Celia
