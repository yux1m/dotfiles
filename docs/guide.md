# 使用与维护指南

## 1. 本方案做了什么

GitHub 保存期望配置和历史，chezmoi 根据源文件生成生效文件，安装脚本负责下载依赖。Mac 和 Linux 都能修改同一个仓库；建议每次只在一台机器上编辑同一项设置，先拉取、后编辑、测试、再发布。

本方案公开保存终端配置。每次新增内容都应查看差异，令牌、密码和机器专用地址放在本机入口，不要添加到公开仓库。

| 内容 | 行为 |
|---|---|
| Starship | 保留原来的 Catppuccin 配色、分段、目录/Git/语言/时间显示规则 |
| Zsh、OMZ | 通用插件、自动建议、语法高亮；历史仍由本机积累 |
| fzf、zoxide | 安装并启用；zoxide 访问记录留在本机 |
| macOS | Homebrew 初始化、已有 Miniforge 初始化、已有 iTerm2 shell integration |
| Ubuntu | 默认 Bash，原生加载 Starship / fzf / zoxide；保留 Zsh、OMZ 及其插件 |
| 字体 | 安装 JetBrainsMono Nerd Font Mono；Mac 已有该字体时保留现状 |
| 仅本机入口 | `~/.bashrc.local`、`~/.zshrc.local`、`~/.zprofile.local`，不会被本仓库覆盖或主动上传 |

不管理项目资料、SSH 密钥、GitHub 登录、Conda 环境、VS Code 扩展、VMware 设置、Ubuntu 桌面设置。字体选用、终端背景色与窗口快捷键仍是终端应用的设置。

## 2. 新 Ubuntu 虚拟机安装

使用普通用户，确保网络可访问 GitHub 与系统软件源：

```bash
sudo apt-get update && sudo apt-get install -y curl && bash -c "$(curl -fsSL https://raw.githubusercontent.com/yux1m/dotfiles/main/install.sh)"
```

不要在 `bash` 前加 sudo，避免装进 root 的主目录。安装系统包及更改默认 shell 时会由脚本调用 sudo。

安装后执行 `exec bash -l`，并在终端偏好设置中选择 **JetBrainsMono Nerd Font Mono**。注销再登录后，默认 shell 设置全面生效。远程 SSH 使用 Mac 终端时，由 Mac 终端选择字体。

脚本可以重跑：备份原配置、跳过已满足的依赖、重试未完成的下载。Linux 工具安装在 `~/.local/bin/`；这个路径优先于系统命令路径。每个下载包在安装前进行 SHA256 校验。

正常更新使用 `dotfiles pull`。一键安装入口会在备份后强制应用配置，适合首次部署或明确恢复仓库版本；不要用它代替保存本机未导入的编辑。

Ubuntu x86_64/ARM64 是主要目标。Debian 走同一套 apt 分支，但尚未单独验收；其他 Linux 发行版会明确退出，不会盲目使用 apt。

## 3. 在 Mac 修改并同步

先更新：

```bash
dotfiles pull
```

按修改内容选择入口：

| 命令 | 修改内容 | 适用系统 |
|---|---|---|
| `dotfiles edit bash` | Bash 的 aliases、函数、选项 | Ubuntu 加载；Mac 也能编辑并发布 |
| `dotfiles edit common` | Zsh 的 aliases、函数、快捷键 | 两边的 Zsh |
| `dotfiles edit options` | OMZ 加载前的设置，如历史时间格式 | 两边的 Zsh |
| `dotfiles edit prompt` | Starship 配色、图标、布局 | 两边 |
| `dotfiles edit macos` | Homebrew/Conda/iTerm2 等 Mac 配置 | 只在 macOS 加载 |
| `dotfiles edit linux` | Linux 的 Zsh 专用配置 | 只在 Linux 的 Zsh 加载 |
| `dotfiles edit plugins` | 插件名称、仓库来源、固定版本 | 根据系统生成 |
| `dotfiles edit local` | 当前机器的私有设置 | Linux 编辑 `.bashrc.local`；Mac 编辑 `.zshrc.local` |
| `dotfiles edit bash-local` / `zsh-local` | 明确选择 shell 的私有入口 | 仅本机 |

