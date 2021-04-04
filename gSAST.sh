#!/bin/bash

# Set ANSI color codes
red="\033[1;31m"
green="\033[1;32m"
blue="\033[1;36m"
yellow="\033[1;33m"
reset="\033[0m"

version="1.1"
# Sets "gSAST.sh" location as the working directory
working_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# Set default values
context=0
pattern_dir="$working_dir/patterns"
included_files=""
# Automatically exclude ".git" and "node_modules" directories from the gSAST search
excluded_dirs="--exclude-dir=.git --exclude-dir=node_modules"
# Automatically exclude image and text files from the gSAST search
excluded_files="--exclude=*.txt --exclude=*.jpg --exclude=*.png --exclude=*.svg --exclude=*.ico"

# Check if "grep" is installed
checkRequirements(){
	if [ ! -x "$(which grep)" ]; then
    	echo -e "${red}[-] 'grep' not found!${reset}"
    	exit 2
	fi
}

# Print gSAST banner and gets the version from the global variable "version"
printBanner(){
	echo -e "${yellow}
           _________   _____    ____________________
     ____ /   _____/  /  _  \  /   _____/\__    ___/
    / ___\\_____  \  /  /_\  \ \_____  \   |    |   
   / /_/  >        \/    |    \/        \  |    |   
   \___  /_______  /\____|__  /_______  /  |____|   
  /_____/        \/         \/        \/            

       Grep Static Analysis Security Tool v"$version"
            by Gustavo Bonito (@gBon1to)${reset}"
}

checkVersion(){
    echo -e "${green}\n[+] gSAST version: $version\n${reset}"
}

# Prints the help menu based on the "checkArgs()" function flags
printUsage(){
	echo -e "${blue}
Options:
  -l Language of the source code (php, javascript, java, php, python, dotnet)
  -i Include only these files (-i *.php,*.js)
  -x Exclude these files (-x *.txt,*.svg)
  -c Case in-sensitive grepping
  -n Number of lines to display
  -v Prints version
  -h Prints help

${green}Usage: ./gSAST.sh [options] /path/\n${reset}"
}

# Choose patterns to use based on the selected source code language
checkLanguage(){
	case $lang in
		"php")
			pattern_dir="$working_dir/patterns/php"
		;;
		"javascript")
			pattern_dir="$working_dir/patterns/javascript"
		;;
		"java")
			pattern_dir="$working_dir/patterns/java"
		;;
		"python")
			pattern_dir="$working_dir/patterns/python"
		;;
		"dotnet")
			pattern_dir="$working_dir/patterns/dotnet"
		;;
	esac
}

# Checks arguments passed to gSAST using getopts
checkArgs(){
	while getopts "l:i:x:cn:vh" opt; do # If the flag is followed by ":", requires additional arguments
	    case $opt in
	        l)
				lang="$OPTARG"
				# Call the "checkLanguage()" function to set patterns path
	            checkLanguage
	        ;;
			i)
				# Include files based on user patterns (ex. *.php,*.js)
				OIFS=$IFS
	            IFS=',' # Pattern separator used
	            excluded_files=""
				# Loops all inserted patterns and appends "--include=" to each pattern (ex. --include=*.php)
	            for inc_pattern in ${OPTARG[@]}; do
	                included_files="$included_files --include=$inc_pattern"
	            done
	            IFS=$OIFS # Reverts the field separator to the default value
				set +f # Enable file globbing
	        ;;
			x)
				# Exclude files based on user patterns (ex. *.php,*.js)
	            OIFS=$IFS
	            IFS=',' # Pattern separator used
				# Loops all inserted patterns and appends "--exclude=" to each pattern (ex. --exclude=*.php)
	            for exc_pattern in ${OPTARG[@]}; do
	                excluded_files="$excluded_files --exclude=$exc_pattern"
	            done
	            IFS=$OIFS # Reverts the field separator to the default value
				set +f # Enable file globbing
	        ;;
			c)
				# Uses "grep -i" for case-insensitive search
	            case_ins="-i"
	        ;;
			n)
				# Uses "grep -C" for context lines
	            context="$OPTARG"
	        ;;
			v)
	            checkVersion
	            exit 0
	        ;;
	        h)
	            printUsage
	            exit 0
	        ;;
	    esac
	done
	shift "$((OPTIND-1))" # Skip the options set by getopts (ex. -l)
	
	# Accept files or directories from stdin or as parameter
	if [ $# -ge 1 ]; then
		input="${@: -1}"
	elif [[ -p /dev/stdin ]]; then
		input="$(cat - )"
	else # If no source code file or directory is specified, print the help menu
	    printUsage
	    exit 1
	fi
}

set -f # Disables file globbing for looping "*.rules" files
checkRequirements
printBanner
checkArgs $@ # Passes all arguments as a list
# Loops all pattern files and uses them for searching
for pattern_file in $pattern_dir/*.rules; do
	# Checks if pattern file exists and is not empty
	if [[ -f $pattern_file && -s $pattern_file ]]; then
		echo -e "${blue}\n[*] Grepping with $pattern_file${reset}"
		# Searches the source code recursively (-R) and includes line numbers (-n) and filenames (-H) by default
		grep --no-group-separator \
			--color=always \
			$excluded_dirs \
			$excluded_files \
			$included_files \
			$case_ins \
			-n -R -H -C $context -E \
			-f $pattern_file $input | sort -u # Print sorted distinct results
			# | awk -F  ":" '{print $1}' - Can be used to print only filenames
	fi
done
exit $?