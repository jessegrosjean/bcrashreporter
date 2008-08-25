//
//  BCrashReporterController.h
//  BCrashReporter
//
//  Created by Jesse Grosjean on 9/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Blocks/Blocks.h>


@interface BCrashReporterController : NSWindowController {
    IBOutlet NSTextField *titleTextField;
    IBOutlet NSTextField *subTitleTextField;
    IBOutlet NSTextField *emailTextField;
    IBOutlet NSTextField *statusMessageTextField;
    IBOutlet NSTextView *problemDescriptionTextView;
    IBOutlet NSButton *sendReportButton;
    IBOutlet NSProgressIndicator *statusProgressIndicator;
	
	NSMutableDictionary *crashReport;
}

#pragma mark class methods

+ (id)sharedInstance;

#pragma mark accessors

- (NSString *)crashPath;
- (NSString *)exceptionPath;
- (void)setStatusMessage:(NSString *)message;

#pragma mark actions

- (IBAction)check:(id)sender;
- (IBAction)sendReport:(id)sender;
- (IBAction)ignore:(id)sender;

@end
