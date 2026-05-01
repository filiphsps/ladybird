/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#pragma once

#import <Foundation/Foundation.h>
#import <Interface/Bridge/LBBookmarkItem.h>

NS_ASSUME_NONNULL_BEGIN

@interface LBBookmarkPromise : NSObject

- (void)resolveWithBookmark:(LBBookmark*)bookmark;
- (void)reject;

@end

@interface LBBookmarkFolderPromise : NSObject

- (void)resolveWithFolder:(LBBookmarkFolder*)folder;
- (void)reject;

@end

NS_ASSUME_NONNULL_END
