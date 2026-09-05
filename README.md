# Ollama Manager - One-Click Installer

自动安装 Ollama �?Web 管理界面的工具�?
## 功能特�?
- 🚀 一键安�?Ollama
- 🌐 Web 管理界面
- 🇨🇳 国内镜像加�?- 📊 实时下载进度
- 💻 智能模型推荐

## 在线安装

### Windows (PowerShell)

```powershell
# 一键安装（推荐�?iex "& {$(irm https://raw.githubusercontent.com/agnes-ai/ollama-manager/main/install.ps1)}"

# 或者手动下载运�?Invoke-WebRequest -Uri "https://raw.githubusercontent.com/agnes-ai/ollama-manager/main/install.ps1" -OutFile "install.ps1"
.\install.ps1
```

### 本地安装

```powershell
git clone https://github.com/agnes-ai/ollama-manager.git
cd ollama-manager
.\one-click-install.ps1
```

## 使用方法

### 命令�?
```powershell
# 安装并启�?.\one-click-install.ps1

# 查看状�?.\ollama-manager.ps1 -Status

# 推荐模型
.\ollama-manager.ps1 -Models

# 启动服务
.\ollama-manager.ps1 -Start

# 打开 Web 界面
.\ollama-manager.ps1 -Web
```

### 访问地址

- Web 管理�? http://localhost:3000
- Ollama API: http://localhost:11434

## 系统要求

- Windows 10/11 (64�?
- Node.js 16+
- 至少 4GB 内存

## 项目结构

```
ollama-manager/
├── one-click-install.ps1   # 一键安装脚�?├── install.ps1            # 在线安装脚本
├── ollama-manager.ps1     # 交互式管理工�?├── server.js              # Web 服务�?├── public/
�?  └── index.html         # 管理界面
├── package.json
└── README.md
```

## 许可�?
MIT License

## 赞助支持

如果这个项目对你有帮助，欢迎扫码赞助支持！�?
![赞助二维码](sponsor.png)

感谢每一位支持者的鼓励�?
## 作�?
Sapiens AI - Agnes
