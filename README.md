# JXPhotoBrowser

[![Version](https://img.shields.io/cocoapods/v/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)
[![License](https://img.shields.io/cocoapods/l/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)
[![Platform](https://img.shields.io/cocoapods/p/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)

# Features


# Version History

## Version 2.0.0
**2018/10/17**
- 重新设计了接口，使用起来更简单易懂。
- 进行了大规模重构，代码更优雅，更易扩展，更易维护。

## Version 1.6.1
1.x版本不再更新功能，若要使用，可参考：[Version_1.x](Version_1.x.md)

查看更多日志：[CHANGELOG](CHANGELOG.md)

# Requirements
- iOS 9.0
- Xcode 10
- Swift 4.2

# Installation

## CocoaPods
更新你的本地仓库以同步最新版本
```
pod repo update
```
在你项目的Podfile中配置
```
pod 'JXPhotoBrowser'
```
如果需要加载WebP图片，则配置
```
pod 'JXPhotoBrowser/KingfisherWebP'
```

# Usage

待补充。

## Install 出错：Error installing libwebp
谷歌家的`libwebp`是放在他家网上的，`pod 'libwebp'`的源指向了谷歌域名的地址，解决办法一是翻墙，二是把本地 repo 源改为放在 Github 上的镜像：
1. `pod search libwebp` 看看有哪些版本，记住你想 install 的版本号，一般用最新的就行，比如 1.0.0。
2. `pod repo` 查看 master 的 path，进入目录搜索 libwebp，进入 libwebp -> 1.0.0，找到`libwebp.podspec.json`
3. 打开`libwebp.podspec.json`，修改 source 地址：
```
"source": {
    "git": "https://github.com/webmproject/libwebp",
    "tag": "v1.0.0
  },
```
4. 回到你的项目目录，可以愉快地`pod install`了~

# 初版实现思路

记录了初版实现思路：[ARTICLE](ARTICLE.md)

# 感谢

若使用过程中有任何问题，请issues我。 ^_^
