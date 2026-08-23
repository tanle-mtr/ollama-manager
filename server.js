/**
 * Ollama Web Manager - 后端服务器
 * 提供模型管理和下载监控功能
 */

const express = require('express');
const cors = require('cors');
const { exec, spawn } = require('child_process');
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// 检测国内网络
async function isChinaUser() {
    try {
        const { execSync } = require('child_process');
        const result = execSync('ping -n 1 baidu.com', { timeout: 3000 });
        return true;
    } catch {
        return false;
    }
}

// 获取系统信息
function getSystemInfo() {
    return {
        platform: os.platform(),
        arch: os.arch(),
        cpus: os.cpus().length,
        memoryGB: Math.round(os.totalmem() / 1024 / 1024 / 1024),
        china: null // 稍后设置
    };
}

// Ollama API 基础地址
let OLLAMA_HOST = process.env.OLLAMA_HOST;
if (!OLLAMA_HOST || OLLAMA_HOST === '0.0.0.0:11434') {
    OLLAMA_HOST = 'http://localhost:11434';
}

// ==================== API 路由 ====================

// 获取系统信息和网络环境
app.get('/api/info', async (req, res) => {
    const info = getSystemInfo();
    info.china = await isChinaUser();
    info.ollamaAvailable = await checkOllamaRunning();
    res.json(info);
});

// 检查 Ollama 是否运行
async function checkOllamaRunning() {
    try {
        await fetch(`${OLLAMA_HOST}/api/tags`);
        return true;
    } catch (e) {
        return false;
    }
}

// 获取已安装的模型列表
app.get('/api/models', async (req, res) => {
    try {
        const response = await fetch(`${OLLAMA_HOST}/api/tags`);
        const data = await response.json();

        const models = (data.models || []).map(m => ({
            name: m.name,
            size: m.size,
            modified: m.modified_at,
            digest: m.digest
        }));

        res.json({ models, china: await isChinaUser() });
    } catch (error) {
        res.status(503).json({ error: '无法连接到 Ollama 服务', detail: error.message });
    }
});

// 拉取模型
app.post('/api/models/pull', async (req, res) => {
    const { model } = req.body;

    if (!model) {
        return res.status(400).json({ error: '请提供模型名称' });
    }

    // 检测网络环境并配置镜像
    const isChina = await isChinaUser();
    const proxyUrl = isChina ? 'http://mirror.ghproxy.com' : '';
    
    // 构建环境变量，设置代理
    const env = {
        ...process.env,
        HTTPS_PROXY: proxyUrl,
        HTTP_PROXY: proxyUrl,
        https_proxy: proxyUrl,
        http_proxy: proxyUrl
    };

    // 使用流式响应
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    const args = ['pull', model];
    const child = spawn('ollama', args, {
        env,
        shell: true
    });

    let totalSize = 0;
    let downloadedSize = 0;
    let lastSize = 0;
    let lastTime = Date.now();

    // 计算下载速度
    function calculateSpeed(currentSize) {
        const now = Date.now();
        const timeDiff = (now - lastTime) / 1000;
        const sizeDiff = currentSize - lastSize;
        lastSize = currentSize;
        lastTime = now;
        return timeDiff > 0 ? sizeDiff / timeDiff : 0;
    }

    child.stdout.on('data', (data) => {
        const output = data.toString();

        // 解析 JSON 行
        output.split('\n').forEach(line => {
            try {
                const json = JSON.parse(line);

                if (json.total) {
                    totalSize = json.total;
                    const progress = Math.round((json.completed / totalSize) * 100);
                    const speed = calculateSpeed(json.completed);
                    sendEvent(res, 'progress', {
                        percent: progress,
                        downloaded: json.completed,
                        total: totalSize,
                        speed: speed,
                        model: model,
                        stage: json.status || 'downloading'
                    });
                }

                if (json.status) {
                    sendEvent(res, 'status', {
                        message: json.status,
                        model: model
                    });
                }
            } catch (e) {
                // 非 JSON 输出，直接发送
                sendEvent(res, 'log', { message: line });
            }
        });
    });

    child.stderr.on('data', (data) => {
        sendEvent(res, 'log', { message: data.toString() });
    });

    // 心跳包
    const heartbeat = setInterval(() => {
        if (res.writable) {
            res.write(': heartbeat\n\n');
        }
    }, 15000);

    child.on('close', (code) => {
        clearInterval(heartbeat);
        if (code === 0) {
            sendEvent(res, 'complete', { model });
        } else {
            sendEvent(res, 'error', { model, code });
        }
        res.end();
    });
});

