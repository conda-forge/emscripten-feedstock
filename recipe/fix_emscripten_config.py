import os

if os.name == "nt":
    prefix = os.environ["LIBRARY_PREFIX"]
else:
    prefix = os.environ["PREFIX"]

pkg_version = os.environ["PKG_VERSION"]

print("PACKAGE_PREFIX AND VERSION: ", prefix, pkg_version)

path = os.path.join(prefix, "lib", "emscripten-" + pkg_version, ".emscripten")

print("Reading path: ", path)

with open(path, "r") as fi:
    lines = fi.readlines()

# check if we're cross-compiling
is_cross_compiling = os.environ.get("CONDA_BUILD_CROSS_COMPILATION") == "1"
build_platform = os.environ.get("build_platform", "")
target_platform = os.environ.get("target_platform", "")

print(f"Cross-compilation detected: {is_cross_compiling}")
print(f"Build platform: {build_platform}, Target platform: {target_platform}")

out_lines = ["import os"]
for line in lines:
    if line.startswith("BINARYEN_ROOT"):
        out_lines.append(f"BINARYEN_ROOT = '{prefix}' # directory\n")
    elif line.startswith("LLVM_ROOT"):
        llvm_root_path = os.path.join(prefix, "bin")
        out_lines.append(f"LLVM_ROOT = '{llvm_root_path}'\n")

        # For cross-compilation, also explicitly verify the clang binary exists and is correct
        if is_cross_compiling:
            clang_path = os.path.join(llvm_root_path, "clang")
            if os.path.exists(clang_path):
                print(f"Verified clang exists at: {clang_path}")
                try:
                    import subprocess
                    result = subprocess.run(
                        ["file", clang_path], capture_output=True, text=True
                    )
                    print(f"Clang binary info: {result.stdout.strip()}")
                except Exception as e:
                    print(f"Could not check clang binary: {e}")
            else:
                print(f"WARNING: clang not found at expected path: {clang_path}")
    else:
        out_lines.append(line)

print("Writing out .emscripten config file\n")
print("".join(out_lines) + "\n")

with open(path, "w") as fo:
    fo.write("".join(out_lines))
