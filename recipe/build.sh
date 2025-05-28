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

# Debug: Check what clang emscripten is trying to use
echo "=== Debugging clang configuration ==="
echo "PREFIX: $PREFIX"
echo "BUILD_PREFIX: ${BUILD_PREFIX:-not set}"
echo "Environment PATH: $PATH"
echo "All clang binaries in PATH:"
which -a clang 2>/dev/null || echo "No clang found in PATH"

echo "PREFIX/bin contents:"
ls -la $PREFIX/bin/ | grep -E "(clang|llvm)" || echo "No clang/llvm tools in PREFIX/bin"

echo "BUILD_PREFIX/bin contents (if different):"
if [[ -n "$BUILD_PREFIX" && "$BUILD_PREFIX" != "$PREFIX" ]]; then
    ls -la $BUILD_PREFIX/bin/ | grep -E "(clang|llvm)" || echo "No clang/llvm tools in BUILD_PREFIX/bin"
fi

echo "Emscripten config file content:"
cat $PREFIX/lib/emscripten-$PKG_VERSION/.emscripten || echo "Config file not found"
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
