#import "UIImage+H568.h"
#import <objc/runtime.h>

@implementation UIImage(H568)

+ (void) load
{
    if  (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) {
        // Running on iPad, nothing to change.
        return;
    }

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    BOOL tallDevice = (screenBounds.size.height > 480);
    if (!tallDevice) {
        // Running on a 320✕480 device, nothing to change.
        return;
    }

    method_exchangeImplementations(
        class_getClassMethod(self, @selector(imageNamed:)),
        class_getClassMethod(self, @selector(imageNamedH568:))
    );
}

// Note that calling +imageNamedH568: here is not a recursive call,
// since we have exchanged the method implementations for +imageNamed:
// and +imageNamedH568: above.
+ (UIImage*) imageNamedH568: (NSString*) imageName
{
    NSString *tallImageName = [imageName stringByAppendingString:@"-h568@2x"];
    NSString *tallImagePath = [[NSBundle mainBundle] pathForResource:tallImageName ofType:@"png"];
    if (tallImagePath != nil) {
        // Tall image found, let’s use it. We just have to pass the
        // image name without the @2x suffix to get the correct scale.
        imageName = [imageName stringByAppendingString:@"-h568"];
    }
    return [UIImage imageNamedH568:imageName];
}

@end
