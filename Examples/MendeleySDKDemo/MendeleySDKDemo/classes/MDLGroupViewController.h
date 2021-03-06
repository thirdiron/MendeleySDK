//
// MDLGroupViewController.h
//
// Copyright (c) 2012-2013 shazino (shazino SAS), http://www.shazino.com/
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

#import <UIKit/UIKit.h>

@class MDLGroup;

@interface MDLGroupViewController : UIViewController

@property (nonatomic, strong) MDLGroup *group;

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *categoryLabel;
@property (nonatomic, weak) IBOutlet UILabel *ownerLabel;
@property (nonatomic, weak) IBOutlet UILabel *publicLabel;
@property (nonatomic, weak) IBOutlet UILabel *numberOfDocumentsLabel;
@property (nonatomic, weak) IBOutlet UILabel *numberOfAdminsLabel;
@property (nonatomic, weak) IBOutlet UILabel *numberOfMembersLabel;
@property (nonatomic, weak) IBOutlet UILabel *numberOfFollowersLabel;

- (IBAction)openWebGroupProfile:(id)sender;
- (IBAction)deleteGroup:(id)sender;
- (IBAction)leaveGroup:(id)sender;
- (IBAction)unfollowGroup:(id)sender;
- (IBAction)showActions:(id)sender;

@end
