# Fussi QTI vibrator HAL adaptation

## Integration

`device/oppo/fussi/device.mk` selects
`vendor.qti.hardware.vibrator.service` from
`vendor/qcom/opensource/vibrator` and installs its excluded-input-devices
configuration. The common tree no longer selects a vibrator service; other
devices inheriting it must provide their own vibrator configuration.

Fussi enables `qti_vibrator.use_effect_stream` and selects the device library
`libqtivibratoreffect.fussi` with `qti_vibrator.effect_lib`. The library exports
`get_effect_stream()` using the QTI header ABI. Standard effects use IDs 0–5;
composition primitives use IDs 0–8 with the HAL's `0x8000` lookup bit.
Unknown IDs return null. The library is installed as a dependency of the HAL.

The QTI OL policy is installed at `/vendor/etc/HapticsPolicy.xml`. This uses the
existing `qcom-hv-haptics` input/FIFO path, without enabling the PAL closed-loop
backend. The existing Qualcomm SELinux configuration labels the new service
and permits input device access. No kernel voltage or calibration is changed.

No Android framework or SystemUI behavior patch is required. The previous
`MSDLPlayerImpl.kt` unlock fallback patch has been reverted. After flashing,
SystemUI should select compositions based on the new HAL's reported primitive
support; this must be confirmed on the running device.

## Waveform source

Samples are extracted from PEEM00 ColorOS 14.0.0.618:
`odm/lib64/libqtivibratoreffect.so`, SHA-256
`b5fe563943546e14a7001f85caee58ceb69bcee9f8346e1c0eace78368db90af`.

The inspected stock 20031 DTBO has no `qcom,vibrator-type`. The stock kernel
module defaults to type 832; the stock HAL routes that type to the default
waveform table. The extractor reads its 43 entries at ELF virtual address
`0x3fb600`, resolving pointers through ELF load segments. It refuses any source
library with a different checksum.

This follows the QTI HAL/effect-library architecture used by waffle, with fussi
waveforms. No waffle waveform samples are copied into this library.

## Standard effects

| Android effect | Stock ID | Rate | Duration |
| --- | --- | --- | --- |
| CLICK (0) | 10 | 24000 Hz | 19.250 ms |
| DOUBLE_CLICK (1) | 10, 50 ms silence, 10 | 24000 Hz | 88.500 ms |
| TICK (2) | 1 | 24000 Hz | 8.625 ms |
| THUD (3) | 3 | 24000 Hz | 61.708 ms |
| POP (4) | 4 | 24000 Hz | 13.042 ms |
| HEAVY_CLICK (5) | 10 | 24000 Hz | 19.250 ms |

With the previous HAL at STRONG, stock 1 was crisp but weak, stock 0 buzzed or
trailed, and stock 10 was crisp with suitable strength. Therefore CLICK and
HEAVY_CLICK share stock 10, and TICK uses stock 1. These observations do not
constitute validation of the new HAL's amplitude handling or compositions.

## Experimental composition primitives

These are candidate mappings, not a recovered ColorOS primitive table. All
nine IDs have entries; having an entry does not prove the intended sensation.
In particular, SPIN and the rise/fall shapes still need perceptual tuning.

| Primitive | Stock ID | Duration | Processing |
| --- | --- | --- | --- |
| NOOP (0) | 5 | 0.083 ms | Original silent samples |
| CLICK (1) | 10 | 19.250 ms | Original samples |
| THUD (2) | 3 | 61.708 ms | Original samples |
| SPIN (3) | 12 | 25.667 ms | Original samples, experimental mapping |
| QUICK_RISE (4) | 6 | 19.125 ms | Original samples, experimental mapping |
| SLOW_RISE (5) | 8 | 23.583 ms | Original samples, experimental mapping |
| QUICK_FALL (6) | 7 | 8.500 ms | Original samples, experimental mapping |
| LIGHT_TICK (7) | 1 | 8.625 ms | Original samples |
| LOW_TICK (8) | 1 | 8.625 ms | Original samples; restored from half amplitude |

All primitives use 24000 Hz sample rate. After device testing found volume and
brightness slider vibration too weak, LOW_TICK was restored from half amplitude
to the original stock 1 samples. It now shares LIGHT_TICK's waveform and duration;
it is not a distinct low-frequency waveform. The stronger slider response still
needs device validation. The QTI HAL further scales each primitive with the requested
composition scale and reports integer sample duration plus one millisecond.
The motor resonance frequency is separate from the sample rate.

The expected benefit is that unlock can use LIGHT_TICK + CLICK, and continuous
sliders can use scaled LOW_TICK sequences instead of the generic timed
waveform fallback. This remains subject to device testing, including callback,
cancellation and rapid consecutive playback behavior.

## Regeneration

From the Android source root:

```sh
python3 device/oppo/fussi/vibrator/extract_effects.py /path/to/odm/lib64/libqtivibratoreffect.so
python3 device/oppo/fussi/vibrator/extract_effects.py /path/to/odm/lib64/libqtivibratoreffect.so --check
```

The generator reads the original library and writes only
`vibrator/include/VibrationEffectConfig.h`. Do not edit generated samples by
hand. The old OPlus JSON loader and INCLUDE_DIR setting are no longer used.

## Build and device validation (performed by the device owner)

Use your normal fussi build environment and build the full ROM, for example
`m pixelos -j8` after your usual environment setup. Include the system update
as well as vendor if the previous MSDL patch was already built or flashed.
The installed package must contain the new service and its dependencies, with
no remaining `.oplus` service init file or duplicate vibrator VINTF instance.
The build system normally removes obsolete installed modules; if a stale
output remains, clean installed output before rebuilding the ROM.

After flashing and rebooting:

```sh
adb shell dumpsys vibrator_manager
adb shell ps -A | grep vibrator
```

Verify COMPOSE capability and primitive IDs 0–8, and confirm only the new
service is running. Test fingerprint unlock, back gesture activation and
cancellation, volume/brightness slider dragging and endpoints, double click,
notifications and ringtones. Compare low and high intensity settings. Inspect
logs for FIFO upload failures, service crashes and SELinux denials. No new HAL
has been flashed by the assistant; successful build and on-device behavior
remain to be verified by the device owner.
