#include "motion_display.h"

#include <cassert>

namespace {

constexpr int16_t LINE_HEIGHT_PX = 8;
constexpr uint32_t SMOOTH_FRAME_MS = 65;
constexpr uint32_t GLANCE_DWELL_MS = 1200;
constexpr uint32_t START_HOLD_MS = 1200;
constexpr uint32_t END_HOLD_MS = 1800;

ogh_motion::AdvanceResult advance(
    ogh_motion::ScrollMode mode,
    int32_t offset_px,
    int32_t max_offset_px
) {
    return ogh_motion::advanceScroll(
        mode,
        offset_px,
        max_offset_px,
        LINE_HEIGHT_PX,
        SMOOTH_FRAME_MS,
        GLANCE_DWELL_MS,
        START_HOLD_MS,
        END_HOLD_MS
    );
}

}  // namespace

int main() {
    ogh_motion::AdvanceResult result = advance(
        ogh_motion::ScrollMode::SMOOTH_PIXELS, 0, 24
    );
    assert(result.offset_px == 1);
    assert(result.wait_ms == SMOOTH_FRAME_MS);

    result = advance(ogh_motion::ScrollMode::SMOOTH_PIXELS, 23, 24);
    assert(result.offset_px == 24);
    assert(result.wait_ms == END_HOLD_MS);

    result = advance(ogh_motion::ScrollMode::LINE_STEPS, 0, 24);
    assert(result.offset_px == LINE_HEIGHT_PX);
    assert(result.wait_ms == GLANCE_DWELL_MS);

    result = advance(ogh_motion::ScrollMode::LINE_STEPS, 16, 20);
    assert(result.offset_px == 24);  // Final view stays aligned even with a partial-row viewport.
    assert(result.wait_ms == END_HOLD_MS);

    result = advance(ogh_motion::ScrollMode::LINE_STEPS, 24, 20);
    assert(result.offset_px == 0);
    assert(result.wait_ms == START_HOLD_MS);

    result = advance(ogh_motion::ScrollMode::LINE_STEPS, 24, 24);
    assert(result.offset_px == 0);
    assert(result.wait_ms == START_HOLD_MS);

    result = advance(ogh_motion::ScrollMode::LINE_STEPS, 0, 0);
    assert(result.offset_px == 0);
    assert(result.wait_ms == 0);

    ogh_motion::TapResult tap = ogh_motion::shortTap(false, true);
    assert(tap.paused);
    assert(tap.blackout);
    tap = ogh_motion::shortTap(tap.paused, true);
    assert(!tap.paused);
    assert(!tap.blackout);

    tap = ogh_motion::shortTap(false, false);
    assert(tap.paused);
    assert(!tap.blackout);
    return 0;
}
