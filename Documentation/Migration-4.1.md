# 从 4.0 迁移到 4.1

## 删除自定义 item 尺寸

`JXPhotoBrowserDelegate.photoBrowser(_:sizeForItemAt:)` 已删除。4.1 的每个 Cell 固定使用浏览器整页尺寸，以保证系统分页、循环索引和页间距使用同一几何模型。

## 使用正式数据重载入口

将：

```swift
browser.collectionView.reloadData()
```

替换为：

```swift
browser.reloadData()
```

若希望重载后重新使用 `initialIndex`：

```swift
browser.reloadData(preservingCurrentPage: false)
```

## 内嵌模式

Banner 必须使用 View Controller containment，并设置：

```swift
browser.isDismissGestureEnabled = false
```

仅把 `browser.view` 添加为子视图不再是受支持的集成方式。

## 自动轮播

`autoPlayInterval` 的最小值为 0.5 秒。运行时修改间隔会重新调度 Timer；Timer 只会在浏览器完成初始定位且可见时启动。
