//
//  StringChecker.h
//  suhos
//
//  Created by Almighty Kim on 11/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#define IS_NULL_STRING(__POINTER) \
		(__POINTER == nil || \
		__POINTER == (NSString *)[NSNull null] || \
		![__POINTER isKindOfClass:[NSString class]] || \
		![__POINTER length])
