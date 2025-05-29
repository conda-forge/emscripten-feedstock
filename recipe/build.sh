#!/bin/bash
set -ex

export EM_BINARYEN_ROOT=$PREFIX

python tools/install.py $PREFIX/lib/emscripten-$PKG_VERSION/
# remove leftovers
rm $PREFIX/lib/emscripten-$PKG_VERSION/build_env_setup.sh
rm $PREFIX/lib/emscripten-$PKG_VERSION/conda_build.sh

python $RECIPE_DIR/link_bin.py

# make emcc etc. executable
chmod -R +x $PREFIX/lib/emscripten-$PKG_VERSION

emcc --generate-config

python $RECIPE_DIR/fix_emscripten_config.py

echo "=== Post-fix configuration check ==="
echo "Updated emscripten config file:"
cat $PREFIX/lib/emscripten-$PKG_VERSION/.emscripten
echo "=== End post-fix check ==="

# Debug: Check what clang emscripten is trying to use
echo "=== Debugging clang configuration ==="
echo "PREFIX: $PREFIX"
echo "BUILD_PREFIX: ${BUILD_PREFIX:-not set}"

echo "Testing emcc directly:"
emcc --version || echo "emcc --version failed"

echo "Checking what clang emcc is trying to use:"
emcc -v asd.c 2>&1 | head -20 || echo "emcc -v failed"

echo "=== End debugging ==="

pushd $PREFIX/lib/emscripten-$PKG_VERSION/
npm install
popd

rm -rf $PREFIX/lib/emscripten-$PKG_VERSION/tests

# build the caches
echo "int main() {};" > asd.c
emcc asd.c

# We should probably not do this
# embuilder build ALL
