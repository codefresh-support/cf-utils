# User-defined functions
# see at the bottom of the file for aliases

# Expects one argument to be tested against pattern. Returns true (0) if 
#  numeric or false (1) otherwise.
is_numeric() {
  n=$1
  #declare -n n=$1
  if [[ $n =~ ^[0-9]+$ ]]; then
    return 0      # true can be used in IF then
  fi
  return 1
}

# Perform an action on a directories in CDPATH
# 
# cdpath        print search directories
# cdpath zip    navigate to the directory in which file "zip" is
#               located
# cdpath vim zip    if passed more than one argument, treat first 
#                   argument as executable and all the others should
#                   searched prior in CDPATH
#
# If file was not found navigate to the directory of the files that mention the pattern
function cdpath() {

  declare -a files
  declare -a found

  #default action
  bin=cd

  if [ "$#" -gt 1 ]   # process found files through executable
  then 
    bin=$1
    shift
    while [[ $1 =~ ^- ]]
    do
      bin=$bin\ $1
      shift
    done
  fi
  action=$bin

  
  for file
  do echo "Processing pattern... '$file'..";

    paths=($(find -L ${CDPATH//:/ } -type f -not -path '*/.*' -and -name ${file} 2> /dev/null ))
        #find ${CDPATH//:/ } -type f -name ${file} 2> /dev/null) 
  
    echo "Found: ${paths[@]} (${#path[@]})"

    case ${#paths[@]} in

      [2-9]|[1-9][0-9]) 

        echo "Found more than one file in a CDPATH"

        PS3="Select files to process or 'all' (action: $action):   "
        select path in ${paths[@]}
        do
          if [ -n "${path}" ]     # selection was made
          then
            paths=( $path ) ; break    # set found[] to one element
          fi

          if [[ $REPLY =~ ^a(ll)?$ ]] || [ -n "${path}" ] 
          then  # if "all" paths[] is not modified 
            break     
          fi
        done    
        ;&
        
      1) 
        # add current files set corresponding to the 'file' pattern to
        # the files[] array
        files+=( ${paths[@]} )
        ;;

      0)
        # no files; nothing to add
        ;;

      *) echo "Something unexpected happened"
        ;;
     esac
  done 

  case $action in
    cd)
      test ${#files[@]} -eq 1 || { echo "Cannot naviagate multiple directories."; \ exit 2; } 
      files=( `dirname $files` )
    ;;
  esac

  # Finally run binary with all the flags
  #echo "${bin} ${files[@]}"
  ${bin} ${files[@]}
}


# Display files in CDPATH, for those who has absolute a relative
# paths specified visualise file existense.
function find_files_in_cdpath() {

  declare -a files
  declare -a paths

  for file
  do #echo "Processing pattern... '$file'..";

    # Search only for those files that are not relative or 
    # full path
    if ! [[ $file =~ \/ ]] 
    then
      paths=( $( find ${CDPATH//:/ } -type f -not -path '*/.*' -and -name ${file} 2> /dev/null ) )
    
      echo "Found: ${paths[@]}"

      case ${#paths[@]} in

        [2-9]|[1-9][0-9]) 

          echo "Found more than one file in a CDPATH"

          PS3="Select files to process or 'all':   "
          select path in ${paths[@]}
          do
            if [ -n "${path}" ]     # selection was made
            then
              paths=( $path ) ; break    # set found[] to one element
            fi

            if [[ $REPLY =~ ^a(ll)?$ ]] || [ -n "${path}" ] 
            then  # if "all" paths[] is not modified 
              break     
            fi
          done    
          ;&
          
        1) 
          # add current files set corresponding to the 'file' pattern to
          # the files[] array
          files+=( ${paths[@]} )
          ;;

        0)
          # no files; nothing to add! add anyway and then run function
          # visualisatino files existence
          ;;

        *) echo "Something unexpected happened"
          ;;
      esac
    #
    # Relative or full path to the file was passed, just add it to the global
    # array
    else
      files+=( file )
    fi
  done 
}

