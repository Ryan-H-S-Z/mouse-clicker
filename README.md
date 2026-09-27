# macOS 鼠标连点器

[简体中文](README.md) | [English](README.en.md)

原生 SwiftUI + AppKit 应用，macOS 13 或更新版本，无第三方依赖。

## 下载安装

在 [Releases](https://github.com/Ryan-H-S-Z/mouse-clicker/releases/latest) 页面下载 `MouseClicker-1.0.0-universal.dmg`，打开后将「鼠标连点器.app」拖到 **Applications**。支持 Apple Silicon 和 Intel Mac；无需下载源码或安装开发工具。

当前版本采用 ad-hoc 签名，**尚未经过 Apple Developer ID 签名与公证**，从互联网下载后可能被 macOS 拦截。确认信任本项目后，可以在尝试打开应用后，按「系统设置 → 隐私与安全性」中的提示选择「仍要打开」。DMG 是安装包格式，不会自动免除首次打开检查或辅助功能授权。

Release 同时提供 `SHA256SUMS.txt`，可在下载目录执行 `shasum -a 256 -c SHA256SUMS.txt` 校验。

## 使用

1. 从「应用程序」启动 `鼠标连点器.app`。
2. 点击「前往授权」，在「系统设置 → 隐私与安全性 → 辅助功能」开启本应用。如果列表中没有应用，使用加号添加这个 `.app`。授权后界面会自动刷新；若系统要求，退出后重新打开应用。
3. 设置左右键、间隔（20–3,600,000 毫秒）和点击次数，或选择无限。
4. 点击「开始连点」，在 3 秒倒计时内把鼠标移到目标位置。每次点击使用鼠标当前所在位置，支持多显示器。
5. **Control + Option + 空格** 全局开始 / 停止，**Esc** 停止。菜单栏也提供停止入口。全局快捷键无法注册时禁止启动，并提示解决冲突。

关闭窗口、退出、睡眠或撤销辅助功能权限都会停止连点。关闭窗口后仍可通过菜单栏重新打开，或用全局快捷键启动。计数代表已发送的完整按下/松开事件对，不代表目标软件成功处理的次数。实际频率受系统负载及目标应用影响，每个事件对的点击计数固定为 1。

## 构建

安装 Apple Command Line Tools 后，双击 `build.command`，或执行：

```sh
./build.command
```

默认输出位于 `~/Applications/鼠标连点器.app`，可以给脚本传入完整 `.app` 路径更改输出位置。构建会编译 arm64 和 x86_64 两种架构并合并为 Universal 应用。建议避免云同步目录，文件提供商附加的 Finder 属性可能影响签名校验。重新构建或移动应用后，macOS 可能要求在辅助功能列表中移除旧条目并重新添加。建议在最终保存位置完成授权。

## 打包 DMG

```sh
./package-dmg.command
```

脚本在临时目录构建通用应用，校验签名，生成并验证压缩 DMG，输出到 `dist/`，同时生成 SHA-256 校验文件。版本号取自 `Info.plist`。
