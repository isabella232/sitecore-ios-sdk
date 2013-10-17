#import "SCItemRecord+SCItemSource.h"

#import "SCItemSourcePOD.h"
#import "SCExtendedApiContext.h"


@implementation SCItemRecord (SCItemSource)

@dynamic itemSource;

-(SCItemSourcePOD*)getSource
{
    // @adk
    // TODO : replace legacy implementation with actual source

    
    if ( nil == self.itemSource )
    {
        return [ self getSourceFromContext ];
    }
    
    return self.itemSource;
}

-(SCItemSourcePOD*)getSourceFromContext
{
    SCExtendedApiContext* context = self.apiContext;
    if ( nil == context )
    {
        return nil;
    }
    
    SCItemSourcePOD* result = [ SCItemSourcePOD new ];
    {
        result.database = context.defaultDatabase;
        result.language = context.defaultLanguage;
        result.site     = context.defaultSite    ;
    }

    return result;
}

@end
