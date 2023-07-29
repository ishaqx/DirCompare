#!/bin/bash

# Function to display the help menu
display_help() {
  echo "Usage: $0 [OPTIONS]"
  echo "Compare the contents of two directories and show if files/directories exist or not in the second directory."
  echo ""
  echo "Options:"
  echo "  -h, --help          : Display this help menu."
  echo "  -d, --depth <depth> : The depth to check for existence. A depth of 1 means only immediate contents, 2 includes subdirectories, and so on. Default is 1."
  echo "  -i, --case-insensitive : Perform case-insensitive comparisons."
  echo "  -x, --exclude <item>   : Exclude a specific file/directory from the comparison. Can be used multiple times."
  echo "  -l, --log <logfile>    : Log output to a specified file."
  echo "  -p, --parallel         : Use parallel processing for faster comparison (requires 'parallel' command)."
  echo "  -c, --colorize         : Colorize the output."
  echo "  -y, --yes              : Skip confirmation and proceed with the comparison."
  echo ""
  echo "Example:"
  echo "  $0 --depth 2 --exclude 'temp' --colorize /path/to/dir1 /path/to/dir2"
  echo "  This will compare the contents of dir1 and dir2 up to a depth of 2, exclude 'temp', and colorize the output."
}

# Function to perform the comparison and check existence
perform_comparison() {
  local dir1="$1"
  local dir2="$2"
  local depth="$3"
  local case_insensitive="$4"
  local exclude_items=("${@:5}")

  # Initialize variables to count the number of directories and files found/not found
  dirs_found=0
  dirs_not_found=0
  files_found=0
  files_not_found=0

  # Function to check if a file/dir exists in dir2 and print the result
  check_existence() {
    local item_name="$1"
    local found=false
    local options=()
    if [ "$case_insensitive" == "true" ]; then
      options+=(-iname)
    else
      options+=(-name)
    fi

    for excluded_item in "${exclude_items[@]}"; do
      if [[ "$item_name" == "$excluded_item" ]]; then
        found=true
        break
      fi
    done

    if ! "$found" && [ -e "$dir2/$item_name" ]; then
      if [ -f "$dir2/$item_name" ]; then
        echo "File exists: $dir2/$item_name"
        ((files_found++))
      elif [ -d "$dir2/$item_name" ]; then
        echo "Directory exists: $dir2/$item_name"
        ((dirs_found++))
      fi
    elif ! "$found" && [ ! -e "$dir2/$item_name" ]; then
      if [ -f "$dir1/$item_name" ]; then
        echo "File not found: $dir2/$item_name"
        ((files_not_found++))
      elif [ -d "$dir1/$item_name" ]; then
        echo "Directory not found: $dir2/$item_name"
        ((dirs_not_found++))
      fi
    fi
  }

  # Function to recursively check the contents of directories up to a specified depth
  check_contents_with_depth() {
    local current_dir="$1"
    local current_depth="$2"
    if [ "$current_depth" -le 0 ]; then
      return
    fi

    for item in "$current_dir"/*; do
      # Extract the base name of the item (file/directory name)
      item_name=$(basename "$item")

      # Check if the item exists in dir2 and print the result
      check_existence "$item_name"

      # If the item is a directory, recursively check its contents with reduced depth
      if [ -d "$item" ]; then
        check_contents_with_depth "$item" "$((current_depth - 1))"
      fi
    done
  }

  # Start by checking the contents of dir1 (including subdirectories up to the specified depth)
  check_contents_with_depth "$dir1" "$depth"

  # Display the summary
  echo ""
  echo "Summary:"
  echo "Directories found: $dirs_found"
  echo "Directories not found: $dirs_not_found"
  echo "Files found: $files_found"
  echo "Files not found: $files_not_found"
}

# Initialize variables with default values
depth=1
case_insensitive="false"
exclude_items=()
colorize="false"
logfile=""
parallel="false"
yes_to_all="false"

# Parse command-line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      display_help
      exit 0
      ;;
    -d|--depth)
      depth="$2"
      shift 2
      ;;
    -i|--case-insensitive)
      case_insensitive="true"
      shift
      ;;
    -x|--exclude)
      exclude_items+=("$2")
      shift 2
      ;;
    -l|--log)
      logfile="$2"
      shift 2
      ;;
    -p|--parallel)
      parallel="true"
      shift
      ;;
    -c|--colorize)
      colorize="true"
      shift
      ;;
    -y|--yes)
      yes_to_all="true"
      shift
      ;;
    *)
      break
      ;;
  esac
done

# Check if at least two directory paths are provided as arguments
if [ $# -lt 2 ]; then
  echo "Error: Invalid number of arguments."
  display_help
  exit 1
fi

dir1="$1"
dir2="$2"

# Check if both paths are valid directories
if [ ! -d "$dir1" ]; then
  echo "Error: Directory '$dir1' not found."
  exit 1
fi

if [ ! -d "$dir2" ]; then
  echo "Error: Directory '$dir2' not found."
  exit 1
fi

# Confirm before proceeding with the comparison unless -y option is provided
if [ "$yes_to_all" == "false" ]; then
  echo "You are about to compare the contents of:"
  echo "  $dir1"
  echo "  $dir2"
  echo "Are you sure you want to proceed? (y/n)"
  read -r confirmation
  if [[ "$confirmation" != [Yy] ]]; then
    echo "Comparison aborted."
    exit 0
  fi
fi

# Check if 'parallel' command is available when parallel option is used
if [ "$parallel" == "true" ] && ! command -v parallel &> /dev/null; then
  echo "Error: 'parallel' command is not installed. Please install 'parallel' or run the script without the parallel option."
  exit 1
fi

# Perform the comparison
if [ "$parallel" == "true" ]; then
  find "$dir1" -maxdepth "$depth" -print0 | parallel -0 perform_comparison {} "$dir2" "$depth" "$case_insensitive" "${exclude_items[@]}"
else
  perform_comparison "$dir1" "$dir2" "$depth" "$case_insensitive" "${exclude_items[@]}"
fi

exit 0
