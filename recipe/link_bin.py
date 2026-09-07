import glob
import os

pkg_version = os.environ['PKG_VERSION']
root_dir = os.path.join('lib', 'emscripten-' + pkg_version)

win_template = """
@echo off
python {pyfile} %*
"""


def ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def relink(dest_file, src_file):
    if os.path.lexists(dest_file):
        return
    rel_src = os.path.relpath(src_file, os.path.dirname(dest_file))
    os.symlink(rel_src, dest_file)

if os.name == 'nt':
    prefix = os.environ['LIBRARY_PREFIX']
    bindir = os.path.join(prefix, 'bin')
    ensure_dir(bindir)
    for f in glob.glob(os.path.join(prefix, root_dir, '*.py')):
        # get binary
        bin_name = f[:-3] + '.bat'  # cut .py
        print("Linking up ", bin_name)
        if os.path.exists(bin_name):
            fname = os.path.basename(bin_name)
            dest_file = os.path.join(bindir, fname)
            with open(dest_file, 'w') as fo:
                fo.write(win_template.format(pyfile=f))
else:
    prefix = os.environ['PREFIX']
    bindir = os.path.join(prefix, 'bin')
    ensure_dir(bindir)
    for f in glob.glob(os.path.join(prefix, root_dir, '*.py')):
        # get binary
        bin_name = f[:-3]  # cut .py
        print("Linking up ", bin_name)
        fname = os.path.basename(bin_name)
        dest_file = os.path.join(bindir, fname)
        if os.path.exists(bin_name):
            relink(dest_file, bin_name)
        else:
            relink(dest_file, f)

        # fix FileNotFoundError: [Errno 2] No such file or directory: 'lib/emscripten-4.0.*/emar'
        if not os.path.exists(bin_name):
            relink(bin_name, f)
