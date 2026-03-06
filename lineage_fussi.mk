#
# Copyright (C) 2021-2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
TARGET_SUPPORTS_OMX_SERVICE := false
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from fussi device
$(call inherit-product, device/oppo/fussi/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_fussi
PRODUCT_DEVICE := fussi
PRODUCT_MANUFACTURER := OPPO
PRODUCT_BRAND := OPPO
PRODUCT_MODEL := CPH2173

PRODUCT_GMS_CLIENTID_BASE := android-oppo

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="OPPOFindX3Pro-user 14 UKQ1.230924.001 R.1bafd8f_650b7_650b6 release-keys" \
    BuildFingerprint=OPPO/OPPOFindX3Pro/OPPOFindX3Pro:14/UKQ1.230924.001/R.1bafd8f_650b7_650b6:user/release-keys \
    DeviceName=OPPOFindX3Pro \
    DeviceProduct=OPPOFindX3Pro \
    SystemDevice=OPPOFindX3Pro \
    SystemName=OPPOFindX3Pro    \
    RisingChipset="Snapdragon 888" \
    RisingMaintainer="MomoYuuki"