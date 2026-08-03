# ---------------------------------------------------------------------------
# marsky_shooter - varlik (asset) ureteci
#
# Neden bir betik: oyunun tum sprite ve ses dosyalari burada KOD ILE uretilir.
# Boylece (1) ucuncu parti telif/lisans sorunu olusmaz, tum varliklar ozgundur,
# (2) varliklar yeniden uretilebilir ve versiyonlanabilir, (3) inceleyen kisi
# gorsellerin nereden geldigini tek dosyada gorur.
#
# Kullanim (proje kokunden):
#   powershell -ExecutionPolicy Bypass -File tools\generate_assets.ps1
# ---------------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$OutputRoot = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# $PSScriptRoot param varsayilaninda guvenilir degil; burada hesapliyoruz.
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $OutputRoot = Join-Path (Split-Path -Parent $scriptDir) 'assets'
}
Write-Host ("Cikti koku: {0}" -f $OutputRoot)

$imagesDir = Join-Path $OutputRoot 'images'
$audioDir  = Join-Path $OutputRoot 'audio'
foreach ($d in @($imagesDir, $audioDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
}

# --------------------------------------------------------------- yardimcilar

function New-Canvas {
    param([int]$Width, [int]$Height)
    $bmp = New-Object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.Clear([System.Drawing.Color]::Transparent)
    return @{ Bitmap = $bmp; Graphics = $g }
}

function Save-Canvas {
    param($Canvas, [string]$Path)
    $Canvas.Graphics.Dispose()
    $Canvas.Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Canvas.Bitmap.Dispose()
    Write-Host ("  + {0}" -f (Split-Path $Path -Leaf))
}

function Get-Rgb {
    param([int]$R, [int]$G, [int]$B, [int]$A = 255)
    return [System.Drawing.Color]::FromArgb($A, $R, $G, $B)
}

function New-VerticalGradient {
    param([int]$Width, [int]$Height, $TopColor, $BottomColor)
    $rect = New-Object System.Drawing.RectangleF(0, 0, [float]$Width, [float]$Height)
    return New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $TopColor, $BottomColor, 90.0)
}

# 16-bit mono PCM WAV yazar.
function Write-Wav {
    param([string]$Path, [System.Collections.Generic.List[int]]$Samples, [int]$SampleRate = 44100)

    $dataBytes = $Samples.Count * 2
    $fs = [System.IO.File]::Create($Path)
    $bw = New-Object System.IO.BinaryWriter($fs)
    try {
        $bw.Write([System.Text.Encoding]::ASCII.GetBytes('RIFF'))
        $bw.Write([int](36 + $dataBytes))
        $bw.Write([System.Text.Encoding]::ASCII.GetBytes('WAVE'))
        $bw.Write([System.Text.Encoding]::ASCII.GetBytes('fmt '))
        $bw.Write([int]16)             # fmt chunk boyutu
        $bw.Write([int16]1)            # PCM
        $bw.Write([int16]1)            # mono
        $bw.Write([int]$SampleRate)
        $bw.Write([int]($SampleRate * 2))  # byte/saniye
        $bw.Write([int16]2)            # blok hizalama
        $bw.Write([int16]16)           # bit derinligi
        $bw.Write([System.Text.Encoding]::ASCII.GetBytes('data'))
        $bw.Write([int]$dataBytes)
        foreach ($s in $Samples) { $bw.Write([int16]$s) }
    }
    finally {
        $bw.Dispose()
        $fs.Dispose()
    }
    Write-Host ("  + {0} ({1} ornek)" -f (Split-Path $Path -Leaf), $Samples.Count)
}

function Convert-ToSample {
    param([double]$Value)
    # -1..1 arasini 16-bit tam sayiya cevirir, tasmayi kirpar (clipping).
    $v = [math]::Round($Value * 32000)
    if ($v -gt 32767) { $v = 32767 }
    if ($v -lt -32768) { $v = -32768 }
    return [int]$v
}

# ------------------------------------------------------------------ SPRITELAR

Write-Host 'Sprite uretiliyor...'

