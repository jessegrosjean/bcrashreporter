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
	NSString *processName = [[NSProcessInfo processInfo] processName];
	NSMutableArray *crashLogs = [NSMutableArray array];
	
	for (NSString *each in [[NSFileManager defaultManager] enumeratorAtPath:[@"~/Library/Logs/CrashReporter/" stringByExpandingTildeInPath]]) {
		if ([each hasPrefix:processName]) {
			[crashLogs addObject:[[NSString stringWithFormat:@"~/Library/Logs/CrashReporter/%@", each] stringByExpandingTildeInPath]];
		}
	}
		
	if ([crashLogs count] > 0) {
		NSWindow *window = [self window];
		NSString *processName = [[NSProcessInfo processInfo] processName];
		NSMutableString *crashLogsContent = [NSMutableString string];
		
		[statusProgressIndicator setUsesThreadedAnimation:YES];
		
		[window setTitle:[NSString stringWithFormat:[window title], processName]];
		[titleTextField setStringValue:[NSString stringWithFormat:[titleTextField stringValue], processName]];
		
		[window center];
		[window orderFront:self];

		for (NSString *each in crashLogs) {
			if ([fileManager fileExistsAtPath:each]) {
				NSString *crashLog = [NSString stringWithContentsOfFile:each];
				if ([crashLog length] > 0) {
					[crashLogsContent appendString:crashLog];
				}
				[fileManager removeFileAtPath:each handler:nil];
			}
		}
		
		if ([crashLogsContent length] > 5000) {
			crashLogsContent = (id) [crashLogsContent substringToIndex:5000];
		}
		
		[crashReport setObject:crashLogsContent forKey:@"log"];
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
    
	BOOL tryingToSendReport = YES;
	
    while (tryingToSendReport) {		
		NSData *data = nil;
		NSError *error = nil;
		NSURLResponse *reply;
		NSURL *crashReportURL = [NSURL URLWithString:crashReportURLString];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:crashReportURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120];
		[request addValue:[[NSProcessInfo processInfo] processName] forHTTPHeaderField:[NSString stringWithFormat:@"%@-Bug-Report", [[NSProcessInfo processInfo] processName]]];
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody:[reportString dataUsingEncoding:NSUTF8StringEncoding]];
		
		[self setStatusMessage:BLocalizedString(@"Sending Report...", nil)];

		data = [NSURLConnection sendSynchronousRequest:request returningResponse:&reply error:&error];
		
		[self setStatusMessage:@""];
		
		if (error) {
			tryingToSendReport = NSRunAlertPanel(BLocalizedString(@"Unable to send crash report", nil),
												 [error localizedDescription],
												 BLocalizedString(@"Try Again", nil), 
												 BLocalizedString(@"Cancel", nil), nil) == NSAlertAlternateReturn;
		} else {
			NSRunAlertPanel(BLocalizedString(@"Thank You", nil),
							BLocalizedString(@"The crash report has been sent.", nil),
							BLocalizedString(@"OK", nil), 
							nil,
							nil);
			tryingToSendReport = NO;
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


/*
 
 Can't get this darn NSExceptionHandler to work!
 + (void)initialize {
 NSUInteger mask = [[NSExceptionHandler defaultExceptionHandler] exceptionHandlingMask];
 mask = NSLogUncaughtExceptionMask | NSLogUncaughtSystemExceptionMask | NSLogUncaughtRuntimeErrorMask | NSLogTopLevelExceptionMask | NSLogOtherExceptionMask | NSHandleUncaughtExceptionMask | NSHandleUncaughtSystemExceptionMask | NSHandleUncaughtRuntimeErrorMask | NSHandleTopLevelExceptionMask | NSHandleOtherExceptionMask;
 [[NSExceptionHandler defaultExceptionHandler] setExceptionHangingMask:mask];
 [[NSExceptionHandler defaultExceptionHandler] setDelegate:[self sharedInstance]];
 }
 
 + (id)sharedInstance {
 static id sharedInstance = nil;
 if (sharedInstance == nil) {
 sharedInstance = [self alloc];
 sharedInstance = [sharedInstance init];
 }
 return sharedInstance;
 }
 
 - (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldHandleException:(NSException *)exception mask:(unsigned int)aMask {
 return YES;
 }
 - (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(unsigned int)aMask {
 return YES;
 }
 */