例如修改提示符：

```bash
dotfiles edit prompt
```

保存退出后会自动应用。对 Zsh 行为的修改，用新终端检查，或执行：

没有设置其他编辑器时，默认使用 nano：`Ctrl+O` 保存、回车确认、`Ctrl+X` 退出。可以在 `common` 或 `local` 中设置自己的 `EDITOR`；图形编辑器需要等待窗口关闭，例如 `code --wait`。

```bash
exec zsh -l
```

确认后发布：

```bash
dotfiles status
chezmoi git diff
dotfiles push
```

然后在 Ubuntu：

```bash
dotfiles pull
exec bash -l
```

本方案没有配置后台监听、自动提交、定时拉取。保存文件、应用到本机、上传 GitHub、其他机器下载，是不同步骤。

## 4. 在 Linux 修改并回传 Mac

流程与 Mac 相同。**Bash 设置改 `bash`，共用提示符改 `prompt`，仅当前虚拟机需要的 Bash 设置改 `local`**。`common` / `options` / `linux` 都属于保留下来的 Zsh 配置，Bash 不会加载。

Mac 也能使用 `dotfiles edit bash` 来维护 Ubuntu 的 Bash 配置。回传到 Mac 后，Bash 文件会同步保存，但不会自动加载进 Mac 的 Zsh。

新虚拟机从公开仓库下载配置无需 GitHub 登录；要向 GitHub 发布，需要单独配置写入身份。

如果使用 GitHub CLI：

```bash
sudo apt-get install -y gh
gh auth login
gh auth setup-git
chezmoi git config user.name yux1m
chezmoi git config user.email 96606372+yux1m@users.noreply.github.com
```

通过浏览器登录自己的 GitHub 账户并选择 HTTPS。邮箱示例是本仓库所有者的 GitHub noreply 邮箱；其他使用者应填自己的身份。不要把登录凭据写进配置仓库。如果系统源没有 `gh`，按 [GitHub CLI 官方安装说明](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)安装。

然后正常编辑与发布：

```bash
dotfiles pull
dotfiles edit bash
# 新终端测试
dotfiles push
```

Mac 上运行 `dotfiles pull` 即可接收。两台机器没有主从限制，GitHub 上已发布的版本是共享来源。

## 5. chezmoi 最需要理解的基础

### 源文件、生效文件、GitHub 是三个位置

默认源目录是 `~/.local/share/chezmoi`，可以用 `chezmoi source-path` 查看。

| 源文件 | 生成的生效文件 |
|---|---|
| `dot_config/bash/common.bash` | `~/.config/bash/common.bash` |
| `modify_dot_bashrc.tmpl` | 只更新 Linux `~/.bashrc` 中的标记块 |
| `dot_zshrc` | `~/.zshrc` |
| `dot_zprofile` | `~/.zprofile` |
| `dot_config/starship.toml` | `~/.config/starship.toml` |
| `dot_config/zsh/common.zsh` | `~/.config/zsh/common.zsh` |
| `dot_local/bin/executable_dotfiles` | 可执行的 `~/.local/bin/dotfiles` |

`dot_` 表示文件名开头的点；`executable_` 表示输出文件具有执行权限；`.tmpl` 表示应用前需要渲染模板。普通文件模式下，源和目标通常是两份文件。

### 常用原生命令

| 命令 | 作用 |
|---|---|
| `chezmoi edit --apply 文件` | 编辑源文件，退出编辑器后应用 |
| `chezmoi diff` | 查看本地源将对生效文件做出的变化；不会先拉 GitHub |
| `chezmoi apply` | 把当前本地源应用到本机；不会先拉 GitHub |
| `chezmoi update` | 拉取 GitHub 并应用 |
| `chezmoi push` | 把源目录更改加入 Git、提交、推送 |
| `chezmoi re-add 文件` | 将直接修改过的普通生效文件重新导入源 |
| `chezmoi git diff` | 查看源仓库的未提交更改 |
| `chezmoi verify --exclude=scripts` | 检查生效文件是否与源一致 |