# Open file(s) found in CDPATH. If file was not found 
# create it.
function vim-in-cdpath() {
  
  declare -a files
  declare -a paths

  flags='-p'          # default flag when opening vim
  bin=`type -P vim`   # find path to vim executatble instead
                      # trigerring an alias again

  while [[ $1 =~ ^- ]]
  do
    flags=$flags\ $1
    shift
  done

  for file
  do 
  
    echo "Processing pattern... '$file'..";

    # Search only for those files that are not relative or 
    # full path
    if [[ ! $file =~ \/ && ! -e $file ]] 
    then

      paths=( $( find ${CDPATH//:/ } -type f -not -path '*/.*' -and -name ${file} 2> /dev/null ) )
    
      echo "Found: ${paths[@]}"

      case ${#paths[@]} in

        [2-9]|[1-9][0-9]) 

          #echo "Found more than one file in a CDPATH"

          PS3="Select files to process or 'all':   "
          select path in ${paths[@]}
          do
            if [ -n "${path}" ]     # selection was made
            then
              paths=( $path ) ; break    # set found[] to one element
            fi

            if [[ $REPLY =~ ^a(ll)?$ ]] || [ -n "${path}" ] 
            then  # if "all" paths[] is not modified 
              break     
            fi
          done    

            ;&
          
        1) 
          # add current files set corresponding to the 'file' pattern to
          # the files[] array
          files+=( ${paths[@]} )

            ;;

        0)
          # no files - create new file (simulating vim behavior)
          files+=( $file )

            ;;

        *) echo "Something unexpected happened"

            ;;
      esac
    #
    # Relative or full path to the file was passed, just add it to the global
    # array
    else
      files+=( $file )
    fi
  done 
  #echo ${bin} ${flags} ${files[@]}
  ${bin} ${flags} ${files[@]}
}

# Print "OK" or ":(" 
function mounted() {
  mount | grep -q "$1" && echo "OK" || echo ":("
}

# Search in files for a pattern and display found strings with file
# name. The idea is that function will accept a maxdepth, mindepth or both

function find_in_file() {
  test $1 || { echo "missing search string"; return 1; }
  find . -maxdepth ${2:-1} -type f -exec grep --with-filename "$1" {} \;  # -H
}

#--------------------------------------------------------------------------#
# Following is the file encryption and decryption functions by openssl(1)  #
# using alghoritm:
OPENSSL_ENC_ALG=-aes-256-cbc
#
# encrypt_file() using ENC_SUF for the newly created encrypted file.
ENC_SUF=.enc
#--------------------------------------------------------------------------#

# encrypt_file FILE [ENC_FILE]
#               Encrypt file using openssl(1) using OPENSSL_ENC_ALG.
#               The resulting file appended an $ENC_SUF.
function encrypt_file() {
  test $1 || { echo "missing file name"; return 1; }
  file=$1
  newfile=${2:-$1}${ENC_SUF}
  
  if [ ${debug:=0} -gt 0 ]
  then
    echo "file:      $file"
    echo "newfile:   $newfile"
    return
  fi

  openssl enc $OPENSSL_ENC_ALG -in $file -out $newfile

  # After file was encrypted try to unencrypt it and diff with the original
  # if they are the same remove original and temporary decrypted and leave
  # only the encrypted one.
}

# Decrypt files encrypted by encrypt_file(). Expects
# second argumnet to be a directory path where file should 
# be decrypted. If it is not a directory treat it as filename.
# If no argument was supplied the output on stdout.
function decrypt_file() {
  test $1 || { echo "missing file name"; return 1; }
  # print to STDOUT by default
  out=-

  # Change output file with respect to the second argument
  case $2 in
    '.'|*/)
      # If '.' was specified as second argument use same file
      # name but without prefix (i.e. creds.enc -> creds )
      # full path is current directory, $2='.'; if '/' is found
      # at the end it is treated as filename. We must use ${var%<end_pattern>} 
      # construct to strip additional '/' then.
      out=${2%/}/`basename $1 .${1/*.}`;;
    
    ?*)
      echo here
      # Full path, slash will remain
      if [ ${2/[a-z]*} ]
      then
        out=$2
      else
        out=./$2
      fi;;
      
  esac


  in=$1; cp $1{,.bak}
  echo "in: $in"
  echo "out: $out"
  # Test if resulting file names pointing to the same file
  test -e $out && { 
  
    echo -e "Warning! Rewriting an existing file!\nSpecify file" \
         "name explictly by full path or base directory by" \
         "\nprepending slash at the end.";
   return 5;}

  openssl enc -d $OPENSSL_ENC_ALG -in $in -out $out
}

