# SPDX-License-Identifier: (GPL-1.0-only OR BSD-2-Clause)
#!/bin/bash -e

timestamp=$(date +%Y_%m_%d-%H_%M)
GIT_SHA=$(git rev-parse --short HEAD)
GIT_SHA_DATE=$(git show -s --format=%cd --date=format:'%Y-%m-%d %H:%M' ${GIT_SHA} | sed -e "s/ \|\:/-/g")
ART_PATH=$ARTIFACTORY_PATH
echo "$ART_PATH"
ls ${SOURCE_DIRECTORY}/DTBs
set_artifactory_path() {
    branch_name="$(echo $BUILD_SOURCEBRANCH | awk -F'/' '{print $NF}')"
	if [ "$BUILD_SOURCEBRANCH" == "main" ]; then
		ART_PATH="$ART_PATH/linux/main"
	else
		ART_PATH="$ART_PATH/releases/$branch_name"
	fi
}
set_artifactory_path
echo $ART_PATH
#prepare the structure of the folder containing artifacts
artifacts_structure() {
	cd ${SOURCE_DIRECTORY}
	mkdir ${timestamp}

	echo "git_branch=${BUILD_SOURCEBRANCHNAME}" >> ${timestamp}/git_properties.txt
	echo "git_sha=${GIT_SHA}" >> ${timestamp}/git_properties.txt
	echo "git_sha_date=${GIT_SHA_DATE}" >> ${timestamp}/git_properties.txt

	typeARCH=( "bcm2709" "bcm2711" "bcmrpi" )
	typeKERNEL=( "kernel7" "kernel7l" "kernel" )
	for index in "${!typeBCM[@]}"; do
		cd adi_"${typeBCM[$index]}"_defconfig
		mkdir overlays modules
		mv ./*.dtbo ./overlays
		tar -xf rpi_modules.tar.gz -C modules
		rm rpi_modules.tar.gz
		mv ./zImage ./"${typeKERNEL[$index]}".img
		cd ../
		cp -r ./adi_"${typeBCM[$index]}"_defconfig/* ./${timestamp}
	done
	tar -C ${SOURCE_DIRECTORY}/${timestamp}/modules -czvf ${SOURCE_DIRECTORY}/${timestamp}/rpi_modules.tar.gz .
	rm -r ${SOURCE_DIRECTORY}/${timestamp}/modules
}