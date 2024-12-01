#!/bin/bash
#
# Compile script for kernel building simple
#

# Delet out folder 
rm -rf out/

# Kernel_Defconfig
KERNEL_DEFCONFIG=vendor/sweet_defconfig
#DEFCONFIG=vendor/sweet.config

# Time date
TIME="$(date "+%Y%m%d-%H%M%S")"
# Build Start
BUILD_START=$(date +"%s")

# Colors 
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# WeebX clang 20.0.0git Downloads
if [ ! -d "$PWD/clang" ]; then
	wget "$(curl -s https://raw.githubusercontent.com/XSans0/WeebX-Clang/main/main/link.txt)" -O "weebx-clang.tar.gz"
	mkdir clang && tar -xvf weebx-clang.tar.gz -C clang && rm -rf weebx-clang.tar.gz
else
	echo "Local clang dir found, will not download clang and using that instead"
fi

# Speed up build proces
MAKE="./makeparallel"

# Set up environment variables for the build
export PATH="$PWD/clang/bin:$PATH"
export ARCH=arm64
export KBUILD_BUILD_USER=Builder~Rem
export KBUILD_BUILD_HOST=Not~Gaming~Kernel~XD
export KBUILD_COMPILER_STRING="$PWD/clang"

clear

echo -e "$blue************************************************"
echo -e "   Starting building kernel Redmi Note 10 Pro    "
echo -e "************************************************$nocol"
# Prompt user to choose the build type (MIUI or AOSP)
echo "Choose the build type:"
echo "1. MIUI"
echo "2. AOSP"
read -p "Enter the number of your choice: " build_choice

# Modify dtsi file if MIUI & AOSP build is selected
if [ "$build_choice" = "1" ]; then
    sed -i 's/qcom,mdss-pan-physical-width-dimension = <69>;$/qcom,mdss-pan-physical-width-dimension = <695>;/' arch/arm64/boot/dts/qcom/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi
    sed -i 's/qcom,mdss-pan-physical-height-dimension = <154>;$/qcom,mdss-pan-physical-height-dimension = <1546>;/' arch/arm64/boot/dts/qcom/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi

# Dimension selected
echo -e "$blue************************************************"
echo -e  "   MIUI build selected For MIUI ROM            "
echo -e "************************************************$nocol"
    zip_name="MIUI"
elif [ "$build_choice" = "2" ]; then
echo -e "$blue************************************************"
echo -e  "   AOSP build selected For AOSP ROM         "
echo -e "************************************************$nocol"
    zip_name="AOSP"
else
    echo "Invalid choice. Exiting..."
    exit 1
fi

# Build the kernel
make O=out ARCH=arm64 $KERNEL_DEFCONFIG
#make O=out $DEFCONFIG
make -j$(nproc --all) \
    O=out \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    AR=llvm-ar \
    NM=llvm-nm \
    LD=ld.lld \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CC=clang \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1 | tee log.txt

kernel="out/arch/arm64/boot/Image.gz"
dtbo="out/arch/arm64/boot/dtbo.img"
dtb="out/arch/arm64/boot/dtb.img"

if [ ! -f "$kernel" ] || [ ! -f "$dtbo" ] || [ ! -f "$dtb" ]; then
	echo -e "\nCompilation failed!"
	exit 1
fi

echo -e "\nKernel compiled successfully! Zipping up...\n"

if [ ! -d "AnyKernel3" ]; then
git clone  --depth=1 https://github.com/basamaryan/AnyKernel3 -b master AnyKernel3
fi

# Modify anykernel.sh to replace device names
sed -i "s/kernel\.string=.*/kernel.string=AGNI-Kernel By @DenomSly/" AnyKernel3/anykernel.sh
sed -i "s/device\.name1=.*/device.name1=sweet/" AnyKernel3/anykernel.sh
sed -i "s/device\.name2=.*/device.name2=sweetin/" AnyKernel3/anykernel.sh
sed -i "s/supported\.versions=.*/supported.versions=11-14/" AnyKernel3/anykernel.sh

cp $kernel AnyKernel3
cp $dtbo AnyKernel3
cp $dtb AnyKernel3
cd AnyKernel3
zip -r9 "../AGNI-${zip_name}-$TIME" * -x .git
cd ..
rm -rf AnyKernel3/Image.gz
rm -rf AnyKernel3/dtbo.img
rm -rf AnyKernel3/dtb.img
rm -rf AnyKernel3/r9.zip

# Function to revert changes made to the dtsi file
revert_changes() {
    sed -i 's/qcom,mdss-pan-physical-width-dimension = <695>;$/qcom,mdss-pan-physical-width-dimension = <69>;/' arch/arm64/boot/dts/qcom/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi
    sed -i 's/qcom,mdss-pan-physical-height-dimension = <1546>;$/qcom,mdss-pan-physical-height-dimension = <154>;/' arch/arm64/boot/dts/qcom/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi
    }

echo -e "$blue************************************************"
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo -e "************************************************$nocol"

# Revert changes after compiling kernel
revert_changes
