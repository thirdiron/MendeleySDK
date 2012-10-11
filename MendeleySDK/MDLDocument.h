//
//  MDLDocument.h
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

#import <Foundation/Foundation.h>

extern NSString * const kMDLDocumentTypeGeneric;

@class MDLMendeleyAPIClient;

/**
 `MDLDocument` represents a user’s document, as described by Mendeley.
 */

@interface MDLDocument : NSObject

/**
 The document identifier, as generated by Mendeley.
 */
@property (copy, nonatomic) NSString *documentIdentifier;

/**
 The document DOI (Digital Object Identifier).
 */
@property (copy, nonatomic) NSString *DOI;

/**
 The type of the document. This is `@"Generic"` by default.
 */
@property (copy, nonatomic) NSString *type;

/**
 The title of the document.
 */
@property (copy, nonatomic) NSString *title;

/**
 Creates a `MDLDocument` and sends an API creation request using the shared client.
 
 @param title The title of the document.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes one argument: the created document with its newly assigned document identifier.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes one argument: the `NSError` object describing the network or parsing error that occurred.
 
 @return  The newly-initialized document, with document identifier = `nil`.
 */
+ (MDLDocument *)documentWithTitle:(NSString *)title success:(void (^)(MDLDocument *))success failure:(void (^)(NSError *))failure;

/**
 Sends an API search request with generic terms using the shared client.
 
 @param terms The terms for the search query
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes one argument: an array of `MDLDocument` objects for the match.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes one argument: the `NSError` object describing the network or parsing error that occurred.
 */
+ (void)searchWithTerms:(NSString *)terms success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure;

/**
 Sends an API search request with specific terms using the shared client.
 
 @param genericTerms The terms for the search query
 @param authors The authors for the search query
 @param title The title for the search query
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes one argument: an array of `MDLDocument` objects for the match.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes one argument: the `NSError` object describing the network or parsing error that occurred.
 */
+ (void)searchWithGenericTerms:(NSString *)genericTerms authors:(NSString *)authors title:(NSString *)title success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure;

/**
 Sends an API upload request using the shared client.
 
 Keep in mind that Mendeley only handles a limited number of file formats (.pdf, etc).
 
 @param fileURL The local URL for the file to upload.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes no argument.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes one argument: the `NSError` object describing the network or parsing error that occurred.
 */
- (void)uploadFileAtURL:(NSURL *)fileURL success:(void (^)())success failure:(void (^)(NSError *))failure;

@end
