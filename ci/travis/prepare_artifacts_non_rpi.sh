# SPDX-License-Identifier: (GPL-1.0-only OR BSD-2-Clause)
#!/bin/bash -e

TIMESTAMP=$(date +%Y_%m_%d-%H_%M)
GIT_SHA=$(git rev-parse --short HEAD)
GIT_SHA_DATE=$(git show -s --format=%cd --date=format:'%Y-%m-%d %H:%M' ${GIT_SHA} | sed -e "s/ \|\:/-/g")
ART_PATH=$ARTIFACTORY_PATH

set_artifactory_path() {
    branch_name="$(echo $BUILD_SOURCEBRANCH | awk -F'/' '{print $NF}')"
	if [ "$BUILD_SOURCEBRANCH" == "main" ]; then
		ART_PATH="$ART_PATH/linux/main"
	else
		ART_PATH="$ART_PATH/releases/$branch_name"
	fi
}
# set_artifactory_path

#prepare the structure of the folder containing artifacts
artifacts_structure() {
    cd ${SOURCE_DIRECTORY}

    # Create folder structure first
    mkdir ${TIMESTAMP}
    # mkdir ${TIMESTAMP}/arm
    # mkdir ${TIMESTAMP}/arm/zynq
    # mkdir ${TIMESTAMP}/arm/a10soc
    # mkdir ${TIMESTAMP}/arm/c5
    # mkdir ${TIMESTAMP}/arm64
    # mkdir ${TIMESTAMP}/arm64/versal
    # mkdir ${TIMESTAMP}/arm64/zynq_u
    # mkdir ${TIMESTAMP}/microblaze

    echo "git_branch=${BUILD_SOURCEBRANCHNAME}" >> ${TIMESTAMP}/git_properties.txt
    echo "git_sha=${GIT_SHA}" >> ${TIMESTAMP}/git_properties.txt
    echo "git_sha_date=${GIT_SHA_DATE}" >> ${TIMESTAMP}/git_properties.txt

    typeARCH=( ["arm"]="arria10 cyclone5 zynq"
               ["arm64"]="versal zynqmp"
               ["microblaze"]="kc705 kcu105 vc707 vcu118 vcu128" )
    for arch in $typeARCH; do
        mkdir ${TIMESTAMP}/${arch}
        for subtype in ${arch}; do
            target_location="${TIMESTAMP}/${arch}/${subtype}"
            mkdir ${target_location}
            dtbs_to_copy=$(ls DTBs | grep "${subtype}")
            for dtb in ${dtbs_to_copy}; do
                cp ${dtb} ${target_location}
            done
        done
    done
	# 	cd adi_"${typeBCM[$arch]}"_defconfig
	# 	mkdir overlays modules
	# 	mv ./*.dtbo ./overlays
	# 	tar -xf rpi_modules.tar.gz -C modules
	# 	rm rpi_modules.tar.gz
	# 	mv ./zImage ./"${typeKERNEL[$index]}".img
	# 	cd ../
	# 	cp -r ./adi_"${typeBCM[$index]}"_defconfig/* ./${timestamp}
	# done
	# tar -C ${SOURCE_DIRECTORY}/${timestamp}/modules -czvf ${SOURCE_DIRECTORY}/${timestamp}/rpi_modules.tar.gz .
	# rm -r ${SOURCE_DIRECTORY}/${timestamp}/modules
}
artifacts_structure