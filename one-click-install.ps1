# ============================================================
# One-Click Ollama Installer - Copy & Paste Version
# Copy this entire script and paste into PowerShell
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Ollama Manager - Auto Installer      ║" -ForegroundColor Cyan
Write-Host "║         Powered by Sapiens AI           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Cyan
Write-Host "[1/5] Checking Node.js..." -ForegroundColor Yellow
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) { Write-Host "  [!] Node.js not found! Install from: https://nodejs.org`n" -ForegroundColor Red; exit 1 }
Write-Host "  [OK] Node.js $($node.Version)" -ForegroundColor Green
Write-Host "`n[2/5] Checking Ollama..." -ForegroundColor Yellow
$ollamaPath = "$env:ProgramFiles\Ollama\ollama.exe"
if (-not (Test-Path $ollamaPath)) {
    $isChina = $false
    try { Invoke-WebRequest -Uri "https://www.baidu.com" -TimeoutSec 3 -UseBasicParsing | Out-Null; $isChina = $true } catch {}
    $mirror = if ($isChina) { "https://mirror.ghproxy.com/" } else { "" }
    Write-Host "  [INFO] Network: $($(if($isChina){'China (Mirror)'})else{'International'}))" -ForegroundColor Cyan
    try { $latest = Invoke-RestMethod -Uri "https://api.github.com/repos/ollama/ollama/releases/latest" -TimeoutSec 10; $ver = $latest.tag_name -replace "^v", "" } catch { Write-Host "  [!] Cannot get version`n" -ForegroundColor Red; exit 1 }
    Write-Host "  [OK] Latest: v$ver" -ForegroundColor Green
    $arch = if ([Environment]::Is64BitOperatingSystem) { "windows-amd64" } else { "windows-386" }
    $url = "${mirror}https://github.com/ollama/ollama/releases/download/v$ver/ollama-$arch.exe"
    $temp = Join-Path $env:TEMP "ollama-setup-$ver.exe"
    Write-Host "  [INFO] Downloading..." -ForegroundColor Cyan
    try { $wc = New-Object System.Net.WebClient; $wc.DownloadFile($url, $temp); Write-Host "  [OK] Download complete" -ForegroundColor Green } catch { Write-Host "  [!] Download failed: $($_.Exception.Message)`n" -ForegroundColor Red; exit 1 }
    Write-Host "  [INFO] Installing..." -ForegroundColor Cyan
    Start-Process -FilePath $temp -ArgumentList "/S" -Wait
    Remove-Item $temp -Force -ErrorAction SilentlyContinue
    if (Test-Path $ollamaPath) { Write-Host "  [OK] Ollama installed!" -ForegroundColor Green } else { Write-Host "  [!] Install failed`n" -ForegroundColor Red; exit 1 }
} else { Write-Host "  [OK] Ollama already installed" -ForegroundColor Green }
Write-Host "`n[3/5] Starting Ollama..." -ForegroundColor Yellow
$ollamaRunning = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if (-not $ollamaRunning) { Start-Process -FilePath $ollamaPath -ArgumentList "serve"; Start-Sleep -Seconds 2; $ollamaRunning = Get-Process -Name "ollama" -ErrorAction SilentlyContinue; if ($ollamaRunning) { Write-Host "  [OK] Started (PID: $($ollamaRunning.Id))" -ForegroundColor Green } else { Write-Host "  [!] Start failed" -ForegroundColor Red } } else { Write-Host "  [OK] Already running (PID: $($ollamaRunning.Id))" -ForegroundColor Green }
Write-Host "`n[4/5] Checking Web Manager..." -ForegroundColor Yellow
$webPath = Join-Path $PSScriptRoot "server.js"
if (Test-Path $webPath) { Write-Host "  [OK] Found" -ForegroundColor Green } else { Write-Host "  [!] Not found - run from project directory`n" -ForegroundColor Red; exit 1 }
Write-Host "`n[5/5] Installing dependencies..." -ForegroundColor Yellow
$nodeModules = Join-Path $PSScriptRoot "node_modules"
if (-not (Test-Path $nodeModules)) { Push-Location $PSScriptRoot; npm install --silent; Pop-Location; Write-Host "  [OK] Done" -ForegroundColor Green } else { Write-Host "  [OK] Already installed" -ForegroundColor Green }
Write-Host "`nStarting Web Manager..." -ForegroundColor Cyan
$webProcess = Start-Process -FilePath "node" -ArgumentList "server.js" -WorkingDirectory $PSScriptRoot -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 2
try { Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 3 -UseBasicParsing | Out-Null; Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Green; Write-Host "║        Installation Complete!            ║" -ForegroundColor Green; Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Green; Write-Host "  Ollama:      http://localhost:11434" -ForegroundColor White; Write-Host "  Web Manager: http://localhost:3000" -ForegroundColor White; Write-Host "`nOpening browser...`n" -ForegroundColor Cyan; Start-Process "http://localhost:3000" } catch { Write-Host "`n[!] Still starting, please wait...`n" -ForegroundColor Yellow }
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
