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
  echo "usage: $me [-e | --env]  [ -o | --output <File Path>] [ -v | --verbose] [ -f | --force] [-h | -help]"
  echo "    options:"
  echo "        -e | --env      (optional) flag to convert from env to json. "
  echo "                                   Leave out to convert from json to env. (default json to env)" 
  echo "        -o | --output   (optional) Output file. (default is local.settings.json for -e and .env for otherwise.)" 
  echo "        -i | --input    (optional) Input file. (default is .env for -e and local.settings.json for otherwise.)"  
  echo "        -f | --force    (optional) Skip prompting for existing file. (default: false)" 
  echo "        -v | --verbose  (optional) Show detailed output log (default: false)" 
  echo "        -h | --help     (optional) Show help text. This :) " 
  echo ""
  echo ""
  echo "    dependencies:"
  printf "        -jq "
  if [ -x "$(command -v jq)" ]; then
    printf "\e[32m(installed - you're good to go!)\e[0m"
  else
    printf "\e[31m(not installed)\e[0m"
  fi
  
  printf "\n            repo: https://github.com/stedolan/jq\f"  
}

################################################
#        Get Script Parameters
################################################
from_env=0
verbose=0
force=0
output_path=""
input_path=""
while [ "$1" != "" ]; do
    case $1 in
        -e | --env )            from_env=1
                                ;;
        -o | --output )         shift
                                output_path=$1
                                ;;
        -i | --input )          shift
                                input_path=$1
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

write_json_file () {
  path_read=$1
  path_create=$2
  header=""
  row=""
  count=0
  while read p; do
    key=$(echo $p| cut -d'=' -f 1)
    value=$(echo $p| cut -d'=' -f 2)
    value=$(sed -e 's/^"//' -e 's/"$//' <<<"$value")
    info "\"$key\" : \"$value\""
    header="${header}$key|"
    row="${row}$value|"
    print_dot
    count=$((count+1))        
  done <$path_read

  s="${header::-1}
  ${row::-1}"

  json=$(jq -Rn '
  ( input  | split("|") ) as $keys |
  ( inputs | split("|") ) as $vals |
  [[$keys, $vals] | transpose[] | {key:.[0],value:.[1]}] | from_entries
  ' <<<"$s")

  json_template='{"IsEncrypted": false,"Values": <--VALUES-->}'
  rendered_template="${json_template/<--VALUES-->/$json}" 
  echo $rendered_template | jq '.' > $path_create

  printf "\nProcessing complete! $count settings converted.\n"
  success "$(readlink -f $path_create) created.\n"  
}

################################################
#        Core Script Logic
################################################
convert_localsettings_to_env (){
  echo "******* Convert JSON to ENV *******"
  path_read='local.settings.json'
  if [[ !  -z  $input_path  ]]; then
    path_read=$input_path
    info "Custom input path provided. input will be from $path_read"
  fi

  path_create='.env'
  if [[ !  -z  $output_path  ]]; then
    path_create=$output_path
    info "Custom ouput path provided. output will be in $path_create"
  fi
  
  info "Converting $path_read to $path_create..."

  text=$(get_text $path_read)
  if [[ $(is_valid_json $text) -eq "0" ]]; then
    error "The contents of $path_read is not valid json!"
    exit -1
  fi
  if [[ $force -eq 1 ]]; then
    mv $path_create "$path_create.f.bak$now"
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
    #cleanup
    if [[ $force -eq 1 ]]; then
      rm "$path_create.f.bak$now"
    fi         
  fi
}

convert_env_to_localsettings(){
  echo "******* Convert ENV to JSON *******"
  path_read='.env'  
  if [[ !  -z  $input_path  ]]; then
    path_read=$input_path
    info "Custom input path provided. input will be from $path_read"
  fi

  path_create='local.settings.json'
  if [[ !  -z  $output_path  ]]; then
    path_create=$output_path
    info "Custom path provided. output will be in $path_create"
  fi
  
  info "Converting $path_read to $path_create..."  
  if [[ $force -eq 1 ]]; then
    mv $path_create "$path_create.f.bak$now"
  fi

  if test -f "$path_create" && [[ $force -eq 0 ]]; then
    read -r -p "WARNING! $path_create exists, overwrite? (y/n) " response
    
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
      #backup old file for the duration
      mv $path_create "$path_create.bak$now"

      write_json_file "$path_read" "$path_create"

      #cleanup
      rm "$path_create.bak$now"
    else
      error "Aborting! .env file was left as is. Please use -p to specify a different file."
    fi
  else
    write_json_file "$path_read" "$path_create"
    #cleanup
    if [[ $force -eq 1 ]]; then
      rm "$path_create.f.bak$now"
    fi         
  fi
}

################################################
#        Main
################################################
convert_settings_env () {
  if [[ $from_env -eq 1 ]]; then
    convert_env_to_localsettings
  else
    convert_localsettings_to_env 
  fi
}

convert_settings_env