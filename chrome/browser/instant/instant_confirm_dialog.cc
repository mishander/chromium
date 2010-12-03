// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "chrome/browser/instant/instant_confirm_dialog.h"

#include "chrome/browser/instant/instant_controller.h"
#include "chrome/browser/instant/promo_counter.h"
#include "chrome/browser/prefs/pref_service.h"
#include "chrome/browser/profiles/profile.h"
#include "chrome/common/pref_names.h"

namespace browser {

const char kInstantLearnMoreURL[] =
    "http://www.google.com/support/chrome/bin/answer.py?answer=180655";

void ShowInstantConfirmDialogIfNecessary(gfx::NativeWindow parent,
                                         Profile* profile) {
  PrefService* prefs = profile->GetPrefs();
  if (!prefs)
    return;

  PromoCounter* promo_counter = profile->GetInstantPromoCounter();
  if (promo_counter)
    promo_counter->Hide();

  if (prefs->GetBoolean(prefs::kInstantConfirmDialogShown)) {
    InstantController::Enable(profile);
    return;
  }

  ShowInstantConfirmDialog(parent, profile);
}

}  // namespace browser
