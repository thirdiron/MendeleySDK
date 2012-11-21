//
// MDLFolder.h
//
// Copyright (c) 2012 shazino (shazino SAS), http://www.shazino.com/
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

+ (MDLFolder *)folderWithIdentifier:(NSString *)identifier name:(NSString *)name numberOfDocuments:(NSNumber *)numberOfDocuments parentIdentifier:(NSString *)parentIdentifier;

@end


@implementation MDLFolder

+ (MDLFolder *)folderWithIdentifier:(NSString *)identifier name:(NSString *)name numberOfDocuments:(NSNumber *)numberOfDocuments parentIdentifier:(NSString *)parentIdentifier
{
    MDLFolder *folder = [MDLFolder new];
    folder.identifier = identifier;
    folder.name = name;
    folder.numberOfDocmuents = numberOfDocuments;
    folder.parentIdentifier = parentIdentifier;
    folder.subfolders = @[];
    return folder;
}

+ (MDLFolder *)createFolderWithName:(NSString *)name parent:(MDLFolder *)parent success:(void (^)(MDLFolder *))success failure:(void (^)(NSError *))failure
{
    MDLFolder *folder = [MDLFolder new];
    folder.name = name;
    folder.subfolders = @[];
    
    [[MDLMendeleyAPIClient sharedClient] postPrivatePath:@"/oapi/library/folders/"
                                                 bodyKey:@"folder"
                                             bodyContent:(parent) ? @{@"name" : folder.name, @"parent": parent.identifier} : @{@"name" : folder.name}
                                                 success:^(AFHTTPRequestOperation *operation, id responseDictionary) {
                                                     
                                                     folder.parent = parent;
                                                     parent.subfolders = [parent.subfolders arrayByAddingObject:folder];
                                                     
                                                     folder.identifier = responseDictionary[@"folder_id"];
                                                     if (success)
                                                         success(folder);
                                                 } failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) { if (failure) failure(error); }];
    
    return folder;
}

+ (void)fetchFoldersInUserLibrarySuccess:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    [[MDLMendeleyAPIClient sharedClient] getPath:@"/oapi/library/folders/"
                          requiresAuthentication:YES
                                      parameters:nil
                                         success:^(AFHTTPRequestOperation *operation, NSArray *responseObject) {
                                             NSMutableArray *folders = [NSMutableArray array];
                                             for (NSDictionary *rawFolder in responseObject)
                                                 [folders addObject:[self folderWithIdentifier:rawFolder[@"id"] name:rawFolder[@"name"] numberOfDocuments:rawFolder[@"size"] parentIdentifier:rawFolder[@"parent"]]];
                                             for (MDLFolder *folder in folders)
                                             {
                                                 if (folder.parentIdentifier)
                                                 {
                                                     for (MDLFolder *aFolder in folders)
                                                     {
                                                         if ([aFolder.identifier isEqualToString:folder.parentIdentifier])
                                                         {
                                                             folder.parent = aFolder;
                                                             folder.parent.subfolders = [folder.parent.subfolders arrayByAddingObject:folder];
                                                             break;
                                                         }
                                                     }
                                                     
                                                 }
                                             }
                                             if (success)
                                                 success([folders filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"parent = nil"]]);
                                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             if (failure) failure(error);
                                         }];
}

- (void)fetchDocumentsAtPage:(NSUInteger)pageIndex count:(NSUInteger)count success:(void (^)(NSArray *, NSUInteger, NSUInteger, NSUInteger, NSUInteger))success failure:(void (^)(NSError *))failure
{
    [[MDLMendeleyAPIClient sharedClient] getPath:[NSString stringWithFormat:@"/oapi/library/folders/%@/", self.identifier]
                          requiresAuthentication:YES
                                      parameters:nil
                                         success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                                             NSArray *rawDocuments = responseObject[@"document_ids"];
                                             NSMutableArray *documents = [NSMutableArray array];
                                             for (NSString *documentIdentifier in rawDocuments)
                                             {
                                                 MDLDocument * document = [MDLDocument new];
                                                 document.identifier = documentIdentifier;
                                                 [documents addObject:document];
                                             }
                                             self.documents = documents;
                                             
                                             NSNumber *totalResults  = [NSNumber numberOrNumberFromString:responseObject[@"total_results"]];
                                             NSNumber *totalPages    = [NSNumber numberOrNumberFromString:responseObject[@"total_pages"]];
                                             NSNumber *pageIndex     = [NSNumber numberOrNumberFromString:responseObject[@"current_page"]];
                                             NSNumber *itemsPerPage  = [NSNumber numberOrNumberFromString:responseObject[@"items_per_page"]];
                                             
                                             if (success)
                                                 success(self.documents, [totalResults unsignedIntegerValue], [totalPages unsignedIntegerValue], [pageIndex unsignedIntegerValue], [itemsPerPage unsignedIntegerValue]);
                                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             if (failure)
                                                 failure(error);
                                         }];
}

- (void)addDocument:(MDLDocument *)document success:(void (^)())success failure:(void (^)(NSError *))failure
{
    [[MDLMendeleyAPIClient sharedClient] postPrivatePath:[NSString stringWithFormat:@"/oapi/library/folders/%@/%@/", self.identifier, document.identifier]
                                                 bodyKey:nil bodyContent:nil
                                                 success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                                                     if (success) success();
                                                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     if (failure) failure(error);
                                                 }];
}

- (void)deleteSuccess:(void (^)())success failure:(void (^)(NSError *))failure
{
    [[MDLMendeleyAPIClient sharedClient] deletePrivatePath:[NSString stringWithFormat:@"/oapi/library/folders/%@/", self.identifier]
                                                parameters:nil
                                                   success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                                       if (self.parent)
                                                       {
                                                           NSMutableArray *siblings = [NSMutableArray arrayWithArray:self.parent.subfolders];
                                                           [siblings removeObject:self];
                                                           self.parent.subfolders = siblings;
                                                       }
                                                       if (success) success();
                                                   }
                                                   failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) { if (failure) failure(error); }];
}

- (void)removeDocument:(MDLDocument *)document success:(void (^)())success failure:(void (^)(NSError *))failure
{
    [[MDLMendeleyAPIClient sharedClient] deletePrivatePath:[NSString stringWithFormat:@"/oapi/library/folders/%@/%@/", self.identifier, document.identifier]
                                                parameters:nil
                                                   success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                                       NSMutableArray *newDocuments = [NSMutableArray arrayWithArray:self.documents];
                                                       [newDocuments removeObject:document];
                                                       self.documents = newDocuments;
                                                       if (success) success();
                                                   }
                                                   failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) { if (failure) failure(error); }];
}

@end
