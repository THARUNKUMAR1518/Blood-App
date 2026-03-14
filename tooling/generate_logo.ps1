Add-Type -AssemblyName System.Drawing
[System.IO.Directory]::CreateDirectory('e:\Blood APP\blood_app\assets\images') | Out-Null
$size = 1024
$bmp = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

$red = [System.Drawing.Color]::FromArgb(229, 0, 0)
$darkRed = [System.Drawing.Color]::FromArgb(183, 28, 28)
$white = [System.Drawing.Color]::White

$dropBrush = New-Object System.Drawing.SolidBrush $red
$cutBrush = New-Object System.Drawing.SolidBrush $white
$plusBrush = New-Object System.Drawing.SolidBrush $darkRed

$drop = New-Object System.Drawing.Drawing2D.GraphicsPath
$drop.StartFigure()
$drop.AddBezier(520, 70, 760, 220, 900, 470, 790, 740)
$drop.AddBezier(790, 740, 705, 940, 470, 1010, 285, 920)
$drop.AddBezier(285, 920, 90, 820, 40, 560, 190, 340)
$drop.AddBezier(190, 340, 285, 200, 390, 120, 520, 70)
$drop.CloseFigure()
$g.FillPath($dropBrush, $drop)

$cut = New-Object System.Drawing.Drawing2D.GraphicsPath
$cut.StartFigure()
$cut.AddBezier(165, 395, 285, 335, 372, 360, 388, 462)
$cut.AddBezier(388, 462, 322, 510, 292, 580, 270, 640)
$cut.AddBezier(270, 640, 358, 654, 360, 736, 272, 758)
$cut.AddBezier(272, 758, 168, 734, 118, 614, 132, 505)
$cut.AddBezier(132, 505, 138, 448, 146, 420, 165, 395)
$cut.CloseFigure()
$g.FillPath($cutBrush, $cut)

$swooshPen = New-Object System.Drawing.Pen $white, 34
$swooshPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$swooshPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawArc($swooshPen, 430, 365, 300, 430, 15, 110)

$g.FillRectangle($plusBrush, 60, 235, 110, 34)
$g.FillRectangle($plusBrush, 98, 197, 34, 110)

$bmp.Save('e:\Blood APP\blood_app\assets\images\app_logo.png', [System.Drawing.Imaging.ImageFormat]::Png)

$swooshPen.Dispose()
$plusBrush.Dispose()
$cutBrush.Dispose()
$dropBrush.Dispose()
$drop.Dispose()
$cut.Dispose()
$g.Dispose()
$bmp.Dispose()
Write-Output 'Generated assets/images/app_logo.png'