`dotfiles pull` 在更新前额外检查未提交源改动和生效文件改动；有未保存更改时会停下，避免无意覆盖。

### 如果习惯直接编辑 ~/.zshrc 或 starship.toml

直接编辑生效文件仍然可以，但发布前必须导回源。比如直接改了 Starship：

```bash
dotfiles capture prompt
chezmoi git diff
dotfiles push
```

直接改了 `~/.zshrc` 用 `dotfiles capture zshrc`；其他普通文件同理。建议平时使用 `dotfiles edit`，减少漏导入的情况。

`plugins.zsh` 是从清单生成的，修改它应使用 `dotfiles edit plugins`。模板文件不要用普通文件的重新导入流程覆盖。

### Bash 入口保留本机内容

Ubuntu 的 `.bashrc` 使用 `modify_` 局部修改，只维护 `dotfiles Bash integration` 标记块。登录入口按 Bash 的优先级，选择已有 `.bash_profile`、已有 `.bash_login`，否则使用 `.profile`。原有内容会保留；Mac 的这些入口不作修改。

需要同步的 Bash 设置写到 `dotfiles edit bash`。直接修改 `~/.config/bash/common.bash` 后，用 `dotfiles capture bash` 导回源。不要对 `.bashrc`、`.profile` 使用 `chezmoi add` / `re-add` 来发布整份本机配置；标记块以外的内容不会自动同步，也不会导致 `dotfiles pull` 拒绝更新。

### 机器差异怎样处理

本仓库把大部分设置保存为普通文件，方便直接阅读和导入。Zsh 根据系统只加载 `macos.zsh` 或 `linux.zsh`。两份文件都会在两边保存，因此你也能在 Mac 上维护 Linux 配置。

插件列表和安装脚本由 `.chezmoidata.toml` 渲染生成。chezmoi 模板也支持操作系统、架构和本机变量；本方案没有要求你在日常修改别名时学习模板语言。

## 6. 新增插件与更新工具版本

Bash 当前只有三个原生集成：`fzf --bash`、`zoxide init bash`、`starship init bash`。它们使用与 Zsh 相同的工具安装和 Starship 配置。下面的 OMZ 插件清单仅影响 Zsh；不会将 Zsh 插件转换成 Bash 插件。

运行 `dotfiles edit plugins`。

OMZ 自带插件：添加名称到 `terminal.builtinPlugins`；Mac 专用插件放入 `terminal.macosPlugins`。

第三方插件：在 `terminal.externalPlugins` 登记 `name`、`url` 和完整 Git commit。名称必须对应 `<name>.plugin.zsh` 入口。将语法高亮插件保持在列表末尾。

仅添加 `plugins=(...)` 中的名字无法告诉安装器第三方代码在哪里，因此需要来源记录。删除清单条目会停止加载；为保留本地数据，本方案不主动删除旧插件目录。

工具版本：Linux 的 Starship、fzf、zoxide 固定在清单指定版本，包含 x86_64 和 ARM64 的下载地址、校验值。升级时一起修改版本、URL、对应 SHA256，运行 `chezmoi apply` 测试后发布。Mac 保留 Homebrew 管理的现有工具版本；需要升级时使用 Homebrew。两边更新配置不会自动把所有软件都升级到最新版本。

OMZ 和第三方插件按 Git commit 管理，自动 OMZ 更新已关闭。升级通过清单进行；已有插件工作区存在未保存改动且需要切换版本时，脚本会停下。不要把 `omz update` 与清单版本管理混用。

更改插件清单属于源仓库编辑，`dotfiles edit plugins` 会自动应用；依赖会在应用阶段检查并按需安装。

## 7. 冲突与同时修改

修改前先 `dotfiles pull`。若两台机器同时修改同一配置并发布，Git 可能拒绝第二次推送。修改会留在本机，先检查：

```bash
dotfiles status
chezmoi git status
```

