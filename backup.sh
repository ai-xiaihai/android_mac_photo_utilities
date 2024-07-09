#!/bin/bash

# Make sure adb is connected to a device
if ! adb get-state 1>/dev/null 2>&1; then
    echo "No device is connected. Please connect a device and try again."
    exit 1
fi

#  Default values
ENDDATE=$(date +%Y-%m-%d)
STARTDATE=$(date -v -1m +%Y-%m-%d)
ORIGIN="/sdcard"
DESTINATION="."

# Function to display usage
usage() {
    echo "Usage: $0 [-s STARTDATE] [-e ENDDATE] [-o ORIGIN] [-d DESTINATION]"
    echo "  -s STARTDATE      Start date for file selection (default: one month ago)"
    echo "  -e ENDDATE        End date for file selection (default: today)"
    echo "  -o ORIGIN         Origin directory (default: $ORIGIN)"
    echo "  -d DESTINATION    Destination directory (default: current directory)"
    exit 1
}

# Parse command line options
while getopts ":s:e:o:d:" opt; do
    case $opt in
        s) STARTDATE="$OPTARG" ;;
        e) ENDDATE="$OPTARG" ;;
        o) ORIGIN="$OPTARG" ;;
        d) DESTINATION="$OPTARG" ;;
        *) usage ;;
    esac
done

# Folders to backup
FOLDERS=("Download"
         "Pictures"
         "Movies"
         "DCIM")

# Backing up photos and videos
for folder in "${FOLDERS[@]}"; do
    mkdir -p "$DESTINATION/$folder"
    adb shell "find $ORIGIN/$folder -type f -not -path '*/.thumbnails*' -not -path '*/.trashed*' -newermt $STARTDATE ! -newermt $ENDDATE" | while IFS= read -r file_path; do
        adb pull "$file_path" "$DESTINATION/$folder"
    done
done
