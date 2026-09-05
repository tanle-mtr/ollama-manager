#!/usr/bin/env pwsh
# ============================================================
# Ollama Manager - Online Installer
# Usage: iex "& {$(irm https://raw.githubusercontent.com/agnes-ai/ollama-manager/main/install.ps1)}"
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Ollama Manager - Online Installer    ║" -ForegroundColor Cyan
Write-Host "║         Powered by Sapiens AI           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Colors
$okColor = "Green"
$infoColor = "Cyan"
$warnColor = "Yellow"
$errorColor = "Red"

function Write-Step { param($n, $total, $msg); Write-Host "[${n}/${total}] $msg" -ForegroundColor $warnColor }
function Write-OK { param($msg); Write-Host "  [OK] $msg" -ForegroundColor $okColor }
function Write-Info { param($msg); Write-Host "  [INFO] $msg" -ForegroundColor $infoColor }
function Write-ErrorMsg { param($msg); Write-Host "  [!] $msg" -ForegroundColor $errorColor }

# Step 1: Check prerequisites
Write-Step 1 5 "Checking prerequisites..."
Write-Host ""

# Check Node.js
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-ErrorMsg "Node.js not found!"
    Write-Host "  Please install Node.js from: https://nodejs.org" -ForegroundColor Red
    Write-Host "  Then run this script again.`n" -ForegroundColor Red
    exit 1
}
Write-OK "Node.js $($node.Version)"

# Check PowerShell version
$psVer = $PSVersionTable.PSVersion
if ($psVer.Major -lt 5) {
    Write-ErrorMsg "PowerShell 5.0+ required (current: $psVer)"
    exit 1
}
Write-OK "PowerShell $psVer"

# Step 2: Detect network
Write-Host ""
Write-Step 2 5 "Detecting network..."
$isChina = $false
try {
    Invoke-WebRequest -Uri "https://www.baidu.com" -TimeoutSec 3 -UseBasicParsing | Out-Null
    $isChina = $true
} catch {}

if ($isChina) {
    Write-OK "China network detected (mirror enabled)"
} else {
    Write-OK "International network"
}

# Step 3: Install Ollama
Write-Host ""
Write-Step 3 5 "Installing Ollama..."

$ollamaPath = "$env:ProgramFiles\Ollama\ollama.exe"
if (Test-Path $ollamaPath) {
    $ver = & $ollamaPath --version 2>$null
    Write-OK "Ollama already installed ($ver)"
} else {
    # Get latest version
    Write-Info "Fetching latest version..."
    try {
        $latest = Invoke-RestMethod -Uri "https://api.github.com/repos/ollama/ollama/releases/latest" -TimeoutSec 10
        $ver = $latest.tag_name -replace "^v", ""
    } catch {
        Write-ErrorMsg "Cannot get latest version: $($_.Exception.Message)"
        exit 1
    }
    Write-OK "Latest version: v$ver"
    
    # Download
    $arch = if ([Environment]::Is64BitOperatingSystem) { "windows-amd64" } else { "windows-386" }
    $mirror = if ($isChina) { "https://modelscope.cn/models" } else { "" }
    $url = "${mirror}https://github.com/ollama/ollama/releases/download/v$ver/ollama-$arch.exe"
    $temp = Join-Path $env:TEMP "ollama-setup-$ver.exe"
    
    Write-Info "Downloading installer..."
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $temp)
        Write-OK "Download complete"
    } catch {
        Write-ErrorMsg "Download failed: $($_.Exception.Message)"
        exit 1
    }
    
    # Install
    Write-Info "Installing Ollama..."
    Start-Process -FilePath $temp -ArgumentList "/S" -Wait
    Remove-Item $temp -Force -ErrorAction SilentlyContinue
    
    if (Test-Path $ollamaPath) {
        Write-OK "Ollama installed successfully"
    } else {
        Write-ErrorMsg "Installation failed"
        exit 1
    }
}

# Step 4: Start services
Write-Host ""
Write-Step 4 5 "Starting services..."

# Configure model mirrors for China users
if ($isChina) {
    Write-Info "Configuring model download mirrors..."
    $env:HTTPS_PROXY = "https://modelscope.cn"
    $env:HTTP_PROXY = "https://modelscope.cn"
    Write-OK "Model mirror enabled (ModelScope 魔塔社区)"
}

# Start Ollama
$ollamaRunning = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if (-not $ollamaRunning) {
    Write-Info "Starting Ollama service..."
    Start-Process -FilePath $ollamaPath -ArgumentList "serve"
    Start-Sleep -Seconds 2
    $ollamaRunning = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
    if ($ollamaRunning) {
        Write-OK "Ollama started (PID: $($ollamaRunning.Id))"
    } else {
        Write-ErrorMsg "Ollama service failed to start"
    }
} else {
    Write-OK "Ollama already running (PID: $($ollamaRunning.Id))"
}

# Step 5: Install Web Manager
Write-Host ""
Write-Step 5 5 "Setting up Web Manager..."

$scriptPath = $PSScriptRoot
if (-not $scriptPath -or $scriptPath -eq "") {
    $scriptPath = Get-Location
}

$webPath = Join-Path $scriptPath "server.js"
if (-not (Test-Path $webPath)) {
    Write-ErrorMsg "Web Manager files not found!"
    Write-Host "  Please clone the repository first:" -ForegroundColor Red
    Write-Host "  git clone https://github.com/agnes-ai/ollama-manager.git" -ForegroundColor Red
    Write-Host "  cd ollama-manager" -ForegroundColor Red
    exit 1
}
Write-OK "Web Manager files found"

# Install dependencies
$nodeModules = Join-Path $scriptPath "node_modules"
if (-not (Test-Path $nodeModules)) {
    Write-Info "Installing npm dependencies..."
    Push-Location $scriptPath
    npm install --silent
    Pop-Location
    Write-OK "Dependencies installed"
} else {
    Write-OK "Dependencies ready"
}

# Start Web Manager
Write-Info "Starting Web Manager..."
$webProcess = Start-Process -FilePath "node" -ArgumentList "server.js" -WorkingDirectory $scriptPath -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 2

# Check if running
$port = 3000
try {
    Invoke-WebRequest -Uri "http://localhost:$port" -TimeoutSec 3 -UseBasicParsing | Out-Null
    Write-OK "Web Manager started"
} catch {
    Write-Host "  [INFO] Web Manager may still be starting..." -ForegroundColor $infoColor
}

# Summary
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║        Installation Complete!            ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "  Ollama Service:  http://localhost:11434" -ForegroundColor White
Write-Host "  Web Manager:     http://localhost:3000" -ForegroundColor White
Write-Host ""

# Open browser
Write-Host "Opening browser..." -ForegroundColor Cyan
Start-Process "http://localhost:3000"

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
