#!/usr/bin/env bash

##########################################################################################################################################
#       Convert local.settings.json file to .env file and the other way around                                                           
#       This command will convert a local.settings.json file in the same folder to a .env file, and do the reverse action if specified.  
#        
#        parameter: -f | --fromenv
#                   Set to yes if you want an .env file to be converted into a local.settings.json file.
#        parameter: -p | --path
#                   The path of the folder containing the file to convert.    
##########################################################################################################################################

me=$0
now=$(date +'%m.%d.%Y')
usage(){
  echo "usage: $me [-e | --env]  [ -p | --path <File Path>] [ -v | --verbose] [ -f | --force] [-h | -help]"
  echo "    Options:"
  echo "        -e | --env      (optional) Set to 'no' (default) if you want to convert a local.settings.json file into a .env file, set to 'yes' if you want to do the opposite." 
  echo "        -p | --path     (optional) Path of the folder containing the file to convert (default: current folder)" 
  echo "        -f | --force    (optional) Skip prompting for existing file. (default: false)" 
  echo "        -v | --verbose  (optional) Show detailed output log (default: false)" 
  echo "        -h | --help     (optional) Show help text. This :) " 
  echo ""
}

################################################
#        Get Script Parameters
################################################
from_env=0
verbose=0
force=0
path="."
while [ "$1" != "" ]; do
    case $1 in
        -e | --env )            from_env=1
                                ;;
        -p | --path )           shift
                                path=$1
                                ;;
        -f | --force )          force=1
                                ;;
        -v | --verbose )        verbose=1
                                ;;
        -h | --help )           usage
                                exit
    esac
    shift
done

################################################
#        Helper Functions
################################################
info() {
  if [[ $verbose -eq 1 ]]; then
    echo -e "\e[33mINFO: $@\e[0m"
  fi
}

error() {
  echo -e "\e[31mERROR: $@\e[0m"
}

success() {
  printf "\e[32m$@\e[0m"
}

get_text() {
  echo $(cat $@)
}

print_dot() {
  if [[ $verbose -ne 1 ]]; then    
      printf "."
    fi
}

is_valid_json() {
  if jq -e . >/dev/null 2>&1 <<<"$@"; then
    echo 1
  else
    echo 0
  fi
}

write_env_file () {
  text=$1
  path_create=$2
  count=0
  for key in $(jq -r '.Values | keys | .[]' <<< "$text"); do
    value=$(jq -r ".Values[\"$key\"]" <<< "$text")
    info "$key = \"$value\""
    echo "$key=\"$value\"" >> "$path_create"
    print_dot
    count=$((count+1))
  done
  printf "\nProcessing complete! $count settings converted.\n"
  success "$(readlink -f $path_create) created.\n"
}

################################################
#        Core Script Logic
################################################
convert_localsettings_to_env (){
  info "Converting local.settings.json to .env..."
  path_read='local.settings.json'
  path_create='.env'
  if [[ !  -z  $path  ]]; then
    path_create=$path
    info "Custom path provided. output will be in $path_create"
  fi

  text=$(get_text $path_read)
  if [[ $(is_valid_json $text) -eq "0" ]]; then
    error "The contents of $path_read is not valid json!"
  fi
  if test -f "$path_create" && [[ $force -eq 0 ]]; then
    read -r -p "WARNING! $path_create exists, overwrite? (y/n) " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
      #backup old file for the duration
      mv $path_create "$path_create.bak$now"

      write_env_file "$text" "$path_create"

      #cleanup
      rm "$path_create.bak$now"
    else
      error "Aborting! .env file was left as is. Please use -p to specify a different file."
    fi
  else
    write_env_file "$text" "$path_create"
  fi
}

convert_env_to_localsettings(){
  info "Converting .env to local.settings.json..."
  path_read='.env'  
  path_create='local.settings.json'
}

################################################
#        Main
################################################
convert_settings_env () {
  echo "******* Convert JSON to ENV *******"
  if [[ $from_env -eq 1 ]]; then
    convert_env_to_localsettings
  else
    convert_localsettings_to_env 
  fi
}

convert_settings_env