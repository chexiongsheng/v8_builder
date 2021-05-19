VERSION=$1
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"

sudo apt-get install -y \
    pkg-config \
    git \
    subversion \
    curl \
    wget \
    build-essential \
    python \
    xz-utils \
    zip

cd ~
echo "=====[ Getting Depot Tools ]====="	
git clone -q https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=$(pwd)/depot_tools:$PATH
gclient


mkdir v8
cd v8

echo "=====[ Fetching V8 ]====="
fetch v8
echo "target_os = ['android']" >> .gclient
cd ~/v8/v8
./build/install-build-deps-android.sh
git checkout refs/tags/$VERSION
gclient sync


echo "=====[ Building V8 ]====="
python ./tools/dev/v8gen.py x64.release -vv -- '
target_os = "android"
target_cpu = "x64"
is_debug = false
v8_enable_i18n_support= true
v8_target_cpu = "x64"
use_goma = false
v8_use_snapshot = true
v8_use_external_startup_data = true
v8_static_library = true
strip_debug_info = false
symbol_level=1
use_custom_libcxx=false
use_custom_libcxx_for_host=true
v8_enable_pointer_compression=false
'
ninja -C out.gn/x64.release -t clean
ninja -C out.gn/x64.release wee8
third_party/android_ndk/toolchains/x86_64-4.9/prebuilt/linux-x86_64/x86_64-linux-android/bin/strip -g -S -d --strip-debug --verbose out.gn/x64.release/obj/libwee8.a

node $GITHUB_WORKSPACE/v8-build/genBlobHeader.js "android x64" out.gn/x64.release/snapshot_blob.bin

mkdir -p output/v8/Lib/Android/x64
cp out.gn/x64.release/obj/libwee8.a output/v8/Lib/Android/x64/
mkdir -p output/v8/Inc/Blob/Android/x64
cp SnapshotBlob.h output/v8/Inc/Blob/Android/x64/
