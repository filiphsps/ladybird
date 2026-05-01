/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#import <Interface/Bridge/LBFindInPageResult.h>

@implementation LBFindInPageResult

- (instancetype)initWithCurrentMatch:(NSInteger)currentMatch
                               total:(NSInteger)total
                            hasTotal:(BOOL)hasTotal
{
    if ((self = [super init])) {
        _currentMatch = currentMatch;
        _total = total;
        _hasTotal = hasTotal;
    }
    return self;
}

@end
