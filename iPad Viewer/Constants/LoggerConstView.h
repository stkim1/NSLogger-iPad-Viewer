//
//  LoggerConstView.h
//  ipadnslogger
//
//  Created by Almighty Kim on 10/26/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import <Foundation/Foundation.h>

/*                     Logger Message Cell Constants                          */

#define MAX_DATA_LINES					16		// max number of data lines to show

#define MINIMUM_CELL_HEIGHT				30.0f
#define INDENTATION_TAB_WIDTH			10.0f	// in pixels

#define TIMESTAMP_COLUMN_WIDTH			85.0f
#define	DEFAULT_THREAD_COLUMN_WIDTH		85.f

#define MSG_CELL_PORTRAIT_WIDTH			768.f
#define MSG_CELL_LANDSCAPE_WDITH		1024.f
#define DEFAULT_FONT_SIZE				10.f

extern NSString * const kMessageAttributesChangedNotification;