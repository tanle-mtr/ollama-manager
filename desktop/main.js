const { app, BrowserWindow, ipcMain, dialog, shell } = require('electron');
const path = require('path');
const { spawn } = require('child_process');
const fs = require('fs');

// 保持对 window 对象的全局引用
let mainWindow;
let ollamaProcess = null;
let webServerProcess = null;
let proxyProcess = null;

// 启动 Ollama 代理服务器（国内镜像）
async function startOllamaProxy() {
  const proxyScript = path.join(__dirname, 'ollama-proxy.js');
  
  if (!fs.existsSync(proxyScript)) {
    return { success: false, error: 'Proxy script not found' };
  }
  
  try {
    proxyProcess = spawn('node', [proxyScript], {
      detached: true,
      stdio: 'ignore',
      windowsHide: true
    });
    
    proxyProcess.unref();
    
    // 等待代理启动
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // 设置环境变量
    process.env.OLLAMA_HOST = 'http://localhost:18080';
    
    return { success: true, message: 'Ollama proxy started on port 18080' };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1200,
    minHeight: 700,
    frame: false,
    transparent: false,
    backgroundColor: '#0d1117',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: false
    },
    icon: path.join(__dirname, 'assets', 'icon.png'),
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 16, y: 16 }
  });

  // 加载应用
  mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'));

  // 开发模式下打开 DevTools
  if (process.argv.includes('--dev')) {
    mainWindow.webContents.openDevTools();
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

// 应用准备就绪
app.whenReady().then(async () => {
  // 启动代理（国内用户）
  await startOllamaProxy();
  
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

// 窗口控制
ipcMain.on('window-minimize', () => {
  mainWindow.minimize();
});

ipcMain.on('window-maximize', () => {
  if (mainWindow.isMaximized()) {
    mainWindow.unmaximize();
  } else {
    mainWindow.maximize();
  }
});

ipcMain.on('window-close', () => {
  mainWindow.close();
});

// Ollama 管理
ipcMain.handle('ollama:status', async () => {
  try {
    const response = await fetch('http://localhost:11434/api/tags');
    const data = await response.json();
    return { 
      running: true, 
      models: data.models || [],
      version: '0.32.15'
    };
  } catch (error) {
    return { running: false, models: [], error: error.message };
  }
});

ipcMain.handle('proxy:start', async () => {
  return await startOllamaProxy();
});

ipcMain.handle('proxy:stop', async () => {
  if (proxyProcess) {
    proxyProcess.kill();
    proxyProcess = null;
  }
  process.env.OLLAMA_HOST = undefined;
  return { success: true };
});

ipcMain.handle('proxy:status', async () => {
  return {
    running: proxyProcess !== null,
    host: process.env.OLLAMA_HOST || 'http://localhost:18080'
  };
});
  const ollamaPath = path.join(process.env.PROGRAMFILES || 'C:\\Program Files', 'Ollama', 'ollama.exe');
  
  if (!fs.existsSync(ollamaPath)) {
    return { success: false, error: 'Ollama not found. Please install Ollama first.' };
  }

  if (ollamaProcess) {
    return { success: true, message: 'Ollama is already running' };
  }

  try {
    ollamaProcess = spawn(ollamaPath, ['serve'], {
      detached: true,
      stdio: 'ignore'
    });
    
    ollamaProcess.unref();
    
    // 等待服务启动
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    return { success: true, message: 'Ollama started successfully' };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('ollama:stop', async () => {
  if (ollamaProcess) {
    ollamaProcess.kill();
    ollamaProcess = null;
  }
  
  // 尝试通过进程名杀死
  const { execSync } = require('child_process');
  try {
    execSync('taskkill /F /IM ollama.exe', { stdio: 'ignore' });
  } catch (e) {
    // 进程可能已经停止
  }
  
  return { success: true, message: 'Ollama stopped' };
});

ipcMain.handle('ollama:pull', async (event, modelName) => {
  const ollamaPath = path.join(process.env.PROGRAMFILES || 'C:\\Program Files', 'Ollama', 'ollama.exe');
  
  if (!fs.existsSync(ollamaPath)) {
    return { success: false, error: 'Ollama not found' };
  }

  return new Promise((resolve) => {
    const child = spawn(ollamaPath, ['pull', modelName], {
      env: {
        ...process.env,
        HTTPS_PROXY: 'https://modelscope.cn',
        HTTP_PROXY: 'https://modelscope.cn'
      }
    });

    let output = '';
    let progress = 0;
    let speed = 0;
    let totalSize = 0;
    let downloadedSize = 0;

    child.stdout.on('data', (data) => {
      const text = data.toString();
      output += text;
      
      // 解析进度
      try {
        const lines = text.split('\n');
        for (const line of lines) {
          try {
            const json = JSON.parse(line);
            if (json.total) {
              totalSize = json.total;
              downloadedSize = json.completed;
              progress = Math.round((json.completed / json.total) * 100);
            }
            if (json.status) {
              event.sender.send('ollama:progress', {
                model: modelName,
                progress,
                speed,
                downloaded: downloadedSize,
                total: totalSize,
                status: json.status
              });
            }
          } catch (e) {
            // 忽略非 JSON 行
          }
        }
      } catch (e) {
        // 忽略解析错误
      }
    });

    child.stderr.on('data', (data) => {
      event.sender.send('ollama:log', data.toString());
    });

    child.on('close', (code) => {
      resolve({
        success: code === 0,
        output,
        model: modelName
      });
    });

    child.on('error', (error) => {
      resolve({ success: false, error: error.message });
    });
  });
});

ipcMain.handle('ollama:delete', async (event, modelName) => {
  try {
    const response = await fetch('http://localhost:11434/api/delete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: modelName })
    });
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('ollama:list', async () => {
  try {
    const response = await fetch('http://localhost:11434/api/tags');
    const data = await response.json();
    return data.models || [];
  } catch (error) {
    return [];
  }
});

// Web 服务器管理
ipcMain.handle('web:start', async () => {
  const serverPath = path.join(__dirname, 'server.js');
  
  if (webServerProcess) {
    return { success: true, message: 'Web server is already running' };
  }

  try {
    webServerProcess = spawn('node', [serverPath], {
      detached: true,
      stdio: 'ignore'
    });
    
    webServerProcess.unref();
    
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    return { success: true, message: 'Web server started' };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('web:stop', async () => {
  if (webServerProcess) {
    webServerProcess.kill();
    webServerProcess = null;
  }
  return { success: true };
});

// 系统信息
ipcMain.handle('system:getInfo', async () => {
  const os = require('os');
  return {
    platform: os.platform(),
    arch: os.arch(),
    cpus: os.cpus().length,
    memoryGB: Math.round(os.totalmem() / 1024 / 1024 / 1024),
    china: await checkChinaNetwork()
  };
});

async function checkChinaNetwork() {
  try {
    const https = require('https');
    return new Promise((resolve) => {
      const req = https.get('https://www.baidu.com', { timeout: 3000 }, (res) => {
        resolve(true);
      });
      req.on('error', () => resolve(false));
      req.on('timeout', () => {
        req.destroy();
        resolve(false);
      });
    });
  } catch {
    return false;
  }
}

// 打开 URL
ipcMain.handle('shell:open', async (event, url) => {
  await shell.openExternal(url);
});

// 文件对话框
ipcMain.handle('dialog:openFile', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile']
  });
  return result.filePaths[0];
});

// 应用退出
ipcMain.on('app:quit', () => {
  app.quit();
});
