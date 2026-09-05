# Ollama Manager Desktop

现代化桌面版 Ollama 管理器，UI 风格模仿 Codex++。

## 功能特性

- 🎨 现代化深色主题 UI（Codex++ 风格）
- 🤖 Ollama 服务管理（启动/停止）
- 📦 模型下载与管理
- 📊 实时进度显示
- 🇨🇳 国内镜像加速
- 💻 系统信息统计

## 技术栈

- **Electron** - 桌面应用框架
- **Node.js** - 后端服务
- **Vanilla JS** - 前端逻辑
- **CSS3** - 样式（Dark Theme）

## 快速开始

### 安装依赖

```bash
cd desktop
npm install
```

### 运行开发版

```bash
npm start
```

### 构建安装包

```bash
npm run build
```

构建产物在 `dist/` 目录。

## 项目结构

```
desktop/
├── main.js           # Electron 主进程
├── preload.js        # 预加载脚本
├── package.json      # 项目配置
├── renderer/
│   ├── index.html    # 主界面
│   ├── styles.css    # 样式（Codex++ 风格）
│   ├── main.js       # 渲染进程逻辑
│   └── splash.html   # 启动画面
└── assets/
    └── icon.png      # 应用图标
```

## 截图

![Ollama Manager Desktop](../README.md)

## 许可证

MIT License

## 作者

Sapiens AI - Agnes
