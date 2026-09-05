# Ollama 国内下载解决方案

## 问题分析

Ollama 模型下载失败的原因：
1. **registry.ollama.ai 被墙** - 国内无法直接访问 Docker Hub 风格的 registry
2. **代理环境变量无效** - Ollama 不使用标准 HTTP_PROXY 环境变量
3. **网络不稳定** - 即使有镜像，连接也时常超时

## 解决方案

### 方案1: 使用本地代理（推荐）⭐

创建一个本地代理服务，将 Ollama registry 请求转发到可用镜像：

```powershell
# 启动代理
cd E:\编程作品\作品\DeepSeek
node desktop\ollama-proxy.js

# 在另一个终端设置环境变量并下载
$env:OLLAMA_HOST = "http://localhost:18080"
ollama pull phi3
```

### 方案2: 使用已安装模型

当前已安装 7 个模型，可以直接使用：

| 模型 | 大小 |
|------|------|
| qwen3:1.7b | 1.27 GB |
| llama3.2:3b | 1.88 GB |
| gemma3:1b | 0.76 GB |
| phi4-mini | 2.32 GB |
| qwen2.5:1.5b | 0.92 GB |
| deepseek-r1:1.5b | 1.04 GB |
| qwen3:0.6b | 0.49 GB |

### 方案3: 手动下载模型文件

1. 从可用镜像下载模型 blob
2. 放入 `~/.ollama/models/` 目录

```powershell
# 查看模型存储位置
echo %OLLAMA_MODELS%
# 默认: C:\Users\<user>\.ollama\models
```

### 方案4: 修改 hosts 文件

找到可用的 registry.ollama.ai IP 地址，添加到 hosts：

```
# C:\Windows\System32\drivers\etc\hosts
127.0.0.1 registry.ollama.ai  # 指向本地代理
```

## 推荐操作流程

```powershell
# 1. 启动代理服务器
cd E:\编程作品\作品\DeepSeek
node desktop\ollama-proxy.js

# 2. 在另一个 PowerShell 窗口
$env:OLLAMA_HOST = "http://localhost:18080"
ollama pull phi3

# 3. 或者运行修复脚本
.\fix-download.ps1
```

## 技术说明

Ollama 使用 Docker Registry v2 API 下载模型：
- 认证: `https://registry.ollama.ai/v2/`
- 镜像: `https://registry.ollama.ai/v2/<model>/manifests/latest`
- Blob: `https://registry.ollama.ai/v2/<model>/blobs/<sha256>`

代理需要处理：
- HTTP 重定向
- Blob 下载
- 认证令牌

## 替代方案

如果代理方案不可用，可以考虑：
1. 使用 **ollama-cn** 项目（社区维护的镜像）
2. 使用 **Docker** 拉取模型后导入
3. 使用 **VPN** 直连官方 registry
