@echo off
echo ========================================
echo   Ollama 管理器 - 启动脚本
echo ========================================
echo.

cd /d "%~dp0"

REM 检查 Node.js 是否安装
where node >nul 2>nul
if errorlevel 1 (
    echo [错误] 未检测到 Node.js，请先安装 Node.js
    echo 下载地址: https://nodejs.org/
    pause
    exit /b 1
)

echo [信息] Node.js 已安装:
node --version
echo.

REM 检查 node_modules
if not exist "node_modules" (
    echo [信息] 正在安装依赖...
    call npm install
    if errorlevel 1 (
        echo [错误] 依赖安装失败
        pause
        exit /b 1
    )
)

echo [信息] 正在启动 Ollama Web 管理器...
echo.
echo 请等待，启动后会自动打开浏览器...
echo.
echo 访问地址: http://localhost:3000
echo.

REM 启动服务器
start "" node server.js

REM 延迟后打开浏览器
timeout /t 3 /nobreak >nul
start "" http://localhost:3000

echo.
echo ========================================
echo   启动成功！
echo ========================================
echo.
echo 停止服务: Ctrl+C 或在任务管理器中结束 node 进程
echo 如需安装 Ollama，请运行: .\ollama-manager.ps1 -Install
echo.
pause
