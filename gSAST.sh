#!/bin/bash

red="\033[1;31m"
green="\033[1;32m"
blue="\033[1;36m"
yellow="\033[1;33m"
reset="\033[0m"

version="1.0"
working_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

context=0
pattern_dir="$working_dir/patterns"
excluded_dirs="--exclude-dir=.git --exclude-dir=node_modules"
excluded_files="--exclude=*.txt --exclude=*.jpg --exclude=*.png --exclude=*.svg --exclude=*.ico"

checkRequirements(){
	if [ ! -x "$(which grep)" ]; then
    	echo -e "${red}[-] 'grep' not found!${reset}"
    	exit 2
	fi
}

printBanner(){
	echo -e "${yellow}
           _________   _____    ____________________
     ____ /   _____/  /  _  \  /   _____/\__    ___/
    / ___\\_____  \  /  /_\  \ \_____  \   |    |   
   / /_/  >        \/    |    \/        \  |    |   
   \___  /_______  /\____|__  /_______  /  |____|   
  /_____/        \/         \/        \/            

       Grep Static Analysis Security Tool v"$version"
            by Gustavo Bonito (@gBon1to)
	${reset}"
}

checkVersion(){
    echo -e "${green}\n[+] gSAST version: $version\n${reset}"
}

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

checkArgs(){
	while getopts "l:i:x:cn:vh" opt; do
	    case $opt in
	        l)
				lang="$OPTARG"
	            checkLanguage
	        ;;
			i)
				OIFS=$IFS
	            IFS=','
	            excluded_files=""
	            for inc_pattern in "$OPTARG"; do
	                included_files="--include=$inc_pattern"
	            done
	            IFS=$OIFS
	        ;;
			x)
	            OIFS=$IFS
	            IFS=','
	            for exc_pattern in "$OPTARG"; do
	                excluded_files="$excluded_files --exclude=$exc_pattern"
	            done
	            IFS=$OIFS
	        ;;
			c)
	            case_ins="-i"
	        ;;
			n)
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
	shift $((OPTIND-1))
	
    if [ $# -ne 1 ]; then
	    printUsage
	    exit 1
	fi
}

checkRequirements
printBanner
checkArgs "$@"
for pattern_file in $pattern_dir/*.rules; do
	if [[ -f "$pattern_file" && -s "$pattern_file" ]]; then
		echo -e "${blue}\n[*] Grepping with $pattern_file${reset}"
		grep --no-group-separator \
			--color=always \
			$excluded_dirs \
			$excluded_files \
			$included_files \
			$case_ins \
			-n -R -H -C "$context" -E \
			-f "$pattern_file" "${@: -1}"
	fi
done
exit $?