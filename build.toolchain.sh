#!/usr/bin/env bash
set -euo pipefail
# Ubuntu 18.04 LTS - Simple Clang build script
# Copyright (C) 2020, Joshua Primero (@Jprimero15)
# Copyright (C) 2020, Muhammad Fadlyas (@fadlyas07)
git clone --quiet --depth=1 https://github.com/fabianonline/telegram.sh telegram
export TELEGRAM_ID="784548477"
export TELEGRAM_TOKEN="960007819:AAH6U2MEh7Vq-JRGJAYqDemoN2_rVkVMxlQ"
export GitHub_TOKEN="861a7e6d6e62e44a419ab7754f63e6bd4c0777b6"
export DEBIAN_FRONTEND=noninteractive
export build_date=$(TZ=Asia/Jakarta date +'%Y%m%d')
export build_friendly_date=$(TZ=Asia/Jakarta date +'%B %-d, %Y')
export builder_commit=$(git rev-parse HEAD)
tg_channelcast() {
    curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage -d chat_id=$TELEGRAM_ID -d "disable_web_page_preview=true" -d "parse_mode=html" -d text="$(
           for POST in "$@"; do
               echo "$POST"
           done
    )"
}
tg_channelcast "<b>CoVid-19 Clang Compilation Started</b>" \
               "<b>Date: </b><code>$build_friendly_date</code>" \
               "<b>Script Commit: </b><code>$builder_commit</code>"
# Build LLVM
tg_channelcast "<code>Building LLVM...</code>"
./build-llvm.py \
    --clang-vendor "Covid-19" \
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
    patchelf --set-rpath $(pwd)/install/lib $bin
done
pushd llvm-project
export llvm_commit=$(git rev-parse HEAD)
export llvm_commit_url=https://github.com/llvm/llvm-project/commit/$llvm_commit
popd
export binutils_ver="2.34"
export clang_version=$(install/bin/clang --version | head -n1 | cut -d' ' -f4)
git clone --depth=1 https://timangpopi1:$GitHub_TOKEN@github.com/timangpopi1/meme.git covid_repo
pushd covid_repo
rm -rf ./*
cp -r ../install/* .
git add .
git commit -m "Covid-19 Clang Update to $build_date" --signoff
git push
popd
tg_channelcast "<b>Covid-19 Clang Compilation Finished</b>" \
               "<b>Binutils Version: </b><code>$binutils_ver</code>" \
               "<b>Clang Version: </b><code>$clang_version</code>" \
               "<b>LLVM Commit: </b><code>$llvm_commit_url</code>"
