#!/bin/bash

# ==========================================
# DEFAULTS
# ==========================================
HARDDRIVE_DIR="/Volumes/foto"
# Default phone directories as a proper Bash array
PHONE_SEARCH_DIRS=("sdcard/Download" "sdcard/Pictures" "sdcard/Movies" "sdcard/DCIM")

# ==========================================
# USAGE FUNCTION
# ==========================================
usage() {
    echo "Usage: cat list.txt | $0 [-d <harddrive_dir>] [-p <phone_dir1> -p <phone_dir2>]"
    echo ""
    echo "Options:"
    echo "  -d    Hard drive base path (Default: $HARDDRIVE_DIR)"
    echo "  -p    Phone base path. Can be used multiple times."
    echo "        (Defaults: ${PHONE_SEARCH_DIRS[*]})"
    exit 1
}

# ==========================================
# PARSE COMMAND LINE FLAGS
# ==========================================
# Reset array if user provides any -p flags
user_provided_p=false

while getopts "d:p:h" opt; do
    case "$opt" in
        d) HARDDRIVE_DIR="$OPTARG" ;;
        p) 
            if [ "$user_provided_p" = false ]; then
                PHONE_SEARCH_DIRS=() # Clear defaults on first -p flag
                user_provided_p=true
            fi
            PHONE_SEARCH_DIRS+=("$OPTARG") 
            ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [ -t 0 ]; then
    echo "Error: No input detected on stdin."
    usage
fi

# ==========================================
# MAIN LOGIC
# ==========================================
while IFS= read -r filename || [ -n "$filename" ]; do
    # Remove carriage returns (common in ADB/Windows sourced lists)
    filename=$(echo "$filename" | tr -d '\r')
    [ -z "$filename" ] && continue

    # 1. Check HARDDRIVE
    # We use -print0 and read to handle filenames with spaces/newlines safely
    hd_results=""
    while IFS= read -r -d '' line; do
        hd_results+="$line"$'\n'
    done < <(find "$HARDDRIVE_DIR" -name "$filename" -print0 2>/dev/null)
    
    hd_count=$(echo -n "$hd_results" | grep -c . )

    if [ "$hd_count" -eq 1 ]; then
        hd_path=$(echo "$hd_results" | xargs) # Clean up whitespace

        # 2. Check PHONE
        combined_phone_results=""
        
        for dir in "${PHONE_SEARCH_DIRS[@]}"; do
            # Search in each directory. 
            # We quote the remote find command and the filename variable heavily.
            res=$(adb shell -n "find \"$dir\" -name \"$filename\" 2>/dev/null" | tr -d '\r')
            if [ -n "$res" ]; then
                combined_phone_results+="$res"$'\n'
            fi
        done

        # Clean up the results list
        combined_phone_results=$(echo "$combined_phone_results" | sed '/^$/d')
        phone_count=$(echo "$combined_phone_results" | grep -c . )

        if [ "$phone_count" -eq 1 ]; then
            # 3. Remove from PHONE
            # We wrap $combined_phone_results in escaped quotes for the remote shell
            adb shell -n "rm \"$combined_phone_results\""
            echo "OK: $filename | HD: Found 1 | PHONE: Removed from $combined_phone_results"
        
        elif [ "$phone_count" -gt 1 ]; then
            echo "SKIP: $filename | HD: Found 1 | PHONE: Multiple matches ($phone_count)"
        else
            echo "SKIP: $filename | HD: Found 1 | PHONE: Not found"
        fi
    else
        echo "SKIP: $filename | HD: Found $hd_count | PHONE: Not searched"
    fi

done