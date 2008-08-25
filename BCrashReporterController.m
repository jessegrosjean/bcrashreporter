//
//  BCrashReporterController.m
//  BCrashReporter
//
//  Created by Jesse Grosjean on 9/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BCrashReporterController.h"


@implementation BCrashReporterController

#pragma mark class methods

+ (id)sharedInstance {
    static id sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

#pragma Init

- (id)init {
    if (self = [super initWithWindowNibName:@"BCrashReporterWindow"]) {
		crashReport = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma awake from nib like methods

- (void)awakeFromNib {
	[statusMessageTextField setStringValue:@""];
	[[self window] setLevel:NSFloatingWindowLevel];
}

#pragma mark accessors

- (NSString *)crashPath {
    return [[NSString stringWithFormat:@"~/Library/Logs/CrashReporter/%@.crash.log", [[NSProcessInfo processInfo] processName]] stringByExpandingTildeInPath];
}

- (NSString *)exceptionPath {
    return [[NSString stringWithFormat:@"~/Library/Logs/CrashReporter/%@.exception.log", [[NSProcessInfo processInfo] processName]] stringByExpandingTildeInPath];
}

- (void)setStatusMessage:(NSString *)message {
    if ([message length]) {
		[statusProgressIndicator startAnimation:nil];
    } else {
		[statusProgressIndicator stopAnimation:nil];
    }
    
    [statusMessageTextField setStringValue:message];
    [statusMessageTextField display];
}

#pragma mark actions

- (IBAction)check:(id)sender {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *crashPath = [self crashPath];
	NSString *exceptionPath = [self exceptionPath];
	
	if ([fileManager fileExistsAtPath:crashPath] || [fileManager fileExistsAtPath:exceptionPath]) {
		NSWindow *window = [self window];
		NSString *processName = [[NSProcessInfo processInfo] processName];
		NSMutableString *crashLogs = [NSMutableString string];
		
		[statusProgressIndicator setUsesThreadedAnimation:YES];
		
		[window setTitle:[NSString stringWithFormat:[window title], processName]];
		[titleTextField setStringValue:[NSString stringWithFormat:[titleTextField stringValue], processName]];
		
		[window center];
		[window orderFront:self];
		
		if ([fileManager fileExistsAtPath:crashPath]) {
			NSString *crashLog = [NSString stringWithContentsOfFile:crashPath];
			if ([crashLog length] > 0) {
				[crashLogs appendString:crashLog];
			}
			[fileManager removeFileAtPath:crashPath handler:nil];
		}
		
		if ([fileManager fileExistsAtPath:[self exceptionPath]]) {
			NSString *exceptionLog = [NSString stringWithContentsOfFile:exceptionPath];
			if ([exceptionLog length] > 0) {
				[crashLogs appendString:exceptionLog];
			}
			[fileManager removeFileAtPath:exceptionPath handler:nil];
		}
		
		[crashReport setObject:crashLogs forKey:@"log"];
	}
}

- (IBAction)sendReport:(id)sender {
	NSString *crashReportURLString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"BCrashReporterPostToURL"];
	
	if (!crashReportURLString) {
		NSRunAlertPanel(BLocalizedString(@"Unable to send crash report", nil),
						BLocalizedString(@"No value has been set for the BCrashReporterPostToURL key in the applications Info.plist. Please contact the applictions developer.", nil),
						BLocalizedString(@"OK", nil), 
						nil,
						nil);
		return;
	}
	
	if ([[emailTextField stringValue] length] < 5) {
		NSRunAlertPanel(BLocalizedString(@"Unable to send crash report", nil),
						BLocalizedString(@"Please enter a valid email address.", nil),
						BLocalizedString(@"OK", nil), 
						nil,
						nil);
		return;
	}
	
    [crashReport setObject:[emailTextField stringValue] forKey:@"email"];
    [crashReport setObject:[[problemDescriptionTextView textStorage] string] forKey:@"description"];
    
    NSMutableString *reportString = [[NSMutableString alloc] init];
	
	for (NSString *key in [crashReport allKeys]) {
		if ([reportString length] != 0) [reportString appendString:@"&"];
		[reportString appendFormat:@"%@=%@", key, [[crashReport objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
    
    NSData *data = nil;
	
    while(!data || [data length] == 0) {
		NSError *error;
		NSURLResponse *reply;
		NSURL *crashReportURL = [NSURL URLWithString:crashReportURLString];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:crashReportURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120];
		[request addValue:[[NSProcessInfo processInfo] processName] forHTTPHeaderField:[NSString stringWithFormat:@"%@-Bug-Report", [[NSProcessInfo processInfo] processName]]];
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody:[reportString dataUsingEncoding:NSUTF8StringEncoding]];
		
		[self setStatusMessage:BLocalizedString(@"Sending Report...", nil)];

		data = [NSURLConnection sendSynchronousRequest:request returningResponse:&reply error:&error];
		
		[self setStatusMessage:@""];
		
		if (!data || [data length] == 0) {
			if (NSRunAlertPanel(BLocalizedString(@"Unable to send crash report", nil),
								[error localizedDescription],
								BLocalizedString(@"Try Again", nil), 
								BLocalizedString(@"Cancel", nil),
								nil) == NSAlertAlternateReturn) {
				break;
			}
		} else {
			NSRunAlertPanel(BLocalizedString(@"Thank You", nil),
							BLocalizedString(@"The crash report has been sent.", nil),
							BLocalizedString(@"OK", nil), 
							nil,
							nil);
		}
    }
	
	[self close];
}

- (IBAction)ignore:(id)sender {
	[self close];
}

#pragma mark Lifecycle Callback

- (void)applicationDidFinishLaunching {
	[self check:nil];
}

@end
