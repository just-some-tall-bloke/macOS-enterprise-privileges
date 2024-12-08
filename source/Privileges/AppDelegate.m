/*
    AppDelegate.m
    Copyright 2024 SAP SE
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
    http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "MTPrivileges.h"
#import "MTRReasonAccessoryController.h"
#import "MTLocalNotification.h"
#import "Constants.h"

#define LOG_FILE_PATH @"/Library/Logs/Privileges.log"

@interface AppDelegate ()
@property (nonatomic, strong, readwrite) NSWindowController *settingsWindowController;
@property (nonatomic, strong, readwrite) MTPrivileges *privilegesApp;
@property (nonatomic, strong, readwrite) MTRReasonAccessoryController *accessoryController;
@property (nonatomic, strong, readwrite) NSOperationQueue *operationQueue;
@property (nonatomic, strong, readwrite) NSAlert *alert;
@property (retain) id configurationObserver;
@property (assign) NSInteger minReasonLength;
@property (assign) NSInteger maxReasonLength;
@property (assign) BOOL enableRequestButton;
@property (assign) BOOL authSuccess;
@end

extern void CoreDockSendNotification(CFStringRef, void*);

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
    [self writeLogToFile:@"Application started"];
    
    if ([[aNotification userInfo] objectForKey:NSApplicationLaunchUserNotificationKey]) {
        [self writeLogToFile:@"Application started due to user notification click"];
        [[NSApp terminate:self];
    } else {
        // Rest of the logic for applicationDidFinishLaunching
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification 
{
    [self writeLogToFile:@"Application is about to terminate"];
}

- (void)requestAdminRightsForUser:(NSString *)username 
{
    NSString *logMessage = [NSString stringWithFormat:@"Admin rights requested by user: %@", username];
    [self writeLogToFile:logMessage];
    // Call privileges app to grant admin rights
}

- (void)grantAdminRightsToUser:(NSString *)username expirationTime:(NSTimeInterval)expiration 
{
    NSString *logMessage = [NSString stringWithFormat:@"Admin rights granted to user: %@ for %.2f minutes", username, expiration / 60.0];
    [self writeLogToFile:logMessage];
    // Call privileges app to grant admin rights
}

- (void)revokeAdminRightsFromUser:(NSString *)username 
{
    NSString *logMessage = [NSString stringWithFormat:@"Admin rights revoked for user: %@", username];
    [self writeLogToFile:logMessage];
    // Call privileges app to revoke admin rights
}

- (void)userPerformedAdminAction:(NSString *)action forUser:(NSString *)username 
{
    NSString *logMessage = [NSString stringWithFormat:@"User %@ performed action: %@", username, action];
    [self writeLogToFile:logMessage];
    // Handle user actions while they have admin privileges
}

- (void)showSettingsWindow 
{
    [self writeLogToFile:@"Settings window displayed"];
    if (![_settingsWindowController.window isVisible]) {
        [_settingsWindowController showWindow:self];
    }
}

- (void)checkForReasonRequirement 
{
    if (!_accessoryController) {
        _accessoryController = [[MTRReasonAccessoryController alloc] init];
        _accessoryController.minLength = _minReasonLength;
        _accessoryController.maxLength = _maxReasonLength;
        [self writeLogToFile:@"Checked for reason requirement"];
    }
}

- (void)configureNotificationCenter 
{
    if (!_configurationObserver) {
        _configurationObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"com.apple.expose.front.awake" 
                                                                                             object:nil 
                                                                                              queue:nil 
                                                                                         usingBlock:^(NSNotification *note) {
                                                                                            [self applicationDidFinishLaunching:note];
                                                                                        }];
    }
}

- (void)writeLogToFile:(NSString *)message 
{
    NSString *logFilePath = LOG_FILE_PATH;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Check if the log file exists, if not, create it
    if (![fileManager fileExistsAtPath:logFilePath]) {
        [fileManager createFileAtPath:logFilePath contents:nil attributes:nil];
    }
    
    // Get current date and format it as a timestamp
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *timestamp = [dateFormatter stringFromDate:currentDate];
    
    // Construct the log message
    NSString *logEntry = [NSString stringWithFormat:@"%@ - %@\n", timestamp, message];
    
    // Write the log entry to the file
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logEntry dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else {
        NSLog(@"Unable to open log file at %@", logFilePath);
    }
}

- (void)dealloc 
{
    [self writeLogToFile:@"Application is deallocating"];
    if (_configurationObserver) {
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:_configurationObserver];
    }
}

@end
