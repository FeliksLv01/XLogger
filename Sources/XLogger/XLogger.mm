//
//  XLogger.mm
//  XLogger
//
//  Created by FeliksLv on 2025/10/6.
//

#import "XLogger.h"

#import <mars/xlog/appender.h>
#import <mars/xlog/xlogger.h>
#import <mars/xlog/xloggerbase.h>

@implementation MarsXLoggerConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _cacheDays = 7;
        _pubKey = @"";
        _compressMode = MarsXLoggerCompressModeZlib;
        _compressLevel = 6;
    }
    return self;
}

@end

@interface MarsXLogger ()
@property(nonatomic, copy) NSString *logDir;
@end

@implementation MarsXLogger

+ (MarsXLogger *)shared {
    static MarsXLogger *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MarsXLogger alloc] init];
    });
    return instance;
}

- (void)setupXLog:(MarsXLoggerConfig *)config {
    // 设置 XLog 配置
    mars::xlog::XLogConfig xlogConfig;
    xlogConfig.mode_ = mars::xlog::kAppenderAsync;
    NSString* logPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:config.logDir];
    self.logDir = logPath;
    
    xlogConfig.logdir_ = [logPath UTF8String];
    xlogConfig.nameprefix_ = config.namePrefix ? [config.namePrefix UTF8String] : "xlog";
    xlogConfig.pub_key_ = [config.pubKey UTF8String];
    xlogConfig.compress_mode_ = (mars::xlog::TCompressMode)config.compressMode;
    xlogConfig.compress_level_ = (int)config.compressLevel;
    xlogConfig.cachedir_ = "";
    xlogConfig.cache_days_ = (unsigned int)config.cacheDays;
    
#if DEBUG
    
    xlogger_SetLevel((TLogLevel)kLevelDebug);
#else
    
    xlogger_SetLevel((TLogLevel)kLevelInfo);
#endif
    
    mars::xlog::appender_open(xlogConfig);
}

- (nullable NSURL *)getLogPath {
    if (self.logDir) {
        return [NSURL fileURLWithPath:self.logDir];
    }
    return nil;
}

- (void)close {
    mars::xlog::appender_close();
}

- (void)logMessage:(DDLogMessage *)logMessage {
    // 转换 DDLogLevel 到 TLogLevel
    TLogLevel level;
    switch (logMessage.level) {
        case DDLogLevelVerbose:
            level = kLevelVerbose;
            break;
        case DDLogLevelDebug:
            level = kLevelDebug;
            break;
        case DDLogLevelInfo:
            level = kLevelInfo;
            break;
        case DDLogLevelWarning:
            level = kLevelWarn;
            break;
        case DDLogLevelError:
            level = kLevelError;
            break;
        default:
            level = kLevelInfo;
            break;
    }
    
    // 提取文件名
    const char *filename =
    logMessage.file ? [logMessage.file.lastPathComponent UTF8String] : "";
    
    // 构建 XLoggerInfo
    XLoggerInfo info;
    info.level = level;
    // 写入日志
    xlogger_Write(&info, [[_logFormatter formatLogMessage:logMessage] UTF8String]);
}

@end
