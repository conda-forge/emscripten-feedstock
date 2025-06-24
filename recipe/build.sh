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

pushd $PREFIX/lib/emscripten-$PKG_VERSION/
echo "Checking node"
file $(which node)
npm install
popd

rm -rf $PREFIX/lib/emscripten-$PKG_VERSION/tests

# build the caches
if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" || "$CROSSCOMPILING_EMULATOR" != "" ]]; then
  export NODE_JS=$BUILD_PREFIX/bin/node
  echo "int main() {};" > asd.c
  emcc asd.c
fi

# We should probably not do this
# embuilder build ALL
