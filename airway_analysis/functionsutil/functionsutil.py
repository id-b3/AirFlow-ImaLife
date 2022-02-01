from typing import List, Tuple, Dict, Union, Any
import glob
import pickle
import os
import re
import shutil
import sys


def currentdir() -> str:
    return os.getcwd()


def makedir(dirname: str) -> bool:
    dirname = dirname.strip().rstrip("\\")
    if not is_exist_dir(dirname):
        os.makedirs(dirname)
        return True
    else:
        return False


def makelink(src_file: str, dest_link: str) -> None:
    os.symlink(src_file, dest_link)


def get_link_realpath(pathname: str) -> str:
    return os.path.realpath(pathname)


def copydir(src_dir: str, dest_dir: str) -> None:
    shutil.copyfile(src_dir, dest_dir)


def copyfile(src_file: str, dest_file: str) -> None:
    shutil.copyfile(src_file, dest_file)


def movedir(src_dir: str, dest_dir: str) -> None:
    os.rename(src_dir, dest_dir)


def movefile(src_file: str, dest_file: str) -> None:
    os.rename(src_file, dest_file)


def removedir(dirname: str) -> None:
    os.rmdir(dirname)


def removefile(filename: str) -> None:
    os.remove(filename)


def set_dirname_suffix(dirname: str, suffix: str) -> str:
    if dirname.endswith("/"):
        dirname = dirname[:-1]
    return "_".join([dirname, suffix])


def set_filename_suffix(filename: str, suffix: str) -> str:
    filename_noext, extension = split_filename_extension_recursive(filename)
    return "_".join([filename_noext, suffix]) + extension


def split_filename_extension(filename: str) -> Tuple[str, str]:
    return os.path.splitext(filename)


def split_filename_extension_recursive(filename: str) -> Tuple[str, str]:
    # accounts for extension that are compound: i.e. '.nii.gz'
    filename_noext, extension = os.path.splitext(filename)
    if extension == "":
        return (filename_noext, extension)
    else:
        sub_filename_noext, sub_extension = split_filename_extension_recursive(
            filename_noext
        )
        return (sub_filename_noext, sub_extension + extension)


def is_exist_dir(dirname: str) -> bool:
    return os.path.exists(dirname) and os.path.isdir(dirname)


def is_exist_file(filename: str) -> bool:
    return os.path.exists(filename) and os.path.isfile(filename)


def is_exist_link(filename: str) -> bool:
    return os.path.exists(filename) and os.path.islink(filename)


def is_exist_exec(execname: str) -> bool:
    return (
        os.path.exists(execname)
        and os.path.isfile(execname)
        and os.access(execname, os.X_OK)
    )


def join_path_names(pathname_1: str, pathname_2: str) -> str:
    return os.path.join(pathname_1, pathname_2)


def basename(pathname: str) -> str:
    return os.path.basename(pathname)


def basenamedir(pathname: str) -> str:
    if pathname.endswith("/"):
        pathname = pathname[:-1]
    return basename(pathname)


def dirname(pathname: str) -> str:
    return os.path.dirname(pathname)


def dirnamedir(pathname: str) -> str:
    if pathname.endswith("/"):
        pathname = pathname[:-1]
    return dirname(pathname)


def fullpathname(pathname: str) -> str:
    return join_path_names(currentdir(), pathname)


def filename_noext(filename: str, is_split_recursive: bool = True) -> str:
    if is_split_recursive:
        return split_filename_extension_recursive(filename)[0]
    else:
        return split_filename_extension(filename)[0]


def fileextension(filename: str, is_split_recursive: bool = True) -> str:
    if is_split_recursive:
        return split_filename_extension_recursive(filename)[1]
    else:
        return split_filename_extension(filename)[1]


def basename_filenoext(filename: str, is_split_recursive: bool = True) -> str:
    return filename_noext(basename(filename), is_split_recursive)


def list_files_dir(
    dirname: str, filename_pattern: str = "*", is_check: bool = True
) -> List[str]:
    listfiles = sorted(glob.glob(join_path_names(dirname, filename_pattern)))
    if is_check:
        if len(listfiles) == 0:
            message = "No files found in '%s' with '%s'" % (dirname, filename_pattern)
            handle_error_message(message)
    return listfiles


def list_dirs_dir(
    dirname: str, dirname_pattern: str = "*", is_check: bool = True
) -> List[str]:
    return list_files_dir(dirname, dirname_pattern, is_check=is_check)


def list_files_dir_old(dirname: str) -> List[str]:
    listfiles = os.listdir(dirname)
    return [join_path_names(dirname, file) for file in listfiles]


def list_links_dir(dirname: str) -> List[str]:
    listfiles = list_files_dir_old(dirname)
    return [file for file in listfiles if os.path.islink(file)]


def get_substring_filename(filename: str, pattern_search: str) -> Union[str, None]:
    sre_substring_filename = re.search(pattern_search, filename)
    if sre_substring_filename:
        return sre_substring_filename.group(0)
    else:
        return None


def handle_error_message(message: str) -> None:
    print("ERROR: %s... EXIT" % (message))
    sys.exit(0)


def read_dictionary(filename: str) -> Dict[str, Any]:
    with open(filename, "rb") as fin:
        return pickle.load(fin)


def save_dictionary(filename: str, in_dictionary: Dict[str, Any]) -> None:
    with open(filename, "wb") as fout:
        pickle.dump(in_dictionary, fout, pickle.HIGHEST_PROTOCOL)
