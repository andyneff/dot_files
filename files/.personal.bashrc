#!/usr/bin/env false bash

has_panfs=0
mount | grep -q "type panfs " && has_panfs=1

# Something to do with panfs and __git_ps1
if [ "${BASH_VERSINFO[0]}" -ge "4" ]; then
  backup_aliases[git]="$(alias git 2> /dev/null || :)"
else
  backup_aliases__git="$(alias git 2> /dev/null || :)"
fi
unalias git &> /dev/null

umask 0022

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

###########################
### Env var and options ###
###########################

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# Make LESS always use ANSI (raw mode)
# https://askubuntu.com/a/1156810
export LESS=FRX
# There is still a possibility this will mess up another application in the future
# at which point, I should use one of these?
# alias less="less -FRX"
# alias less="env LESS=FRX less"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

if [ "${BASH_VERSINFO[0]}" -gt "3" ]; then
  # If set, the pattern "**" used in a pathname expansion context will
  # match all files and zero or more directories and subdirectories.
  shopt -s globstar
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

function add_element_post ()
{
  target=$1
  local IFS=':'
  t=( ${!target} )

  needToAdd=1
  for t1 in "${t[@]}"; do
    if [ $t1 == $2 ]; then
      needToAdd=0
      break
    fi
  done

  if [ $needToAdd == 1 ]; then
    t=( ${t[@]} $2 )
    export $target="${t[*]}"
  fi
}

if [ -n "${DISPLAY+set}" ]; then
  _ORIGINAL_DISPLAY="${DISPLAY}"
fi
if [ -f ~/.displayrc ]; then
  source ~/.displayrc

  if [ -z "$(xauth -n list "${DISPLAY}")" ] || ! timeout 1 xhost &> /dev/null; then
    echo "Stale x11 detected, removing ~/.displayrc"
    rm -f ~/.displayrc
    unset DISPLAY
    if [ -n "${_ORIGINAL_DISPLAY+set}" ]; then
      DISPLAY="${_ORIGINAL_DISPLAY}"
    fi
  fi
fi
unset _ORIGINAL_DISPLAY

if [[ "${DISPLAY-}" =~ ^:[0-9]+$ ]]; then
  X_WORKING=1 #don't check :0
elif command -v xhost &> /dev/null; then
  if timeout 1 xhost &> /dev/null; then
    X_WORKING=1
  else
    X_WORKING=0
  fi
elif timeout 1 xset &> /dev/null; then
  X_WORKING=1
else
  X_WORKING=0
fi
export X_WORKING

# .docker/config
if [ "${OS-}" = "Windows_NT" ]; then
  export DOCKER_CONFIG=~/.docker/windows
elif [ -n "${WSL_DISTRO_NAME+set}" ]; then
  # export DOCKER_CONFIG=~/.docker/wsl
  # WSL has special integration, it's just easier to leave it here for now
  export DOCKER_CONFIG=~/.docker
elif [[ ${OSTYPE-} = darwin* ]]; then
  export DOCKER_CONFIG=~/.docker/macos
else
  export DOCKER_CONFIG=~/.docker/linux
fi

if [ "${X_WORKING}" = "1" ]; then
  if [[ "${DISPLAY-}" =~ ^:[0-9]+$ ]]; then
    function edit()
    {
      code -n -w "${@}"
    }
    export EDITOR=code
  else
    function edit()
    {
      vim "${@}"
    }
    export EDITOR=vim
  fi
fi

add_element_post PATH ~/bin
#add_element_post PATH /opt/projects/just/vsi_common/linux
#add_element_pre PYTHONPATH /home/andy/tools/
#add_element_pre PYTHONPATH /usr/local/lib64/python2.7/site-packages

export PYTHONSTARTUP=~/.pyrc
#export PS1='\[\e[40;93m\]\w\[\e[0m\]\n[\u@\h \W]$ '

################
### Bindings ###
################

# To discover bind key codes:
# bind -p | grep quote
# "\C-q": quoted-insert  # Ctrl+q, doesn't always work (e.g. cygwin)
# "\C-v": quoted-insert  # Ctrl+v, doesn't work on Windows Terminal, but does work in Command prompt
# "\e[2~": quoted-insert # Works in Windows Terminal!

# ^[[H - "^[" is "\e" (Alt), so "\e[H"
# ^? - "^" is "\C-" (Ctrl), so "\C-?"

# ?+Left/Right
bind '"\e[5C": forward-word'
bind '"\e[5D": backward-word'
# Ctrl+Left/Right
bind '"\e[1;5C": forward-word'
bind '"\e[1;5D": backward-word'
# bind '"\e[1~": beginning-of-line' # Home
# bind '"\e[4~": end-of-line'       # End

#################
### My Prompt ###
#################

source ~/.git-prompt
#PS1='\[\e[40;93m\]\w\[\e[0m\]\n[\u@\h \W]$ '
#PROMPT_COMMAND='__git_ps1 "\u@\h:\w" "\\\$ "'
GIT_PS1_SHOWCOLORHINTS=1
if [ "${OS-}" != "Windows_NT" ]; then
  # Too slow on windows, CreateProcess is too slow
  GIT_PS1_SHOWUNTRACKEDFILES=1
  GIT_PS1_SHOWUPSTREAM=verbose
  GIT_PS1_SHOWSTASHSTATE=1
  GIT_PS1_SHOWDIRTYSTATE=1
fi
# If one of the HPC machines
if [ -n "${BC_HOST+set}" ]; then
  # disable this for speed
  unset GIT_PS1_SHOWDIRTYSTATE
fi
alias quick_git_ps1='unset GIT_PS1_SHOWDIRTYSTATE'
if command -v tput &>/dev/null && [[ $(tput colors) -ge 256 ]]; then
  hostcolor=$(echo ${BC_HOST:-$(hostname)} | cksum | awk '{print $1}')
  if [ "${BC_HOST-}" = "gaffney" ]; then
    hostcolor=$(( hostcolor + 10 ))
  fi
  # 24-231
  hostcolor=$(( hostcolor % 207 + 24 ))
  # I'm not 100% sure I understand this ansi code, especially the [] on the
  # outside, but this is passed to PROMPT_COMMAND and evaluated later, hence no
  # literal $''. Using the literal causes issues with chars being left behind.
  hostcolor='\[\e[38;5;'$hostcolor'm\]'
fi

