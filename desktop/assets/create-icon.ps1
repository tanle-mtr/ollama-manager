# ============================================================
# Ollama Manager Icon Generator
# Creates modern AI-themed icon with gradient effects
# ============================================================

Add-Type -AssemblyName System.Drawing

# 创建不同尺寸的图标
$sizes = @(16, 32, 48, 64, 128, 256)

foreach ($size in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    
    # 计算参数
    $cx = $size / 2
    $cy = $size / 2
    $radius = $size * 0.42
    
    # 背景渐变 (深蓝到紫色)
    $bgBrush = New-Object System.Drawing.LinearGradientBrush(
        [System.Drawing.Rectangle]::FromLTRB(0, 0, $size, $size),
        [System.Drawing.Color]::FromArgb(30, 41, 59),
        [System.Drawing.Color]::FromArgb(15, 23, 42),
        45
    )
    $g.FillEllipse($bgBrush, ($size - $size * 0.84) / 2, ($size - $size * 0.84) / 2, $size * 0.84, $size * 0.84)
    
    # 外圈光环 (蓝色渐变)
    $ringBrush = New-Object System.Drawing.LinearGradientBrush(
        [System.Drawing.Rectangle]::FromLTRB(0, 0, $size, $size),
        [System.Drawing.Color]::FromArgb(88, 166, 255),
        [System.Drawing.Color]::FromArgb(163, 113, 247),
        135
    )
    $pen = New-Object System.Drawing.Pen($ringBrush, $size * 0.06)
    $g.DrawEllipse($pen, $cx - $radius, $cy - $radius, $radius * 2, $radius * 2)
    
    # 内圈光晕
    $innerRadius = $radius * 0.7
    $glowBrush = New-Object System.Drawing.LinearGradientBrush(
        [System.Drawing.Rectangle]::FromLTRB(0, 0, $size, $size),
        [System.Drawing.Color]::FromArgb(100, 180, 255, 0.3),
        [System.Drawing.Color]::FromArgb(150, 110, 240, 0.1),
        45
    )
    $g.FillEllipse($glowBrush, $cx - $innerRadius, $cy - $innerRadius, $innerRadius * 2, $innerRadius * 2)
    
    # 机器人头部 (简洁几何设计)
    $headSize = $size * 0.35
    $headX = $cx - $headSize / 2
    $headY = $cy - $headSize / 2 - $size * 0.05
    
    # 头部渐变
    $headBrush = New-Object System.Drawing.LinearGradientBrush(
        [System.Drawing.Rectangle]::FromLTRB($headX, $headY, $headX + $headSize, $headY + $headSize),
        [System.Drawing.Color]::FromArgb(148, 163, 184),
        [System.Drawing.Color]::FromArgb(100, 116, 139),
        90
    )
    
    # 圆角矩形头部
    $headRect = [System.Drawing.Rectangle]::FromLTRB($headX, $headY, $headSize, $headSize)
    $roundRect = New-Object System.Drawing.Drawing2D.GraphicsPath
    $roundRect.AddArc($headRect.X, $headRect.Y, $size * 0.08, $size * 0.08, 180, 90)
    $roundRect.AddArc($headRect.Right - $size * 0.08, $headRect.Y, $size * 0.08, $size * 0.08, 270, 90)
    $roundRect.AddArc($headRect.Right - $size * 0.08, $headRect.Bottom - $size * 0.08, $size * 0.08, $size * 0.08, 0, 90)
    $roundRect.AddArc($headRect.X, $headRect.Bottom - $size * 0.08, $size * 0.08, $size * 0.08, 90, 90)
    $roundRect.CloseFigure()
    $g.FillPath($headBrush, $roundRect)
    
    # 眼睛 (发光的蓝色)
    $eyeSize = $size * 0.08
    $eyeY = $headY + $headSize * 0.4
    
    # 左眼
    $leftEyeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(88, 166, 255))
    $g.FillEllipse($leftEyeBrush, $cx - $headSize * 0.25 - $eyeSize / 2, $eyeY, $eyeSize, $eyeSize)
    
    # 右眼
    $g.FillEllipse($leftEyeBrush, $cx + $headSize * 0.1, $eyeY, $eyeSize, $eyeSize)
    
    # 天线
    $antennaHeight = $size * 0.12
    $antennaBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(148, 163, 184))
    $g.FillRectangle($antennaBrush, $cx - $size * 0.01, $headY - $antennaHeight, $size * 0.02, $antennaHeight)
    
    # 天线球 (发光点)
    $ballBrush = New-Object System.Drawing.LinearGradientBrush(
        [System.Drawing.Rectangle]::FromLTRB($cx - $size * 0.04, $headY - $antennaHeight - $size * 0.04, $cx + $size * 0.04, $headY - $antennaHeight + $size * 0.04),
        [System.Drawing.Color]::FromArgb(88, 166, 255),
        [System.Drawing.Color]::FromArgb(163, 113, 247),
        45
    )
    $g.FillEllipse($ballBrush, $cx - $size * 0.03, $headY - $antennaHeight - $size * 0.03, $size * 0.06, $size * 0.06)
    
    # 底座
    $baseBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 116, 139))
    $baseRect = [System.Drawing.Rectangle]::FromLTRB($cx - $headSize * 0.4, $headY + $headSize + $size * 0.02, $headSize * 0.8, $size * 0.08)
    $g.FillRectangle($baseBrush, $baseRect)
    
    # 清理
    $g.Dispose()
    $bgBrush.Dispose()
    $ringBrush.Dispose()
    $pen.Dispose()
    $headBrush.Dispose()
    $leftEyeBrush.Dispose()
    $antennaBrush.Dispose()
    $ballBrush.Dispose()
    $baseBrush.Dispose()
    $roundRect.Dispose()
    
    # 保存PNG
    $path = Join-Path "assets" "icon-${size}.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    
    Write-Host "  Created: icon-${size}.png" -ForegroundColor Green
}

# 创建ICO文件 (组合所有尺寸)
Write-Host ""
Write-Host "Creating ICO file..." -ForegroundColor Cyan

$iconBuilder = New-Object System.IO.MemoryStream
$images = @()

foreach ($size in $sizes) {
    $path = Join-Path "assets" "icon-${size}.png"
    if (Test-Path $path) {
        $images += [System.Drawing.Image]::FromFile($path)
    }
}

# 保存为ICO (简化版：使用最大尺寸)
$bmp256 = New-Object System.Drawing.Bitmap(256, 256)
$g256 = [System.Drawing.Graphics]::FromImage($bmp256)
$g256.SmoothingMode = [System.Drawing.Drawing2D]::AntiAlias
$g256.InterpolationMode = [System.Drawing.Drawing2D]::HighQualityBicubic

$srcPath = Join-Path "assets" "icon-256.png"
if (Test-Path $srcPath) {
    $srcImg = [System.Drawing.Image]::FromFile($srcPath)
    $g256.DrawImage($srcImg, 0, 0, 256, 256)
    $srcImg.Dispose()
    
    $icoPath = Join-Path "assets" "icon.ico"
    # 保存为ICO需要特殊处理，这里先保存高质量PNG
    $bmp256.Save($icoPath -replace "\.ico$", ".png", [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "  Created: icon.png (256x256)" -ForegroundColor Green
}

$g256.Dispose()
$bmp256.Dispose()

Write-Host ""
Write-Host "All icons created in assets/ folder!" -ForegroundColor Yellow
Write-Host ""
