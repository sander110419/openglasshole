#pragma once

#include <stdint.h>

// These preprocessor settings deliberately have defaults here so an existing,
// private config.h from an older checkout still builds after a firmware update.
// Set them before including this header (config.h is included first in main.cpp).
#ifndef OGH_SCROLL_MODE
#define OGH_SCROLL_MODE 0
#endif

#ifndef OGH_GLANCE_DWELL_MS
#define OGH_GLANCE_DWELL_MS 1200UL
#endif

#ifndef OGH_BLACKOUT_ON_PAUSE
#define OGH_BLACKOUT_ON_PAUSE 1
#endif

namespace ogh_motion {

enum class ScrollMode : uint8_t {
    SMOOTH_PIXELS = 0,
    LINE_STEPS = 1,
};

struct AdvanceResult {
    int32_t offset_px;
    uint32_t wait_ms;
};

// Pure state transition used by the device and the host-side regression test.
// max_offset_px is the minimum offset needed to reveal the final content pixel.
// LINE_STEPS rounds that limit up to a row boundary so it never returns a
// partially exposed text row; the small resulting blank margin is intentional.
inline AdvanceResult advanceScroll(
    ScrollMode mode,
    int32_t current_offset_px,
    int32_t max_offset_px,
    int16_t line_height_px,
    uint32_t smooth_frame_ms,
    uint32_t glance_dwell_ms,
    uint32_t start_hold_ms,
    uint32_t end_hold_ms
) {
    if (max_offset_px <= 0) {
        return {0, 0};
    }
    const int32_t scroll_limit_px = mode == ScrollMode::LINE_STEPS
        ? ((max_offset_px + line_height_px - 1) / line_height_px) * line_height_px
        : max_offset_px;
    if (current_offset_px >= scroll_limit_px) {
        return {0, start_hold_ms};
    }

    const int32_t step_px = mode == ScrollMode::LINE_STEPS
        ? static_cast<int32_t>(line_height_px)
        : 1;
    const int32_t unclamped_offset_px = current_offset_px + step_px;
    const int32_t next_offset_px = unclamped_offset_px < scroll_limit_px
        ? unclamped_offset_px
        : scroll_limit_px;
    const uint32_t wait_ms = next_offset_px == scroll_limit_px
        ? end_hold_ms
        : (mode == ScrollMode::LINE_STEPS ? glance_dwell_ms : smooth_frame_ms);
    return {next_offset_px, wait_ms};
}

struct TapResult {
    bool paused;
    bool blackout;
};

// A short tap preserves pause/resume semantics. With blackout enabled, the
// paused state also blanks the OLED and selects display-off; the next tap is
// the peek. This is not a hardware VCC disconnect.
inline TapResult shortTap(bool currently_paused, bool blackout_on_pause) {
    const bool next_paused = !currently_paused;
    return {next_paused, next_paused && blackout_on_pause};
}

}  // namespace ogh_motion
