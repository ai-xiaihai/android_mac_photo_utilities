#!/bin/bash

# ==========================================
# DEFAULTS
# ==========================================
HARDDRIVE_DIR="/Volumes/foto"
PHONE_DIR="sdcard/DCIM/"

# ==========================================
# USAGE FUNCTION
# ==========================================
usage() {
    echo "Usage: cat list.txt | $0 [-d <harddrive_dir>] [-p <phone_dir>]"
    echo ""
    echo "Reads filenames from standard input (one per line)."
    echo ""
    echo "Options:"
    echo "  -d    Hard drive base path (Default: $HARDDRIVE_DIR)"
    echo "  -p    Phone base path (Default: $PHONE_DIR)"
    echo ""
    echo "Example:"
    echo "  ls *.jpg | $0 -p /sdcard/DCIM/Camera"
    echo "  grep \"2024\" photos.txt | $0"
    exit 1
}

# ==========================================
# PARSE COMMAND LINE FLAGS
# ==========================================
while getopts "d:p:h" opt; do
    case "$opt" in
        d) HARDDRIVE_DIR="$OPTARG" ;;
        p) PHONE_DIR="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# ==========================================
# MAIN LOGIC
# ==========================================

# Check if stdin is a terminal (meaning no data was piped in)
if [ -t 0 ]; then
    echo "Error: No input detected on stdin."
    usage
fi

# Read from stdin line by line
while IFS= read -r filename || [ -n "$filename" ]; do
    # Skip empty lines
    if [ -z "$filename" ]; then
        continue
    fi

    # 1. Check within HARDDRIVE file path
    hd_results=$(find "$HARDDRIVE_DIR" -name "$filename" 2>/dev/null)
    
    if [ -z "$hd_results" ]; then
        hd_count=0
    else
        hd_count=$(echo "$hd_results" | wc -l)
    fi

    # If exactly one file is found on the Hard Drive
    if [ "$hd_count" -eq 1 ]; then
        
        # 2. Check within PHONE file path via ADB
        # tr -d '\r' removes Windows-style line endings from ADB output
        phone_results=$(adb shell "find \"$PHONE_DIR\" -name \"$filename\" 2>/dev/null" | tr -d '\r')

        if [ -z "$phone_results" ]; then
            phone_count=0
        else
            phone_count=$(echo "$phone_results" | wc -l)
        fi

        # If exactly one file is found on the Phone
        if [ "$phone_count" -eq 1 ]; then
            
            # 3. Remove the exact file path found on the phone
            adb shell "rm \"$phone_results\""
            
            echo "$filename  |  HD: Found (1)  |  PHONE: Found & Removed"
        
        else
            echo "$filename  |  HD: Found (1)  |  PHONE: Skipped ($phone_count matches)"
        fi

    else
        echo "$filename  |  HD: Skipped ($hd_count matches)  |  PHONE: Skipped (Not searched)"
    fi

done
