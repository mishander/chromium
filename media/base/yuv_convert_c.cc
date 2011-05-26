// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "media/base/yuv_convert.h"
#include "media/base/yuv_convert_internal.h"

namespace media {

static int clip_byte(int x) {
  if (x > 255)
    return 255;
  else if (x < 0)
    return 0;
  else
    return x;
}

void ConvertRGB32ToYUV_C(const uint8* rgbframe,
                         uint8* yplane,
                         uint8* uplane,
                         uint8* vplane,
                         int width,
                         int height,
                         int rgbstride,
                         int ystride,
                         int uvstride) {
  for (int i = 0; i < height; ++i) {
    for (int j = 0; j < width; ++j) {
      // Since the input pixel format is RGB32, there are 4 bytes per pixel.
      const uint8* pixel = rgbframe + 4 * j;
      yplane[j] = clip_byte(((pixel[2] * 66 + pixel[1] * 129 +
                             pixel[0] * 25 + 128) >> 8) + 16);
      if (i % 2 == 0 && j % 2 == 0) {
        uplane[j / 2] = clip_byte(((pixel[2] * -38 + pixel[1] * -74 +
                                   pixel[0] * 112 + 128) >> 8) + 128);
        vplane[j / 2] = clip_byte(((pixel[2] * 112 + pixel[1] * -94 +
                                    pixel[1] * -18 + 128) >> 8) + 128);
      }
    }

    rgbframe += rgbstride;
    yplane += ystride;
    if (i % 2 == 0) {
      uplane += uvstride;
      vplane += uvstride;
    }
  }
}

void ConvertRGB24ToYUV_C(const uint8* rgbframe,
                         uint8* yplane,
                         uint8* uplane,
                         uint8* vplane,
                         int width,
                         int height,
                         int rgbstride,
                         int ystride,
                         int uvstride) {
  for (int i = 0; i < height; ++i) {
    for (int j = 0; j < width; ++j) {
      // Since the input pixel format is RGB24, there are 3 bytes per pixel.
      const uint8* pixel = rgbframe + 3 * j;
      yplane[j] = clip_byte(((pixel[2] * 66 + pixel[1] * 129 +
                              pixel[0] * 25 + 128) >> 8) + 16);
      if (i % 2 == 0 && j % 2 == 0) {
        uplane[j / 2] = clip_byte(((pixel[2] * -38 + pixel[1] * -74 +
                                    pixel[0] * 112 + 128) >> 8) + 128);
        vplane[j / 2] = clip_byte(((pixel[2] * 112 + pixel[1] * -94 +
                                    pixel[1] * -18 + 128) >> 8) + 128);
      }
    }

    rgbframe += rgbstride;
    yplane += ystride;
    if (i % 2 == 0) {
      uplane += uvstride;
      vplane += uvstride;
    }
  }
}

void ConvertYUY2ToYUV_C(const uint8* src,
                        uint8* yplane,
                        uint8* uplane,
                        uint8* vplane,
                        int width,
                        int height) {
  for (int i = 0; i < height / 2; ++i) {
    for (int j = 0; j < (width / 2); ++j) {
      yplane[0] = src[0];
      *uplane = src[1];
      yplane[1] = src[2];
      *vplane = src[3];
      src += 4;
      yplane += 2;
      uplane++;
      vplane++;
    }
    for (int j = 0; j < (width / 2); ++j) {
      yplane[0] = src[0];
      yplane[1] = src[2];
      src += 4;
      yplane += 2;
    }
  }
}

}  // namespace media
