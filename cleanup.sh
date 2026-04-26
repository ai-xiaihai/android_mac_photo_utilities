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
    echo "Options:"
    echo "  -d    Hard drive base path (Default: $HARDDRIVE_DIR)"
    echo "  -p    Phone base path (Default: $PHONE_DIR)"
    exit 1
}

while getopts "d:p:h" opt; do
    case "$opt" in
        d) HARDDRIVE_DIR="$OPTARG" ;;
        p) PHONE_DIR="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [ -t 0 ]; then
    echo "Error: No input detected on stdin."
    usage
fi

while IFS= read -r filename || [ -n "$filename" ]; do
    # Strip carriage returns from the input line itself just in case
    filename=$(echo "$filename" | tr -d '\r')
    
    if [ -z "$filename" ]; then
        continue
    fi

    # 1. Check HARDDRIVE
    hd_results=$(find "$HARDDRIVE_DIR" -name "$filename" 2>/dev/null)
    
    if [ -z "$hd_results" ]; then
        hd_count=0
    else
        hd_count=$(echo "$hd_results" | wc -l)
    fi

    if [ "$hd_count" -eq 1 ]; then
        
        # 2. Check PHONE 
        # FIX: Added -n to adb shell to prevent it from reading from stdin
        phone_results=$(adb shell -n "find \"$PHONE_DIR\" -name \"$filename\" 2>/dev/null" | tr -d '\r')

        if [ -z "$phone_results" ]; then
            phone_count=0
        else
            phone_count=$(echo "$phone_results" | wc -l)
        fi

        if [ "$phone_count" -eq 1 ]; then
            # 3. Remove from PHONE
            # FIX: Added -n here as well
            adb shell -n "rm \"$phone_results\""
            echo "$filename  |  HD: Found (1)  |  PHONE: Found & Removed"
        else
            echo "$filename  |  HD: Found (1)  |  PHONE: Skipped ($phone_count matches)"
        fi
    else
        echo "$filename  |  HD: Skipped ($hd_count matches)  |  PHONE: Skipped (Not searched)"
    fi

done