# find(1) wrapper, displays file names in which pattern was found
#  
# Usage: [GREP_OPTS] dir [DIR] [DEPTH] EXPR
#
#   DIR DEPTH EXPR
#   DIR EXPR
#   EXPR
# Note the options to grep(1). It can be changed by passing another values
# explicitly on the command line by prepending command with grep_opts=
# ADD . .  and handle ${m:--max-depth 5} or empty, is it ?
grep_opts="--color --with-filename --line-number";
function dir() 
{ 
  # Accept asterisk '*' for any depth
  test -n "$GREP_OPTS" && grep_opts=$GREP_OPTS
  # Must by delcared as such, otherwise they retain values after a call
  declare ERROR
  
  if [ $# -gt 3 ]; then
    echo "Excess number of arguments specified" >&2 
    ((ERROR++)) 
  elif [  $# -eq 0 ]; then
    echo "Search pattern must be specified!" >&2;
    ((ERROR++)) 
  fi
  test -z "$ERROR" || { echo "Usage: [grep_opts] dir [DIR] [DEPTH] EXPR" >&2; \
                        return 1; }
  expr=${!#}
  while [ $# -gt 1 ]
  do
    if test $1 = 'max'
    then
      depth='300' 
    elif test -e $1; then
      dir=$1
    else
      depth=$1
    fi
    shift;
  done;
#  echo "dir: $dir"
#  echo "depth: $depth"
#  echo "expr: $expr"
# return 2
  #echo "find ${dir:-.} -maxdepth ${depth:-1} -type f -exec grep ${grep_opts} {} -e \"$expr\" \;"
  find ${dir:-.} -maxdepth ${depth:-1} -type f -exec grep ${grep_opts} {} -e "$expr" \;
}


################# GIT ####################

# Return first six digit of the last commit
function sixcommit() {
  git log -n1 | sed -n '/^commit/ s/.* \([[:xdigit:]]\{6\}\).*/\1/p'
}
################# DOCKER ####################

# Configure container aliases

# Set cnt_id to id of the last container
alias cnt_id='docker ps --no-trunc --latest --quiet'
# Set cnt_ip to ip of the last created container
alias cnt_ip='docker container inspect `cnt_id` -f "{{ .NetworkSettings.IPAddress}}"'
# Show environment of the last container that was created
alias cnt_env='docker exec $(cnt_id) env'
# Open a shell to the last container that was used
alias cnt_open='docker exec -it $(cnt_id) bash'
# Display network information about the last container that was used
alias cnt_netinfo='docker inspect $(cnt_id) -f "{{json .NetworkSettings}}" | grep -o "\(NetworkID\|IPAddress\)[^,]\+" | sed -n "/NetworkID/,/IPAddress/ {s/\":\"/\t/; s/\"//p}"'
#  Display network id of the last container that was used
alias cnt_netid='docker inspect $(cnt_id) -f "{{json .NetworkSettings}}" | grep -o "NetworkID[^,]\+" | cut -d: -f2'
# Remove last container that was used
alias cnt_rm='docker rm -f $(cnt_id)'

# Display mounts
alias cnt_mounts='docker inspect $(cnt_id) --format "{{ .Mounts }}"'

function compose()  { docker-compose $@; }
function  images()  { docker  images $@; }

# Inspect container
function inspect() {
  test $1 && id=$1 || id=$(cnt_id)
  docker inspect $id | less
}

# Inspect network of the last container or the one in arguments
function netinfo() {
  test $1 && id=$1 || id=$(cnt_id)
  docker inspect ${id} -f "{{json .NetworkSettings}}" | \
    grep -o "\(NetworkID\|IPAddress\)[^,]\+" | \
    sed -n "/NetworkID/,/IPAddress/ {s/\":\"/\t/; s/\"//p}"
}

# what about ports and mounts
function docker_root_dir() 
{
  DOCKER_ROOT_DIR=$( docker info | awk -F: '/Docker Root Dir/ {print $2}' )
  echo "DOCKER_ROOT_DIR was set to '$DOCKER_ROOT_DIR'"
}

_init_image_dir() {
  dir=$( docker info | awk -F: '/Docker Root Dir/ {print $2}' )
  driver=$( docker info | awk -F: '/Storage Driver/ {print $2}' | tr -d ' ' )
  export img_dir=$dir/image/$driver/imagedb
}
######################### Kubernetes #####################################

# Print default names or set all namespaces
function ns() {
  if [ "$1" == "get" ]
  then
    kubectl get ns
    return
  fi
  test $1 || {
    kubectl config view -o json --minify | jq '.contexts[].context.namespace';
    return;
  }
  kubectl config set-context --current --namespace "$1"
}

# Get container names and images. Optionally first argument can be a namespace
function getImagesByContainerName() {
  ns=${1:+"-n $1"}
  kubectl get pods -o json ${ns} | jq '.items[].spec.containers[] | { (.name): .image }'
}

# Print pod name along to it's image
function getImagesByPodName() {
  ns=${1}
  k get pods ${ns:+"-n $ns"} -o json | jq '.items[] | { (.metadata.name ): .spec.containers[].image }'
}

function podsByName() {
  k get pods -o json | jq '.items[].metadata | { (.name): .labels }'
}
# Print useful pod information or filter it, depends on the
# args. Print image name by default
function pod() {
  p=$1
  if test -e "$p"; then
    pod_dump="$p" 
  else
    pod_dump=`mktemp`
    kubectl get pod "$p" -o json ${ns:+"-n $ns"} > $pod_dump
  fi

  echo "$pod_dump"
  image=$(cat $pod_dump | jq '.spec.containers[] | { (.name): .image }')
  node=$(cat $pod_dump | jq '.spec.nodeName')
  namespace=$( cat $pod_dump | jq '.metadata.namespace' )

  echo "image: $image"
  echo "node: $node"
  echo "namespace: $namespace"
}

# Get node names
function nodes() {
  node="$1"
  k get nodes -o json | jq .items[].metadata.name -r
}

# Get images stored on nodes
# by default display image [node] 
function getNodeImages() {
  node="$1"
  test -n "$1" || { nodes; exit; }
  kubectl get node $node -o json | jq '.status | .images[].names[]' | grep -v sha
}

# Decode jwt token using jwt-cli package
function sa_token() {

  test "$1" || { echo "Specify a pod"; return 1; }

  # 1. Find sa used by pod
  SA=$( kubectl get pod "$1" -o json | jq -r '.spec | .serviceAccount' )
  # 2. Find secret used by sa
  SECRET=$( kubectl get sa ${SA} -o json | jq -r '.secrets[].name' )

  # 3. Find token used by secret
  TOKEN=$(kubectl get secret $SECRET -o jsonpath="{['data']['token']}" | base64 --decode) 
  # same here
  #TOKEN=$( kubectl describe secret "$1"  | awk -F: '/^token/ {print $2}' | tr -d " " )

  jwt $token
}

# Print mounts
function mountPath() {
  test "$1" || { echo "Missing pod name"; return 1; }
  kubectl get pod "$1" -o json | jq -r '.spec.containers[].volumeMounts[]'
}

# Get useful pods info
function podinfo() {
  k get po "$1" -o json |\
    jq .spec | '{ "Node: ": .nodeName }'
}

function getPodOwner() {
  
}
# Get useful information for the service
function svc_net() {
    if test "$2" == "all"
    then
      k describe svc "$1"
    else
      k describe svc "$1" | grep -iE '(port)|(End)'
    fi
}

# Patch service type (c,n,l)
function patch_svc() {
  # Allow for regular command flags (i.e., -n)
  # Handle short service names
  kubectl patch svc "$1" -p '{"spec": {"type": "'$2'"}}'
}
    # Convert branch asdf
#function getOwner() {
 # 
#}

# Find pods under service
function getPodsUnderService() {
  kubectl get po -l $( k get svc "$1" -o json | jq -r '.spec.selector' | sed -n '{s/"//g; s/: /=/p}' )
}

# Find selector or with items[]. In deployment manifest!
alias match-labels="jq -r '.spec.selector.matchLabels' | sed -n '/:/ s/\"//g; s/: */=/p;'"

#function getChilds() {
  #
#}

function name() {

  export name=$(echo )
}

########## Convertion

function toyaml() {
  test "$1" || { echo "missing filename"; exit 1; }
  perl -MYAML -MJSON -0777 -wnl -e 'print YAML::Dump(decode_json($_))' $1
}


# Wrapper around jq 
function ke() {
  if [ $# -eq 0 ]
  then
    cmdline="keys"
  else
    cmdline="`echo "$*" | sed 's/\(^\| \)/./g; s/\. *$/\| keys/;'`"
  fi
  echo "$cmdline"
  jq "$cmdline"
}

# Convert to yaml
function toyaml() {
 perl -MYAML -MJSON -0777 -wnl -e 'print YAML::Dump(decode_json($_))'
}

# Print common information per container
# images, sa, node, ip, mounts 
### Aliases
alias jvim='vim -c "set ft=json" -'
alias json='jq -C . | less -r'
alias tojson='yq e - -o=json'
alias toyaml='yq -P e -'
alias keys='jq keys'
alias lsjson='ls *.json -l'
alias rmjson='rm *.json'
alias gp='k get pods'
alias gs='k get svc'

# parsing json defitions
alias labels='jq .metadata.labels'
alias name='jq -r .metadata.name'

# Display without comments
alias real_line="grep '^\s*[^ #]'"
alias clean="sed 's/^\({\|}\)\|\"//g; /^\s*$/d;' | uniq"

PATH=$PATH:$HOME/repos/KCs
AWS_CONFIG=835357571861_SupportPowerUser
