#!/bin/bash
#
# Copyright (C) 2018-2019 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

LINEAGE_ROOT="${MY_DIR}"/../../..

HELPER="${LINEAGE_ROOT}/vendor/lineage/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
    system_ext/etc/init/dpmd.rc)
        sed -i "s/\/system\/product\/bin\//\/system\/system_ext\/bin\//g" "${2}"
        ;;
    system_ext/etc/permissions/com.qti.dpmframework.xml)
        ;&
    system_ext/etc/permissions/dpmapi.xml)
        ;&
    system_ext/etc/permissions/qcrilhook.xml)
        ;&
    system_ext/etc/permissions/telephonyservice.xml)
        sed -i "s/\/product\/framework\//\/system_ext\/framework\//g" "${2}"
        ;;
    system_ext/etc/permissions/com.qualcomm.qti.imscmservice-V2.0-java.xml)
        ;&
    system_ext/etc/permissions/com.qualcomm.qti.imscmservice-V2.1-java.xml)
        ;&
    system_ext/etc/permissions/com.qualcomm.qti.imscmservice-V2.2-java.xml)
        sed -i "s/\/system\/product\/framework\//\/system_ext\/framework\//g" "${2}"
        ;;
    system_ext/etc/init/wfdservice.rc)
        sed -i "s/\/system\/bin\//\/system_ext\/bin\//g" "${2}"
        ;;
    system_ext/etc/permissions/qti_libpermissions.xml)
        sed -i "s/name=\"android.hidl.manager-V1.0-java/name=\"android.hidl.manager@1.0-java/g" "${2}"
        ;;
    system_ext/lib64/libdpmframework.so)
        patchelf --add-needed libcutils_shim.so "${2}"

    esac
}

# Initialize the helper for common device
setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${LINEAGE_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

if [ -s "${MY_DIR}/../${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${LINEAGE_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/../${DEVICE}/proprietary-files.txt" "${SRC}" \
            "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"
