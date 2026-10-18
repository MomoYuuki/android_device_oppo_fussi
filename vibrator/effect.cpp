// SPDX-License-Identifier: Apache-2.0

#include <cstdint>

#include <effect.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(*(a)))
#include "VibrationEffectConfig.h"

const effect_stream* get_effect_stream(uint32_t effect_id) {
    constexpr uint32_t kPrimitiveMask = 0x8000;
    if (effect_id & kPrimitiveMask) {
        const auto primitive_id = effect_id & ~kPrimitiveMask;
        for (const auto& primitive : primitives) {
            if (primitive.effect_id == primitive_id) return &primitive;
        }
    } else {
        for (const auto& effect : effects) {
            if (effect.effect_id == effect_id) return &effect;
        }
    }
    return nullptr;
}
