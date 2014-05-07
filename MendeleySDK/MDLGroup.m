//
// MDLGroup.m
//
// Copyright (c) 2012-2014 shazino (shazino SAS), http://www.shazino.com/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MDLGroup.h"
#import "MDLCategory.h"
#import "MDLUser.h"
#import "MDLDocument.h"
#import "MDLFolder.h"
#import "MDLMendeleyAPIClient.h"

@interface MDLGroup ()

+ (NSString *)stringValueForType:(MDLGroupType)type;
+ (instancetype)groupWithIdentifier:(NSString *)identifier
                               name:(NSString *)name
                          ownerName:(NSString *)ownerName
                           category:(MDLCategory *)category;
+ (instancetype)groupWithRawGroup:(NSDictionary *)rawGroup;
+ (NSArray *)usersFromRawUsers:(NSArray *)rawUsers;
- (void)updateWithRawGroup:(NSDictionary *)rawGroup;
- (void)deleteAtPath:(NSString *)path
             success:(void (^)())success
             failure:(void (^)(NSError *))failure;

@end

@implementation MDLGroup

+ (NSString *)stringValueForType:(MDLGroupType)type
{
    switch (type) {
        case MDLGroupTypePrivate:
            return @"private";
        case MDLGroupTypeInvite:
            return @"invite";
        case MDLGroupTypeOpen:
        default:
            return @"open";
    }
}

+ (instancetype)groupWithIdentifier:(NSString *)identifier
                               name:(NSString *)name
                          ownerName:(NSString *)ownerName
                           category:(MDLCategory *)category
{
    MDLGroup *group = [MDLGroup new];
    group.identifier = identifier;
    group.name       = name;
    group.owner      = [MDLUser userWithIdentifier:nil
                                              name:ownerName];
    group.category   = category;
    return group;
}

+ (instancetype)groupWithRawGroup:(NSDictionary *)rawGroup
{
    MDLGroup *group = [MDLGroup new];
    [group updateWithRawGroup:rawGroup];
    return group;
}

+ (instancetype)createGroupWithName:(NSString *)name
                               type:(MDLGroupType)type
                            success:(void (^)(MDLGroup *))success
                            failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];

    MDLGroup *group = [MDLGroup new];
    group.name = name;
    group.type = type;

    NSDictionary *bodyContent = @{@"name" : group.name,
                                  @"type" : [self stringValueForType:group.type]};

    [client postPath:@"/oapi/library/groups/"
             bodyKey:@"group"
         bodyContent:bodyContent
             success:^(AFHTTPRequestOperation *operation, id responseDictionary) {
                 if ([responseDictionary isKindOfClass:[NSDictionary class]]) {
                     group.identifier = responseDictionary[@"group_id"];
                 }

                 if (success) {
                     success(group);
                 }
             } failure:failure];
    
    return group;
}

+ (void)fetchTopGroupsInPublicLibraryForCategory:(NSString *)categoryIdentifier
                                          atPage:(NSUInteger)pageIndex
                                           count:(NSUInteger)count
                                         success:(void (^)(NSArray *, NSUInteger, NSUInteger, NSUInteger, NSUInteger))success
                                         failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (categoryIdentifier) {
        parameters[@"cat"] = categoryIdentifier;
    }

    parameters[@"page"]  = @(pageIndex);
    parameters[@"items"] = @(count);

    [client getPath:@"/oapi/documents/groups"
requiresAuthentication:NO
         parameters:parameters
            success:^(AFHTTPRequestOperation *operation, NSDictionary *responseDictionary) {
                NSMutableArray *groups = [NSMutableArray array];

                for (NSDictionary *rawGroup in responseDictionary[@"groups"]) {
                    [groups addObject:[self groupWithRawGroup:rawGroup]];
                }

                if (success) {
                    success(groups,
                            [responseDictionary responseTotalResults],
                            [responseDictionary responseTotalPages],
                            [responseDictionary responsePageIndex],
                            [responseDictionary responseItemsPerPage]);
                }
            } failure:failure];
}

