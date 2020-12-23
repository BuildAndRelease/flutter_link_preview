#import "LinkFetchPlugin.h"
#if __has_include(<flutter_link_preview/flutter_link_preview-Swift.h>)
#import <flutter_link_preview/flutter_link_preview-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_link_preview-Swift.h"
#endif

@implementation LinkFetchPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftLinkFetchPlugin registerWithRegistrar:registrar];
}
@end
