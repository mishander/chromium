// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CHROME_BROWSER_COCOA_TAB_CONTROLLER_H_
#define CHROME_BROWSER_COCOA_TAB_CONTROLLER_H_

#import <Cocoa/Cocoa.h>

// The loading/waiting state of the tab.
// TODO(pinkerton): this really doesn't belong here, but something needs to
// know the state and another parallel array in TabStripController doesn't seem
// like the right place either. In a perfect world, this class shouldn't know
// anything about states that are specific to a browser.
enum TabLoadingState {
  kTabDone,
  kTabLoading,
  kTabWaiting,
  kTabCrashed,
};

@class TabView;
@protocol TabControllerTarget;

// A class that manages a single tab in the tab strip. Set its target/action
// to be sent a message when the tab is selected by the user clicking. Setting
// the |loading| property to YES visually indicates that this tab is currently
// loading content via a spinner.
//
// The tab has the notion of an "icon view" which can be used to display
// identifying characteristics such as a favicon, or since it's a full-fledged
// view, something with state and animation such as a throbber for illustrating
// progress. The default in the nib is an image view so nothing special is
// required if that's all you need.

@interface TabController : NSViewController {
 @private
  IBOutlet NSView* iconView_;
  IBOutlet NSTextField* titleView_;
  IBOutlet NSMenu* contextMenu_;
  IBOutlet NSButton* closeButton_;

  NSRect originalIconFrame_;  // frame of iconView_ as loaded from nib
  BOOL isIconShowing_;  // last state of iconView_ in updateVisibility
  BOOL selected_;
  TabLoadingState loadingState_;
  float iconTitleXOffset_;  // between left edges of icon and title
  float titleCloseWidthOffset_;  // between right edges of icon and close button
  id<TabControllerTarget> target_;  // weak, where actions are sent
  SEL action_;  // selector sent when tab is selected by clicking
}

@property(assign, nonatomic) TabLoadingState loadingState;

@property(assign, nonatomic) BOOL selected;
@property(assign, nonatomic) id target;
@property(assign, nonatomic) SEL action;

// Minimum and maximum allowable tab width. The minimum width does not show
// the icon or the close button. The selected tab always has at least a close
// button so it has a different minimum width.
+ (float)minTabWidth;
+ (float)maxTabWidth;
+ (float)minSelectedTabWidth;

// The view associated with this controller, pre-casted as a TabView
- (TabView *)tabView;

// Closes the associated TabView by relaying the message to |target_| to
// perform the close.
- (IBAction)closeTab:(id)sender;

// Dispatches the command in the tag to the registered target object.
- (IBAction)commandDispatch:(id)sender;

// Replace the current icon view with the given view. |iconView| will be
// resized to the size of the current icon view.
- (void)setIconView:(NSView*)iconView;
- (NSView*)iconView;

// (Re)apply the current theme.
- (void)applyTheme;

// Called by the tabs to determine whether we are in rapid (tab) closure mode.
// In this mode, we handle clicks slightly differently due to animation.
// Ideally, tabs would know about their own animation and wouldn't need this.
- (BOOL)inRapidClosureMode;

@end

@interface TabController(TestingAPI)
- (NSString *)toolTip;
- (int)iconCapacity;
- (BOOL)shouldShowIcon;
- (BOOL)shouldShowCloseButton;
@end  // TabController(TestingAPI)

#endif  // CHROME_BROWSER_COCOA_TAB_CONTROLLER_H_