# Modifies the title and inserts the tty name after the hostname in ()
function my_vte_prompt_command()
{
  local vte
  local tty_name
  declare -f -F __vte_prompt_command > /dev/null #In case not using gnome-terminal
  if type -p __vte_prompt_command; then
    if command -v tty &> /dev/null; then
      vte="$(__vte_prompt_command)"
      tty_name="$(tty)"
      tty_name="${tty_name#/*/}"
      # Use the :, since I know it is between the hostname and directory. This
      # is easier than rewriting __vte_prompt_command myself
      printf '%s' "${vte/:/(${tty_name}):}"
    else
      __vte_prompt_command
    fi
  fi
}

if [ -e /.dockerenv ]; then
  SINGULARITY_NAME=docker
fi

OS_PROMPT=
if [ -n "${MSYSTEM+set}" ]; then
  OS_PROMPT=" \[\e[35m\]${MSYSTEM}\[\e[0m\]"
elif [ -n "${WSL_INTEROP+set}" ]; then
  OS_PROMPT=" \[\e[33m\]${WSL_DISTRO_NAME}\[\e[0m\]"
elif [ -n "${WSL_DISTRO_NAME+set}" ]; then
  OS_PROMPT=" \[\e[36m\]${WSL_DISTRO_NAME}\[\e[0m\]"
elif [ "${OS-}" = "Windows_NT" ]; then
  OS_PROMPT=" \[\e[34m\]Windows\[\e[0m\]"
elif [[ ${OSTYPE-} = darwin* ]]; then
  OS_PROMPT=" \[\e[31m\]macOS\[\e[0m\]"
else
  OS_PROMPT=" \[\e[32m\]Linux\[\e[0m\]"
fi

source ~/.dot/external/dot_core/external/vsi_common/linux/time_tools.bsh
get_time_nanoseconds >& /dev/null # preload optimization