# --- oyuncu gemisi: yukari bakan, camgobegi govdeli ---
$c = New-Canvas -Width 96 -Height 96
[System.Drawing.PointF[]]$hull = @(
    (New-Object System.Drawing.PointF(48, 4)),
    (New-Object System.Drawing.PointF(80, 72)),
    (New-Object System.Drawing.PointF(58, 64)),
    (New-Object System.Drawing.PointF(48, 84)),
    (New-Object System.Drawing.PointF(38, 64)),
    (New-Object System.Drawing.PointF(16, 72))
)
$brush = New-VerticalGradient -Width 96 -Height 96 -TopColor (Get-Rgb 125 234 255) -BottomColor (Get-Rgb 12 96 140)
$pen = New-Object System.Drawing.Pen((Get-Rgb 6 32 48), 3.0)
$c.Graphics.FillPolygon($brush, $hull)
$c.Graphics.DrawPolygon($pen, $hull)
# kokpit
$cockpit = New-Object System.Drawing.Drawing2D.GraphicsPath
$cockpit.AddEllipse(38, 24, 20, 28)
$c.Graphics.FillPath((New-Object System.Drawing.SolidBrush((Get-Rgb 235 253 255))), $cockpit)
$c.Graphics.DrawPath((New-Object System.Drawing.Pen((Get-Rgb 6 32 48), 2.0)), $cockpit)
# motor parlamasi
$c.Graphics.FillEllipse((New-Object System.Drawing.SolidBrush((Get-Rgb 255 196 84 220))), 42, 74, 12, 16)
$brush.Dispose(); $pen.Dispose()
Save-Canvas -Canvas $c -Path (Join-Path $imagesDir 'player.png')

# --- dusman: asagi bakan, macenta govdeli ---
$c = New-Canvas -Width 80 -Height 80
[System.Drawing.PointF[]]$body = @(
    (New-Object System.Drawing.PointF(40, 76)),
    (New-Object System.Drawing.PointF(8, 22)),
    (New-Object System.Drawing.PointF(26, 32)),
    (New-Object System.Drawing.PointF(40, 6)),
    (New-Object System.Drawing.PointF(54, 32)),
    (New-Object System.Drawing.PointF(72, 22))
)
$brush = New-VerticalGradient -Width 80 -Height 80 -TopColor (Get-Rgb 255 118 196) -BottomColor (Get-Rgb 132 18 82)
$pen = New-Object System.Drawing.Pen((Get-Rgb 46 6 28), 3.0)
$c.Graphics.FillPolygon($brush, $body)
$c.Graphics.DrawPolygon($pen, $body)
$c.Graphics.FillEllipse((New-Object System.Drawing.SolidBrush((Get-Rgb 255 236 128))), 31, 30, 18, 18)
$c.Graphics.FillEllipse((New-Object System.Drawing.SolidBrush((Get-Rgb 46 6 28))), 36, 35, 8, 8)
$brush.Dispose(); $pen.Dispose()
Save-Canvas -Canvas $c -Path (Join-Path $imagesDir 'enemy.png')

# --- mermi: parlak kapsul ---
$c = New-Canvas -Width 16 -Height 40
$c.Graphics.FillEllipse((New-Object System.Drawing.SolidBrush((Get-Rgb 90 240 255 90))), 0, 0, 16, 40)
$c.Graphics.FillEllipse((New-Object System.Drawing.SolidBrush((Get-Rgb 160 250 255))), 4, 4, 8, 32)
$c.Graphics.FillEllipse((New-Object System.Drawing.SolidBrush((Get-Rgb 255 255 255))), 6, 10, 4, 18)
Save-Canvas -Canvas $c -Path (Join-Path $imagesDir 'bullet.png')

# --- toplanabilir: altin elmas ---
$c = New-Canvas -Width 48 -Height 48
[System.Drawing.PointF[]]$gem = @(
    (New-Object System.Drawing.PointF(24, 3)),
    (New-Object System.Drawing.PointF(45, 24)),
    (New-Object System.Drawing.PointF(24, 45)),
    (New-Object System.Drawing.PointF(3, 24))
)
$brush = New-VerticalGradient -Width 48 -Height 48 -TopColor (Get-Rgb 255 240 150) -BottomColor (Get-Rgb 214 142 12)
$pen = New-Object System.Drawing.Pen((Get-Rgb 82 50 4), 2.5)
$c.Graphics.FillPolygon($brush, $gem)
$c.Graphics.DrawPolygon($pen, $gem)
$brush.Dispose(); $pen.Dispose()
Save-Canvas -Canvas $c -Path (Join-Path $imagesDir 'pickup.png')

