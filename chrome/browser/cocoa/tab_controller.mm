// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac_util.h"
#include "chrome/browser/cocoa/nsimage_cache.h"
#import "chrome/browser/cocoa/tab_controller.h"
#import "chrome/browser/cocoa/tab_controller_target.h"
#import "chrome/browser/cocoa/tab_view.h"
#import "third_party/GTM/AppKit/GTMTheme.h"

@interface TabController(Private)
- (void)updateVisibility;
@end

@implementation TabController

@synthesize loadingState = loadingState_;
@synthesize target = target_;
@synthesize action = action_;

// The min widths match the windows values and are sums of left + right
// padding, of which we have no comparable constants (we draw using paths, not
// images). The selected tab width includes the close button width.
+ (float)minTabWidth { return 31; }
+ (float)minSelectedTabWidth { return 47; }
+ (float)maxTabWidth { return 220; }

- (TabView*)tabView {
  return static_cast<TabView*>([self view]);
}

- (id)init {
  self = [super initWithNibName:@"TabView" bundle:mac_util::MainAppBundle()];
  if (self != nil) {
    isIconShowing_ = YES;
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(viewResized:)
               name:NSViewFrameDidChangeNotification
             object:[self view]];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

// The internals of |-setSelected:| but doesn't check if we're already set
// to |selected|. Pass the selection change to the subviews that need it and
// mark ourselves as needing a redraw.
- (void)internalSetSelected:(BOOL)selected {
  selected_ = selected;
  [(TabView *)[self view] setState:selected];
  [self updateVisibility];
  [self applyTheme];
}

// Called when the tab's nib is done loading and all outlets are hooked up.
- (void)awakeFromNib {
  // Remember the icon's frame, so that if the icon is ever removed, a new
  // one can later replace it in the proper location.
  originalIconFrame_ = [iconView_ frame];

  // When the icon is removed, the title expands to the left to fill the space
  // left by the icon.  When the close button is removed, the title expands to
  // the right to fill its space.  These are the amounts to expand and contract
  // titleView_ under those conditions.
  NSRect titleFrame = [titleView_ frame];
  iconTitleXOffset_ = NSMinX(titleFrame) - NSMinX(originalIconFrame_);
  titleCloseWidthOffset_ = NSMaxX([closeButton_ frame]) - NSMaxX(titleFrame);

  // Ensure we don't show favicon if the tab is already too small to begin with.
  [self updateVisibility];

  [self internalSetSelected:selected_];
}

- (IBAction)closeTab:(id)sender {
  if ([[self target] respondsToSelector:@selector(closeTab:)]) {
    [[self target] performSelector:@selector(closeTab:)
                        withObject:[self view]];
  }
}

// Dispatches the command in the tag to the registered target object.
- (IBAction)commandDispatch:(id)sender {
  TabStripModel::ContextMenuCommand command =
      static_cast<TabStripModel::ContextMenuCommand>([sender tag]);
  [[self target] commandDispatch:command forController:self];
}

// Called for each menu item on its target, which would be this controller.
// Returns YES if the menu item should be enabled. We ask the tab's
// target for the proper answer.
- (BOOL)validateMenuItem:(NSMenuItem*)item {
  TabStripModel::ContextMenuCommand command =
      static_cast<TabStripModel::ContextMenuCommand>([item tag]);
  return [[self target] isCommandEnabled:command forController:self];
}

- (void)setTitle:(NSString *)title {
  [[self view] setToolTip:title];
  [super setTitle:title];
}

- (void)setSelected:(BOOL)selected {
  if (selected_ != selected)
    [self internalSetSelected:selected];
}

- (BOOL)selected {
  return selected_;
}

- (void)setIconView:(NSView*)iconView {
  [iconView_ removeFromSuperview];
  iconView_ = iconView;
  [iconView_ setFrame:originalIconFrame_];

  // Ensure that the icon is suppressed if no icon is set or if the tab is too
  // narrow to display one.
  [self updateVisibility];

  if (iconView_)
    [[self view] addSubview:iconView_];
}

- (NSView*)iconView {
  return iconView_;
}

- (NSString *)toolTip {
  return [[self view] toolTip];
}

// Return a rough approximation of the number of icons we could fit in the
// tab. We never actually do this, but it's a helpful guide for determining
// how much space we have available.
- (int)iconCapacity {
  float width = NSMaxX([closeButton_ frame]) - NSMinX(originalIconFrame_);
  float iconWidth = NSWidth(originalIconFrame_);

  return width / iconWidth;
}

// Returns YES if we should show the icon. When tabs get too small, we clip
// the favicon before the close button for selected tabs, and prefer the
// favicon for unselected tabs.  The icon can also be suppressed more directly
// by clearing iconView_.
- (BOOL)shouldShowIcon {
  if (!iconView_)
    return NO;

  int iconCapacity = [self iconCapacity];
  if ([self selected])
    return iconCapacity >= 2;
  return iconCapacity >= 1;
}

// Returns YES if we should be showing the close button. The selected tab
// always shows the close button.
- (BOOL)shouldShowCloseButton {
  return [self selected] || [self iconCapacity] >= 3;
}

// Updates the visibility of certain subviews, such as the icon and close
// button, based on criteria such as the tab's selected state and its current
// width.
- (void)updateVisibility {
  // iconView_ may have been replaced or it may be nil, so [iconView_ isHidden]
  // won't work.  Instead, the state of the icon is tracked separately in
  // isIconShowing_.
  BOOL oldShowIcon = isIconShowing_ ? YES : NO;
  BOOL newShowIcon = [self shouldShowIcon] ? YES : NO;

  [iconView_ setHidden:newShowIcon ? NO : YES];
  isIconShowing_ = newShowIcon;

  BOOL oldShowCloseButton = [closeButton_ isHidden] ? NO : YES;
  BOOL newShowCloseButton = [self shouldShowCloseButton] ? YES : NO;

  [closeButton_ setHidden:newShowCloseButton ? NO : YES];

  // Adjust the title view based on changes to the icon's and close button's
  // visibility.
  NSRect titleFrame = [titleView_ frame];

  if (oldShowIcon != newShowIcon) {
    // Adjust the left edge of the title view according to the presence or
    // absence of the icon view.

    if (newShowIcon) {
      titleFrame.origin.x += iconTitleXOffset_;
      titleFrame.size.width -= iconTitleXOffset_;
    } else {
      titleFrame.origin.x -= iconTitleXOffset_;
      titleFrame.size.width += iconTitleXOffset_;
    }
  }

  if (oldShowCloseButton != newShowCloseButton) {
    // Adjust the right edge of the title view according to the presence or
    // absence of the close button.
    if (newShowCloseButton)
      titleFrame.size.width -= titleCloseWidthOffset_;
    else
      titleFrame.size.width += titleCloseWidthOffset_;
  }

  [titleView_ setFrame:titleFrame];
}

// Called when our view is resized. If it gets too small, start by hiding
// the close button and only show it if tab is selected. Eventually, hide the
// icon as well. We know that this is for our view because we only registered
// for notifications from our specific view.
- (void)viewResized:(NSNotification*)info {
  [self updateVisibility];
}

- (void)applyTheme {
  GTMTheme* theme = [[self view] gtm_theme];
  NSColor* color = nil;
  if (!selected_) {
    color = [theme textColorForStyle:GTMThemeStyleTabBarDeselected
                               state:GTMThemeStateActiveWindow];
  }
  // Default to the selected text color unless told otherwise.
  if (!color) {
    color = [theme textColorForStyle:GTMThemeStyleToolBar
                               state:GTMThemeStateActiveWindow];
  }

  [titleView_ setTextColor:color ? color : [NSColor textColor]];
  [[self view] setNeedsDisplay:YES];
}

// Called by the tabs to determine whether we are in rapid (tab) closure mode.
- (BOOL)inRapidClosureMode {
  if ([[self target] respondsToSelector:@selector(inRapidClosureMode)]) {
    return [[self target] performSelector:@selector(inRapidClosureMode)] ?
        YES : NO;
  }
  return NO;
}

@end
