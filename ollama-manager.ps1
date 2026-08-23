# ============================================================
# Ollama Manager - Modern Installation Script
# Author: Agnes (Sapiens AI)
# Version: 1.0.0
# ============================================================

# 强制使用 UTF-8 编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ==================== 颜色配置 ====================
$Colors = @{
    Primary   = " Cyan"
    Success   = " Green"
    Warning   = " Yellow"
    Error     = " Red"
    Info      = " Cyan"
    Dark      = " Gray"
    Light     = " White"
}

# ==================== 工具函数 ====================
function Write-Color {
    param([string]$Text, [string]$Color = "White", [bool]$NoNewline = $false)
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Show-Header {
    Write-Host ""
    Write-Host "  +----------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |              OLLAMA MANAGER                  |" -ForegroundColor Cyan
    Write-Host "  |         Powered by Sapiens AI                |" -ForegroundColor Cyan
    Write-Host "  |            Version 1.0.0                     |" -ForegroundColor Cyan
    Write-Host "  +----------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    param([bool]$IsChina = $false)
    Show-Header
    Write-Color "  Network: " -ForegroundColor Gray
    if ($IsChina) {
        Write-Color " China (Mirror) " -ForegroundColor Cyan
    } else {
        Write-Color " International " -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host ""
    Write-Color "  [1]" -ForegroundColor Cyan -NoNewline
    Write-Color "  Install Ollama" -ForegroundColor White
    Write-Color "  [2]" -ForegroundColor Cyan -NoNewline
    Write-Color "  Start Service" -ForegroundColor White
    Write-Color "  [3]" -ForegroundColor Cyan -NoNewline
    Write-Color "  Stop Service" -ForegroundColor White
    Write-Color "  [4]" -ForegroundColor Cyan -NoNewline
    Write-Color "  Show Status" -ForegroundColor White
    Write-Color "  [5]" -ForegroundColor Cyan -NoNewline
    Write-Color "  Recommended Models" -ForegroundColor White
    Write-Color "  [6]" -ForegroundColor Cyan -NoNewline
    Write-Color "  Open Web Interface" -ForegroundColor White
    Write-Color "  [0]" -ForegroundColor Red -NoNewline
    Write-Color "  Exit" -ForegroundColor White
    Write-Host ""
    Write-Color "  Enter option: " -ForegroundColor Gray -NoNewline
}

function Test-NetworkChina {
    try {
        $r = Invoke-WebRequest -Uri "https://www.baidu.com" -TimeoutSec 3 -UseBasicParsing
        return $true
    } catch { return $false }
}

function Get-OllamaVersion {
    try {
        $r = Invoke-RestMethod -Uri "https://api.github.com/repos/ollama/ollama/releases/latest" -TimeoutSec 10
        return $r.tag_name -replace "^v", ""
    } catch { return $null }
}

function Install-Ollama {
    param([bool]$IsChina = $false)
    
    Write-Host ""
    Write-Color "  [>] Checking latest version..." -ForegroundColor Cyan
    
    $version = Get-OllamaVersion
    if (-not $version) {
        Write-Host ""
        Write-Color "  [x] Cannot get version info, check network" -ForegroundColor Red
        Write-Host ""
        return $false
    }
    
    Write-Color "  [OK] Latest version: v$version" -ForegroundColor Green
    
    $arch = if ([Environment]::Is64BitOperatingSystem) { "windows-amd64" } else { "windows-386" }
    $mirror = if ($IsChina) { "https://mirror.ghproxy.com/" } else { "" }
    $url = "${mirror}https://github.com/ollama/ollama/releases/download/v$version/ollama-$arch.exe"
    
    $tempDir = Join-Path $env:TEMP "ollama-setup-$version"
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    $installer = Join-Path $tempDir "ollama-installer.exe"
    
    Write-Host ""
    Write-Color "  [>] Downloading Ollama ($version)..." -ForegroundColor Cyan
    Write-Color "      URL: $url`n" -ForegroundColor Gray
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $installer)
        
        Write-Color "  [OK] Download complete" -ForegroundColor Green
        Write-Host ""
        
        Write-Color "  [>] Installing..." -ForegroundColor Cyan
        Start-Process -FilePath $installer -ArgumentList "/S" -Wait
        
        $exePath = "$env:ProgramFiles\Ollama\ollama.exe"
        if (Test-Path $exePath) {
            Write-Color "  [OK] Installation successful!" -ForegroundColor Green
            Write-Host ""
            return $true
        } else {
            Write-Color "  [x] Installation verification failed" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host ""
        Write-Color "  [x] Download failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

function Start-Service {
    $exePath = "$env:ProgramFiles\Ollama\ollama.exe"
    if (-not (Test-Path $exePath)) {
        Write-Color "  [x] Ollama not installed, run install first" -ForegroundColor Red
        return $false
    }
    
    $running = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
    if ($running) {
        Write-Color "  [OK] Ollama already running (PID: $($running.Id))" -ForegroundColor Green
        return $true
    }
    
    Start-Process -FilePath $exePath -ArgumentList "serve"
    Start-Sleep -Seconds 2
    
    $newProc = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
    if ($newProc) {
        Write-Color "  [OK] Service started (PID: $($newProc.Id))" -ForegroundColor Green
        return $true
    } else {
        Write-Color "  [x] Service start failed" -ForegroundColor Red
        return $false
    }
}

function Stop-Service {
    $procs = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force
        Write-Color "  [OK] Service stopped" -ForegroundColor Yellow
    } else {
        Write-Color "  [!] Service not running" -ForegroundColor Gray
    }
}

function Show-Status {
    Write-Host ""
    Write-Host "  +----------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |          OLLAMA STATUS                 |" -ForegroundColor Cyan
    Write-Host "  +----------------------------------------+" -ForegroundColor Cyan
    
    $exePath = "$env:ProgramFiles\Ollama\ollama.exe"
    if (Test-Path $exePath) {
        Write-Host "  |  Install:  " -ForegroundColor Gray -NoNewline
        Write-Color "  OK Installed" -ForegroundColor Green
        $ver = & $exePath --version 2>$null
        if ($ver) {
            Write-Host "  |  Version:  " -ForegroundColor Gray -NoNewline
            Write-Color "  $ver" -ForegroundColor White
        }
    } else {
        Write-Host "  |  Install:  " -ForegroundColor Gray -NoNewline
        Write-Color "  NOT Installed" -ForegroundColor Red
    }
    
    $proc = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "  |  Status:   " -ForegroundColor Gray -NoNewline
        Write-Color "  Running (PID: $($proc.Id))" -ForegroundColor Green
        Write-Host "  |  URL:      " -ForegroundColor Gray -NoNewline
        Write-Color "  http://localhost:11434" -ForegroundColor Cyan
    } else {
        Write-Host "  |  Status:   " -ForegroundColor Gray -NoNewline
        Write-Color "  Stopped" -ForegroundColor Yellow
    }
    
    Write-Host "  +----------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
}

function Show-RecommendedModels {
    $memoryGB = [Math]::Round([Environment]::PhysicalMemory / 1GB, 0)
    
    Write-Host ""
    Write-Host "  +--------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |         RECOMMENDED MODELS                       |" -ForegroundColor Cyan
    Write-Host "  +--------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |  Memory: $memoryGB GB RAM" + (" " * (48 - $memoryGB.ToString().Length)) + " |" -ForegroundColor White
    Write-Host "  +--------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    
    $models = @(
        @{ Name = "phi3"; Size = "3.8GB"; Tags = "Light,Fast"; MinRam = 4 },
        @{ Name = "gemma:2b"; Size = "1.4GB"; Tags = "Light,Google"; MinRam = 4 },
        @{ Name = "qwen2:0.5b"; Size = "0.4GB"; Tags = "Light,Chinese"; MinRam = 2 },
        @{ Name = "qwen2:1.5b"; Size = "1.0GB"; Tags = "Light,Chinese"; MinRam = 4 },
        @{ Name = "llama3.2:3b"; Size = "2.0GB"; Tags = "General,Meta"; MinRam = 8 },
        @{ Name = "qwen2:7b"; Size = "4.5GB"; Tags = "General,Chinese"; MinRam = 8 },
        @{ Name = "mistral:7b"; Size = "4.1GB"; Tags = "General"; MinRam = 8 },
        @{ Name = "llama3.1:8b"; Size = "4.9GB"; Tags = "General,Latest"; MinRam = 16 },
        @{ Name = "qwen2.5:7b"; Size = "4.9GB"; Tags = "General,Chinese,Latest"; MinRam = 16 },
        @{ Name = "deepseek-coder:6.7b"; Size = "4.0GB"; Tags = "Code,Chinese"; MinRam = 16 }
    )
    
    $suitable = $models | Where-Object { $_.MinRam -le $memoryGB }
    
    Write-Color "  Suitable models for your system:" -ForegroundColor Green
    Write-Host ""
    
    foreach ($m in $suitable) {
        $tagColor = if ($m.Tags -like "*Chinese*") { "Green" } 
                    elseif ($m.Tags -like "*Latest*") { "Cyan" }
                    elseif ($m.Tags -like "*Code*") { "Magenta" }
                    else { "White" }
        
        Write-Color "  * $($m.Name.PadRight(20))" -ForegroundColor White -NoNewline
        Write-Color "  [$($m.Size.PadRight(6))]" -ForegroundColor Gray -NoNewline
        Write-Host "  $($m.Tags)" -ForegroundColor $tagColor
    }
    
    Write-Host ""
    Write-Color "  Usage: ollama run <model-name>" -ForegroundColor Gray
    Write-Host ""
}

function Open-WebInterface {
    $port = 3000
    $webPath = Join-Path $PSScriptRoot "server.js"
    
    if (-not (Test-Path $webPath)) {
        Write-Color "  [x] Web manager file not found" -ForegroundColor Red
        return
    }
    
    $nodeExists = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeExists) {
        Write-Color "  [x] Node.js not detected, install from: https://nodejs.org" -ForegroundColor Red
        return
    }
    
    $nodeModules = Join-Path $PSScriptRoot "node_modules"
    if (-not (Test-Path $nodeModules)) {
        Write-Color "  [>] Installing dependencies..." -ForegroundColor Cyan
        Push-Location $PSScriptRoot
        npm install --silent
        Pop-Location
        Write-Color "  [OK] Dependencies installed" -ForegroundColor Green
    }
    
    Write-Color "  [>] Starting Web Manager..." -ForegroundColor Cyan
    
    $process = Start-Process -FilePath "node" -ArgumentList "server.js" -WorkingDirectory $PSScriptRoot -PassThru -WindowStyle Hidden
    
    Start-Sleep -Seconds 2
    
    try {
        Invoke-WebRequest -Uri "http://localhost:$port" -TimeoutSec 3 -UseBasicParsing | Out-Null
        Write-Color "  [OK] Web Manager started" -ForegroundColor Green
        Write-Color "  URL: http://localhost:$port" -ForegroundColor Cyan
        Start-Process "http://localhost:$port"
    } catch {
        Write-Color "  [!] Service starting, please wait..." -ForegroundColor Yellow
    }
}

