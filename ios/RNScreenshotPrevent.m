#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import "RNScreenshotPrevent.h"
#import "UIImage+ImageEffects.h"

bool hasListeners = NO;
@interface RNScreenshotPrevent()

@property (strong, nonatomic)   UIImageView *obfuscatingView;
@property (strong, nonatomic)   UITextField *secureField;
@property (assign, nonatomic) BOOL enabled;
@end
 
@implementation RNScreenshotPrevent



#pragma mark Initialization
 

- (NSArray<NSString *> *)supportedEvents {
    return @[@"userDidTakeScreenshot"];
}

#pragma mark

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

#pragma mark - Lifecycle

- (void) startObserving {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    // handle inactive event
    [center addObserver:self selector:@selector(handleAppStateResignActive)
                            name:UIApplicationWillResignActiveNotification
                            object:nil];
    // handle active event
    [center addObserver:self selector:@selector(handleAppStateActive)
                            name:UIApplicationDidBecomeActiveNotification
                            object:nil];
    // handle screenshot taken event
    [center addObserver:self selector:@selector(handleAppScreenshotNotification)
                            name:UIApplicationUserDidTakeScreenshotNotification
                            object:nil];

    hasListeners = YES;
}

- (void) stopObserving {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    hasListeners = NO;
}
RCT_EXPORT_MODULE()
#pragma mark - App Notification Methods

/** displays blurry view when app becomes inactive */
- (void)handleAppStateResignActive {
    if (self.enabled) {
        UIWindow    *keyWindow = [UIApplication sharedApplication].keyWindow;
        UIImageView *blurredScreenImageView = [[UIImageView alloc] initWithFrame:keyWindow.bounds];

        UIGraphicsBeginImageContext(keyWindow.bounds.size);
        [keyWindow drawViewHierarchyInRect:keyWindow.frame afterScreenUpdates:NO];
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        blurredScreenImageView.image = [viewImage applyLightEffect];

        self.obfuscatingView = blurredScreenImageView;
        [keyWindow addSubview:self.obfuscatingView];
    }
}

/** removes blurry view when app becomes active */
- (void)handleAppStateActive {
    if  (self.obfuscatingView) {
        [UIView animateWithDuration: 0.3
                         animations: ^ {
                            self.obfuscatingView.alpha = 0;
                         }
                         completion: ^(BOOL finished) {
                             [self.obfuscatingView removeFromSuperview];
                             self.obfuscatingView = nil;
                         }
         ];
    }
}

/** sends screenshot taken event into app */
- (void) handleAppScreenshotNotification {
    // only send events when we have some listeners
    if(hasListeners) {
        [self sendEventWithName:@"userDidTakeScreenshot" body:nil];
    }
}

+(BOOL) requiresMainQueueSetup
{
  return YES;
}

/**
 * creates secure text field inside rootView of the app
 * taken from https://stackoverflow.com/questions/18680028/prevent-screen-capture-in-an-ios-app
 * 
 * converted to ObjC and modified to get it working with RCT
 */
-(void) addSecureTextFieldToView:(UIView *) view {
    UIView *rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
    // fixes safe-area
    self.secureField = [[UITextField alloc] initWithFrame:rootView.frame];
    self.secureField.secureTextEntry = TRUE;
    self.secureField.userInteractionEnabled = FALSE;

    [view sendSubviewToBack:self.secureField];
    [view addSubview:self.secureField];
    [view.layer.superlayer addSublayer:self.secureField.layer];
    [[self.secureField.layer.sublayers objectAtIndex:0] addSublayer:view.layer];
}

// TODO: not working now, fix crash on _UITextFieldCanvasView contenttViewInvalidated: unrecognized selector sent to instance
-(void) removeSecureTextFieldFromView:(UIView *) view {
    for(UITextField *subview in view.subviews){
        if([subview isMemberOfClass:[UITextField class]]) {
            if(subview.secureTextEntry == TRUE) {
                [subview removeFromSuperview];
                subview.secureTextEntry = FALSE;
                self.secureField.userInteractionEnabled = TRUE;
            }
        }
    }
}

#pragma mark - Public API

RCT_EXPORT_METHOD(enabled:(BOOL)enable)
{
    self.enabled = enable;
}

/** adds secure textfield view */
RCT_EXPORT_METHOD(enableSecureView)
{
    if(self.secureField.secureTextEntry == false) {
        UIView *view = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        for(UIView *subview in view.subviews) {
            [self addSecureTextFieldToView:subview];
        }
    }
}

/** removes secure textfield from the view */
RCT_EXPORT_METHOD(disableSecureView)
{
    self.secureField.secureTextEntry = false;
    UIView *view = [UIApplication sharedApplication].keyWindow.rootViewController.view;
    for(UIView *subview in view.subviews) {
        [self removeSecureTextFieldFromView:subview];
    }
}


@end
