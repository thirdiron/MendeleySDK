//
// MDLFolder.h
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

#import "MDLFolder.h"

#import "MDLMendeleyAPIClient.h"
#import "MDLDocument.h"

@interface MDLFolder ()

+ (instancetype)folderWithIdentifier:(NSString *)identifier
                                name:(NSString *)name
                   numberOfDocuments:(NSNumber *)numberOfDocuments
                    parentIdentifier:(NSString *)parentIdentifier;

@end


@implementation MDLFolder

+ (instancetype)folderWithIdentifier:(NSString *)identifier
                                name:(NSString *)name
                   numberOfDocuments:(NSNumber *)numberOfDocuments
                    parentIdentifier:(NSString *)parentIdentifier
{
    MDLFolder *folder = [MDLFolder new];
    folder.identifier = identifier;
    folder.name = name;
    folder.numberOfDocuments = [NSNumber numberOrNumberFromString:numberOfDocuments];
    if (! ([parentIdentifier isKindOfClass:[NSNumber class]] && [parentIdentifier isEqual:@(-1)])) {
        folder.parentIdentifier = parentIdentifier;
    }
    folder.subfolders = @[];
    return folder;
}

+ (instancetype)createFolderWithName:(NSString *)name
                              parent:(MDLFolder *)parent
                             success:(void (^)(MDLFolder *))success
                             failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];

    MDLFolder *folder = [MDLFolder new];
    folder.name       = name;
    folder.subfolders = @[];

    NSDictionary *bodyContent;
    if (parent) {
        bodyContent = @{@"name" : folder.name,
                        @"parent": parent.identifier};
    }
    else {
        bodyContent = @{@"name" : folder.name};
    }

    [client postPath:@"/oapi/library/folders/"
             bodyKey:@"folder"
         bodyContent:bodyContent
             success:^(AFHTTPRequestOperation *operation, id responseDictionary) {
                 folder.parent     = parent;
                 parent.subfolders = [parent.subfolders arrayByAddingObject:folder];
                 folder.identifier = responseDictionary[@"folder_id"];

                 if (success) {
                     success(folder);
                 }
             }
             failure:failure];

    return folder;
}

+ (void)fetchFoldersInUserLibrarySuccess:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];

    [client getPath:@"/oapi/library/folders/"
requiresAuthentication:YES
         parameters:nil
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if (success) {
                    NSArray *folders = [self treefiedFoldersFromResponseObject:responseObject];
                    success(folders);
                }
            } failure:failure];
}

+ (NSArray *)treefiedFoldersFromResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *responseArray = responseObject;
    NSMutableArray *folders = [NSMutableArray array];

    for (NSDictionary *rawFolder in responseArray) {
        [folders addObject:[self folderWithIdentifier:rawFolder[@"id"]
                                                 name:rawFolder[@"name"]
                                    numberOfDocuments:rawFolder[@"size"]
                                     parentIdentifier:rawFolder[@"parent"]]];
    }

    for (MDLFolder *folder in folders) {
        if (folder.parentIdentifier) {
            for (MDLFolder *aFolder in folders) {
                if ([aFolder.identifier isEqualToString:folder.parentIdentifier]){
                    folder.parent = aFolder;
                    folder.parent.subfolders = [folder.parent.subfolders arrayByAddingObject:folder];
                    break;
                }
            }
        }
    }

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent = nil"];
    return [folders filteredArrayUsingPredicate:predicate];
}

- (void)fetchDocumentsAtPage:(NSUInteger)pageIndex count:(NSUInteger)count success:(void (^)(NSArray *, NSUInteger, NSUInteger, NSUInteger, NSUInteger))success failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];
    NSString *path = [NSString stringWithFormat:@"/oapi/library/folders/%@/",
                      self.identifier];

    [client getPath:path
requiresAuthentication:YES
         parameters:nil
            success:^(AFHTTPRequestOperation *operation, NSDictionary *responseDictionary) {
                NSArray *rawDocuments = responseDictionary[@"document_ids"];
                NSMutableArray *documents = [NSMutableArray array];

                for (NSString *documentIdentifier in rawDocuments) {
                    MDLDocument * document = [MDLDocument new];
                    document.identifier = documentIdentifier;
                    [documents addObject:document];
                }

                self.documents = documents;

                if (success) {
                    success(self.documents,
                            [responseDictionary responseTotalResults],
                            [responseDictionary responseTotalPages],
                            [responseDictionary responsePageIndex],
                            [responseDictionary responseItemsPerPage]);
                }
            } failure:failure];
}

- (void)addDocument:(MDLDocument *)document success:(void (^)())success failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];
    NSString *path = [NSString stringWithFormat:@"/oapi/library/folders/%@/%@/",
                      self.identifier,
                      document.identifier];

    [client postPath:path
             bodyKey:nil
         bodyContent:nil
             success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                 if (success) {
                     success();
                 }
             }
             failure:failure];
}

- (void)deleteSuccess:(void (^)())success failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];
    NSString *path = [NSString stringWithFormat:@"/oapi/library/folders/%@/",
                      self.identifier];

    [client deletePath:path
            parameters:nil
               success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                   if (self.parent) {
                       NSMutableArray *siblings = [NSMutableArray arrayWithArray:self.parent.subfolders];
                       [siblings removeObject:self];
                       self.parent.subfolders = siblings;
                   }

                   if (success) {
                       success();
                   }
               }
               failure:failure];
}

- (void)removeDocument:(MDLDocument *)document success:(void (^)())success failure:(void (^)(NSError *))failure
{
    MDLMendeleyAPIClient *client = [MDLMendeleyAPIClient sharedClient];

    [client deletePath:[NSString stringWithFormat:@"/oapi/library/folders/%@/%@/", self.identifier, document.identifier]
            parameters:nil
               success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                   NSMutableArray *newDocuments = [NSMutableArray arrayWithArray:self.documents];
                   [newDocuments removeObject:document];
                   self.documents = newDocuments;

                   if (success) {
                       success();
                   }
               }
               failure:failure];
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"%@ (identifier: %@; name: %@; parent identifier: %@)",
            [super description], self.identifier, self.name, self.parentIdentifier];
}

@end