PROMPT_COMMAND='__ps1_rv=${__vsc_status-$?};
__ps1_time=$(get_time_nanoseconds);
__git_ps1 "\[\e[40;93m\]\w\[\e[0m\]\n'\
'$(for x in ~/.prompt_command/*; do'\
'    if [ -r "${x}" ]; then'\
'      source "${x}" 0;'\
'    fi;'\
'  done)'\
'${SINGULARITY_NAME+\[\e[30;41m\]{${SINGULARITY_NAME}\}\[\e[0m\] }'\
'${VIRTUAL_ENV+($(basename "${VIRTUAL_ENV}")) }$(printf -v x "%*s" ${SHLVL}; echo -n "${x// /[}")\u@'"${hostcolor-}"'${BC_HOST+${BC_HOST}(}\h${BC_HOST+)}\[\e[0m\] $('\
'if [ "$__ps1_rv" != "0" ]; then'\
'  echo "\[\e[41m\]${__ps1_rv}\[\e[0m\]";'\
'else'\
'  echo "${__ps1_rv}";'\
'fi)'"${OS_PROMPT}"' \W" "]$ ";
__ps1_time=$(($(get_time_nanoseconds)-__ps1_time+500000));
__ps1_time="${__ps1_time::${#__ps1_time}-6}";
if [ "${__ps1_time}" -gt "250" ]; then
  echo "Git took ${__ps1_time}ms, this is longer than expected." >&2
  echo "Consider calling: quick_git_ps1 or set DISABLE_GIT_PROMPT=1" >& 2
fi;
touch ~/.last_ran_command;
my_vte_prompt_command'
# PROMPT_COMMAND+=$'; printf "\033]0;%s@%s(%s):%s\033\\\\" "${USER}" "${HOSTNAME%%.*}" -1 "${PWD}"'
# To add a custom terminal title, add '; printf "\033]0;CUSTOM TITLE\007"' to
# the *end* of PROMPT_COMMAND (After vte_command, which sets it too). You can
# also add $'\e]0;CUSTOM TITLE\007' or $'\e]0;CUSTOM TITLE\e\\' to PS1 too...
# (\e and \033 and \x1b are the same), only if TERM is xterm*|rxvt*)

# To disable git part of prompt, set DISABLE_GIT_PROMPT=1

# A great way to time the PROMPT_COMMAND is to change the last line like so
# 'fi) \W" "] $(date +%s.%N) $ "; my_vte_prompt_command'
# and just run "date +%s.%N" and take the diff

unset hostcolor OS_PROMPT
alias no_prompt='unset PROMPT_COMMAND; PS1="$ "'

function parent_find()
{
  local OLDPWD
  local previous_pwd
  # Speed improvement: if it's right there, echo it out right away
  if [ -e "${1}" ]; then
    return 0
  fi

  \pushd . > /dev/null
    # Search for the file until some match is found
    while [ "${PWD}" != "${previous_pwd-}" ]; do
      if [ -e "${1}" ]; then
        \popd > /dev/null
        return 0
      fi
      previous_pwd="${PWD}"
      \cd ..
    done
  \popd > /dev/null
  return 1
}

# This was so efficient, I took off the has_panfs gate.
eval "$(declare -f __git_ps1 | sed $'1c\\\n__orig_git_ps1()\n')"
function __git_ps1()
{
  if [ "${DISABLE_GIT_PROMPT-}" != "1" ] && (parent_find .git &> /dev/null); then
    unalias git &> /dev/null
    __orig_git_ps1 "${1}" "${2}"
    if [ "${BASH_VERSINFO[0]}" -ge "4" ]; then
      eval "${backup_aliases[git]-}"
    else
      eval "${backup_aliases__git-}"
    fi
  else
    PS1="$1$2"
  fi
}
# Have to set git aliase AFTER __git_ps1, or else the alias is hardcoded into
# the function
if [ "${BASH_VERSINFO[0]}" -ge "4" ]; then
  eval "${backup_aliases[git]-}"
else
  eval "${backup_aliases__git-}"
fi

# export TERM=linux
# export TERM=xterm-256color
#Apparently its bad to mess with the TERM variable, for example it fucks up less and changed the End key from doing G to F

# Stop virtual env activate script from messing with PS1, I use PROMPT_COMMAND
# anyways
VIRTUAL_ENV_DISABLE_PROMPT=1

#gnome-terminal --save-config ~/.gnome-termainl-session

#############################
### Host Specific Section ###
#############################

# WSL
if [ "${BASH_VERSINFO[0]}" -ge "5" -a -n "${WSL_INTEROP+set}" ]; then
  function _custom_initial_word_complete()
  {
    if [ "${2-}" != "" ]; then
      if [ "${2::3}" == "wor" ]; then
        COMPREPLY=($(compgen -c "${2}" | \grep -v workfolderssvc))
      else
        COMPREPLY=($(compgen -c "${2}"))
      fi
    fi
  }

  complete -I -F _custom_initial_word_complete
fi

# WSL
if [ -n "${WSL_DISTRO_NAME+set}" ]; then
  function mount_self()
  {
    mkdir -p "/mnt/wsl/${WSL_DISTRO_NAME}"
    if sudo -n mount --bind / "/mnt/wsl/${WSL_DISTRO_NAME}/"; then
      echo "Mounted to /mnt/wsl/${WSL_DISTRO_NAME}/" >&2
    else
      (
        source ~/.dot/external/dot_core/external/vsi_common/linux/quotemire
        echo "Unable to mount. Make sure the following is in your sudoers file:" >&2
        quotemire "sudo bash -c" "echo 'ALL ALL=(ALL) NOPASSWD: /usr/bin/mount --bind / $(printf %q /mnt/wsl/${WSL_DISTRO_NAME}/)' > /etc/sudoers.d/wsl_mount_self" >&2
      )
    fi
  }
fi

# WSL2 fix
if [ -n "${WSL_INTEROP+set}" ]; then
  if [ "${HOSTNAME-}" = "kaku" ]; then
    if [ "${WSL_DISTRO_NAME}" != "Ubuntu-20.04" ]; then
      if ! /mnt/c/Windows/System32/wsl.exe --cd / -d Ubuntu-20.04 service wsl-vpnkit status &>/dev/null; then
        /mnt/c/Windows/System32/wsl.exe --cd / -d Ubuntu-20.04 --user root service wsl-vpnkit start
      fi
    fi
  fi
fi

#############################
### Functions and Aliases ###
#############################

## Docker ##

function dc_images_parent_id(){
  /opt/venvs/docker/bin/python -c "from __future__ import print_function; import docker; c=docker.client.from_env();imgs=c.images.list(all=True);ids=[(i.attrs['ParentId'], i.id) for i in imgs]; [print('{} {}'.format(i[0].replace('sha256:', ''), i[1].replace('sha256:', ''))) for i in ids]"
}

function dc_children(){
  dc_children_q $1 " "
}

function dc_children_q(){
  if [ "$2" != "" ]; then
    local depth=-$2
  fi
  local cache=$3
  if [ "$cache" == "" ]; then
    local cache_use=`mktemp`
    dc_images_parent_id > "${cache_use}"
    local dockid=$(docker inspect -f '{{.Id}}' $1 | sed 's|sha256:||')
  else
    local cache_use="${cache}"
    local dockid=$1
  fi

  if (( ${#dockid} < 64 )); then return; fi

  while read line; do
    local newid=`echo $line | awk '{print $2}'`
    echo ${depth}${newid}
    dc_children_q "${newid}" "${depth}" "${cache_use}"
  done < <(grep "^${dockid}" "${cache_use}")

  if [ "${cache}" == "" ]; then
    \rm "${cache_use}"
  fi
}

# Find out which docker is responsible for host pid
function dc_pid(){
  local ds=($(docker ps --format '{{.ID}}' | xargs docker inspect -f '{{.State.Pid}} {{.Id}}'))
  local ppid=$1
  while (( ${ppid} != 1 )); do
    for x in $(seq 0 2 ${#ds[@]}); do
      if [ "${ds[$x]}" == "${ppid}" ]; then
        echo ${ds[$(($x+1))]}
        return
      fi
    done
    ppid=$(ps -ho ppid $ppid)
  done
}

# List all containers (running and not-running) that are bound to a particular
# volume (from docker volume ls). This is useful for trying to remove a volume,
# but a stray container has it mounted
function dc_find_volume()
{
  local volumes=($(docker inspect --format '{{$x:=.Name}} {{range .Mounts}} {{if .Name}} {{$x}}@{{ .Name }} {{end}} {{end}}' $(docker ps -aq)))
  local x
  for x in "${volumes[@]}"; do
    if [[ ${x} =~ .*@$1 ]]; then
      echo ${x%@*}
    fi
  done
}

function dc_volume()
{
  docker volume rm $(docker volume ls | \grep -E '^local +[a-f0-9]{64}$' | awk '{print $2}')
}

# Removes an image and all its children. Will probably fail if containers are
# left behind using any of the images.
function dc_rmi(){
  docker rmi $(dc_children_q $1 | tac)
  docker rmi $1
}

function docker_list-tags()
{
  curl -sL "https://hub.docker.com/v1/repositories/${1}/tags" | jq -r '.[].name'
}

function _de_cleanup()
{
  local nullglob=1
  if \shopt -q nullglob; then
    nullglob=0
  fi

  for f in ~/.ssh/docker_*; do
    if ! \fuser "${f}" >& /dev/null; then
      \rm "${f}"
    fi
  done

  if [ "${nullglob}" = "1" ]; then
    \shopt -u nullglob
  fi
}

#**
# .. function:: de_activate
#
# Docker environment activate - connected to remote docker server using ssh tunneling. This does **not** employ the *insecure* method of exposing the docker daemon to an open TCP port.
#
# :Arguments: ``$1``... - Arguments to ``ssh`` command, machine name and options
#
# :Parameters: [``DE_OLDER``] - Set to 1 if using ssh older than 6.7. When you use this flag, the server needs to have ``socat`` installed.
#
# .. rubric:: Example
#
# .. code-block:: bash
#
#     de_activate username@server -p 1234
#
# .. seealso::
#   :func:`de_reverse_activate`
#**
function de_activate()
{
  local docker_host
  local ssh_args
  if [ "$#" == "0" ]; then
    echo "usage: $0 <ssh flags>"
    echo "  Set DE_OLDER to 1 when using openssh version before 6.7"
    return 1
  fi

  _de_ssh_args=("${@}")
  _OLD_DOCKER_HOST="${DOCKER_HOST-}"

  ssh_args=(-o ControlPath=~/.ssh/%C -o ControlMaster=auto -o ControlPersist=yes)

  _de_cleanup

  if [ "${DE_OLDER-}" = "1" ]; then
    ssh -n -L 2375:localhost:2375 "${@}" \
       'socat TCP-LISTEN:2375,fork,bind=localhost UNIX-CONNECT:/var/run/docker.sock&
        pid=$!
        trap "kill $pid" 0
        while printf \\0; do
          sleep 5
        done' &
    docker_host="tcp://localhost:2375"
  else
    # Requires opensshd 6.7 or newer... THANKS CentOS! :(
    _de_socket="$(mktemp -u -d ~/.ssh/docker_XXXXXXXX)"
    ssh_args+=(-fTN -L "${_de_socket}":/var/run/docker.sock "${@}")
    docker_host="unix://${_de_socket}"

    if ssh -O check "${ssh_args[@]}" >&/dev/null; then
      # I can't tell when a command fails. Oh well
      ssh -o ServerAliveInterval=60 "${ssh_args[@]}"&
    else
      ssh -o ServerAliveInterval=60 "${ssh_args[@]}" || return $?
    fi
  fi

  export DOCKER_HOST="${docker_host}"

  #This will not always be correct, but oh well
  VIRTUAL_ENV="de $1"
  echo "VIRTUAL_ENV=\"${VIRTUAL_ENV}\""
  echo "export DOCKER_HOST=\"${DOCKER_HOST}\""

  function de_deactivate()
  {
    ssh -o ControlPath=~/.ssh/%C -O exit "${_de_ssh_args[@]}" # || return $?

    if [ "${_OLD_DOCKER_HOST-}" == "" ]; then
      unset DOCKER_HOST
    else
      export DOCKER_HOST="${_OLD_DOCKER_HOST}"
    fi

    # Newer way leaves a stray socket behind... which if you close without
    # deactivating will result in a "socket" leak
    if [ "${_de_socket+set}" == "set" ]; then
      \rm "${_de_socket}"
      unset _de_socket
    fi

    _de_cleanup

    unset _de_ssh_args VIRTUAL_ENV
    unset -f de_deactivate
  }
}

#**
# .. function:: de_reverse_activate
#
# Not as good as :func:`de_activate`, but needed on systems where you can't directly ssh into a docker enabled user or for some reason on Synology this is needed too.
#
# :Arguments: [``$1``] - Name of computer connecting back on. Optional if 2... is only one argument, and defaults to $(hostname)
#             ``$2``... - Arguments to ``ssh`` command, machine name and options
#
# :Parameters: [``CHANGE_USER``] - The ssh-ed user needs to ``sudo`` to another user, add that command using the ``CHANGE_USER`` environment variable. With something like ``sudo su - root -c``, the ``-c`` needs the next ``ssh`` command to be passed in as one argument to the ``su`` command, use ``CHANGE_SINGLE`` too to make this work.
#              [``CHANGE_SINGLE``] - Set to one for a more complicated scenario for chaning user, such as ``su -c`` where the ``-c`` take only one single argument.
# .. rubric:: Example
#
# .. code-block:: bash
#
#     de_reverse_activate my_username@my_hostname username@server -p 1234
#     # or
#     CHANGE_SINGLE="1" CHANGE_USER="sudo su - root -c" de_reverse_activate my_username@my_hostname username@server -p 1234
#     # or
#     CHANGE_USER="sudo" de_reverse_activate my_username@my_hostname username@server -p 1234
#
# .. seealso::
#   :func:`de_reverse_activate`
#**
function de_reverse_activate()
{
  if [ "$#" = "1" ]; then
    de_reverse_activate $(hostname) "$1"
  fi
  local phone_home="${1}"
  local args=()
  shift 1
  local de_socket="$(mktemp -u -d ~/".ssh/docker_XXXXXXXX")"

  args[0]="$(~/.dot/external/dot_core/external/vsi_common/linux/print_command ssh -t "${@}")"
  args[1]="ssh -t -R '${de_socket}:/var/run/docker.sock' ${phone_home}"
  args[2]="env 'DOCKER_HOST=unix://${de_socket}' 'DISPLAY=${DISPLAY}' bash -c"
  args[3]="cd '$(pwd)'; exec bash"

  if [ -n "${CHANGE_USER+set}" ]; then
    if [ "${CHANGE_SINGLE-}" = "1" ]; then
      args=("${args[0]}" "${CHANGE_USER}" "${args[@]:1}")
    else
      args[1]="${CHANGE_USER} ${args[1]}"
    fi
  fi
  eval "$(~/.dot/external/dot_core/external/vsi_common/linux/quotemire "${args[@]}")"
}

#**
# .. function:: dcp2v
#
# Docker copy files to a docker volume
#
# :Arguments: ``$1`` - Volume name
#             ``$2``... - Filenames
# .. seealso::
#   :func:`dcpfv`
#**
function dcp2v()
{
  local volume="$1"
  shift 1
  tar zc "${@}" | docker run -i --rm -v "${volume}":/cp -w /cp alpine tar zx
}

#**
# .. function:: dcpfv
#
# Copy files from a docker volume
#
# :Arguments: ``$1`` - Volume name
#             ``$2``... - Filenames
#
# .. note::
#
#    Does not handle spaces correctly. See :func:`dcpfv2`
#
# .. seealso::
#   :func:`dcpfv2`
#**
function dcpfv()
{
  local volume="$1"
  shift 1
  local args=("${@}")
  docker run --rm -e IFS=t \
             -v "${volume}":/cp:ro -w /cp \
             debian bash -xvc "$(declare -p args);"' eval tar zc "${args[@]}"' | tar zx
}

#**
# .. function:: dcpfv2
#
# Version of :func:`dcpfv` that supports spaces
#
# :Arguments: ``$1`` - Volume name
#             ``$2``... - Filenames
# .. seealso::
#   :func:`dcpfv`
#**
function dcpfv2()
{
  local volume="$1"
  shift 1
  local args=("${@}")
  docker run --rm -e IFS=$'\t' \
             -v "${volume}":/cp:ro -w /cp \
             debian bash -c "$(declare -p args);"' tar zc "${args[@]}"' | tar zx
}

alias dc_images_list='docker images -a -q | uniq'

# Get an anonymous token. $1 = repo (no tag)
function docker_login()
{
  TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${1}:pull" | jq -r .token)
}

function pad_base64()
{
  local data="${1-$(cat -)}"
  case $((${#data} % 4)) in
    2)
      data+="=="
      ;;
    3)
      data+="="
      ;;
  esac
  echo -n "${data}"
}

function jwt()
{
  local IFS=.
  local tokens=(${1-$(cat -)})

  # Break apart the main components
  local header=$(pad_base64 <<< "${tokens[0]}" | base64 -d)
  local payload=$(pad_base64 <<< "${tokens[1]}" | base64 -d)
  local signature=$(pad_base64 <<< "${tokens[2]}" | tr _- /+) # why was /+ replaced with _-?

  # Print
  jq <<< "${header}"
  jq <<< "${payload}"

  ########################
  # The rest assumes RS256
  ########################

  local pub_cert=$(jq -r '.x5c[0]' <<< "${header}" | pad_base64)
  pub_cert=$'-----BEGIN CERTIFICATE-----\n'"${pub_cert}"$'\n-----END CERTIFICATE-----'
  local pub_key=$(openssl x509 -pubkey -noout -inform PEM <<< "${pub_cert}")

  # Verify signature
  echo -n "${tokens[0]}.${tokens[1]}" | openssl dgst -sha256 -verify <(echo -n "${pub_key}") -signature <(base64 -d <<< "${signature}")

  # # Useless information
  # openssl x509 -noout -text -inform PEM <<< "${pub_cert}"
}

function docker_fun()
{
  local args=("${@}")

  while (( ${#} )); do
    case "${1}" in
      -H|-l|\
      --config|--context|--host|--log-level|--tlscacert|--tlscert|--tlskey)
        shift 1
        shift 1
        ;;
      -*|image)
        shift 1
        ;;
      images|ls)
        command docker "${args[@]}" | sed -E 's|^([^ ]*) ( *)([^ ]*)|\1:\3\2|'
        return
        ;;
      *)
        break
        ;;
    esac
  done

  command docker "${args[@]}"
  return
}
alias docker=docker_fun

## SSH ##

alias forcessh='ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
alias ssh2="ssh -o ControlPath=none"
alias sshki="ssh2 -o PreferredAuthentications=keyboard-interactive"
alias scp2="scp -o ControlPath=none"
alias ssh3="ssh -o 'UserKnownHostsFile=/dev/null'"
alias ssh_check='ssh -O check'
alias ssh_close='ssh -O exit'
#alias ssh_forward='ssh -O forward'
#alias ssh_unforward='ssh -O cancel'
function ssh_check_socket()
{
  local pid="$(ssh -S "${1}" -O check 127.0.0.0 2>&1)"
  pid="${pid#*=}"
  pid="${pid%)*}"
  lsof -P -i -a -p "${pid}" 2>/dev/null
}

# Disable capture mouse clicks to terminal which tmux turn on, and gets left on if ssh connection disconnects.
alias mouse_reset="echo -n $'\x1b[?1000l'"

function ssh_close_all()
{
  find ~/.ssh/ -maxdepth 1 -type s -regextype posix-egrep -regex '.*/[0-9a-f]{40}' -print0 | \
    xargs -0 -I controlpath bash -c "ssh -O exit -S controlpath foobar || rm controlpath"
}

## GPG ##

export GPG_TTY="$(tty)"
alias gpg_load_key='gpg --sign -o /dev/null /dev/null'
alias gpg_reset_agent='gpg-connect-agent reloadagent /bye'
alias gpg_keyinfo='gpg-connect-agent "keyinfo --list" /bye'

## Process ##

function ptop(){
  local PGREP_ARG=$1
  shift
  top -p$(pgrep $PGREP_ARG | tr '\n' , | sed 's/,$//') "${@}"
}

# NAME
#   ppgrep - Pgrep that returns the parent ids instead
# BUGS
#   Uses ps right justify, so extra spaces are included
function ppgrep()
{
  local output="$(pgrep "${@}")"
  if [ "${output}" != "" ]; then
    ps -o'%P' --no-header ${output}
  fi
}

function pps()
{
  ps -f $(pgrep "${@}")
}

## Core ##

if [[ ! ${OSTYPE} =~ darwin.* ]]; then
  alias ls='ls --color=auto'
  alias lsd='ls --color=auto */ -lasd'
else
  alias ls='ls -G'
  alias lsd='ls -G */ -lasd'
fi

# This determines if you are using a file in  order to decide if you
# should recursively grep or not. This logic is not perfect. It does not appear
# to detect --file, -f[filename], -f=filename, but will detect -f filename
function grep_fun() {
  local orig=("${@}")
  declare -i stdin=0

  declare -i pattern=0
  declare -i files=0

  while [[ ${#} > 0 ]]; do
    # Anything after -- is automatically a file
    if [ "${files}" = 1 ]; then
      files=2
    fi

    # Patterns that are expressions and take an extra arg
    if [[ $1 =~ ^-[a-eg-zA-Z]*f$|^-[a-df-zA-Z]*e$ ||
          $1 = --file ||
          $1 = --regexp ]]; then
      shift
      pattern=1
    # Same, arg included
    elif [[ $1 =~ ^-[a-eg-zA-Z]*f|^-[a-df-zA-Z]*e ||
            $1 = --file=* ||
            $1 = --regexp=* ]]; then
      pattern=1
    # Everything that takes an arg
    elif [[ $1 =~ ^-[a-ln-zA-Z]*m|^-[a-zB-Z]*A|^-[a-zAC-Z]*B|^-[a-zABD-Z]*C|^-[a-zA-CE-Z]*D|^-[a-ce-zA-Z]*d ||
            $1 = --max-count ||
            $1 = --after-context ||
            $1 = --before-context ||
            $1 = --context ||
            $1 = --devices ||
            $1 = --directories ||
            $1 = --color ||
            $1 = --label ||
            $1 = --exclude ||
            $1 = --exclude-from ||
            $1 = --exclude-dir ||
            $1 = --include ||
            $1 = --group-separator ||
            $1 = --binary-files ]]; then
      shift
    # Special case
    elif [ "$1" = "--" ]; then
      files+=1
    # Anything else not starting with - is a pattern/file
    elif [[ $1 != -* ]]; then
      # If pattern already specified, it's a file
      if [ "${pattern}" = "1" ]; then
        files=2
      else # else it WAS a pattern!
        pattern=1
      fi
    fi

    shift
  done

  if (( files + pattern < 3 )); then
    \grep -in --color=always ${orig[@]+"${orig[@]}"} -
  else
    \grep -rin --color=always ${orig[@]+"${orig[@]}"}
  fi
}
#alias grep="grep -rin --color=always"
alias grep="grep_fun"

# alias myeclipse="env GIT_SSH=/usr/bin/ssh /opt/software/eclipse/luna/eclipse"
alias rm="rm -i"

## Custer ##

function onyx_node_info()
{
  local data="$(pbsnodes -a)"
  # onyx_0 is weird, skip it.
  data="$(\grep -E '^[^ ]|available\.bigmem|available\.n[cgm]|^     state' <<< "${data}"  | sed -n '/^onyx_0$/{N;N;d}; N;N;N;N;N;N; s|\n[^\n]* = | |g; /free/p')"
  local IFS=$'\n'
  onyx_info=(${data})
}

# state = free
# resources_available.bigmem = 0
# resources_available.ncpus = 128
# resources_available.ngpus = 0
# resources_available.nmics = 0
# resources_available.nmlas = 0
function free_onyx()
{
  local -A free=()
  local x
  for x in "${onyx_info[@]}"; do
    if [[ ${x} = batch* ]]; then
      ((free[batch]+=1))
    elif [[ ${x} =~ free\ 1 ]]; then
      ((free[bigmem]+=1))
    elif [[ ${x} =~ free\ 0\ 44\ 0\ 0\ 0 ]]; then
      ((free[cpus]+=1))
    elif [[ ${x} =~ free\ [0-9]*\ [0-9]*\ [^0] ]]; then
      ((free[gpus]+=1))
    else
      ((free[other]+=1))
    fi
  done
  declare -p free
}

function free_nodes()
{
  local python=python
  if command -v python3 &> /dev/null; then
    python=python3
  fi
  "${python}" << 'EOF'
from subprocess import Popen, PIPE
import sys
import json
import re

pid = Popen(['pbsnodes', '-a', '-F', 'json'], stdout=PIPE)
data = pid.communicate()[0]
if sys.version_info[0] == 3:
  data = data.decode()
data = '\n'.join([d for d in data.split('\n') if not d.endswith('"comment": ,')])
data = json.loads(data)

resource_keys = set()
for node in data['nodes'].values():
  resource_keys.update(node['resources_available'].keys())

# config_keys = [k for k in resource_keys if re.match('(bigmem$|n.*s|clustertype|jobtype)$', k)]
config_keys = [k for k in resource_keys if re.match('(bigmem$|n.*s)$', k)]

cluster_types = {}
config_count = {}
config_count_hie = {}
for node in data['nodes'].values():

  try:
    if node['state'] == 'free':
      free = True
    else:
      free = False
  except:
    free = None

  if 'clustertype' in node['resources_available']:
    ctypes = node['resources_available']['clustertype'].split(',')
  elif 'jobtype' in node['resources_available']:
    ctypes = node['resources_available']['jobtype'].split(',')
  elif 'available_queues' in node['resources_available']:
    ctypes = node['resources_available']['available_queues'].split(',')
  else:
    ctypes = ['None']
  for ctype in ctypes:
    if ctype not in cluster_types:
      cluster_types[ctype] = [0,0]
    if free:
      cluster_types[ctype][0]+=1
    else:
      cluster_types[ctype][1]+=1

  config = {}
  for k in config_keys:
    try:
      config[k.split('.')[-1]] = node['resources_available'][k]
    except:
      config[k.split('.')[-1]] = 'None'
  config = tuple(sorted(config.items()))
  if config not in config_count:
    config_count[config] = [0,0]
  if free:
    config_count[config][0]+=1
  else:
    config_count[config][1]+=1

  if 'hie' in [c.lower() for c in ctypes]:
    if config not in config_count_hie:
      config_count_hie[config] = [0,0]
    if free:
      config_count_hie[config][0]+=1
    else:
      config_count_hie[config][1]+=1

cluster_type_f = '{:>%d}' % max(len(x) for x in cluster_types.keys())
cluster_type_f += ' {:>5}' * 3
print(cluster_type_f.format('Type', 'Free', 'Used', 'Total'))
for cluster_type in cluster_types:
  print(cluster_type_f.format(cluster_type, cluster_types[cluster_type][0],
                              cluster_types[cluster_type][1],
                              sum(cluster_types[cluster_type])))

print('')

config_f = '{:>%d}:{:>4}' % max(len(c) for c in config_keys)
config_f2 = ' {:>5}' * 3

def pprint(conf):
  print(config_f.format('Type', 'Val') +
        config_f2.format('Free', 'Used', 'Total'))

  for config in conf:
    for c in config:
      if c is config[-1]:
        print(config_f.format(c[0], c[1]) +
              config_f2.format(conf[config][0],
                              conf[config][1],
                              sum(conf[config])))
        print('---')
      else:
        print(config_f.format(c[0], c[1]))
pprint(config_count)

if config_count_hie:
  print('\nHIE\n')
  pprint(config_count_hie)

EOF
}

function pbsnodes_filter()
{
  # Example: pbsnodes_filter ".resources_available.ngpus == 1
  local filter="${1}"
  pbsnodes -a -F json | jq ".nodes | .[] | select($1)"
}

function pbsnodes_filter_to_jobs()
{
  pbsnodes -a -F json | jq -r '.nodes | to_entries[] | select(.value.resources_available.ngpus == 1) | (.key + " " + .value.jobs[0])'
}

function something_else()
{
  jq -r '.nodes | to_entries[] | select(.value.resources_available.ngpus == 1) | (.key + " " + .value.jobs[0])' <<< "${nodes}" | awk '{print $2}' | xargs qstat -F json -f | jq '.Jobs | to_entries[] | {.key}' | less
}

function singularity_ps()
{
  local pid
  ps -f $(lsns -t mnt -n -o user,pid,command | sed -nE "/ \/usr\/lib\/systemd\/systemd/d; / \/sbin\/launchd/d; s|^andy *([0-9]+) .*|\1|p")
}

function singularity_top()
{
  local pid
  for pid in $(lsns -t mnt -n -o user,pid,command | sed -nE "/ \/usr\/lib\/systemd\/systemd/d; / \/sbin\/launchd/d; s|^andy *([0-9]+) .*|\1|p"); do
    echo "Processes in: $(ps -p $pid -o command=)"
    echo "ps \$(pgrep --ns ${pid} --nslist mnt)"
    ps $(pgrep --ns ${pid} --nslist mnt)
    echo
  done
}

function queue_up()
{
  local queue_name="$1"
  shift 1
  if ! screen -ls "${queue_name}" &> /dev/null; then
    screen -d -m -S "${queue_name}"
  fi

  screen -S "${queue_name}" -X stuff "${*}^M"
}

function queue_status()
{
  local pipe="$(mktemp -u)"
  mkfifo "${pipe}"
  screen -S "${1}" -X hardcopy "${pipe}"
  cat "${pipe}" | sed -e '/./,$!d' -e :a -e '/^\n*$/{$d;N;};/\n$/ba'
  rm -f "${pipe}"
}

## Other ##

alias pro="pushd /opt/projects/"
# alias vip="/opt/projects/vip/wrap"

#alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'

alias notebook="cd ~/notebook; pipenv run jupyter-notebook"
alias lab="cd ~/notebook; pipenv run jupyter-lab"

# alias clear_cache='sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"'
alias clear_cache='su a-andy -c "sudo -S sh -c \"sync && echo 3 > /proc/sys/vm/drop_caches\""'
alias clear_swap='sudo sh -c "swapoff -a; swapon -a"'

alias stray_pyc="find . -name \*.pyc -exec bash -c 'x={}; if [ ! -f \${x:0:\${#x}-1} ]; then echo \$x; fi' \;"

alias fix_sfm="xsetroot -cursor_name left_ptr"

alias nvidia-smi2='while :; do nvidia-settings -q GPUUtilization; nvidia-smi; sleep 1; done'

alias scott="env HOME=~/.dot/other/scott LESSHISTFILE=/dev/null"

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# NAME
#   autojust - Auto source your just setup file, and start using just
function just()
{
  if [[ $(type -at just) == *file* ]]; then
    unset just
    command just ${@+"${@}"}
  elif [ -e setup.env ]; then
    . setup.env
    unset just
    just ${@+"${@}"}
  elif [ "${PWD}" != "/" ]; then
    pushd .. >& /dev/null
    just ${@+"${@}"}
    popd >& /dev/null
  else
    command just ${@+"${@}"}
  fi
}

function git_ssh_remote()
(
  source ~/.dot/external/dot_core/external/vsi_common/linux/git_functions.bsh
  convert_git_remote_http_to_git ${@+"${@}"}
)

function git()
{
  if (( $# > 0 )) && [ "${1}" == "commit" ]; then
    command git ${@+"${@}"} -s
  else
    command git ${@+"${@}"}
  fi
}

function ruler()
{
  local cols="$(tput cols)"
  if [ -z "${cols}" ]; then
    cols=80
  fi
  local tens=$((cols / 10))
  local i
  for (( i=1 ; i <= tens ; i++ )); do
    printf "% 9d|" $((i * 10))
  done
  printf '\n'
}

function auto_agent()
{
  # Source file if this has been run before
  if [ -f ~/.ssh/ssh-agent ]; then
    source ~/.ssh/ssh-agent > /dev/null
  fi

  # See if the agent is still running, maybe rebooted
  kill -0 $SSH_AGENT_PID >& /dev/null

  # If not running
  if [ "$?" != "0" ]; then
    # Cleanup
    rm -f ~/.ssh/ssh-agent_pipe >& /dev/null
    # Run again, using a socket in my home dir, storing the env vars in root of
    # home dir
    ssh-agent -a ~/.ssh/ssh-agent_pipe > ~/.ssh/ssh-agent

    source ~/.ssh/ssh-agent

    # Auto kill after a week of not being used
    function watch_ssh_agent()
    {
      # Do one touch just to cover corner conditions
      touch ~/.last_ran_command
      # Store the last bash pid running this function
      echo $$ > ~/.ssh/.watch_ssh.pid
      while kill -0 "${SSH_AGENT_PID}" && (( $(date '+%s') - $(date -r ~/.last_ran_command '+%s') < 1*3600*24 )); do
        # In case this function get called multiple time, last one wins, only need one
        if [ "$(cat ~/.ssh/.watch_ssh.pid)" != "$$" ]; then
          return
        fi

        sleep 60
      done
      kill ${SSH_AGENT_PID}
    }
    export -f watch_ssh_agent

    if command -v screen &> /dev/null; then
      screen -d -m -S auto_kill_ssh_agent bash -c watch_ssh_agent
    elif [ "${OS-}" = "Windows_NT" ]; then
      # https://superuser.com/a/1657415/352118
      if command -v mintty &> /dev/null; then
        mintty bash -mc '(watch_ssh_agent) &> /dev/null < /dev/null &'
      # elif command -v cygstart &> /dev/null; then
      else
        echo "Woops, fixme"
      fi
    else
      watch_ssh_agent &
    fi
    unset watch_ssh_agent
  fi
}

if [ -e ~/.ssh/auto_agent ]; then
  auto_agent
else
  if [ -f ~/.ssh/ssh-agent ]; then
    source ~/.ssh/ssh-agent > /dev/null
  fi
fi

# Parses "rows cols" for a specific tty
# Args: [$1] - TTY to check, e.g. /dev/pts/1
#       Default is to use current tty
function get_tty_rows_cols()
{
  if (( $# )); then
    stty -F "${1}" -a
  else
    stty -a
  fi | sed -En ':combine
                $bdone
                N
                bcombine
                :done
                s|; *|\n|g
                s|(.*)rows ([0-9]+)(.*)|\2 \1\3|
                s|([0-9]+) .*columns ([0-9]+).*|\1 \2|
                p'
}

# Pipe a command's output to another tty, making sure rows and cols match
# - Will not rows and col changing as the command runs
# Args: $1 - tty to match, e.g. "/dev/pts/1"
#       [$2...] command to execute and redirect to $1
# If only one argument is specified, it will start another bash session to match
# the other tty, but not redirect output for you.
function pipe_pts()
{
  local pts="${1}"
  shift 1
  local orig_rows_cols=($(get_tty_rows_cols))
  local rows_cols=($(get_tty_rows_cols "${pts}"))

  if (( $# )); then
    stty rows "${rows_cols[0]}"
    stty columns "${rows_cols[1]}"
    ${@+"${@}"} > "${pts}" 2> "${pts}"
  else
    stty rows "${rows_cols[0]}"
    stty columns "${rows_cols[1]}"
    bash
  fi
  stty rows "${orig_rows_cols[0]}"
  stty columns "${orig_rows_cols[1]}"
}

ascii_animation=" ⠁⠂⠄⡀⢀⢁⢂⢄⣀⣁⣂⣄⣠⣡⣢⣤⣥⣦⣴⣵⣶⣷⣾⣿⡿⣷⣾⡾⣶⡶⣦⣴⡴⣤⡤⣄⣠⡠⣀⡀⢀"
function ascii_animate()
{
  ascii_animation_index=$((${ascii_animation_index-0}+1))
  printf "\b${ascii_animation:ascii_animation_index%${#ascii_animation}:1}"
} # while :; do ascii_animate; sleep 0.1; done

#**
# .. function:: copy_to_clipboard
#
# :Optional Arguments: ``[-t]`` - Use an x server to copy to clipboard
# :Input: ``*stdin*`` - String to copy to clipboard
#
# Copy the content of stdin to your local clipboard. Uses OSC 52, which will work as long as your terminal supports it.
#
# ``tmux`` supposts this out of the box, vim needs a plugin: https://github.com/ojroques/vim-oscyank
#
# Verified terminals that support OSC 52:
#
# Works
# * Windows Terminal
# * iterm2
# * "However, xterm supports it, alacritty supports it, hterm and many others..."
# Does not work:
# * gnome-terminal: https://gitlab.gnome.org/GNOME/vte/-/issues/2495
# * konsole?: https://bugs.kde.org/show_bug.cgi?id=372116
# * cygwin terminal
# * putty
# * mintty, it says it did in 2.6.1? I'm not sure: https://github.com/mintty/mintty/issues/258
# * cygwin xterm
# * macOS Terminal
#**
function copy_to_clipboard()
{
  if [ "${1-}" = "-x" ]; then
    # X ways to do it
    if command -v xsel &> /dev/null; then
      xsel -i
    elif command -v xclip &> /dev/null; then
      xclip -sel clip -i
    else
      echo "xsel or xclip not installed" >&2
      return 1
    fi
  elif [ "${1}" = "-t" ] || [ -n "${TMUX:+set}" ] || [[ ${TERM-} = tmux* ]]; then
    echo -e "\033Ptmux;\033\033]52;c;$(base64 | tr -d '\n')\a\033\\"
  # elif [ "${1}" = "-s" ] || [[ ${TERM-} = screen* ]]; then
  # function screen_dcs() {
  # # Screen limits the length of string sequences, so we have to break it up.
  # # Going by the screen history:
  # #   (v4.2.1) Apr 2014 - today: 768 bytes
  # #   Aug 2008 - Apr 2014 (v4.2.0): 512 bytes
  # #   ??? - Aug 2008 (v4.0.3): 256 bytes
  # # Since v4.2.0 is only ~4 years old, we'll use the 256 limit.
  # # We can probably switch to the 768 limit in 2022.
  # local limit=256
  # # We go 4 bytes under the limit because we're going to insert two bytes
  # # before (\eP) and 2 bytes after (\e\) each string.
  # echo "$1" | \
  #   sed -E "s:.{$(( limit - 4 ))}:&\n:g" | \
  #   sed -E -e 's:^:\x1bP:' -e 's:$:\x1b\\:' | \
  #   tr -d '\n'
  # }
  else
    # Todo: Integrate https://chromium.googlesource.com/apps/libapps/+/master/hterm/etc/osc52.sh
    echo -e "\033]52;c;$(base64 | tr -d '\n')\a"
  fi
}

#**
# .. function:: x_forward_to_file
#
# :Arguments: * ``$1`` - The localhost X11 identifier currently being used.
#             * ``$2`` - The local X server being spoofed
#
#  .. rubric:: Example:
#
#  .. code:: bash
#
#     x_forward_to_file 10 1 # localhost:10.0 to :1
#**
function x_forward_to_file()
{
  socat "UNIX-LISTEN:/tmp/.X11-unix/X${2},fork" "TCP:localhost:$((6000+${1}))"
}

####################
### Experimental ###
####################

# function reservegpu()
# {
#   local days
#   local gpu
#   days="${1-}"
#   shift 1

#   while [[ ! ${days} =~ ^[1-9][0-9]*$ ]] || [ "${days}" -lt "1" ] || [ "${days}" -gt 28 ]; do
#     read -p "How many days do you expect to run? (1 - 28) " days
#   done

#   gpu="${1-}"
#   shift 1

#   while [ -n "${1+set}" ]; do
#     reservegpu "${days}" "${1}"
#     shift 1
#   done

#   while [[ ! ${gpu} =~ ^[0-9][0-9]*$ ]] || [ ! -c "/dev/nvidia${gpu}" ]; do
#     read -p "Which gpu are you reserving? ($(echo /dev/nvidia[0-9]* | sed 's|/dev/nvidia||g')) " gpu
#   done

#   if [ -f "/tmp/.longgpu${gpu}" ]; then
#     local owner=$(stat -c %U "/tmp/.longgpu${gpu}")
#     if [ "$(id -un)" != "${owner}" ] && \
#        [ "$(($(date +%s) - $(date +%s -r "/tmp/.longgpu${gpu}" 2>/dev/null || echo 0)))" -lt "0" ]; then
#       echo "Sorry, GPU ${gpu} is reserved by ${owner}. Reservation denied!" >&2
#       return 1
#     fi
#   fi

#   rm -f "/tmp/.longgpu${gpu}"

#   touch -d "+ ${days} days" "/tmp/.longgpu${gpu}"
# }

function ppcd()
{
  popd
  pushd .
}

# if [ "${TERM_PROGRAM-}" = "tmux" ] && [ -z "${TMUX_OWD+set}" ]; then
#   export TMUX_OWD="${PWD}"
#   pushd .
# fi

# In Git for Windows, list all the open VSOCK ports that WSLg is using for graphics... Still can't figure out who is which
# for port in $(powershell "gwmi -Query \"select CommandLine from win32_process where Name='mstsc.exe'\" | Format-List -Property CommandLine" | sed -En 's|.*hvsocketserviceid:([0-9A-F]{8})-.*|\1|p'); do echo -n "$((16#$port))|"; done; echo 0

#**
# .. function:: progress
#
# Like the ``time`` command, only gives you live update on the elapsed time
#
# :Arguments: * ``$1...`` - Command to execute
#
#  .. rubric:: Example:
#
#  .. code:: bash
#
#     progress sleep 10
#**
function progress()
( # This prevents the Done and [1] Pid# printouts; so would disabling job monitoring, but this is easier and more robust
  source ~/.dot/external/dot_core/external/vsi_common/linux/time_tools.bsh
  source ~/.dot/external/dot_core/external/vsi_common/linux/signal_tools.bsh
  set_bashpid

  get_time_nanoseconds > /dev/null # pre-cache
  local dt=0.25

  local ppid="${BASHPID}"

  tic
  {
    while kill -0 "${ppid}" &> /dev/null; do
      #echo -ne "$(toc_ms)\033[0K\r" >&2
      printf '\e]2;%s\e\\' "$(toc_ms)"
      sleep "${dt}"
    done
  } &
  local cpid=$!
  time "${@}"
  kill "${cpid}"
  printf '\e]2;%s\e\\' "$(toc_ms)"
)
