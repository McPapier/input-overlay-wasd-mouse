# Regenerates keyboard/ and mouse/ presets for Input Overlay 5.1+.
# Keys are taken from keyboard-layout.txt in the repo root.
# Usage (from the repo folder), or just double-click make-presets.bat:
#   powershell -ExecutionPolicy Bypass -File tools\make-presets.ps1
#   powershell -ExecutionPolicy Bypass -File tools\make-presets.ps1 -Accent "#FF4FA3"
param(
  [string]$Accent = "#00E5FF",
  [string]$Root = (Split-Path $PSScriptRoot -Parent),
  [string]$Layout = ""
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
if (-not $Layout) { $Layout = Join-Path $Root 'keyboard-layout.txt' }
$KbOut = Join-Path $Root 'keyboard'; $MsOut = Join-Path $Root 'mouse'
New-Item -ItemType Directory -Force $KbOut, $MsOut | Out-Null

$cCap    = [Drawing.Color]::FromArgb(222, 28, 30, 38)
$cEdge   = [Drawing.Color]::FromArgb(170, 0, 0, 0)
$cText   = [Drawing.Color]::FromArgb(255, 233, 236, 243)
$cAccent = [Drawing.ColorTranslator]::FromHtml($Accent)
$cPText  = [Drawing.Color]::FromArgb(255, 21, 22, 28)
$cWheel  = [Drawing.Color]::FromArgb(200, 110, 112, 128)
$cDot    = [Drawing.Color]::FromArgb(255, 233, 236, 243)
$B = 3   # gap between normal and pressed state (Input Overlay convention)
$Utf8 = New-Object Text.UTF8Encoding $false

function RoundRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$tl, [float]$tr, [float]$br, [float]$bl) {
  $p = New-Object Drawing.Drawing2D.GraphicsPath
  if ($tl -gt 0) { $p.AddArc($x, $y, 2*$tl, 2*$tl, 180, 90) } else { $p.AddLine($x, $y, $x, $y) }
  if ($tr -gt 0) { $p.AddArc($x+$w-2*$tr, $y, 2*$tr, 2*$tr, 270, 90) } else { $p.AddLine($x+$w, $y, $x+$w, $y) }
  if ($br -gt 0) { $p.AddArc($x+$w-2*$br, $y+$h-2*$br, 2*$br, 2*$br, 0, 90) } else { $p.AddLine($x+$w, $y+$h, $x+$w, $y+$h) }
  if ($bl -gt 0) { $p.AddArc($x, $y+$h-2*$bl, 2*$bl, 2*$bl, 90, 90) } else { $p.AddLine($x, $y+$h, $x, $y+$h) }
  $p.CloseFigure(); return $p
}
function NewG($bmp) {
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'; $g.Clear([Drawing.Color]::Transparent)
  return $g
}
function Fill($g, $path, $color) { $b = New-Object Drawing.SolidBrush $color; $g.FillPath($b, $path); $b.Dispose() }
$sf = New-Object Drawing.StringFormat; $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'

# ================= KEY TABLE =================
# name -> @(Input Overlay 5.1+ (libuiohook) key code, label)
$KeyTable = @{
  'ESC'=@(0x01,'ESC'); 'TAB'=@(0x2e,'TAB'); 'CAPS'=@(0x2f,'CAPS'); 'ENTER'=@(0x4f,'ENTER')
  'BACKSPACE'=@(0x2d,'BKSP'); 'SPACE'=@(0x53,'SPACE')
  'SHIFT'=@(0x90,'SHIFT'); 'RSHIFT'=@(0x91,'SHIFT'); 'CTRL'=@(0x92,'CTRL'); 'RCTRL'=@(0x93,'CTRL')
  'ALT'=@(0x94,'ALT'); 'RALT'=@(0x95,'ALT'); 'WIN'=@(0x96,'WIN')
  'INS'=@(0x65,'INS'); 'DEL'=@(0x66,'DEL'); 'HOME'=@(0x67,'HOME'); 'END'=@(0x68,'END')
  'PGUP'=@(0x69,'PGUP'); 'PGDN'=@(0x6a,'PGDN')
  'UP'=@(0x6b,[string][char]0x2191); 'LEFT'=@(0x6c,[string][char]0x2190)
  'RIGHT'=@(0x6d,[string][char]0x2192); 'DOWN'=@(0x6e,[string][char]0x2193)
  '`'=@(0x20,'`'); '-'=@(0x2b,'-'); '='=@(0x2c,'='); '['=@(0x4a,'['); ']'=@(0x4b,']'); '\'=@(0x4c,'\')
  ';'=@(0x4d,';'); "'"=@(0x4e,"'"); ','=@(0x50,','); '.'=@(0x51,'.'); '/'=@(0x52,'/')
  'NUM/'=@(0x7c,'/'); 'NUM*'=@(0x7d,'*'); 'NUM-'=@(0x7e,'-'); 'NUM+'=@(0x80,'+'); 'NUMENTER'=@(0x81,'ENTER')
}
for ($i = 0; $i -lt 26; $i++) { $c = [string][char](65 + $i); $KeyTable[$c] = @((0x30 + $i), $c) }
for ($i = 1; $i -le 9; $i++) { $KeyTable["$i"] = @((0x20 + $i), "$i"); $KeyTable["NUM$i"] = @((0x70 + $i), "$i") }
$KeyTable['0'] = @(0x2a, '0'); $KeyTable['NUM0'] = @(0x7a, '0')
for ($i = 1; $i -le 24; $i++) { $KeyTable["F$i"] = @((0x01 + $i), "F$i") }

