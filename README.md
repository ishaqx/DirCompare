# DirCompare
A bash shell script to compare directories for missing files and directories.  

```
Usage: ./dircomp.sh [OPTIONS]

Compare the contents of two directories and show if files/directories exist or not in the second directory.

Options:

  -h, --help          : Display this help menu. 
  -d, --depth <depth> : The depth to check for existence. A depth of 1 means only immediate contents, 2 includes subdirectories, and so on. Default is 1.
  -i, --case-insensitive : Perform case-insensitive comparisons.
  -x, --exclude <item>   : Exclude a specific file/directory from the comparison. Can be used multiple times.
  -l, --log <logfile>    : Log output to a specified file.
  -p, --parallel         : Use parallel processing for faster comparison (requires 'parallel' command).
  -c, --colorize         : Colorize the output.
  -y, --yes              : Skip confirmation and proceed with the comparison.

```

Example:

  `./compare-directory-contents2.sh --depth 2 --exclude 'temp' --colorize /path/to/dir1 /path/to/dir2`
  
  This will compare the contents of dir1 and dir2 up to a depth of 2, exclude 'temp', and colorize the output.
