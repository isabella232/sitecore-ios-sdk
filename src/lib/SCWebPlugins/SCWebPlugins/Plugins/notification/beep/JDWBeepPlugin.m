
#import "SCWebPlugin.h"

#include "JBeepFileURL.h"

#import <AudioToolbox/AudioToolbox.h>

static SystemSoundID systemSoundID( void )
{
    static SystemSoundID result_;
	static dispatch_once_t predicate_;

	dispatch_once( &predicate_, ^void( void )
    {
        AudioServicesCreateSystemSoundID( (__bridge CFURLRef)jdfBeepFileURL()
                                         , &result_ );
    } );

    return result_;
}

@interface JDWBeepPlugin : NSObject < SCWebPlugin >

@property ( nonatomic, weak ) id< SCWebPluginDelegate > delegate;

@end

@implementation JDWBeepPlugin
{
    NSURLRequest* _request;
}

-(id)initWithRequest:( NSURLRequest* )request_
{
    self = [ super init ];

    if ( self )
    {
        self->_request = request_;
    }

    return self;
}

+(BOOL)canInitWithRequest:( NSURLRequest* )request_
{
    return [ request_.URL.path isEqualToString: @"/scmobile/notification/beep" ];
}

-(void)didOpenInWebView:( UIWebView* )webView_
{
    AudioServicesPlaySystemSound( systemSoundID() );

    [ self.delegate close ];
}

@end
