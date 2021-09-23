#!/bin/bash

PrintUsage() {
    printf "Usage:
    -t VALUE   target to build, [VALUE] is file or dir
    -o VALUE   output dir, [VALUE] is output dir
    -h         this help
"
}

PatchFile() {
    local target="$1"
    local output_dir="$2"

    fontforge -script font-patcher -out "$output_dir" -s -c -w "$target"
}

PatchDir() {
    local target="$1"
    local output_dir="$2"

    # For bash 4.x, must not be in posix mode, may use temporary files
    mapfile -t ttf_files_separated_by_enter < <(find "$target" -type f -name "*.ttf")
    mapfile -t otf_files_separated_by_enter < <(find "$target" -type f -name "*.otf")

    for each_file in "${ttf_files_separated_by_enter[@]}"; do
        PatchFile "$each_file" "$output_dir"
    done

    for each_file in "${otf_files_separated_by_enter[@]}"; do
        PatchFile "$each_file" "$output_dir"
    done
}

InstallDepends() {
    local depends="fontforge"

    local arr=("$depends")
    for package in "${arr[@]}"; do
        if dpkg -s "$package" >/dev/null 2>&1; then
            continue # package already installed
        fi

        echo "Installing $package, please input sudo password"
        sudo apt -y install "$package"
    done
}

Main() {
    local target="$1"
    local output_dir="$2"

    InstallDepends

    if [ ! -e "$target" ]; then
        echo "$target: No such file or directory"
        exit 1
    fi

    if [ -z "$output_dir" ]; then
        output_dir="./"
    else
        if [ ! -d "$output_dir" ]; then
            mkdir -p "$output_dir"
        fi
    fi

    if [ -f "$target" ]; then
        PatchFile "$target" "$output_dir"
    else
        PatchDir "$target" "$output_dir"
    fi
}

while getopts "t:o:h" arg; do
    case $arg in
        t)
            g_target=$OPTARG
            ;;
        o)
            g_output_dir=$OPTARG
            ;;
        h)
            PrintUsage
            exit 0
            ;;
        *)
            PrintUsage
            exit 1
            ;;
    esac
done

if [ -z "$g_target" ]; then
    PrintUsage
    exit 1
fi

Main "$g_target" "$g_output_dir"

