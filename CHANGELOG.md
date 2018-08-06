# Version History

## Version 1.4.0
**2018/07/15**
- 现在可以自由选用Cell插件
- 支持嵌入导航栏
- 支持谷歌`WebP`格式
- Cell 插件协议增加 CellWillDisplay 和 CellDidEndDisplaying 回调
- 图片下拉手势现在改为加在`cell.contentView`上
- 增加`scrollToItem()`方法，可随时控制滑动到哪张图片

## Version 1.3.3
**2018/07/02**
- 让查看原图按钮插件暴露一些常用属性，增加背景色，提高在白图上的辨识度。
- 现在可以通过PhotoBrowser类主动调用加载原图方法。

## Version 1.3.2
**2018/06/17**
- 修复`locationInView`返回`nan`导致 crash 的问题。

## Version 1.3.1
**2018/06/11**
- 修复取`TopMostViewController`可能不正确的问题。

## Version 1.3.0
**2018/06/04**
- 在`scale`转场模式下，可选择不隐藏关联缩略图。设置`animationType = .scaleNoHiding`即可。
- 对于浏览本地图片，现在同时支持传图片组和通过代理取本地图片两种方式。

## Version 1.2.0
**2018/5/26**
- 优化`DefaultPageControlPlugin.centerBottomY`和`NumberPageControlPlugin.centerY`为可选属性。在这两个属性为`nil`时，将使用默认值，并进行`iPhoneX`适配。如果用户为这两个属性赋了值，则框架认为用户自行完成了适配，将直接使用所赋值。

## Version 1.1.2
**2018/5/24**
- 修复`.fade模式`下的`originPageIndex`无效问题

## Version 1.1.1
**2018/5/23**
- 修正`DefaultPageControlPlugin`和`NumberPageControlPlugin`在`iPhoneX`上的偏移

## Version 1.1.0 
**2018/5/22**
- 重构本地图片浏览方法
    - 由原来的通过协议方式取本地图片，改为直接在打开图片浏览时传入图片组：
    ```swift
    PhotoBrowser.show(localImages: localImages, originPageIndex: index)
    ```
    - 删除`PhotoBrowserDelegate.photoBrowser(_:, localImageForIndex:)`
    - 新增`PhotoBrowser.localImages`属性，接收传入的图片组
    - 新增`PhotoBrowser.show(localImages:)`类方法，一行代码打开图片浏览器
- 新增`PhotoBrowser.deleteItem(at index: Int)`，支持删除动画
- 优化`PhotoBrowser.reloadData`，更好支持数据源删减操作
- 优化`PhotoBrowser.viewWillTransition`，处理屏幕旋转
- 优化`PhotoBrowser.viewDidLayoutSubviews`
- 优化`PhotoBrowser.dismiss`，修复状态栏显示问题
- `PhotoBrowser.photoLoader`属性不再是可选，必须给值
- 为了更准确表达方法含义，重命名以下协议方法（请原谅我再一次改方法名 >o<）：
    - `PhotoBrowserPlugin`协议：`photoBrowser(_:, scrollView:)`重命名为`photoBrowser(_:, scrollViewDidScroll:)`
    - `PhotoPhotoBrowserDelegate`协议：`photoBrowser(_:, originViewForIndex:)`重命名为`photoBrowser(_:, thumbnailViewForIndex:)`
    - `PhotoPhotoBrowserDelegate`协议：`photoBrowser(_:, originImageForIndex:)`重命名为`photoBrowser(_:, thumbnailImageForIndex:)`

## Version 1.0.0 
**2018/5/17**
- 稳定主要API，完成大部分功能的设计与实现

## Version 0.0.1
**2017/4/13**
- 完成初版实现
