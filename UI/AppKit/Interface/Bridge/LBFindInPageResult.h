/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LBFindInPageResult : NSObject

@property (nonatomic, readonly) NSInteger currentMatch;
@property (nonatomic, readonly) NSInteger total;
@property (nonatomic, readonly) BOOL hasTotal;

- (instancetype)initWithCurrentMatch:(NSInteger)currentMatch
                               total:(NSInteger)total
                            hasTotal:(BOOL)hasTotal;

@end

NS_ASSUME_NONNULL_END
