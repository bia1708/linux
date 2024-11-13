# SPDX-License-Identifier: (GPL-1.0-only OR BSD-2-Clause)
#!/bin/bash -e

TIMESTAMP=$(date +%Y_%m_%d-%H_%M)
GIT_SHA=$(git rev-parse --short HEAD)
GIT_SHA_DATE=$(git show -s --format=%cd --date=format:'%Y-%m-%d %H:%M' ${GIT_SHA} | sed -e "s/ \|\:/-/g")
BRANCH_NAME="$(echo $BUILD_SOURCEBRANCH | awk -F'/' '{print $NF}')"
SERVER_PATH=""

set_artifactory_path() {
	if [ "$BRANCH_NAME" == "main" ]; then
		SERVER_PATH="test_upload/linux/main"
	else
		SERVER_PATH="test_upload/linux/releases/$BRANCH_NAME"
	fi
}

create_extlinux() {
    local platform=$1

    touch extlinux.conf
    if [ "${platform}" == "arria10" ]; then
        dtb_name="socfpga_arria10_socdk_sdmmc.dtb"
    else
        dtb_name="socfpga.dtb"
    fi

    echo "LABEL Linux Default"                > extlinux.conf
    echo "    KERNEL ../zImage"              >> extlinux.conf
    echo "    FDT ../${dtb_name}"            >> extlinux.conf
    echo "    APPEND root=/dev/mmcblk0p2 rw rootwait earlyprintk console=ttyS0,115200n8" >> extlinux.conf
}

#prepare the structure of the folder containing artifacts
artifacts_structure() {
    cd ${SOURCE_DIRECTORY}

    # Create folder structure first
    mkdir ${TIMESTAMP}

    echo "git_branch=${BUILD_SOURCEBRANCHNAME}" >> ${TIMESTAMP}/git_properties.txt
    echo "git_sha=${GIT_SHA}" >> ${TIMESTAMP}/git_properties.txt
    echo "git_sha_date=${GIT_SHA_DATE}" >> ${TIMESTAMP}/git_properties.txt

    declare -A typeARCH
    typeARCH=( ["arm"]="arria10 cyclone5 zynq"
               ["arm64"]="versal zynqmp"
               ["microblaze"]="kc705 kcu105 vc707 vcu118 vcu128" )

    declare -A image_to_copy
    image_to_copy=( ["arria10"]="socfpga_adi_defconfig/zImage"
                    ["cyclone5"]="socfpga_adi_defconfig/zImage"
                    ["zynq"]="zynq_xcomm_adv7511_defconfig/uImage"
                    ["versal"]="adi_versal_defconfig/Image"
                    ["zynqmp"]="adi_zynqmp_defconfig/Image" )

    for arch in "${!typeARCH[@]}"; do
        mkdir ${TIMESTAMP}/${arch}
        for platform in ${typeARCH[$arch]}; do
            # First copy kernels and make extlinux files.
            if [ "${arch}" != "microblaze" ]; then
                image_location="${TIMESTAMP}/${arch}/${platform}"
                mkdir ${image_location}
                if [ "${platform}" == "arria10" ] || [ "${platform}" == "cyclone5" ]; then
                    create_extlinux ${platform}
                    cp ./extlinux.conf ${image_location}
                fi
                echo "IMAGE: ${image_to_copy[${platform}]}!"
                cp ${image_to_copy[${platform}]} ${image_location}
            fi
        done

        if [ "${arch}" == "microblaze" ]; then
            dtbs_to_copy=$(ls -d -1 Microblaze/*)
        else
            dtbs_to_copy=$(ls -d -1 DTBs/* | grep "${platform}")
        fi

        # Copy DTBs to the correct location
        for dtb in ${dtbs_to_copy}; do
            cp ${dtb} "${TIMESTAMP}/${arch}"
        done
    done
}

artifacts_structure
set_artifactory_path
python3 ../ci/travis/upload_to_artifactory.py \
        --base_path="${ARTIFACTORY_PATH}" \
        --server_path="${SERVER_PATH}" \
        --local_path="${TIMESTAMP}" \
        --props_level="2" \
        --properties="git_sha=${BUILD_SOURCEVERSION};commit_date=${TIMESTAMP}" \
        --token="${ARTIFACTORY_TOKEN}"

echo "##vso[task.setvariable variable=TIMESTAMP;isOutput=true]${TIMESTAMP}"
echo "##vso[task.setvariable variable=BRANCH;isOutput=true]${BRANCH_NAME}"
if [ -n "$(System.PullRequest.PullRequestId)" ]; then
    echo "##vso[task.setvariable variable=PR_ID]$(System.PullRequest.PullRequestId)"
else
    echo "##vso[task.setvariable variable=PR_ID]commit"
fi
