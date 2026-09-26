# platform-support Specification

## Purpose
明确图片浏览器面向宿主应用的最低系统兼容性，以及不同发布方式和示例的支持范围，保证部署配置、文档与产物一致，并约束示例保存媒体时只请求添加相册的权限。

## Requirements

### Requirement: 库最低支持 iOS 15

库 SHALL 在 SwiftPM、CocoaPods 和框架构建配置中统一声明最低 iOS 15.0，保留既有公开浏览接口及隐私清单打包。

#### Scenario: 使用受支持的宿主集成
- **WHEN** 宿主使用 iOS 15.0 或更高部署目标集成当前库
- **THEN** 库能编译并包含隐私清单，不要求宿主将最低版本提升至 iOS 16 或 26

#### Scenario: 查看系统支持说明
- **WHEN** 开发者阅读中英文安装说明
- **THEN** 文档明确最低 iOS 15，不再声称当前版本支持 iOS 12 至 14

### Requirement: 示例部署范围明确且可构建

UIKit 和 Carthage 示例 SHALL 支持 iOS 15.0 起的系统；使用现代导航容器的 SwiftUI 示例 SHALL 明确要求 iOS 16.0。工程级与 target 级的 Debug/Release 配置 MUST 保持一致。

#### Scenario: 默认构建示例
- **WHEN** 开发者使用 Xcode 27 安装依赖并构建示例
- **THEN** 不需要在构建命令中覆盖部署目标，CocoaPods 生成的 iOS target 也不得低于 iOS 15

### Requirement: 保存媒体使用只添加授权

UIKit 示例 SHALL 使用只添加相册的授权保存图片和视频；授权后继续原有保存流程，拒绝时给出原有失败提示且不开始保存。

#### Scenario: 首次申请授权或已有授权
- **WHEN** 用户保存媒体且授权尚未决定或已经允许
- **THEN** 示例只请求添加权限或直接继续保存，不调用旧版读写相册授权接口

#### Scenario: 拒绝授权
- **WHEN** 用户拒绝添加相册权限
- **THEN** 示例提示无法保存；视频保存状态允许用户之后重新尝试
