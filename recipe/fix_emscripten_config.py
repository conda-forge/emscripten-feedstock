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
build_prefix = os.environ.get("BUILD_PREFIX", "")

print(f"Cross-compilation detected: {is_cross_compiling}")
print(f"Build platform: {build_platform}, Target platform: {target_platform}")
print(f"Build prefix: {build_prefix}")

out_lines = ["import os"]
for line in lines:
    if line.startswith("BINARYEN_ROOT"):
        p = prefix.replace("\\", "/")
        out_lines.append(
            "BINARYEN_ROOT = os.path.expanduser(os.getenv('BINARYEN', '{}')) # directory\n".format(
                p
            )
        )
    elif line.startswith("LLVM_ROOT"):
        # For cross-compilation, use build platform's LLVM tools, not target platform's
        if is_cross_compiling and build_prefix:
            p = os.path.join(build_prefix, "bin").replace("\\", "/")
            print(f"Cross-compilation: Using build platform LLVM tools from {p}")
        else:
            p = os.path.join(prefix, "bin").replace("\\", "/")
            print(f"Native build: Using target platform LLVM tools from {p}")

        out_lines.append(
            "LLVM_ROOT = os.path.expanduser(os.getenv('LLVM', '{}'))\n".format(p)
        )

        # Verify the clang binary exists
        test_clang_path = p.replace("$BUILD_PREFIX", build_prefix).replace(
            "$PREFIX", prefix
        )
        clang_path = os.path.join(test_clang_path, "clang")
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
