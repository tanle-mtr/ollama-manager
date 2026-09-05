// Ollama Manager Desktop - Renderer Script

// 全局状态
let currentModels = [];
let isDownloading = false;

// 初始化
document.addEventListener('DOMContentLoaded', () => {
  initializeApp();
});

async function initializeApp() {
  await loadSystemInfo();
  await refreshStatus();
  setupNavigation();
  loadPopularModels();
}

// 导航
function setupNavigation() {
  document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const page = item.dataset.page;
      showPage(page);
    });
  });
}

function showPage(pageName) {
  // 更新导航状态
  document.querySelectorAll('.nav-item').forEach(item => {
    item.classList.remove('active');
  });
  document.querySelector(`.nav-item[data-page="${pageName}"]`).classList.add('active');
  
  // 切换页面
  document.querySelectorAll('.page').forEach(page => {
    page.classList.remove('active');
  });
  document.getElementById(`page-${pageName}`).classList.add('active');
  
  // 页面特定初始化
  if (pageName === 'models') {
    loadModels();
  } else if (pageName === 'download') {
    loadPopularModels();
  }
}

// 加载系统信息
async function loadSystemInfo() {
  const info = await window.electronAPI.systemInfo();
  
  document.getElementById('info-platform').textContent = info.platform;
  document.getElementById('info-arch').textContent = info.arch;
  document.getElementById('info-cpus').textContent = `${info.cpus} 核`;
  document.getElementById('info-network').textContent = info.china ? '🇨🇳 国内 (镜像启用)' : '🌍 国际';
}

// 刷新状态
async function refreshStatus() {
  const status = await window.electronAPI.ollamaStatus();
  
  // 更新状态指示器
  const statusDot = document.querySelector('.status-dot');
  const statusText = document.querySelector('.status-text');
  
  if (status.running) {
    statusDot.classList.add('online');
    statusDot.classList.remove('offline');
    statusText.textContent = '运行中';
  } else {
    statusDot.classList.add('offline');
    statusDot.classList.remove('online');
    statusText.textContent = '已停止';
  }
  
  // 更新统计
  document.getElementById('stat-models').textContent = status.models.length;
  document.getElementById('stat-status').textContent = status.running ? '正常' : '停止';
  
  // 计算总大小
  const totalSize = status.models.reduce((sum, m) => sum + (m.size || 0), 0);
  document.getElementById('stat-size').textContent = formatSize(totalSize);
  
  // 保存模型列表
  currentModels = status.models;
  
  // 更新推荐模型
  updateRecommendedModels(status.models);
}

// 启动 Ollama
async function startOllama() {
  const result = await window.electronAPI.ollamaStart();
  if (result.success) {
    showToast('Ollama 启动成功', 'success');
    setTimeout(refreshStatus, 2000);
  } else {
    showToast(result.error || '启动失败', 'error');
  }
}

// 停止 Ollama
async function stopOllama() {
  const result = await window.electronAPI.ollamaStop();
  if (result.success) {
    showToast('Ollama 已停止', 'success');
    setTimeout(refreshStatus, 1000);
  }
}

// 打开 Web UI
function openWebUI() {
  window.electronAPI.openUrl('http://localhost:3000');
}