# ================= KEYBOARD =================
$U = 64; $D = 5; $GAP = 8; $H = $U + $D; $R = 12
if (-not (Test-Path $Layout)) { throw "Layout file not found: $Layout" }
$keys = @(); $row = 0; $maxW = 0; $bad = @()
foreach ($line in (Get-Content -LiteralPath $Layout -Encoding UTF8)) {
  $t = $line.Trim()
  if (-not $t -or $t.StartsWith('#')) { continue }
  $x = 0.0
  foreach ($tok in ($t -split '\s+')) {
    $name = $tok; $units = 1.0
    if ($tok -match '^(.+)\*([0-9]+(?:[.,][0-9]+)?)$') { $name = $matches[1]; $units = [double]($matches[2] -replace ',', '.') }
    $w = [int][Math]::Round($units * $U + ($units - 1) * $GAP)
    if ($name -ne '_') {
      $k = $KeyTable[$name.ToUpper()]
      if (-not $k) { $bad += $tok }
      else { $keys += @{ name = $name.ToUpper(); code = $k[0]; label = $k[1]; w = $w; x = [int]$x; y = $row * ($H + $GAP) } }
    }
    $x += $w + $GAP
  }
  $maxW = [Math]::Max($maxW, $x - $GAP); $row++
}
if ($bad.Count) { throw ("Unknown keys in layout: " + ($bad -join ', ')) }
if (-not $keys.Count) { throw "Layout is empty" }

$texW = 1; foreach ($k in $keys) { $texW += $k.w + $B }
$texH = 1 + $H + $B + $H + 1
$bmp = New-Object Drawing.Bitmap $texW, $texH
$g = NewG $bmp

function KeyFont($g, [string]$label, [float]$w) {
  $size = if ($label.Length -gt 1 -and $label -notmatch '^F\d+$') { 14 } else { 21 }
  if ($label -match '^F\d+$') { $size = 18 }
  while ($size -gt 8) {
    $f = New-Object Drawing.Font 'Segoe UI', $size, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
    if ($g.MeasureString($label, $f).Width -le ($w - 8)) { return $f }
    $f.Dispose(); $size--
  }
  return (New-Object Drawing.Font 'Segoe UI', 8, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel))
}
function DrawKey($g, [float]$x, [float]$y, [float]$w, [bool]$pressed, [string]$label) {
  $off = if ($pressed) { 4 } else { 0 }
  Fill $g (RoundRect $x ($y + $off + 1) $w ($U - 1 + $D - $off) $R $R $R $R) $cEdge
  Fill $g (RoundRect $x ($y + $off) $w $U $R $R $R $R) $(if ($pressed) { $cAccent } else { $cCap })
  $font = KeyFont $g $label $w
  $tb = New-Object Drawing.SolidBrush $(if ($pressed) { $cPText } else { $cText })
  $g.DrawString($label, $font, $tb, (New-Object Drawing.RectangleF $x, ($y + $off), $w, $U), $sf)
  $tb.Dispose(); $font.Dispose()
}

