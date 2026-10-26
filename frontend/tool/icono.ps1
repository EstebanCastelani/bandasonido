# Dibuja el ícono de la app (barras de sonido con degradé cian -> violeta).
# Genera assets/icon/icon.png (completo) e icon_foreground.png (solo las barras,
# con margen para el ícono adaptable de Android). Luego:
#   dart run flutter_launcher_icons
Add-Type -AssemblyName System.Drawing
$dir = Join-Path $PSScriptRoot '..\assets\icon'
New-Item -ItemType Directory -Force $dir | Out-Null

# alturas relativas de las 7 barras (de la imagen original)
$alturas = 0.22, 0.48, 0.64, 0.84, 0.64, 0.48, 0.22

function Dibujar([string]$ruta, [bool]$conFondo, [double]$escala) {
  $n = 1024
  $bmp = New-Object System.Drawing.Bitmap $n, $n
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.Clear([System.Drawing.Color]::Transparent)
  if ($conFondo) {
    $rect = New-Object System.Drawing.Rectangle 0, 0, $n, $n
    $fondo = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(255, 14, 12, 40)), ([System.Drawing.Color]::FromArgb(255, 8, 10, 28)), 90
    $g.FillRectangle($fondo, $rect)
    # resplandor suave detrás de las barras
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse(100, 220, 824, 584)
    $glow = New-Object System.Drawing.Drawing2D.PathGradientBrush $path
    $glow.CenterColor = [System.Drawing.Color]::FromArgb(70, 80, 120, 255)
    $glow.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 80, 120, 255))
    $g.FillPath($glow, $path)
  }
  $ancho = 78 * $escala
  $sep = 118 * $escala
  $alto = 760 * $escala
  $x0 = ($n - ($sep * 6 + $ancho)) / 2
  for ($i = 0; $i -lt 7; $i++) {
    $h = $alto * $alturas[$i]
    $x = $x0 + $i * $sep
    $y = ($n - $h) / 2
    $barra = New-Object System.Drawing.RectangleF $x, $y, $ancho, $h
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $r = $ancho
    $p.AddArc($x, $y, $r, $r, 180, 180)
    $p.AddArc($x, $y + $h - $r, $r, $r, 0, 180)
    $p.CloseFigure()
    $pincel = New-Object System.Drawing.Drawing2D.LinearGradientBrush $barra, ([System.Drawing.Color]::FromArgb(255, 56, 210, 255)), ([System.Drawing.Color]::FromArgb(255, 168, 85, 247)), 90
    $g.FillPath($pincel, $p)
  }
  $g.Dispose()
  $bmp.Save($ruta, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

Dibujar (Join-Path $dir 'icon.png') $true 1.0
Dibujar (Join-Path $dir 'icon_foreground.png') $false 0.78
"ok"
