# iOS 无签名构建流程

当前仓库的本地无签名 iOS 构建入口是 [`scripts/build_ios_unsigned.sh`](../scripts/build_ios_unsigned.sh)。

## 适用范围

- 构建目标：`Runner` 的 `release` iOS 包
- 签名方式：`--no-codesign`
- 适用场景：本地编译验证、Xcode 工程联调、为后续归档签名做预检

## 前置条件

- 安装完整 Xcode。仅安装 Command Line Tools 不够。
- 当前仓库的 iOS 最低版本已提升到 `13.0`
- 执行 `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
- 执行 `sudo xcodebuild -runFirstLaunch`
- 已安装 CocoaPods
- 如果访问 GitHub 较慢，可先设置本地代理：
- 如果 Flutter iOS artifact 从 Google 存储下载不稳定，可额外设置：

```bash
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

- 如果访问 GitHub 较慢，可先设置本地代理：

```bash
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897
```

## 脚本会做什么

- 优先使用仓库内的 `./.flutter/bin/flutter`
- 自动补齐 `gj_common` 软链
- 自动下载 `ios/libs` 预编译库
- 运行 `flutter pub get`
- 运行 `flutter precache --ios`
- 运行 `pod install`
- 执行 `flutter build ios --release --no-codesign`

## 执行命令

```bash
./scripts/build_ios_unsigned.sh
```

## 当前已知限制

- 没有完整 Xcode 时，Flutter 会报 `Xcode installation is incomplete`
- 这条链路不会产出已签名的 `ipa`
- 仓库里的旧 provisioning profile 已过期，因此正式发布仍需要更新证书与 profile
