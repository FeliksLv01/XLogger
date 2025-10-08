//
//  XLogger.h
//  XLogger
//
//  Created by FeliksLv on 2025/10/6.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MarsXLoggerCompressMode) {
    MarsXLoggerCompressModeZlib = 0,
    MarsXLoggerCompressModeZstd = 1
};

typedef NS_ENUM(NSUInteger, MarsXLoggerLevel) {
    MarsXLoggerLevelVerbose = 0,
    MarsXLoggerLevelDebug,
    MarsXLoggerLevelInfo,
    MarsXLoggerLevelWarn,
    MarsXLoggerLevelError,
    MarsXLoggerLevelFatal,
    MarsXLoggerLevelNone,
};

/// MarsXLogger 配置类
@interface MarsXLoggerConfig : NSObject

/// 日志写入目录
@property (nonatomic, copy) NSString *logDir;

/// 日志文件名前缀
@property (nonatomic, copy, nullable) NSString *namePrefix;

/// 缓存天数
@property (nonatomic, assign) NSUInteger cacheDays;

/// 加密公钥
@property (nonatomic, copy) NSString *pubKey;

/// 压缩模式
@property (nonatomic, assign) MarsXLoggerCompressMode compressMode;

/// 压缩级别 (1-9)
@property (nonatomic, assign) NSUInteger compressLevel;

@end

@interface MarsXLogger : DDAbstractLogger

/// 单例实例
@property (class, nonatomic, readonly) MarsXLogger *shared;

/// 初始化并配置 XLog
/// - Parameter config: MarsXLogger 配置对象
- (void)setupXLog:(MarsXLoggerConfig *)config;

/// 获取日志路径
- (nullable NSURL *)getLogPath;

/// 关闭 XLog
- (void)close;

/// 压缩日志并返回压缩包路径
- (void)zipLogsWithCompletion:(void (^)(NSURL *_Nullable, NSError *_Nullable))completion;

@end

NS_ASSUME_NONNULL_END
