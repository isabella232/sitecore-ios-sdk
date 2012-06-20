#import "NSURL+URLWithItemsReaderRequest.h"

#import "SCEditItemsRequest.h"
#import "SCCreateItemRequest.h"
#import "SCItemsReaderRequest.h"
#import "SCCreateMediaItemRequest.h"

#import "SCItemsReaderRequest+Factory.h"
#import "SCCreateMediaItemRequest+ToItemsReadRequest.h"
#import "SCApiContext.h"

#include <math.h>

static NSString* const apiVersion_ = @"v1";

@interface NSString (URLWithItemsReaderRequest)
@end

@implementation NSString (URLWithItemsReaderRequest)

-(NSString*)apiVersionPathWithSitecoreShell
{
    return [ self stringByAppendingString: @"/sitecore/shell" ];
}

@end

@interface SCItemsReaderRequest (URLWithItemsReaderRequestPrivate)

@property ( nonatomic, readonly ) NSString* database;

@end

@implementation SCItemsReaderRequest (URLWithItemsReaderRequest)

-(NSString*)pathURLParam
{
    return ( self.requestType == SCItemReaderRequestItemPath && self.request )
        ? [ self.request stringByEncodingURLFormat ]
        : @"";
}

-(NSString*)itemIdURLParam
{
    NSString* request_ = [ ( self.request ?: @"" ) stringByEncodingURLFormat ];
    return ( self.requestType == SCItemReaderRequestItemId )
        ? [ NSString stringWithFormat: @"sc_itemid=%@", request_ ]
        : @"";
}

-(NSString*)scopeURLParam
{
    if ( self.requestType == SCItemReaderRequestQuery )
        return @"";

    NSArray* scopes_ = [ NSMutableArray arrayWithObjects: @"p"
                        , @"s"
                        , @"c"
                        , nil ];

    scopes_ = [ scopes_ selectWithIndex: ^BOOL( id object_, NSUInteger index_ )
    {
        NSUInteger paw_ = pow( 2, index_ );
        return ( self.scope & paw_ );
    } ];

    NSString* result_ = [ scopes_ componentsJoinedByString: @"|" ];
    result_ = [ result_ stringByEncodingURLFormat ];
    return [ NSString stringWithFormat: @"scope=%@", result_ ];
}

-(NSString*)queryURLParam
{
    if ( self.requestType != SCItemReaderRequestQuery )
        return @"";

    NSString* request_ = [ self.request ?: @"" stringByEncodingURLFormat ];
    return [ NSString stringWithFormat: @"query=%@", request_ ];
}

-(NSString*)fieldsURLParam
{
    if ( !self.fieldNames )
        return @"";

    if ( [ self.fieldNames count ] == 0 )
        return @"payload=1";

    NSString* fieldsParams_ = [ [ self.fieldNames allObjects ] componentsJoinedByString: @"|" ];
    return [ NSString stringWithFormat: @"fields=%@", [ fieldsParams_ stringByEncodingURLFormat ] ];
}

-(NSString*)pagesURLParam
{
    return self.pageSize == 0
        ? @""
        : [ NSString stringWithFormat: @"pageSize=%d&page=%d", self.pageSize, self.page ];
}

@end

@implementation NSURL (URLWithItemsReaderRequest)

+(NSString*)nameParamWithName:( NSString* )name_
{
    name_ = [ name_ stringByEncodingURLFormat ];
    return [ name_ length ] == 0
        ? @""
        : [ NSString stringWithFormat: @"name=%@", name_ ];
}

+(NSString*)templateParamWithTemplate:( NSString* )template_
{
    template_ = [ template_ stringByEncodingURLFormat ];
    return [ template_ length ] == 0
        ? @""
        : [ NSString stringWithFormat: @"template=%@", template_ ];
}

+(NSString*)databaseParamWithDatabase:( NSString* )database_
{
    database_ = [ ( database_ ?: @"" ) stringByEncodingURLFormat ];
    return [ database_ length ]
        ? [ NSString stringWithFormat: @"sc_database=%@", database_ ]
        : @"";
}

+(NSString*)languageParamWithLanguage:( NSString* )language_
{
    if ( [ language_ length ] == 0 )
        return @"";

    return [ NSString stringWithFormat: @"sc_lang=%@", language_ ];
}

