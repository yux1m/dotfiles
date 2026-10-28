# Terminal dotfiles

[![Ubuntu installation tests](https://github.com/yux1m/dotfiles/actions/workflows/ubuntu.yml/badge.svg)](https://github.com/yux1m/dotfiles/actions/workflows/ubuntu.yml)

用 GitHub + chezmoi 管理 macOS / Ubuntu 的 Zsh、Oh My Zsh、Starship、fzf、zoxide 和 JetBrainsMono Nerd Font Mono。

## Ubuntu 一行安装

以普通用户运行（脚本会在安装系统包和切换默认 shell 时使用 sudo）：

```bash
sudo apt-get update && sudo apt-get install -y curl && bash -c "$(curl -fsSL https://raw.githubusercontent.com/yux1m/dotfiles/main/install.sh)"
```

已有 curl 时可用短版：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/yux1m/dotfiles/main/install.sh)"
```

随后执行 `exec zsh -l`，或注销并重新登录。Ubuntu 终端的字体请选择 **JetBrainsMono Nerd Font Mono**。字体文件会自动安装，终端应用的字体选择和背景色由你设置。

需要网络能访问 GitHub 和 Ubuntu 软件源，以及 sudo 权限。脚本支持 Ubuntu / Debian 的 x86_64 与 ARM64；CI 验证 Ubuntu 22.04 x86_64、24.04 x86_64 和 24.04 ARM64。Debian 尚未做独立集成测试。macOS 使用已有 Homebrew。

## 平时只记住这几个命令

Mac 和 Linux 使用同一个流程：

```bash
dotfiles pull          # 开始修改之前，获取别人/另一台机器已发布的版本
dotfiles edit common   # 修改共用别名、函数、快捷键，并应用到本机
# 在新终端测试效果
dotfiles push          # 提交并发布到 GitHub
```

其他机器运行 `dotfiles pull`，然后重新打开终端。

```bash
dotfiles edit prompt   # Starship 配色和提示符
dotfiles edit options  # Oh My Zsh 加载前的选项
dotfiles edit macos    # macOS 专用配置
dotfiles edit linux    # Linux 专用配置
dotfiles edit plugins  # 插件清单、来源、版本、下载校验值
dotfiles edit local    # 仅本机，永不由本方案发布
dotfiles status        # 查看源文件和生效文件的差异
dotfiles doctor        # 检查组件及配置一致性
```

`dotfiles` 是本仓库提供的便利命令；`chezmoi` 是底层管理工具。

## 管理范围

同步通用 shell 行为、OMZ 插件选择和 Starship 外观。macOS 按条件加载 Homebrew、已有 Miniforge 和已有 iTerm2 shell integration。Linux 安装清单中固定版本的命令行组件。

各台机器保留自己的 shell 历史、zoxide 数据库、Conda 环境、SSH 密钥、登录凭据、项目文件与终端应用设置。OMZ 的 `git` / `vscode` 插件不会自动配置 Git 身份或安装 VS Code。

原配置在应用前备份到 `~/.local/state/dotfiles/backups/`，不上传 GitHub。`~/.zshrc.local` 和 `~/.zprofile.local` 是本机自定义入口。

**详细维护、Linux 回传、基础知识、冲突处理、备份恢复与版本升级见 [使用指南](docs/guide.md)。**

## 仓库结构

```text
.chezmoidata.toml             插件与下载版本清单
.chezmoiscripts/              应用前备份、安装与修复脚本
dot_zshrc / dot_zprofile      Zsh 入口
dot_config/starship.toml      Starship 外观
dot_config/zsh/               通用、macOS、Linux 和生成的插件配置
dot_local/bin/executable_dotfiles  日常维护命令
install.sh                   新机器的一键入口
tests/                       隔离验证和 Ubuntu 集成测试
```

## 开发验证

本地运行 `bash tests/static.sh`，需要 chezmoi、Zsh、ShellCheck。它使用临时目标目录，跳过依赖安装，不加载宿主机 shell 配置。

`tests/integration.sh` 只应在新建的测试账户/临时虚拟机运行，会执行真实安装并切换该账户默认 shell。GitHub Actions 为它创建专用临时账户。
