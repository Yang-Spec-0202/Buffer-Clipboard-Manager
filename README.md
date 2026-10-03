# Buffer

**A local-first clipboard manager for macOS, with screenshot paste for terminal AI tools.**

This is an unofficial community-maintained build based on [Samir Patil's Buffer](https://github.com/samirpatil2000/Buffer). It keeps clipboard history on your Mac and adds a focused workflow for pasting screenshots into terminal TUIs such as Codex CLI and OpenCode. It is not affiliated with the original author.

[Download the latest macOS release](https://github.com/Yang-Spec-0202/Buffer-Clipboard-Manager/releases/latest) · [中文说明](#中文)

- Universal macOS app for Apple Silicon and Intel; macOS 13 or later.
- Simplified Chinese and English interface.
- Paste one or multiple clipboard screenshots into a local terminal TUI as image paths.
- Clipboard contents and screenshots are not uploaded. Update checks contact GitHub for release metadata.

## 中文

这是基于 [Samir Patil 的 Buffer](https://github.com/samirpatil2000/Buffer) 维护的非官方社区版本，保留本地剪切板历史，并重点支持把截图粘贴到 Codex CLI、OpenCode 等终端 TUI。

### 下载与安装

前往[最新 Release 页面](https://github.com/Yang-Spec-0202/Buffer-Clipboard-Manager/releases/latest)，下载 `Buffer_3.0.2_Universal.dmg`，打开后将 Buffer 拖入“应用程序”。此通用版支持 Apple Silicon 和 Intel，最低支持 macOS 13。

当前发布包使用本地 ad-hoc 签名，**没有 Apple Developer ID 签名或公证**。首次打开时，macOS 可能提示无法验证开发者。请先检查公开源码；只有在信任来源时才通过 Finder 的“按住 Control 点击 → 打开”继续。

### 授权终端自动粘贴

Buffer 通过模拟 `⌘V` 完成自动粘贴，因此需要辅助功能授权。打开“系统设置 → 隐私与安全 → 辅助功能”，允许 Buffer；部分较新的 macOS 界面会把此项放在“设备控制和数据访问”中。未授权时内容仍会复制到剪切板，可以切回目标应用手动按 `⌘V`。

### 粘贴截图到终端

1. 将光标放在本机 Codex CLI 或 OpenCode 的输入框。
2. 使用 Buffer 的历史快捷键（默认 `⇧⌘V`）打开剪切板历史。
3. 选择截图并粘贴。Buffer 会将每张截图写为独立 PNG 临时文件，再把路径送入终端，让 TUI 识别为图片附件。

图片路径只在本机有效；远程 SSH 会话无法读取本机临时文件。图片保存在系统临时目录 `BufferPaste`，由系统清理。

### 从源码构建

需要 macOS 及 Xcode Command Line Tools：

```sh
./build_release.sh
```

产物包含通用 `.dmg` 和 `.zip`。本项目没有 Apple Developer ID 发布证书，因此构建脚本生成 ad-hoc 签名、未公证的发布包。验证代码可运行：

```sh
./scripts/test_local.sh
python3 scripts/verify_localization.py
```

## English

### Paste screenshots into a terminal TUI

Focus the input field in a **local** Codex CLI or OpenCode session, open Buffer with its configured history shortcut (default `⇧⌘V`), select a screenshot, and paste. Buffer exports each image to a separate temporary PNG and inserts its local path so the TUI can attach it as an image. Paths do not work in remote SSH sessions.

Automatic paste simulates `⌘V` and requires Accessibility permission. Find Buffer under **System Settings → Privacy & Security → Accessibility**; some recent macOS versions group this under **Device Control & Data Access**. Without permission, the content remains on the clipboard for manual `⌘V` paste.

The release is an ad-hoc signed, non-notarized community build. Review the source before installing and proceed past Gatekeeper only if you trust it. Clipboard contents and screenshots remain on your Mac; update checks fetch release metadata from GitHub.

## Credits and license

Based on [Buffer by Samir Patil](https://github.com/samirpatil2000/Buffer), distributed under the MIT License. See [LICENSE](LICENSE).
