# MaxNits 控制台

[MaxNits](https://github.com/yogeshvar/maxnits) 命令行工具的图形界面（SwiftUI，macOS 13+）。
MaxNits 负责解锁 MacBook Pro XDR 屏幕的亮度上限；本应用只是替你调用 `maxnits` 命令，本身不碰显示器。

## 功能

- 亮度增强总开关
- 强度滑块（0–100%，表示用掉当前 EDR 余量的多少）与 25 / 50 / 75 / 100 预设
- 每块显示器当前与上限的 EDR 余量
- 登录时自动启动守护进程、停止守护进程
- 菜单栏太阳图标，点开是同一个面板

## 前置条件

已安装 `maxnits`，位于 `~/.local/bin`、`/opt/homebrew/bin` 或 `/usr/local/bin` 之一。

## 构建与安装

需要 Xcode Command Line Tools。

```sh
./build.sh            # 生成 dist/MaxNitsControl.app
./build.sh install    # 生成并复制到 /Applications
```

图标由 `scripts/make_icon.swift` 绘制，改完后跑 `./scripts/make_icns.sh` 重新生成 `Resources/AppIcon.icns`。