# --- yildiz alani: parallax icin DOSENEBILIR (tileable) katman ---
# Sabit tohum (seed) kullanilir: her uretimde ayni yildiz deseni cikar, boylece
# git diff'inde sebepsiz degisiklik olusmaz.
function New-StarLayer {
    param([int]$Size, [int]$StarCount, [int]$Seed, [int]$MaxRadius, [int]$Alpha)
    $c = New-Canvas -Width $Size -Height $Size
    $rnd = New-Object System.Random($Seed)
    for ($i = 0; $i -lt $StarCount; $i++) {
        $x = $rnd.Next(0, $Size)
        $y = $rnd.Next(0, $Size)
        $r = $rnd.Next(1, $MaxRadius + 1)
        $a = $rnd.Next([int]($Alpha * 0.45), $Alpha)
        $col = Get-Rgb 255 255 255 $a
        $c.Graphics.FillEllipse((New-Object System.Drawing.SolidBrush($col)), $x, $y, $r, $r)
        # Kenarlardan tasan yildizlari karsi kenara da ciz -> desen kusursuz doseneir.
        if ($x + $r -gt $Size) { $c.Graphics.FillEllipse((New-Object System.Drawing.SolidBrush($col)), $x - $Size, $y, $r, $r) }
        if ($y + $r -gt $Size) { $c.Graphics.FillEllipse((New-Object System.Drawing.SolidBrush($col)), $x, $y - $Size, $r, $r) }
    }
    return $c
}

Save-Canvas -Canvas (New-StarLayer -Size 256 -StarCount 90  -Seed 20260803 -MaxRadius 2 -Alpha 150) -Path (Join-Path $imagesDir 'stars_far.png')
Save-Canvas -Canvas (New-StarLayer -Size 256 -StarCount 40  -Seed 20260804 -MaxRadius 4 -Alpha 235) -Path (Join-Path $imagesDir 'stars_near.png')

# --------------------------------------------------------------------- SESLER

Write-Host 'Ses uretiliyor...'
$sr = 44100
$twoPi = [math]::PI * 2

# --- ates: hizli alcalan blip ---
$samples = New-Object 'System.Collections.Generic.List[int]'
$n = [int]($sr * 0.09)
$phase = 0.0
for ($i = 0; $i -lt $n; $i++) {
    $p = $i / $n
    $freq = 900.0 - (520.0 * $p)
    $phase += ($twoPi * $freq / $sr)   # frekans degisirken faz sicramasin diye faz biriktirilir
    $env = [math]::Exp(-9.0 * $p)
    $samples.Add((Convert-ToSample ([math]::Sin($phase) * 0.32 * $env)))
}
Write-Wav -Path (Join-Path $audioDir 'shoot.wav') -Samples $samples -SampleRate $sr

# --- patlama: sonumlenen beyaz gurultu + alcak gurultu ---
$samples = New-Object 'System.Collections.Generic.List[int]'
$n = [int]($sr * 0.38)
$rnd = New-Object System.Random(1337)
$phase = 0.0
$prev = 0.0
for ($i = 0; $i -lt $n; $i++) {
    $p = $i / $n
    $noise = ($rnd.NextDouble() * 2.0) - 1.0
    # basit alcak geciren filtre: tiz cizirtiyi yumusatir
    $prev = ($prev * 0.72) + ($noise * 0.28)
    $phase += ($twoPi * (70.0 - 30.0 * $p) / $sr)
    $rumble = [math]::Sin($phase) * 0.45
    $env = [math]::Exp(-6.5 * $p)
    $samples.Add((Convert-ToSample ((($prev * 1.4) + $rumble) * 0.5 * $env)))
}
Write-Wav -Path (Join-Path $audioDir 'explosion.wav') -Samples $samples -SampleRate $sr

# --- toplama: yukselen iki notali arpej ---
$samples = New-Object 'System.Collections.Generic.List[int]'
$n = [int]($sr * 0.16)
$phase = 0.0
for ($i = 0; $i -lt $n; $i++) {
    $p = $i / $n
    $freq = 660.0
    if ($p -gt 0.45) { $freq = 990.0 }
    $phase += ($twoPi * $freq / $sr)
    $env = [math]::Exp(-4.0 * $p)
    $samples.Add((Convert-ToSample ([math]::Sin($phase) * 0.28 * $env)))
}
Write-Wav -Path (Join-Path $audioDir 'pickup.wav') -Samples $samples -SampleRate $sr

Write-Host ''
Write-Host ('Bitti. Sprite: {0}  Ses: {1}' -f $imagesDir, $audioDir)
