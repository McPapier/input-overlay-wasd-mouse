# Regenerates keyboard/ and mouse/ presets for Input Overlay 5.1+.
# Usage (from the repo folder):
#   powershell -ExecutionPolicy Bypass -File tools\make-presets.ps1
#   powershell -ExecutionPolicy Bypass -File tools\make-presets.ps1 -Accent "#FF4FA3"
param(
  [string]$Accent = "#00E5FF",
  [string]$Root = (Split-Path $PSScriptRoot -Parent)
)
Add-Type -AssemblyName System.Drawing
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

# ================= KEYBOARD =================
# Key codes are Input Overlay 5.1+ (libuiohook) codes.
$U = 64; $D = 5; $GAP = 8; $H = $U + $D; $R = 12
$keys = @(
  @{id='esc';   label='ESC';   code=1;   w=$U;  col=0; row=0},
  @{id='q';     label='Q';     code=64;  w=$U;  col=0; row=1},
  @{id='w';     label='W';     code=70;  w=$U;  col=1; row=1},
  @{id='e';     label='E';     code=52;  w=$U;  col=2; row=1},
  @{id='r';     label='R';     code=65;  w=$U;  col=3; row=1},
  @{id='a';     label='A';     code=48;  w=$U;  col=0; row=2},
  @{id='s';     label='S';     code=66;  w=$U;  col=1; row=2},
  @{id='d';     label='D';     code=51;  w=$U;  col=2; row=2},
  @{id='f';     label='F';     code=53;  w=$U;  col=3; row=2},
  @{id='shift'; label='SHIFT'; code=144; w=$U;  col=0; row=3},
  @{id='z';     label='Z';     code=73;  w=$U;  col=1; row=3},
  @{id='x';     label='X';     code=71;  w=$U;  col=2; row=3},
  @{id='c';     label='C';     code=50;  w=$U;  col=3; row=3},
  @{id='ctrl';  label='CTRL';  code=146; w=$U;  col=0; row=4},
  @{id='space'; label='SPACE'; code=83;  w=(3*$U + 2*$GAP); col=1; row=4}
)
$texW = 1; foreach ($k in $keys) { $texW += $k.w + $B }
$texH = 1 + $H + $B + $H + 1
$bmp = New-Object Drawing.Bitmap $texW, $texH
$g = NewG $bmp
$big   = New-Object Drawing.Font 'Segoe UI', 21, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$small = New-Object Drawing.Font 'Segoe UI', 14, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)

function DrawKey($g, [float]$x, [float]$y, [float]$w, [bool]$pressed, [string]$label) {
  $off = if ($pressed) { 4 } else { 0 }
  Fill $g (RoundRect $x ($y + $off + 1) $w ($U - 1 + $D - $off) $R $R $R $R) $cEdge
  Fill $g (RoundRect $x ($y + $off) $w $U $R $R $R $R) $(if ($pressed) { $cAccent } else { $cCap })
  $font = if ($label.Length -gt 1) { $small } else { $big }
  $tb = New-Object Drawing.SolidBrush $(if ($pressed) { $cPText } else { $cText })
  $g.DrawString($label, $font, $tb, (New-Object Drawing.RectangleF $x, ($y + $off), $w, $U), $sf)
  $tb.Dispose()
}

$elements = @(); $tx = 1
foreach ($k in $keys) {
  DrawKey $g $tx 1 $k.w $false $k.label
  DrawKey $g $tx (1 + $H + $B) $k.w $true $k.label
  $px = $k.col * ($U + $GAP); $py = $k.row * ($H + $GAP)
  $elements += [ordered]@{ code = $k.code; id = $k.id; mapping = @($tx, 1, $k.w, $H); pos = @($px, $py); type = 1; z_level = 1 }
  $tx += $k.w + $B
}
$g.Dispose()
$bmp.Save((Join-Path $KbOut 'keys.png'), [Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
$cfg = [ordered]@{
  default_height = $H; default_width = $U; elements = $elements; flags = 0
  overlay_height = (5 * $H + 4 * $GAP); overlay_width = (4 * $U + 3 * $GAP)
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
"Done: $KbOut, $MsOut"