对已经提交、但落后于远端的分支，可以在确认工作区干净后执行：

```bash
chezmoi git pull -- --rebase
```

若 Git 报冲突，编辑冲突文件，使用 `chezmoi git add 冲突文件`，再 `chezmoi git rebase -- --continue`；也可以 `chezmoi git rebase -- --abort` 取消本次合并。解决后 `chezmoi apply`、测试，再 `dotfiles push`。不要用强制推送来处理日常同步冲突。

## 8. 备份、恢复与卸载

每次应用前，脚本会对已有受管理文件建立本地快照；内容与上一份完全相同时不重复保存。查看：

```bash
dotfiles backups
```

备份位置：`~/.local/state/dotfiles/backups/时间戳-进程号/`。里面保留原目录结构及校验清单。备份不包含软件包、插件仓库和 Conda 环境；也不回滚默认 shell。

恢复某个文件，例如原 `.zshrc`：

```bash
cp ~/.local/state/dotfiles/backups/实际快照目录/.zshrc ~/.zshrc
```

把“实际快照目录”替换为列出的目录。若要保留旧内容并继续管理，随后 `dotfiles capture zshrc` 并发布；否则下次应用仓库配置时仍可能将它改回。

如果某个 shell 配置出错，可用 `bash --noprofile --norc` 进入不加载用户配置的 Bash，再恢复文件。Ubuntu 默认 shell 由本方案设为 `/bin/bash`。每次应用都会检查默认 shell；临时跳过可用 `DOTFILES_SKIP_SHELL=1 chezmoi apply`。这不卸载 Zsh，也不会切换已有会话。

停止管理某文件可用 `chezmoi forget 文件`，它保留当前生效文件。注意它同时改变源仓库；发布该改动后其他机器也会停止管理对应文件。整个仓库删除前先保留你需要的生效文件和备份。

## 9. Bash 与 Zsh 切换

Ubuntu 正常启动 Bash；输入 `zsh` 进入保留的 Zsh/OMZ，输入 `exit` 回到外层 Bash。要把当前窗口直接切换为 Bash，可运行 `exec bash -l`。`ps -p $$ -o comm=` 查看当前解释器；`getent passwd "$USER" | cut -d: -f7` 查看账户默认 shell。旧会话里的 `$SHELL` 可能暂时仍是旧值。

Bash 具有 Starship 外观、fzf 历史/文件搜索、zoxide 的 `z` / `zi`。OMZ Git 简写、extract、sudo 双击快捷键、colored-man-pages、Zsh 自动建议和语法高亮只在 Zsh 中启用；Git、tar、sudo 等底层命令在 Bash 仍可正常使用。

如果注销登录后新窗口仍启动 Zsh，请检查终端配置中是否显式指定了 `zsh` 自定义命令；账户默认 shell 不会覆盖终端自己的自定义命令。

## 10. 更多边界

- 一条命令完成安装并不等于没有交互：sudo 可能要求密码，字体需要在具体终端里选择。
- 新虚拟机的用户名、目录、Git 状态和版本显示会反映新机器本身；配置相同并不意味着动态内容相同。
- SSH 使用的字体由客户端终端决定；在 Ubuntu 桌面直接使用终端时，由 Ubuntu 终端决定。
- 缓存和历史不属于配置同步。自动建议需要本机历史；zoxide 需要本机访问记录。
- `chezmoi diff` / `status` 中出现 `R` 表示脚本会执行。本仓库每次应用都会检查依赖，但符合清单时不会重新下载。
- 自动备份不等于自动 Git 提交。备份用于本机恢复，Git 提交用于共享版本和追踪变化。
- `dotfiles push` 会提交源仓库中的改动，包括新添加的文件。发布前检查 `chezmoi git diff` 和 `chezmoi git status`。

## 官方参考

- [项目与基础概念](https://www.chezmoi.io/what-does-chezmoi-do/)
- [快速开始](https://www.chezmoi.io/quick-start/)
- [日常操作](https://www.chezmoi.io/user-guide/daily-operations/)
- [处理机器差异](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [脚本执行](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)
