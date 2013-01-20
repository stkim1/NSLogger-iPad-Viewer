//
//  LoggerPreferenceManager.m
//  ipadnslogger
//
//  Created by Almighty Kim on 11/5/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import "LoggerPreferenceManager.h"
#import "SynthesizeSingleton.h"

@implementation LoggerPreferenceManager
@synthesize shouldPublishBonjourService;
@synthesize hasDirectTCPIPResponder;
@synthesize directTCPIPResponderPort;
@synthesize bonjourServiceName;

SYNTHESIZE_SINGLETON_FOR_CLASS_WITH_ACCESSOR(LoggerPreferenceManager,sharedPrefManager);

NSString * const kBonjourServiceName = @"NSLogger iPad";

-(BOOL)shouldPublishBonjourService
{
	return YES;
}

-(BOOL)hasDirectTCPIPResponder
{
	return YES;
}

-(NSInteger)directTCPIPResponderPort
{
	return 5000;
}

-(NSString*)bonjourServiceName
{
	//return @"NSLogger iPad";
	return kBonjourServiceName;
}


@end
