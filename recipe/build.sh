#!/bin/bash
set -ex

export EM_BINARYEN_ROOT=$PREFIX
export EM_CONFIG=$PREFIX/lib/emscripten-$PKG_VERSION/.emscripten

python tools/install.py $PREFIX/lib/emscripten-$PKG_VERSION/
# remove leftovers
rm -f $PREFIX/lib/emscripten-$PKG_VERSION/build_env_setup.sh
rm -f $PREFIX/lib/emscripten-$PKG_VERSION/conda_build.sh

python $RECIPE_DIR/link_bin.py

# make emcc etc. executable
chmod -R +x $PREFIX/lib/emscripten-$PKG_VERSION

$PREFIX/bin/emcc --generate-config

# emcc may materialize additional entrypoints such as emar during config generation
python $RECIPE_DIR/link_bin.py

# make emcc etc. executable again after relinking
chmod -R +x $PREFIX/lib/emscripten-$PKG_VERSION

python $RECIPE_DIR/fix_emscripten_config.py

pushd $PREFIX/lib/emscripten-$PKG_VERSION/
echo "Checking node"
file $(which node)
popd

rm -rf $PREFIX/lib/emscripten-$PKG_VERSION/tests

# build the caches
if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" || "$CROSSCOMPILING_EMULATOR" != "" ]]; then
  export NODE_JS=$BUILD_PREFIX/bin/node
  echo "int main() {};" > asd.c
  $PREFIX/bin/emcc asd.c
fi

# We should probably not do this
# embuilder build ALL
