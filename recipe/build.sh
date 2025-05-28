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

if [[ "${build_platform}" == "${target_platform}" ]]; then
    pushd $PREFIX/lib/emscripten-$PKG_VERSION/
    npm install
    popd
else
    # some diagnostic output; remove after debugging
    echo "We're skipping 'npm install' due to cross-compilation (${build_platform} -> ${target_platform})"
fi

rm -rf $PREFIX/lib/emscripten-$PKG_VERSION/tests

if [[ "${build_platform}" == "${target_platform}" ]]; then
    # build the caches
    echo "int main() {};" > asd.c
    emcc asd.c
    rm -f asd.c asd.js asd.wasm  # cleanup
else
    # some diagnostic output; remove after debugging
    echo "We're skipping cache building due to cross-compilation (${build_platform} -> ${target_platform})"
fi

# We should probably not do this
# embuilder build ALL
