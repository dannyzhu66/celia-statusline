$ErrorActionPreference = 'SilentlyContinue'
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$input_raw = [Console]::In.ReadToEnd()
$data = $input_raw | ConvertFrom-Json

$esc = [char]27
$reset = "$esc[0m"
$sep = " $esc[90m|$esc[0m "

$ctx_pct = $data.context_window.used_percentage
$five_pct = $data.rate_limits.five_hour.used_percentage
$five_resets_at = $data.rate_limits.five_hour.resets_at
$duration_ms = $data.cost.total_duration_ms
$session_name = $data.session_name
$transcript_path = $data.transcript_path

$term_width = 0
if ($data.terminal -and $data.terminal.width) { $term_width = [int]$data.terminal.width }
if ($term_width -le 0) {
    try { $term_width = [int]$Host.UI.RawUI.WindowSize.Width } catch {}
}
if ($term_width -le 0) { $term_width = 120 }

function Get-VisibleWidth($s) {
    $s2 = $s -replace "$([char]27)\[[0-9;]*m", ''
    $w = 0
    $chars = $s2.ToCharArray()
    for ($i = 0; $i -lt $chars.Length; $i++) {
        $c = $chars[$i]
        $code = [int]$c
        if ($code -ge 0xD800 -and $code -le 0xDBFF -and ($i + 1) -lt $chars.Length) {
            $w += 2; $i++; continue
        }
        if (($code -ge 0x1100 -and $code -le 0x115F) -or
            ($code -ge 0x2E80 -and $code -le 0x303E) -or
            ($code -ge 0x3041 -and $code -le 0x33FF) -or
            ($code -ge 0x3400 -and $code -le 0x4DBF) -or
            ($code -ge 0x4E00 -and $code -le 0x9FFF) -or
            ($code -ge 0xA000 -and $code -le 0xA4CF) -or
            ($code -ge 0xAC00 -and $code -le 0xD7A3) -or
            ($code -ge 0xF900 -and $code -le 0xFAFF) -or
            ($code -ge 0xFE30 -and $code -le 0xFE4F) -or
            ($code -ge 0xFF00 -and $code -le 0xFF60) -or
            ($code -ge 0xFFE0 -and $code -le 0xFFE6) -or
            ($code -eq 0x231B) -or ($code -eq 0x23F1) -or
            ($code -ge 0x2600 -and $code -le 0x27BF)) {
            $w += 2
        } else {
            $w += 1
        }
    }
    return $w
}

function Fmt-Tokens($n) {
    if ($n -ge 1000000) {
        $v = [math]::Round($n / 1000000.0, 1)
        if ($v -eq [math]::Floor($v)) { return "$([int]$v)M" }
        return ('{0:N1}M' -f $v)
    }
    if ($n -ge 1000) { return ('{0}K' -f [math]::Round($n / 1000.0)) }
    return [string]$n
}

function Build-Bar($pct, $len, $base_color) {
    if ($null -eq $pct) { return $null }
    $color = if ($pct -ge 80) { "$esc[0;31m" }
             elseif (-not $base_color) {
                 if ($pct -ge 50) { "$esc[0;33m" } else { "$esc[0;94m" }
             } else { $base_color }
    $filled = [int][math]::Round($pct / 100.0 * $len)
    if ($pct -gt 0 -and $filled -eq 0) { $filled = 1 }
    if ($filled -gt $len) { $filled = $len }
    $bar = ('█' * $filled) + ('░' * ($len - $filled))
    return "$color$bar $([int][math]::Round($pct))%$reset"
}

$dark_green = "$esc[0;32m"
$dark_blue = "$esc[0;34m"

$five_part = ''
if ($null -ne $five_pct) {
    $bar = Build-Bar $five_pct 6 $dark_green
    $reset_str = ''
    if ($five_resets_at) {
        $resets_dt = [datetimeoffset]::FromUnixTimeSeconds([int64]$five_resets_at).LocalDateTime
        $h12 = $resets_dt.Hour % 12
        if ($h12 -eq 0) { $h12 = 12 }
        $ampm = if ($resets_dt.Hour -ge 12) { 'pm' } else { 'am' }
        $time_str = "$ampm ${h12}:$('{0:D2}' -f $resets_dt.Minute)"
        $reset_str = " $dark_green(↻ $time_str)$reset"
    }
    $five_part = "⏳ $bar$reset_str"
}

$ctx_part = ''
if ($null -ne $ctx_pct) {
    $bar = Build-Bar $ctx_pct 6 $dark_blue
    $ctx_part = "🧠 $bar"
}

$dur_part = ''
if ($null -ne $duration_ms) {
    $total_sec = [int][math]::Floor($duration_ms / 1000)
    $m = [int][math]::Floor($total_sec / 60)
    $s = $total_sec % 60
    $dur_str = if ($m -gt 0) { "${m}m ${s}s" } else { "${s}s" }
    $dur_part = "$esc[0;37m⏱ $dur_str$reset"
}

$gold = "$esc[38;2;255;215;0m"
$title_part = if ($session_name) {
    "$gold📌 $session_name$reset"
} else {
    "$esc[90m📌 (未命名)$reset"
}

$right_parts = @($five_part, $ctx_part, $dur_part) | Where-Object { $_ }
$right = $right_parts -join $sep

$left_w = Get-VisibleWidth $title_part
$right_w = Get-VisibleWidth $right
$pad_w = $term_width - $left_w - $right_w - 10
if ($pad_w -lt 1) { $pad_w = 1 }
$pad = ' ' * $pad_w

$line1 = "$title_part$pad$right"

$line2 = ''
if ($transcript_path -and (Test-Path $transcript_path)) {
    $tail = Get-Content -LiteralPath $transcript_path -Tail 300 -Encoding UTF8
    for ($i = $tail.Count - 1; $i -ge 0; $i--) {
        $line = $tail[$i]
        if (-not $line) { continue }
        try { $obj = $line | ConvertFrom-Json } catch { continue }
        if ($obj.type -ne 'user') { continue }
        $content = $obj.message.content
        $text = $null
        if ($content -is [string]) {
            $text = $content
        } elseif ($content -is [array]) {
            foreach ($c in $content) {
                if ($c.type -eq 'text' -and $c.text) { $text = $c.text; break }
            }
        }
        if (-not $text) { continue }
        if ($text -match '^<.*?>' -or $text -match 'tool_result') { continue }
        $text = ($text -replace '\r?\n', ' ').Trim()
        if ($text.Length -gt 60) { $text = $text.Substring(0, 60) + '…' }
        $line2 = "$esc[90m» $text$reset"
        break
    }
}

if ($line2) { "$line1`n$line2" } else { $line1 }