+ (void)fetchGroupsInUserLibrarySuccess:(void (^)(NSArray *))success
                                failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];

    [client getPath:@"/oapi/library/groups/"
requiresAuthentication:YES
         parameters:nil
            success:^(AFHTTPRequestOperation *operation, NSArray *responseObject) {
                NSMutableArray *groups = [NSMutableArray array];

                for (NSDictionary *rawGroup in responseObject) {
                    [groups addObject:[self groupWithRawGroup:rawGroup]];
                }

                if (success) {
                    success(groups);
                }
            } failure:failure];
}

- (void)updateWithRawGroup:(NSDictionary *)rawGroup
{
    NSNumberFormatter *formatter = [NSNumberFormatter new];

    self.identifier = rawGroup[@"id"];
    self.name       = rawGroup[@"name"];
    if (!self.owner) {
        self.owner = [MDLUser new];
    }

    self.owner.name         = rawGroup[@"owner"];
    self.category           = [MDLCategory categoryWithIdentifier:rawGroup[@"disciplines"][@"id"]
                                                             name:rawGroup[@"disciplines"][@"name"]
                                                             slug:nil];
    self.mendeleyURL        = [NSURL URLWithString:rawGroup[@"public_url"]];
    self.numberOfDocuments  = (rawGroup[@"size"]) ? [formatter numberFromString:rawGroup[@"size"]] : rawGroup[@"total_documents"];
    self.numberOfAdmins     = [formatter numberFromString:rawGroup[@"people"][@"admins"]];
    self.numberOfMembers    = [formatter numberFromString:rawGroup[@"people"][@"members"]];
    self.numberOfFollowers  = [formatter numberFromString:rawGroup[@"people"][@"followers"]];

    if (rawGroup[@"type"]) {
        if([rawGroup[@"type"] isEqualToString:[MDLGroup stringValueForType:MDLGroupTypePrivate]]) {
            self.type = MDLGroupTypePrivate;
        }
        else if([rawGroup[@"type"] isEqualToString:[MDLGroup stringValueForType:MDLGroupTypeInvite]]) {
            self.type = MDLGroupTypeInvite;
        }
        else if([rawGroup[@"type"] isEqualToString:[MDLGroup stringValueForType:MDLGroupTypeOpen]]
                || [rawGroup[@"type"] isEqualToString:@"public"]) {
            self.type = MDLGroupTypeOpen;
        }
    }
}

- (void)fetchDetailsSuccess:(void (^)(MDLGroup *))success
                    failure:(void (^)(NSError *))failure
{
    if (self.type == MDLGroupTypePrivate) {
        success(self);
        return;
    }

    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];

    [client getPath:[NSString stringWithFormat:@"/oapi/documents/groups/%@/", self.identifier]
requiresAuthentication:NO
         parameters:nil
            success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                [self updateWithRawGroup:responseObject];
                if (success) {
                    success(self);
                }
            } failure:failure];
}

+ (NSArray *)usersFromRawUsers:(NSArray *)rawUsers
{
    NSMutableArray *users = [NSMutableArray array];
    for (NSDictionary *rawUser in rawUsers) {
        [users addObject:[MDLUser userWithIdentifier:rawUser[@"user_id"]
                                                name:rawUser[@"name"]]];
    }

    return users;
}