+(id)URLWithItemsReaderRequest:( SCItemsReaderRequest* )request_
                          host:( NSString* )host_
                    apiVersion:( NSString* )apiVersionWithPath_
                   newItemName:( NSString* )newItemName_
               newItemTemplate:( NSString* )newItemTemplate_
{
    NSString* databaseParam_ = [ self databaseParamWithDatabase: request_.database ];
    NSString* languageParam_ = [ self languageParamWithLanguage: request_.language ];

    NSString* nameParam_     = [ self nameParamWithName:         newItemName_     ];
    NSString* templateParam_ = [ self templateParamWithTemplate: newItemTemplate_ ];

    NSString* pathParam_   = [ request_ pathURLParam   ];
    NSString* scopeParam_  = [ request_ scopeURLParam  ];
    NSString* queryParam_  = [ request_ queryURLParam  ];
    NSString* itemIdParam_ = [ request_ itemIdURLParam ];
    NSString* fieldsParam_ = [ request_ fieldsURLParam ];
    NSString* pagesParam_  = [ request_ pagesURLParam  ];

    NSArray* params_ = [ [ NSArray alloc ] initWithObjects:
                        scopeParam_
                        , queryParam_
                        , itemIdParam_
                        , fieldsParam_
                        , pagesParam_
                        , languageParam_
                        , databaseParam_
                        , nameParam_
                        , templateParam_
                        , nil ];

    params_ = [ params_ select: ^BOOL( NSString* string_ )
    {
        return [ string_ length ] != 0;
    } ];

    NSString* hostWithSheme_ = host_;
    if ( ![ hostWithSheme_ hasPrefix: @"https://" ]
        && ![ hostWithSheme_ hasPrefix: @"http://" ] )
    {
        hostWithSheme_ = [ @"http://" stringByAppendingString: host_ ];
    }

    NSString* urlString_ = [ NSString stringWithFormat: @"%@/%@%@?%@"
                            , hostWithSheme_
                            , apiVersionWithPath_
                            , pathParam_
                            , [ params_ componentsJoinedByString: @"&" ] ];

    return [ NSURL URLWithString: urlString_ ];
}

+(id)URLWithItemsReaderRequest:( SCItemsReaderRequest* )request_
                          host:( NSString* )host_
                    apiVersion:( NSString* )lcApiVersion_
{
    return [ self URLWithItemsReaderRequest: request_
                                       host: host_
                                 apiVersion: lcApiVersion_
                                newItemName: nil
                            newItemTemplate: nil ];
}

+(id)URLWithItemsReaderRequest:( SCItemsReaderRequest* )request_
                          host:( NSString* )host_
{
    return [ self URLWithItemsReaderRequest: request_
                                       host: host_
                                 apiVersion: apiVersion_ ];
}

+(id)URLToEditItemsWithRequest:( SCItemsReaderRequest* )request_
                          host:( NSString* )host_
{
    NSString* apiVersionWithShell_ = [ apiVersion_ apiVersionPathWithSitecoreShell ];
    return [ NSURL URLWithItemsReaderRequest: request_
                                        host: host_
                                  apiVersion: apiVersionWithShell_ ];
}

+(id)URLToCreateItemWithRequest:( SCCreateItemRequest* )request_
                           host:( NSString* )host_
{
    NSString* apiVersionWithShellPath_ = [ apiVersion_ apiVersionPathWithSitecoreShell ];
    return [ self URLWithItemsReaderRequest: request_
                                       host: host_
                                 apiVersion: apiVersionWithShellPath_
                                newItemName: request_.itemName
                            newItemTemplate: request_.itemTemplate ];
}

+(id)URLToCreateMediaItemWithRequest:( SCCreateMediaItemRequest* )createItemRequest_
                                host:( NSString* )host_
                          apiContext:( SCApiContext* )apiContext_
{
    SCItemsReaderRequest* request_     = [ createItemRequest_ toItemsReadRequestWithApiContext: apiContext_ ];
    NSString* apiVersionWithShellPath_ = [ apiVersion_ apiVersionPathWithSitecoreShell ];

    return [ self URLWithItemsReaderRequest: request_
                                       host: host_
                                 apiVersion: apiVersionWithShellPath_
                                newItemName: createItemRequest_.itemName
                            newItemTemplate: createItemRequest_.itemTemplate ];
}

+(id)URLToGetRenderingHTMLLoaderForRenderingId:( NSString* )rendereringId_
                                      sourceId:( NSString* )sourceId_
                                          host:( NSString* )host_
                                    apiContext:( SCApiContext* )apiContext_
{
    NSString* hostWithSheme_ = host_;
    if ( ![ hostWithSheme_ hasPrefix: @"https://" ]
        && ![ hostWithSheme_ hasPrefix: @"http://" ] )
    {
        hostWithSheme_ = [ @"http://" stringByAppendingString: host_ ];
    }

    NSString* requestString_ = [ NSString stringWithFormat: @"%@/%@/-/system/GetRenderingHtml?database=%@&language=%@&renderingId=%@&itemId=%@"
                                , hostWithSheme_
                                , apiVersion_
                                , [ apiContext_.defaultDatabase stringByEncodingURLFormat ]
                                , [ apiContext_.defaultLanguage stringByEncodingURLFormat ]
                                , [ rendereringId_ stringByEncodingURLFormat ]
                                , [ sourceId_ stringByEncodingURLFormat ] ];

    return [ NSURL URLWithString: requestString_ ];
}

@end