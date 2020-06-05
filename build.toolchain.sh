#!/usr/bin/env bash
set -euo pipefail
# Ubuntu 18.04 LTS - Simple Clang build script
# Copyright (C) 2020, Joshua Primero (@Jprimero15)
# Copyright (C) 2020, Muhammad Fadlyas (@fadlyas07)
git clone --quiet --depth=1 https://github.com/fabianonline/telegram.sh telegram
export TELEGRAM_ID="784548477"
export TELEGRAM_TOKEN="960007819:AAH6U2MEh7Vq-JRGJAYqDemoN2_rVkVMxlQ"
export GitHub_TOKEN="3f6ebfe8be6b4e14d7b529b67798f0be2bff69c1"
export DEBIAN_FRONTEND=noninteractive
export build_date=$(TZ=Asia/Jakarta date +'%Y%m%d')
export build_friendly_date=$(TZ=Asia/Jakarta date +'%B %-d, %Y')
export builder_commit=$(git rev-parse HEAD)
git config --global user.email "fadlyardhians@outlook.com"
git config --global user.name "timangpopi1"
tg_channelcast() {
    curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage -d chat_id=$TELEGRAM_ID -d "disable_web_page_preview=true" -d "parse_mode=html" -d text="$(
           for POST in "$@"; do
               echo "$POST"
           done
    )"
}
tg_channelcast "<b>MiHub Clang Compilation Started</b>" \
               "<b>Date: </b><code>$build_friendly_date</code>" \
               "<b>Script Commit: </b><code>$builder_commit</code>"
# Build LLVM
tg_channelcast "<code>Building LLVM...</code>"
./build-llvm.py \
    --clang-vendor "MiHub" \
    --targets "ARM;AArch64;X86" \
    --shallow-clone \
    --pgo
# Build binutils
tg_channelcast "<code>Building Binutils...</code>"
./build-binutils.py --targets arm aarch64 x86_64
# Remove unused products
tg_channelcast "<code>Removing Unused Products...</code>"
rm -fr install/include
rm -f install/lib/*.a install/lib/*.la
# Strip remaining products
tg_channelcast "<code>Stripping Remaining Products...</code>"
for f in $(find install -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}'); do
    strip "${f::-1}"
done
# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
tg_channelcast "<code>Setting Library Load Paths for Portability...</code>"
for bin in $(find install -mindepth 2 -maxdepth 3 -type f -exec file {} \; | grep 'ELF .* interpreter' | awk '{print $1}'); do
    bin=${bin::-1}
    echo $bin
    patchelf --set-rpath "$(pwd)/install/lib" "$bin"
done
pushd llvm-project
export llvm_commit=$(git rev-parse HEAD)
export llvm_commit_url=https://github.com/llvm/llvm-project/commit/$llvm_commit
popd
export binutils_ver="2.34"
export clang_version=$(install/bin/clang --version | head -n1 | cut -d' ' -f4)
git clone --depth=1 https://timangpopi1:$GitHub_TOKEN@github.com/timangpopi1/meme.git covid_repo
pushd covid_repo
rm -fr ./*
cp -r ../install/* .
git add .
tar -zcvf MiHub-clang-$build_date.tar.gz *
tg_channelcast "Uploading into telegram..."
curl -F document=@$(echo *tar.gz) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
popd
tg_channelcast "<b>MiHub Clang Compilation Finished</b>" \
               "<b>Binutils Version: </b><code>$binutils_ver</code>" \
               "<b>Clang Version: </b><code>$clang_version</code>" \
               "<b>LLVM Commit: </b><code>$llvm_commit_url</code>"