- (void)fetchPeopleSuccess:(void (^)(MDLGroup *))success
                   failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];
    NSString *path = [NSString stringWithFormat:@"/oapi/%@/groups/%@/people", (self.type == MDLGroupTypePrivate) ? @"library" : @"documents", self.identifier];

    [client getPath:path
requiresAuthentication:(self.type == MDLGroupTypePrivate)
         parameters:nil
            success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                self.admins            = [MDLGroup usersFromRawUsers:responseObject[@"admins"]];
                self.numberOfAdmins    = @([self.admins count]);
                self.members           = [MDLGroup usersFromRawUsers:responseObject[@"members"]];
                self.numberOfMembers   = @([self.members count]);
                self.followers         = [MDLGroup usersFromRawUsers:responseObject[@"followers"]];
                self.numberOfFollowers = @([self.followers count]);

                if (responseObject[@"owner"]) {
                    self.owner = [MDLUser userWithIdentifier:responseObject[@"owner"][@"user_id"]
                                                        name:responseObject[@"owner"][@"name"]];
                }

                if (success) {
                    success(self);
                }
            } failure:failure];
}

- (void)fetchDocumentsAtPage:(NSUInteger)pageIndex
                       count:(NSUInteger)count
                     success:(void (^)(NSArray *, NSUInteger, NSUInteger, NSUInteger, NSUInteger))success
                     failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];
    NSString *path;
    if (self.type == MDLGroupTypePrivate) {
        path = [NSString stringWithFormat:@"/oapi/library/groups/%@/", self.identifier];
    }
    else {
        path = [NSString stringWithFormat:@"/oapi/documents/groups/%@/docs/", self.identifier];
    }

    NSDictionary *parameters = @{@"page":  @(pageIndex),
                                 @"items": @(count)};

    [client getPath:path
requiresAuthentication:(self.type == MDLGroupTypePrivate)
         parameters:parameters
            success:^(AFHTTPRequestOperation *operation, NSDictionary *responseDictionary) {
                NSArray *rawDocuments = responseDictionary[@"documents"];
                NSMutableArray *documents = [NSMutableArray array];
                for (NSDictionary *rawDocument in rawDocuments) {
                    if ([rawDocument isKindOfClass:[NSDictionary class]]) {
                        MDLDocument * document = [MDLDocument new];
                        if ([rawDocument[@"id"] isKindOfClass:[NSString class]]) {
                            document.identifier = rawDocument[@"id"];
                        }
                        if ([rawDocument[@"version"] isKindOfClass:[NSNumber class]]) {
                            document.version = rawDocument[@"version"];
                        }
                        document.group      = self;
                        [documents addObject:document];
                    }
                }
                self.documents = documents;
                self.numberOfDocuments = @(self.documents.count);

                if (success) {
                    success(self.documents,
                            [responseDictionary responseTotalResults],
                            [responseDictionary responseTotalPages],
                            [responseDictionary responsePageIndex],
                            [responseDictionary responseItemsPerPage]);
                }
            } failure:failure];
}

- (void)fetchFoldersSuccess:(void (^)(NSArray *))success
                    failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];
    NSString *path = [NSString stringWithFormat:@"/oapi/library/groups/%@/folders/",
                      self.identifier];

    [client getPath:path
requiresAuthentication:YES
         parameters:nil
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if (success) {
                    NSArray *folders = [MDLFolder treefiedFoldersFromResponseObject:responseObject];
                    success(folders);
                }
            } failure:failure];
}

- (void)deleteAtPath:(NSString *)path
             success:(void (^)())success
             failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];

    [client deletePath:path
            parameters:nil
               success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                   if (success) {
                       success();
                   }
               }
               failure:failure];
    
}

- (void)deleteSuccess:(void (^)())success
              failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"/oapi/library/groups/%@/",
                      self.identifier];

    [self deleteAtPath:path
               success:success
               failure:failure];
}

- (void)leaveSuccess:(void (^)())success
             failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"/oapi/library/groups/%@/leave/",
                      self.identifier];

    [self deleteAtPath:path
               success:success
               failure:failure];
}

- (void)unfollowSuccess:(void (^)())success
                failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"/oapi/library/groups/%@/unfollow",
                      self.identifier];

    [self deleteAtPath:path
               success:success
               failure:failure];
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"%@ (identifier: %@; name: %@; type: %tu)",
            [super description], self.identifier, self.name, self.type];
}

@end
