/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#pragma once

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LBBookmarkMenuItemKind) {
    LBBookmarkMenuItemKindBookmark,
    LBBookmarkMenuItemKindFolder,
};

@interface LBBookmarkMenuItem : NSObject

@property (nonatomic, readonly) LBBookmarkMenuItemKind kind;
@property (nonatomic, readonly, copy) NSString* identifier;
@property (nonatomic, readonly, copy) NSString* title;
@property (nonatomic, readonly, copy, nullable) NSString* tooltip;
@property (nonatomic, readonly, copy, nullable) NSString* targetFolderIdentifier;
@property (nonatomic, readonly, nullable) NSImage* icon;

- (instancetype)initWithKind:(LBBookmarkMenuItemKind)kind
                  identifier:(NSString*)identifier
                       title:(NSString*)title
                     tooltip:(nullable NSString*)tooltip
      targetFolderIdentifier:(nullable NSString*)targetFolderIdentifier
                        icon:(nullable NSImage*)icon NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

@protocol LBBookmarkItemView <NSObject>
@property (nonatomic, readonly, nullable) LBBookmarkMenuItem* bookmarkMenuItem;
@end

NS_ASSUME_NONNULL_END