$elements = @(); $tx = 1; $ids = @{}
foreach ($k in $keys) {
  DrawKey $g $tx 1 $k.w $false $k.label
  DrawKey $g $tx (1 + $H + $B) $k.w $true $k.label
  $id = $k.name.ToLower(); if ($ids[$id]) { $ids[$id]++; $id = "$id$($ids[$id])" } else { $ids[$id] = 1 }
  $elements += [ordered]@{ code = $k.code; id = $id; mapping = @($tx, 1, $k.w, $H); pos = @($k.x, $k.y); type = 1; z_level = 1 }
  $tx += $k.w + $B
}
$g.Dispose()
$bmp.Save((Join-Path $KbOut 'keys.png'), [Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
$cfg = [ordered]@{
  default_height = $H; default_width = $U; elements = $elements; flags = 0
  overlay_height = ($row * ($H + $GAP) - $GAP); overlay_width = [int]$maxW
  space_h = 0; space_v = 0; version = 508
}
[IO.File]::WriteAllText((Join-Path $KbOut 'keys.json'), ($cfg | ConvertTo-Json -Depth 5), $Utf8)

# ================= MOUSE =================
$MW = 120; $BW = 59; $BH = 76; $BODYH = 108; $MR = 58
$WW = 20; $WH = 40
$DOT = 14; $AREA = 64
$xL = 1; $xR = $xL + $BW + $B; $xBody = $xR + $BW + $B; $xWheel = $xBody + $MW + $B
$xDot = $xWheel + 4 * ($WW + $B); $xArea = $xDot + $DOT + $B
$texW = $xArea + $AREA + 2
$texH = [Math]::Max(1 + $BH + $B + $BH + 1, 1 + $BODYH + 1)
$bmp = New-Object Drawing.Bitmap $texW, $texH
$g = NewG $bmp
$lab = New-Object Drawing.Font 'Segoe UI', 13, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)

function DrawBtn($g, [float]$x, [float]$y, [bool]$left, [bool]$pressed) {
  $p = if ($left) { RoundRect $x $y $BW $BH $MR 4 0 0 } else { RoundRect $x $y $BW $BH 4 $MR 0 0 }
  Fill $g $p $(if ($pressed) { $cAccent } else { $cCap })
  $tb = New-Object Drawing.SolidBrush $(if ($pressed) { $cPText } else { [Drawing.Color]::FromArgb(150, 233, 236, 243) })
  $t = if ($left) { 'L' } else { 'R' }
  $tx = if ($left) { $x + 10 } else { $x + $BW - 26 }
  $g.DrawString($t, $lab, $tb, (New-Object Drawing.RectangleF $tx, ($y + $BH - 26), 16, 18), $sf)
  $tb.Dispose()
}
DrawBtn $g $xL 1 $true $false;  DrawBtn $g $xL (1 + $BH + $B) $true $true
DrawBtn $g $xR 1 $false $false; DrawBtn $g $xR (1 + $BH + $B) $false $true

# body (lower part of the mouse)
Fill $g (RoundRect $xBody 1 $MW $BODYH 4 4 $MR $MR) $cCap

# wheel states: idle / pressed / scroll up / scroll down
for ($i = 0; $i -lt 4; $i++) {
  $wx = $xWheel + $i * ($WW + $B)
  Fill $g (RoundRect $wx 1 $WW $WH 10 10 10 10) $(if ($i -eq 1) { $cAccent } else { $cWheel })
  if ($i -eq 2) { Fill $g (RoundRect $wx 1 $WW ($WH / 2) 10 10 0 0) $cAccent }
  if ($i -eq 3) { Fill $g (RoundRect $wx (1 + $WH / 2) $WW ($WH / 2) 0 0 10 10) $cAccent }
}
# movement dot (its area texture stays transparent)
$dotB = New-Object Drawing.SolidBrush $cDot
$g.FillEllipse($dotB, $xDot, 1, $DOT, $DOT); $dotB.Dispose()
$g.Dispose()
$bmp.Save((Join-Path $MsOut 'mouse.png'), [Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()

$bodyY = $BH + 2
$els = @(
  [ordered]@{ id = 'body'; mapping = @($xBody, 1, $MW, $BODYH); pos = @(0, $bodyY); type = 0; z_level = 0 },
  [ordered]@{ code = 1; id = 'lmb'; mapping = @($xL, 1, $BW, $BH); pos = @(0, 0); type = 3; z_level = 1 },
  [ordered]@{ code = 2; id = 'rmb'; mapping = @($xR, 1, $BW, $BH); pos = @(($MW - $BW), 0); type = 3; z_level = 1 },
  [ordered]@{ id = 'wheel'; mapping = @($xWheel, 1, $WW, $WH); pos = @([int](($MW - $WW) / 2), 18); type = 4; z_level = 2 },
  [ordered]@{ id = 'area'; mapping = @($xArea, 1, $AREA, $AREA); pos = @([int](($MW - $AREA) / 2), [int]($bodyY + ($BODYH - $AREA) / 2)); type = 0; z_level = 1 },
  [ordered]@{ id = 'dot'; mapping = @($xDot, 1, $DOT, $DOT); mouse_radius = 26; mouse_type = 0; pos = @([int](($MW - $DOT) / 2), [int]($bodyY + ($BODYH - $DOT) / 2)); type = 9; z_level = 2 }
)
$cfg = [ordered]@{
  default_height = 0; default_width = 0; elements = $els; flags = 8
  overlay_height = ($bodyY + $BODYH); overlay_width = $MW
  space_h = 0; space_v = 0; version = 508
}
[IO.File]::WriteAllText((Join-Path $MsOut 'mouse.json'), ($cfg | ConvertTo-Json -Depth 5), $Utf8)
"Done: $($keys.Count) keys -> $KbOut\keys.png + keys.json; mouse -> $MsOut"