function sendEvent(res, type, data) {
    res.write(`data: ${JSON.stringify({ type, ...data })}\n\n`);
}

// 删除模型
app.delete('/api/models/:name', async (req, res) => {
    const { name } = req.params;

    try {
        await fetch(`${OLLAMA_HOST}/api/delete`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name })
        });
        res.json({ success: true, message: `模型 ${name} 已删除` });
    } catch (error) {
        res.status(503).json({ error: '删除失败', detail: error.message });
    }
});

// 获取可用的主流模型列表
app.get('/api/recommended', async (req, res) => {
    const systemInfo = getSystemInfo();
    systemInfo.china = await isChinaUser();

    // 根据内存推荐模型
    const memoryGB = systemInfo.memoryGB;

    const allModels = [
        // 轻量级模型 (<4GB)
        { name: 'phi3', size: '3.8GB', tags: ['轻量', '快速'], minRam: 4 },
        { name: 'gemma:2b', size: '1.4GB', tags: ['轻量', 'Google'], minRam: 4 },
        { name: 'qwen2:0.5b', size: '0.4GB', tags: ['轻量', '中文'], minRam: 2 },
        { name: 'qwen2:1.5b', size: '1.0GB', tags: ['轻量', '中文'], minRam: 4 },
        { name: 'starcoder2:3b', size: '1.9GB', tags: ['轻量', '代码'], minRam: 4 },

        // 中等模型 (4-8GB)
        { name: 'llama3.2:3b', size: '2.0GB', tags: ['通用', 'Meta'], minRam: 8 },
        { name: 'qwen2:7b', size: '4.5GB', tags: ['通用', '中文'], minRam: 8 },
        { name: 'gemma:7b', size: '4.8GB', tags: ['通用', 'Google'], minRam: 8 },
        { name: 'mistral:7b', size: '4.1GB', tags: ['通用'], minRam: 8 },
        { name: 'dolphin-mistral:7b', size: '4.1GB', tags: ['通用', '无过滤'], minRam: 8 },
        { name: 'codellama:7b', size: '4.3GB', tags: ['代码'], minRam: 8 },

        // 大型模型 (8-16GB)
        { name: 'llama3.1:8b', size: '4.9GB', tags: ['通用', 'Meta', '最新'], minRam: 16 },
        { name: 'qwen2.5:7b', size: '4.9GB', tags: ['通用', '中文', '最新'], minRam: 16 },
        { name: 'qwen2.5:14b', size: '8.9GB', tags: ['通用', '中文', '强大'], minRam: 16 },
        { name: 'deepseek-coder:6.7b', size: '4.0GB', tags: ['代码', '中文'], minRam: 16 },
        { name: 'deepseek-coder:33b', size: '20GB', tags: ['代码', '强大'], minRam: 32 },
        { name: 'llama3:70b', size: '40GB', tags: ['通用', '强大', '需要大显存'], minRam: 64 },

        // 视觉模型
        { name: 'llava', size: '4.7GB', tags: ['视觉', '图像理解'], minRam: 8 },
        { name: 'nomic-embed-text', size: '0.3GB', tags: ['嵌入', '搜索'], minRam: 2 },
    ];

    // 根据内存过滤
    const recommended = allModels.filter(m => m.minRam <= memoryGB);

    res.json({
        models: recommended,
        systemInfo,
        china: systemInfo.china
    });
});

// 测试连接
app.get('/api/test-connection', async (req, res) => {
    try {
        const response = await fetch(`${OLLAMA_HOST}/api/tags`);
        const data = await response.json();
        res.json({
            connected: true,
            modelCount: data.models?.length || 0,
            host: OLLAMA_HOST
        });
    } catch (error) {
        res.json({
            connected: false,
            error: error.message,
            host: OLLAMA_HOST
        });
    }
});

// 启动页面
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 启动服务器
app.listen(PORT, async () => {
    const isChina = await isChinaUser();
    console.log(`\n${'='.repeat(50)}`);
    console.log('  Ollama Web Manager 已启动');
    console.log(`  访问地址: http://localhost:${PORT}`);
    console.log(`  Ollama 地址: ${OLLAMA_HOST}`);
    console.log(`  网络环境: ${isChina ? '国内 (使用镜像)' : '国际'}`);
    console.log(`${'='.repeat(50)}\n`);
});