// 加载模型列表
async function loadModels() {
  const models = await window.electronAPI.ollamaList();
  const tbody = document.getElementById('models-table-body');
  document.getElementById('model-count').textContent = `${models.length} 个模型`;
  
  if (models.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="5" class="empty-state">
          <i class="fas fa-inbox"></i>
          <span>暂无模型，去下载页面获取</span>
        </td>
      </tr>
    `;
    return;
  }
  
  tbody.innerHTML = models.map(model => `
    <tr>
      <td>
        <div class="model-name">${model.name}</div>
      </td>
      <td>${formatSize(model.size)}</td>
      <td>${formatDate(model.modified_at)}</td>
      <td>${model.details?.parameter_size || '-'}</td>
      <td>
        <button class="btn btn-danger btn-small" onclick="deleteModel('${model.name}')">
          <i class="fas fa-trash"></i>
          删除
        </button>
      </td>
    </tr>
  `).join('');
}

// 删除模型
async function deleteModel(modelName) {
  if (!confirm(`确定要删除模型 ${modelName} 吗？`)) return;
  
  const result = await window.electronAPI.ollamaDelete(modelName);
  if (result.success) {
    showToast('模型已删除', 'success');
    loadModels();
    refreshStatus();
  } else {
    showToast('删除失败', 'error');
  }
}

// 下载模型
async function downloadModel() {
  const modelName = document.getElementById('model-input').value.trim();
  if (!modelName) {
    showToast('请输入模型名称', 'warning');
    return;
  }
  
  if (isDownloading) {
    showToast('正在下载中，请稍候...', 'warning');
    return;
  }
  
  isDownloading = true;
  
  // 显示进度
  document.getElementById('download-progress').style.display = 'block';
  document.getElementById('download-log').style.display = 'block';
  document.getElementById('progress-model').textContent = modelName;
  document.getElementById('progress-percent').textContent = '0%';
  document.getElementById('progress-fill').style.width = '0%';
  document.getElementById('log-content').innerHTML = '';
  
  addLog(`开始下载: ${modelName}`);
  
  // 监听进度
  const progressHandler = (data) => {
    document.getElementById('progress-percent').textContent = `${data.progress}%`;
    document.getElementById('progress-fill').style.width = `${data.progress}%`;
    document.getElementById('progress-size').textContent = 
      `${formatSize(data.downloaded)} / ${formatSize(data.total)}`;
    document.getElementById('progress-speed').textContent = 
      `${formatSize(data.speed || 0)}/s`;
  };
  
  const logHandler = (data) => {
    addLog(data);
  };
  
  window.electronAPI.onProgress(progressHandler);
  window.electronAPI.onLog(logHandler);
  
  try {
    const result = await window.electronAPI.ollamaPull(modelName);
    
    if (result.success) {
      showToast(`模型 ${modelName} 下载完成`, 'success');
      addLog('下载完成！');
      refreshStatus();
    } else {
      showToast(`下载失败: ${result.error}`, 'error');
      addLog(`错误: ${result.error}`);
    }
  } catch (error) {
    showToast(`下载失败: ${error.message}`, 'error');
    addLog(`错误: ${error.message}`);
  } finally {
    isDownloading = false;
  }
}

// 添加日志
function addLog(message) {
  const logContent = document.getElementById('log-content');
  const time = new Date().toLocaleTimeString();
  logContent.innerHTML += `<div class="log-line">[${time}] ${message}</div>`;
  logContent.scrollTop = logContent.scrollHeight;
}

// 清空日志
function clearLog() {
  document.getElementById('log-content').innerHTML = '';
}

// 加载热门模型
function loadPopularModels() {
  const models = [
    { name: 'phi3', size: '3.8GB', tags: ['轻量', '快速'], minRam: 4 },
    { name: 'gemma:2b', size: '1.4GB', tags: ['轻量', 'Google'], minRam: 4 },
    { name: 'qwen2:0.5b', size: '0.4GB', tags: ['轻量', '中文'], minRam: 2 },
    { name: 'qwen2:1.5b', size: '1.0GB', tags: ['轻量', '中文'], minRam: 4 },
    { name: 'llama3.2:3b', size: '2.0GB', tags: ['通用', 'Meta'], minRam: 8 },
    { name: 'qwen2:7b', size: '4.5GB', tags: ['通用', '中文'], minRam: 8 },
    { name: 'mistral:7b', size: '4.1GB', tags: ['通用'], minRam: 8 },
    { name: 'llama3.1:8b', size: '4.9GB', tags: ['通用', '最新'], minRam: 16 },
    { name: 'qwen2.5:7b', size: '4.9GB', tags: ['通用', '中文', '最新'], minRam: 16 },
    { name: 'deepseek-coder:6.7b', size: '4.0GB', tags: ['代码', '中文'], minRam: 16 }
  ];
  
  const container = document.getElementById('popular-models');
  container.innerHTML = models.map(m => `
    <div class="popular-model" onclick="quickDownload('${m.name}')">
      <div class="popular-model-name">${m.name}</div>
      <div class="popular-model-size">${m.size}</div>
      <div class="popular-model-tags">
        ${m.tags.map(t => `<span class="tag">${t}</span>`).join('')}
      </div>
    </div>
  `).join('');
}

// 快速下载
function quickDownload(modelName) {
  document.getElementById('model-input').value = modelName;
  downloadModel();
}

// 更新推荐模型
function updateRecommendedModels(installedModels) {
  const container = document.getElementById('recommended-models');
  const installed = installedModels.map(m => m.name);
  
  const recommended = [
    { name: 'phi3', tags: ['轻量', '快速'] },
    { name: 'llama3.2:3b', tags: ['通用', 'Meta'] },
    { name: 'qwen2.5:7b', tags: ['通用', '中文'] }
  ];
  
  const toShow = recommended.filter(m => !installed.includes(m.name));
  
  if (toShow.length === 0) {
    container.innerHTML = '<p style="color: var(--text-muted);">已安装所有推荐模型</p>';
    return;
  }
  
  container.innerHTML = toShow.map(m => `
    <div class="model-item" onclick="quickDownload('${m.name}')" style="cursor: pointer;">
      <div class="model-info">
        <span class="model-name">${m.name}</span>
        <span class="model-meta">点击快速下载</span>
      </div>
      <div class="model-tags">
        ${m.tags.map(t => `<span class="tag">${t}</span>`).join('')}
      </div>
    </div>
  `).join('');
}

// 工具函数
function formatSize(bytes) {
  if (!bytes) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  let i = 0;
  let size = bytes;
  while (size >= 1024 && i < units.length - 1) {
    size /= 1024;
    i++;
  }
  return `${size.toFixed(2)} ${units[i]}`;
}

function formatDate(dateStr) {
  if (!dateStr) return '-';
  return new Date(dateStr).toLocaleDateString('zh-CN');
}

function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  const icons = {
    success: 'fas fa-check-circle',
    error: 'fas fa-exclamation-circle',
    warning: 'fas fa-exclamation-triangle',
    info: 'fas fa-info-circle'
  };
  
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <i class="${icons[type]}"></i>
    <span>${message}</span>
  `;
  
  container.appendChild(toast);
  
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

// 回车键下载
document.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && document.activeElement.id === 'model-input') {
    downloadModel();
  }
});
