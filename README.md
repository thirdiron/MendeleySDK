# MendeleySDK
**Objective-C client for the Mendeley Open API.**

> _This is still in early stages of development, so proceed with caution when using this in a production application.
> Any bug reports, feature requests, or general feedback at this point would be greatly appreciated._

MendeleySDK is a [Mendeley API](http://apidocs.mendeley.com) client for iOS and Mac OS X. It’s built on top of [AFNetworking](http://www.github.com/AFNetworking/AFNetworking) and [AFOAuth1Client](http://www.github.com/AFNetworking/AFOAuth1Client) to deal with network operations and authentication.

![Demo app screenshot paper](https://github.com/shazino/MendeleySDK/wiki/images/demo-app-screenshot-paper.png) ![Demo app screenshot publication](https://github.com/shazino/MendeleySDK/wiki/images/demo-app-screenshot-pub.png)

## Getting Started

### Download

Using Git, you can download MendeleySDK (dependencies included) with just one command line.

```
git clone --recursive git@github.com:shazino/MendeleySDK.git
```

### Installation

1/ Create a new project with Xcode (with ARC enabled).

2/ Drag and drop the following files into your project navigator.

- MendeleySDK/MendeleySDK/*
- MendeleySDK/AFOAuth1Client/AFOAuth1Client.h
- MendeleySDK/AFOAuth1Client/AFOAuth1Client.m
- MendeleySDK/AFOAuth1Client/AFNetworking/AFNetworking/*

3/ At this point, AFOAuth1Client and AFNetworking don’t use ARC, so you’ll need to set the `-fno-objc-arc` compiler flag for all their files (as explained [here](http://stackoverflow.com/questions/6646052/how-can-i-disable-arc-for-a-single-file-in-a-project)).

![Disable ARC for AFOAuth1Client and AFNetworking](https://github.com/shazino/MendeleySDK/wiki/images/Xcode-disable-ARC.png)

4/ Define your API consumer key and secret (in your AppDelegate.m, for instance):

```objective-c
NSString * const kMDLConsumerKey    = @"###my_consumer_key###";
NSString * const kMDLConsumerSecret = @"###my_consumer_secret###";
```

If you don’t have a consumer key and secret, go to the [Mendeley Developers Portal](http://dev.mendeley.com/applications/register/) and register your application first.

5/ The Mendeley Open API uses [3leg OAuth 1.0](http://apidocs.mendeley.com/home/authentication) authentication. In order to gain access to protected resources, your application will open Mobile Safari and prompt for user credentials. iOS will then switch back to your application using a custom URL scheme. It means that you need to it set up in your Xcode project.

- Open the project editor, select your main target, click the Info button.
- Add a URL Type, and type a unique URL scheme (for instance ’mymendeleyclient’).

![Xcode URL types](https://github.com/shazino/MendeleySDK/wiki/images/Xcode-URL-types.png)

- Update your app delegate to notify MendeleySDK as following:

```objective-c
#import "AFOAuth1Client.h"

NSString * const kMDLURLScheme = @"##INSERT-URL-SCHEME-HERE##";

(…)

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[url scheme] isEqualToString:kMDLURLScheme])
    {
        NSNotification *notification = [NSNotification notificationWithName:kAFApplicationLaunchedWithURLNotification object:nil userInfo:[NSDictionary dictionaryWithObject:url forKey:kAFApplicationLaunchOptionsURLKey]];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
    
    return YES;
}
```
_Note: you can skip this step if you only use public resources_

Okay, you should be ready to go now! You can also take a look at the demo iOS app and see how things work.

## Examples

### How to create a new document

```objective-c
[MDLDocument createNewDocumentWithTitle:@"title" success:^(MDLDocument *document) {
     /* ... */
} failure:^(NSError *error) {
    /* ... */
}];
```

### How to upload a file

```objective-c
MDLDocument *document;
[document uploadFileAtURL:localFileURL success:^() {
    /* ... */
} failure:^(NSError *error) {
    /* ... */
}];
```

## References

- [Documentation](http://shazino.github.com/MendeleySDK/)
- [Changelog](https://github.com/shazino/MendeleySDK/wiki/Changelog)
- [Contribute](https://github.com/shazino/MendeleySDK/wiki/Contribute)

## Requirements

MendeleySDK requires Xcode 4.4 with either the [iOS 5.0](http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniPhoneOS/Articles/iOS5.html) or [Mac OS 10.6](http://developer.apple.com/library/mac/#releasenotes/MacOSX/WhatsNewInOSX/Articles/MacOSX10_6.html#//apple_ref/doc/uid/TP40008898-SW7) ([64-bit with modern Cocoa runtime](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtVersionsPlatforms.html)) SDK, as well as [AFOAuth1Client](https://github.com/AFNetworking/AFOAuth1Client).

## Credits

MendeleySDK is developed by [shazino](http://www.shazino.com).

## License

MendeleySDK is available under the MIT license. See the LICENSE file for more info.