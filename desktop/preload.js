const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  // 窗口控制
  minimize: () => ipcRenderer.send('window-minimize'),
  maximize: () => ipcRenderer.send('window-maximize'),
  close: () => ipcRenderer.send('window-close'),
  
  // Ollama API
  ollamaStatus: () => ipcRenderer.invoke('ollama:status'),
  ollamaStart: () => ipcRenderer.invoke('ollama:start'),
  ollamaStop: () => ipcRenderer.invoke('ollama:stop'),
  ollamaPull: (modelName) => ipcRenderer.invoke('ollama:pull', modelName),
  ollamaDelete: (modelName) => ipcRenderer.invoke('ollama:delete', modelName),
  ollamaList: () => ipcRenderer.invoke('ollama:list'),
  
  // 代理 API
  proxyStart: () => ipcRenderer.invoke('proxy:start'),
  proxyStop: () => ipcRenderer.invoke('proxy:stop'),
  proxyStatus: () => ipcRenderer.invoke('proxy:status'),
  
  // 事件监听
  onProgress: (callback) => {
    ipcRenderer.on('ollama:progress', (event, data) => callback(data));
  },
  onLog: (callback) => {
    ipcRenderer.on('ollama:log', (event, data) => callback(data));
  },
  
  // Web 服务器
  webStart: () => ipcRenderer.invoke('web:start'),
  webStop: () => ipcRenderer.invoke('web:stop'),
  
  // 系统信息
  systemInfo: () => ipcRenderer.invoke('system:getInfo'),
  
  // Shell
  openUrl: (url) => ipcRenderer.invoke('shell:open', url),
  
  // 文件对话框
  openFile: () => ipcRenderer.invoke('dialog:openFile'),
  
  // 应用
  quit: () => ipcRenderer.send('app:quit')
});
