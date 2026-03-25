Pod::Spec.new do |spec|
  spec.name         = "XLogger"
  spec.version      = "0.0.6"
  spec.summary      = "A logging framework based on Mars XLog"
  spec.description  = "XLogger is a logging framework that integrates Mars XLog with CocoaLumberjack for iOS applications."
  
  spec.homepage     = "https://github.com/FeliksLv01/XLogger"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Your Name" => "your.email@example.com" }
  
  spec.ios.deployment_target = '12.0'
  spec.source       = { :git => "https://github.com/FeliksLv01/XLogger.git", :tag => "#{spec.version}" }
  
  spec.source_files = "Sources/XLogger/*.{h,mm,m}"
  spec.public_header_files = "Sources/XLogger/*.h"
  
  spec.vendored_frameworks = "XCFrameworks/mars.xcframework"
  
  spec.dependency "CocoaLumberjack"
  spec.dependency "SSZipArchive"
  
  spec.library = 'c++'
  
  spec.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
  }
end
 
