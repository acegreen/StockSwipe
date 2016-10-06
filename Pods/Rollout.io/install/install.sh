#!/bin/bash

export PATH=/usr/bin:/bin:"$PATH"
export LC_ALL=UTF-8

BIN_DIR="$(cd "$(dirname "$0")" && pwd )"
BASE_DIR="$(dirname "$BIN_DIR")"
PROJECT_DIR=$(dirname "$BASE_DIR")

unset help exit tweaker_before_linking include_swift
while getopts "hls" option; do #{{{
  case $option in
    h)
      help=1
      ;;
    l)
      tweaker_before_linking=1
      ;;
    s)
      include_swift="-s"
      ;;
    *)
      exit=1
      ;;
  esac
done #}}}
shift $(($OPTIND - 1))

[ -z "$help" ] || { #{{{
  cat << EOF
Usage:
$0 [<options>] <xcode_dir> <app_key>

  -l                     set tweaker script phase before the linking phase
  -h                     this help message
  -s                     Inlude swift support
EOF
  exit
} #}}}

xcode_dir="$1"
app_key=$2
include_swift=$3

[ -d "$xcode_dir" ] || { echo "Can't find xcode project dir ($xcode_dir)"; exit=1; }
[ -n "$app_key" ] || { echo "app_key is required"; exit=1; }

[ -z "$exit" ] || exit 1

[ -n "$include_swift" ] && "$BIN_DIR"/Installer "$xcode_dir" "$app_key" "$include_swift" || {
    "$BIN_DIR"/Installer "$xcode_dir" "$app_key"
}
