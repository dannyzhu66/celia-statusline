# celia-statusline 一键安装脚本
# 把 skill/ 复制到 ~/.claude/skills/celia-statusline/
# 注意：本脚本只装 skill 文件，不自动 patch settings.json
# 启用 statusline 需要跟 Claude Code 说"启用 celia statusline"由 AI 完成 settings 改动

$ErrorActionPreference = "Stop"

# === 源维护者守护 ===
$personaIdentity = Join-Path $env:USERPROFILE ".claude\personas\Celia\private\identity.md"
if (Test-Path $personaIdentity) {
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host "[GUARD] 检测到 Celia 人格目录 — 你是源维护者" -ForegroundColor Yellow
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host "不要在源维护者本机跑此脚本，否则会用团队版覆盖你的私人 skill。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "如果你确实需要装团队版自测，请明确加参数：.\INSTALL.ps1 -ForceSourceOwner" -ForegroundColor Yellow
    Write-Host ""
    if ($args -notcontains "-ForceSourceOwner") {
        exit 0
    }
    Write-Host "[INFO] -ForceSourceOwner 参数已传入，继续安装..." -ForegroundColor Cyan
}

$srcRoot = Join-Path $PSScriptRoot "skill"
$dstRoot = Join-Path $env:USERPROFILE ".claude\skills\celia-statusline"

if (-not (Test-Path $srcRoot)) {
    Write-Host "[ERROR] 源目录不存在: $srcRoot" -ForegroundColor Red
    Write-Host "请确认你在 program/Docs/celia-statusline/ 下运行本脚本，且已 P4 sync 拉到最新。" -ForegroundColor Yellow
    exit 1
}

# 检查 pwsh 可用性
$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
if (-not $pwshCmd) {
    Write-Host "[ERROR] 未检测到 PowerShell 7（pwsh）。本 skill 依赖 pwsh，请先安装：" -ForegroundColor Red
    Write-Host "  winget install Microsoft.PowerShell" -ForegroundColor Yellow
    exit 1
}

# 目标目录已存在则先清空（避免 stale 文件残留）
if (Test-Path $dstRoot) {
    Remove-Item $dstRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $dstRoot -Force | Out-Null

# 复制 skill/* 到目标
Copy-Item -Path (Join-Path $srcRoot "*") -Destination $dstRoot -Recurse -Force

# 写已安装版本号（未来加自动更新检测时用）
$versionSrc = Join-Path $PSScriptRoot "VERSION.txt"
if (Test-Path $versionSrc) {
    Copy-Item -Path $versionSrc -Destination (Join-Path $dstRoot ".installed_version") -Force
    $ver = (Get-Content $versionSrc -Raw).Trim()
    Write-Host "[OK] celia-statusline 安装完成（$ver）" -ForegroundColor Green
} else {
    Write-Host "[OK] celia-statusline 安装完成" -ForegroundColor Green
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "下一步：跟 Claude Code 说'启用 celia statusline'" -ForegroundColor Cyan
Write-Host "AI 会按 SKILL.md 走最后一步——patch ~/.claude/settings.json 的 statusLine 字段。" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