# ==================== 主程序 ====================
$scriptParams = $MyInvocation.MyCommand.Parameters

if ($scriptParams["Install"] -or $scriptParams["Start"] -or $scriptParams["Stop"] -or $scriptParams["Status"] -or $scriptParams["Models"] -or $scriptParams["Web"]) {
    # 命令行模式
    $isChina = Test-NetworkChina
    
    if ($scriptParams["Install"]) {
        Install-Ollama -IsChina $isChina
    }
    if ($scriptParams["Start"]) {
        Start-Service
    }
    if ($scriptParams["Stop"]) {
        Stop-Service
    }
    if ($scriptParams["Status"]) {
        Show-Status
    }
    if ($scriptParams["Models"]) {
        Show-RecommendedModels
    }
    if ($scriptParams["Web"]) {
        Open-WebInterface
    }
} else {
    # 交互模式
    $isChina = Test-NetworkChina
    $running = $true
    
    while ($running) {
        Clear-Host
        Show-Menu -IsChina $isChina
        $input = Read-Host
        
        switch ($input) {
            "1" { 
                $result = Install-Ollama -IsChina $isChina
                if ($result) { Start-Service }
                Write-Host ""
                Write-Color "  Press any key to continue..." -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" { Start-Service; Write-Host ""; Write-Color "  Press any key to continue..." -ForegroundColor Gray; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
            "3" { Stop-Service; Write-Host ""; Write-Color "  Press any key to continue..." -ForegroundColor Gray; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
            "4" { Show-Status; Write-Host ""; Write-Color "  Press any key to continue..." -ForegroundColor Gray; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
            "5" { Show-RecommendedModels; Write-Host ""; Write-Color "  Press any key to continue..." -ForegroundColor Gray; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
            "6" { Open-WebInterface; Write-Host ""; Write-Color "  Press any key to continue..." -ForegroundColor Gray; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
            "0" { $running = $false }
            default { Write-Host ""; Write-Color "  Invalid option, please try again" -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}
