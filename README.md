# XLogger

[![Version](https://img.shields.io/badge/version-0.0.1-blue.svg)](https://github.com/yourusername/XLogger)
[![Platform](https://img.shields.io/badge/platform-iOS%2012.0%2B-lightgrey.svg)](https://github.com/yourusername/XLogger)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

XLogger 是一个基于 Mars XLog 的 iOS 日志框架，集成了 CocoaLumberjack，为 iOS 应用提供高性能、可配置的日志记录解决方案。

## 特性

- 🚀 **高性能**: 基于腾讯 Mars XLog，支持异步日志写入
- 🔒 **安全**: 支持日志加密，保护敏感信息
- 📦 **压缩**: 支持 Zlib 和 Zstd 压缩算法，节省存储空间
- 🔧 **可配置**: 灵活的配置选项，满足不同场景需求
- 🔌 **兼容**: 完全兼容 CocoaLumberjack，无缝集成现有项目
- 📱 **iOS 优化**: 专为 iOS 平台优化，支持 iOS 12.0+

## 安装

### CocoaPods

在你的 `Podfile` 中添加：

```ruby
pod 'XLogger'
```

然后运行：

```bash
pod install
```

### 手动安装

1. 下载项目源码
2. 将 `Sources/XLogger` 文件夹拖入你的项目
3. 将 `Frameworks/mars.framework` 添加到项目中
4. 添加 CocoaLumberjack 依赖

## 使用方法

### 基本配置

```objc
#import <XLogger/XLogger.h>

// 创建配置对象
MarsXLoggerConfig *config = [[MarsXLoggerConfig alloc] init];
config.logDir = @"/xlogger";  // 日志目录
config.namePrefix = @"myapp"; // 日志文件名前缀
config.cacheDays = 7;         // 缓存天数
config.pubKey = @"";          // 加密公钥（可选）
config.compressMode = MarsXLoggerCompressModeZlib; // 压缩模式
config.compressLevel = 6;     // 压缩级别

// 初始化 XLogger
[[MarsXLogger shared] setupXLog:config];

// 添加到 DDLog
[DDLog addLogger:[MarsXLogger shared]];
```

### 日志记录

使用标准的 CocoaLumberjack 宏进行日志记录：

```objc
// 不同级别的日志
DDLogVerbose(@"详细信息");
DDLogDebug(@"调试信息");
DDLogInfo(@"一般信息");
DDLogWarn(@"警告信息");
DDLogError(@"错误信息");

// 带参数的日志
DDLogInfo(@"用户 %@ 登录成功", username);
DDLogError(@"网络请求失败，错误码: %d", errorCode);
```

### 获取日志路径

```objc
NSURL *logPath = [[MarsXLogger shared] getLogPath];
NSLog(@"日志路径: %@", logPath.path);
```

### 关闭日志

```objc
// 应用退出时关闭日志
[[MarsXLogger shared] close];
```

## 配置选项

### MarsXLoggerConfig

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `logDir` | NSString* | 必填 | 日志文件存储目录 |
| `namePrefix` | NSString* | nil | 日志文件名前缀 |
| `cacheDays` | NSUInteger | 7 | 日志缓存天数 |
| `pubKey` | NSString* | @"" | 加密公钥，为空则不加密 |
| `compressMode` | MarsXLoggerCompressMode | Zlib | 压缩模式 |
| `compressLevel` | NSUInteger | 6 | 压缩级别 (1-9) |

### 压缩模式

```objc
typedef NS_ENUM(NSUInteger, MarsXLoggerCompressMode) {
    MarsXLoggerCompressModeZlib = 0,  // Zlib 压缩
    MarsXLoggerCompressModeZstd = 1   // Zstd 压缩
};
```

### 日志级别

```objc
typedef NS_ENUM(NSUInteger, MarsXLoggerLevel) {
    MarsXLoggerLevelVerbose = 0,
    MarsXLoggerLevelDebug,
    MarsXLoggerLevelInfo,
    MarsXLoggerLevelWarn,
    MarsXLoggerLevelError,
    MarsXLoggerLevelFatal,
    MarsXLoggerLevelNone,
};
```

## 高级用法

### 自定义日志格式

```objc
// 设置自定义格式化器
MarsXLogger *logger = [MarsXLogger shared];
logger.logFormatter = [[MyCustomFormatter alloc] init];
[DDLog addLogger:logger];
```
