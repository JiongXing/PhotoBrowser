# 自定义Cell注册功能使用指南

## 功能概述

JXPhotoBrowser 框架现在支持注册自定义Cell，允许调用方创建完全自定义的Cell类来展示图片或视频，同时保持框架的简单易用性。

## 设计特点

### 1. 简单易用
- **默认行为**：无需任何额外代码，框架自动使用 `JXPhotoCell` 和 `JXVideoCell`
- **自动注册**：如果通过 `cellClassForItemAt` 返回自定义Cell类，框架会自动注册和管理

### 2. 高可定制性
- **完全自定义**：可以创建继承自 `JXPhotoCell` 的自定义Cell类
- **灵活注册**：支持提前注册或延迟注册（自动注册）
- **自定义标识符**：可以指定自定义的 `reuseIdentifier`，或使用框架自动生成的

## 使用方式

### 方式一：提前注册（推荐）

在创建 `JXPhotoBrowser` 实例后、设置 `delegate` 之前注册自定义Cell：

```swift
let browser = JXPhotoBrowser()

// 注册自定义Cell（指定reuseIdentifier）
browser.register(CustomPhotoCell.self, forReuseIdentifier: CustomPhotoCell.customReuseIdentifier)

// 或者不指定reuseIdentifier，框架会自动生成
browser.register(CustomPhotoCell.self)

browser.delegate = self
browser.present(from: self)
```

### 方式二：延迟注册（自动注册）

如果未提前注册，框架会在 `cellForItemAt` 时自动注册：

```swift
// 只需在 delegate 方法中返回自定义Cell类
func photoBrowser(_ browser: JXPhotoBrowser, cellClassForItemAt index: Int) -> AnyClass? {
    if index < 3 {
        return CustomPhotoCell.self  // 框架会自动注册
    }
    return JXPhotoCell.self
}
```

## 创建自定义Cell

### 基本要求

1. **继承自 `JXPhotoCell`**：
```swift
class CustomPhotoCell: JXPhotoCell {
    // 自定义实现
}
```

2. **实现必要的初始化方法**：
```swift
override init(frame: CGRect) {
    super.init(frame: frame)
    setupCustomUI()
}

required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupCustomUI()
}
```

3. **可选：重写生命周期方法**：
```swift
override func prepareForReuse() {
    super.prepareForReuse()
    // 重置自定义状态
}

override func reloadContent() {
    super.reloadContent()
    // 添加自定义逻辑
}
```

### 完整示例

参考 `Demo/HomePage/CustomPhotoCell.swift` 中的完整实现示例。

## API 说明

### JXPhotoBrowser

#### `register(_:forReuseIdentifier:)`
注册自定义Cell类到浏览器实例。

- **参数**：
  - `cellClass`: 要注册的Cell类（必须继承自 `JXPhotoCell`）
  - `reuseIdentifier`: 可选的复用标识符，如果为 `nil` 则自动生成
- **返回**：实际使用的 `reuseIdentifier`

#### `cellRegistry`
Cell注册管理器的只读属性，用于访问注册信息。

### JXPhotoBrowserDelegate

#### `photoBrowser(_:cellClassForItemAt:)`
为指定索引返回要使用的Cell类。

- **返回**：
  - `AnyClass?`: Cell类，如果返回 `nil` 则使用默认的 `JXPhotoCell`
  - 如果返回未注册的自定义Cell类，框架会自动注册

## 注意事项

1. **Cell类必须继承自 `JXPhotoCell`**：框架依赖 `JXPhotoCell` 的基础功能（如缩放、转场等）

2. **reuseIdentifier 唯一性**：如果指定自定义 `reuseIdentifier`，请确保其唯一性，避免与其他Cell冲突

3. **注册时机**：建议在创建 `JXPhotoBrowser` 实例后立即注册自定义Cell，这样可以避免延迟注册可能带来的性能开销

4. **线程安全**：Cell注册管理器使用单例模式，在多线程环境下需要注意线程安全

## 示例场景

### 场景1：为特定索引使用自定义Cell
```swift
func photoBrowser(_ browser: JXPhotoBrowser, cellClassForItemAt index: Int) -> AnyClass? {
    // 前3个使用自定义Cell，其他使用默认Cell
    return index < 3 ? CustomPhotoCell.self : JXPhotoCell.self
}
```

### 场景2：根据资源类型选择Cell
```swift
func photoBrowser(_ browser: JXPhotoBrowser, cellClassForItemAt index: Int) -> AnyClass? {
    let resource = getResource(at: index)
    if resource.isSpecial {
        return SpecialPhotoCell.self
    }
    return JXPhotoCell.self
}
```

## 技术实现

- **注册管理器**：`JXPhotoBrowserCellRegistry` 负责管理Cell类与 `reuseIdentifier` 的映射关系
- **自动注册**：在 `cellForItemAt` 中检测到未注册的Cell类时，自动注册到管理器和 `UICollectionView`
- **延迟注册**：如果 `collectionView` 尚未加载，会在首次使用时注册
