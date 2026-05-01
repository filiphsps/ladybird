/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LBBookmark : NSObject

@property (nonatomic, copy) NSString* urlString;
@property (nonatomic, copy, nullable) NSString* title;
@property (nonatomic, copy, nullable) NSData* faviconPng;

- (instancetype)initWithURLString:(NSString*)urlString
                            title:(nullable NSString*)title
                       faviconPng:(nullable NSData*)faviconPng;

@end

@interface LBBookmarkFolder : NSObject

@property (nonatomic, copy, nullable) NSString* title;

- (instancetype)initWithTitle:(nullable NSString*)title;

@end

NS_ASSUME_NONNULL_END
