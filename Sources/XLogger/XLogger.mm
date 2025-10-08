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

#import <SSZipArchive/SSZipArchive.h>

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

@interface MarsXLoggerDefaultFormatter: NSObject <DDLogFormatter>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation MarsXLoggerDefaultFormatter

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSDate *timestamp = logMessage.timestamp ?: [NSDate date];
    NSString *fileName = [logMessage.fileName lastPathComponent];
    NSUInteger lineNumber = logMessage.line;
    NSString *functionName = logMessage.function ?: @"";
    NSString *flagName;
    switch (logMessage.flag) {
        case DDLogFlagError:
            flagName = @"Error";
            break;
        case DDLogFlagWarning:
            flagName = @"Warning";
            break;
        case DDLogFlagInfo:
            flagName = @"Info";
            break;
        case DDLogFlagDebug:
            flagName = @"Debug";
            break;
        case DDLogFlagVerbose:
            flagName = @"Verbose";
            break;
        default:
            flagName = @"Unknown";
            break;
    }
    
    return [NSString stringWithFormat:@"[%@] [%@] %@:%lu %@: %@",
            [self.dateFormatter stringFromDate:timestamp],
            flagName,
            fileName,
            (unsigned long)lineNumber,
            functionName,
            logMessage.message];
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return _dateFormatter;
}

@end

@interface MarsXLogger ()
@property (nonatomic, copy) NSString *logDir;
@property (nonatomic) MarsXLoggerDefaultFormatter *defaultFormatter;
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
    id <DDLogFormatter> logFormatter = _logFormatter;
    if (_logFormatter == nil) {
        logFormatter = self.defaultFormatter;
    }
    const char *message = [[logFormatter formatLogMessage:logMessage] UTF8String];
    xlogger_Write(&info, message);
}

- (nullable NSURL *)zipLogs:(NSError **)error {
    NSURL *pathURL = [self getLogPath];
    if (!pathURL) {
        return nil;
    }
    
    NSString *path = [pathURL path];
    // 检查日志文件夹是否存在
    BOOL isDirectory = YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
        return nil;
    }
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *zipFileName = [NSString stringWithFormat:@"%@.zip", bundleIdentifier];
    
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *zipFilePath = [cacheDir stringByAppendingPathComponent:zipFileName];
    
    if ([fileManager fileExistsAtPath:zipFilePath]) {
        @try {
            [fileManager removeItemAtPath:zipFilePath error:error];
            if (*error) {
                return nil;
            }
        } @catch (NSException *exception) {
            if (error) {
                *error = [NSError errorWithDomain:@"LogZipError"
                                             code:-3
                                         userInfo:@{NSLocalizedDescriptionKey: @"Failed to remove existing zip file"}];
            }
            return nil;
        }
    }
    BOOL success = [SSZipArchive createZipFileAtPath:zipFilePath withContentsOfDirectory:path];
    if (success) {
        return [NSURL fileURLWithPath:zipFilePath];
    } else {
        if (error) {
            *error = [NSError errorWithDomain:@"LogZipError"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create zip file"}];
        }
        return nil;
    }
}

- (void)zipLogsWithCompletion:(void (^)(NSURL *_Nullable, NSError *_Nullable))completion {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSURL *resultURL = [weakSelf zipLogs:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(resultURL, error);
            }
        });
    });
}

- (MarsXLoggerDefaultFormatter *)defaultFormatter {
    if (!_defaultFormatter) {
        _defaultFormatter = [[MarsXLoggerDefaultFormatter alloc] init];
    }
    return _defaultFormatter;
}

@end
