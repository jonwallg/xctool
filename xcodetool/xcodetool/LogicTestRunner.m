
#import "LogicTestRunner.h"
#import "XcodeToolUtil.h"
#import "TaskUtil.h"
#import "PJSONKit.h"

@implementation LogicTestRunner

- (BOOL)runTestsAndFeedOutputTo:(void (^)(NSString *))outputLineBlock error:(NSString **)error
{
  NSString *octestBundlePath = [_buildSettings[@"BUILT_PRODUCTS_DIR"] stringByAppendingPathComponent:_buildSettings[@"EXECUTABLE_FOLDER_PATH"]];

  if ([[NSFileManager defaultManager] fileExistsAtPath:octestBundlePath] ||
      // Always take this path when we're under test.
      [[[NSProcessInfo processInfo] processName] isEqualToString:@"otest"]) {
    NSString *version = [_buildSettings[@"SDK_NAME"] stringByReplacingOccurrencesOfString:@"iphonesimulator" withString:@""];
    NSString *simulatorHome = [NSString stringWithFormat:@"%@/Library/Application Support/iPhone Simulator/%@", NSHomeDirectory(), version];
    
    NSDictionary *taskEnvironment = @{
                                      @"CFFIXED_USER_HOME" : simulatorHome,
                                      @"HOME" : simulatorHome,
                                      @"IPHONE_SHARED_RESOURCES_DIRECTORY" : simulatorHome,
                                      @"DYLD_FALLBACK_FRAMEWORK_PATH" : @"/Developer/Library/Frameworks",
                                      @"DYLD_FRAMEWORK_PATH" : _buildSettings[@"BUILT_PRODUCTS_DIR"],
                                      @"DYLD_LIBRARY_PATH" : _buildSettings[@"BUILT_PRODUCTS_DIR"],
                                      @"DYLD_ROOT_PATH" : _buildSettings[@"SDKROOT"],
                                      @"IPHONE_SIMULATOR_ROOT" : _buildSettings[@"SDKROOT"],
                                      @"IPHONE_SIMULATOR_VERSIONS" : @"iPhone Simulator (external launch) , iPhone OS 6.0 (unknown/10A403)",
                                      @"NSUnbufferedIO" : @"YES",
                                      @"DYLD_INSERT_LIBRARIES" : [PathToFBXcodetoolBinaries() stringByAppendingPathComponent:@"otest-lib-ios.dylib"],
                                      };
    
    NSArray *taskArguments = @[
                               @"-NSTreatUnknownArgumentsAsOpen", @"NO",
                               @"-ApplePersistenceIgnoreState", @"YES",
                               @"-SenTestInvertScope", _senTestInvertScope ? @"YES" : @"NO",
                               @"-SenTest", _senTestList,
                               octestBundlePath,
                               ];
    
    NSTask *task = TaskInstance();
    [task setLaunchPath:[NSString stringWithFormat:@"%@/Developer/usr/bin/otest", _buildSettings[@"SDKROOT"]]];
    [task setArguments:taskArguments];
    [task setEnvironment:taskEnvironment];
    
    LaunchTaskAndFeedOuputLinesToBlock(task, outputLineBlock);
    
    return [task terminationStatus] == 0 ? YES : NO;
  } else {
    *error = [NSString stringWithFormat:@"Test bundle not found at: %@", octestBundlePath];
    return NO;
  }
}

@end
