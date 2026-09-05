# ============================================================
# Ollama Manager - 国内模型下载解决方案
# 解决 registry.ollama.ai 无法访问的问题
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Ollama Model Download Fix           ║" -ForegroundColor Cyan
Write-Host "║         Powered by Sapiens AI           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Cyan

# 检测网络环境
$isChina = $false
try {
    Invoke-WebRequest -Uri "https://www.baidu.com" -TimeoutSec 3 -UseBasicParsing | Out-Null
    $isChina = $true
} catch {}

Write-Host "[INFO] Network: $(if($isChina){'China'}else{'International'})" -ForegroundColor Cyan

# 方案1: 使用本地代理
Write-Host ""
Write-Host "=== Solution 1: Local Proxy (Recommended) ===" -ForegroundColor Yellow
Write-Host ""

$proxyScript = Join-Path $PSScriptRoot "desktop\ollama-proxy.js"
$proxyPort = 18080

if (Test-Path $proxyScript) {
    Write-Host "[STEP] Starting Ollama proxy on port $proxyPort..." -ForegroundColor Cyan
    
    # 启动代理（后台运行）
    $proxyProcess = Start-Process -FilePath "node" -ArgumentList $proxyScript -PassThru -WindowStyle Hidden
    
    # 设置环境变量
    $env:OLLAMA_HOST = "http://localhost:$proxyPort"
    Write-Host "[OK] Ollama proxy started (PID: $($proxyProcess.Id))" -ForegroundColor Green
    Write-Host "[OK] Set OLLAMA_HOST=http://localhost:$proxyPort" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Now you can download models:" -ForegroundColor Green
    Write-Host "  ollama pull phi3" -ForegroundColor Gray
    Write-Host "  ollama pull llama3.2:3b" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "[WARN] Proxy script not found: $proxyScript" -ForegroundColor Yellow
}

# 方案2: 修改 hosts 文件
Write-Host ""
Write-Host "=== Solution 2: Hosts File Modification ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Add to C:\Windows\System32\drivers\etc\hosts:" -ForegroundColor Cyan
Write-Host "  # Ollama Registry Mirror" -ForegroundColor Gray
Write-Host "  127.0.0.1 registry.ollama.ai" -ForegroundColor Gray
Write-Host ""
Write-Host "Note: You need to find a working mirror IP first" -ForegroundColor Yellow

# 方案3: 使用已有的模型
Write-Host ""
Write-Host "=== Solution 3: Use Existing Models ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Your currently installed models:" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
    if ($response.models) {
        $response.models | ForEach-Object {
            Write-Host "  • $($_.name) - $([math]::Round($_.size/1GB,2)) GB" -ForegroundColor White
        }
    }
} catch {
    Write-Host "  [WARN] Cannot connect to Ollama" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "For China users, the best solution is to run the local proxy:" -ForegroundColor Green
Write-Host ""
Write-Host "  cd desktop" -ForegroundColor Gray
Write-Host "  node ollama-proxy.js" -ForegroundColor Gray
Write-Host "  # In another terminal:" -ForegroundColor Gray
Write-Host "  set OLLAMA_HOST=http://localhost:18080" -ForegroundColor Gray
Write-Host "  ollama pull <model-name>" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Cyan
Read-Host
