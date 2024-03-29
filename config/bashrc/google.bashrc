#
# Copyright 2015 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Avoid sourcing bashrc.google more than once for a session as some of
# the commands below are not reentrant.
#if [[ -n "${GOOGLE_BASHRC_SOURCED}" ]]; then
#  return
#fi
GOOGLE_BASHRC_SOURCED=1

START_TIME=$(date +%s%3N)

for FILE in /google/devshell/bashrc.google.d/*; do
  if [ $FILE == "/google/devshell/bashrc.google.d/nvm" ]; then
    # Don't source that file, instead send true.
    true
  elif [ -f "$FILE" ]; then
    source "$FILE"
  fi
done

# Assigns a unique per current session configuration location for Cloud SDK
# tools to isolate independent Developer Shell session from each other.
export CLOUDSDK_CONFIG=$(mktemp -d)

# Makes Cloud SDK use Python3 if the environment variable is set to true.
export CLOUDSDK_PYTHON=python3

# This dir is deleted on devshell session exit by a script installed in
# /google/devshell/bash_exit.google.d/rm_temp_cloudsdk_config.sh
export __TMP_CLOUDSDK_CONFIG=$CLOUDSDK_CONFIG

# Returns a gcloud property by section and name.
# Could parse it from "gcloud config list" output, but invoking gcloud on
# each prompt is impractically slow currently.  Use custom Python for now.
get_gcloud_config_property () {

  # CD to the root directory so we don't pick up unexpected python modules.
  CUR_DIR=`pwd`
  cd /

  SECTION=\'$1\'
  PROPERTY=\'$2\'
  ACTIVE_CONFIG=`cat $CLOUDSDK_CONFIG/active_config`
  python2 <<EOF
import os
import ConfigParser as cp
try:
  config_path = os.environ['CLOUDSDK_CONFIG'] + '/configurations/config_' + "$ACTIVE_CONFIG"
  config = cp.ConfigParser()
  config.read(config_path)
  print config.get($SECTION, $PROPERTY)
except:
  print ""
EOF

  cd $CUR_DIR
}

# Similar to the above, but sets the property.  Passing an empty string for
# the value will remove the property.
set_gcloud_config_property () {

  # CD to the root directory so we don't pick up unexpected python modules.
  CUR_DIR=`pwd`
  cd /

  SECTION=\'$1\'
  PROPERTY=\'$2\'
  VALUE=\'$3\'
  ACTIVE_CONFIG=`cat $CLOUDSDK_CONFIG/active_config`
  python2 <<EOF
import os
import ConfigParser as cp
try:
  config_path = os.environ['CLOUDSDK_CONFIG'] + '/configurations/config_' + "$ACTIVE_CONFIG"
  config = cp.ConfigParser()
  config.read(config_path)
  if not config.has_section($SECTION):
    config.add_section($SECTION)
  if $VALUE:
    config.set($SECTION, $PROPERTY, $VALUE)
  else:
    config.remove_option($SECTION, $PROPERTY)
  with open(config_path, 'w') as configfile:
    config.write(configfile)
except:
  pass
EOF

  cd $CUR_DIR
}

export DEVSHELL_GCLOUD_CONFIG=cloudshell-$RANDOM

# Makes it so `gcloud info --run-diagnostics` doesn't choke on our hidden
# properties
export CLOUDSDK_DIAGNOSTICS_HIDDEN_PROPERTY_WHITELIST=compute/gce_metadata_read_timeout_sec

function setupGcloud() {
  echo -n $DEVSHELL_GCLOUD_CONFIG > $CLOUDSDK_CONFIG/active_config
  if [ ! -d "$CLOUDSDK_CONFIG/configurations" ]; then
    mkdir $CLOUDSDK_CONFIG/configurations
  fi
  touch $CLOUDSDK_CONFIG/configurations/config_$DEVSHELL_GCLOUD_CONFIG

  # Sets the default Cloud SDK session project from Developer Shell environment.
  if [[ -z "${DEVSHELL_PROJECT_ID:-}" ]]; then
    set_gcloud_config_property 'core' 'project' ''
  else
    set_gcloud_config_property 'core' 'project' "${DEVSHELL_PROJECT_ID}"
  fi
}

(setupGcloud &)

# Sets the default port for ASP.NET Core local previews to run on 8080 instead
# of the usual port 5000. This makes it easier to preview a local running .NET
# app in Cloud Shell's Web Preview.
export ASPNETCORE_URLS="http://*:8080"

export HISTSIZE=1000
export HISTFILESIZE=1000
shopt -s histappend

export PS1='\[\e]0;${DEVSHELL_PROJECT_ID:-Cloud Shell}\a\]'
# Prompt that looks like `codr@cloudshell:~/google $`
# or if the project is set `codr@cloudshell:~/google (cool-project) $`
export PS1+='\u@cloudshell:\[\033[1;34m\]\w$([[ -n $DEVSHELL_PROJECT_ID ]] && printf " \[\033[1;33m\](%s)" ${DEVSHELL_PROJECT_ID} )\[\033[00m\]$ '
if [[ -n $TMUX ]]; then
  export PS1+='\[\033k$([[ -n $DEVSHELL_PROJECT_ID ]] && printf "(%s)" ${DEVSHELL_PROJECT_ID} || printf "cloudshell")\033\\\]'
fi

if [[ "${THEIA:-false}" = "true" ]]; then
  export PROMPT_DIRTRIM=2
fi

# Updates DEVSHELL_PROJECT_ID environment variable to the current project ID
# stored in the session configuration area.
update_devshell_project_id () {
  # If the gcloud sentinal file exists, that means a configuration changed.
  # The file will not exists until `gcloud config set` is called.
  if [[ -e $CLOUDSDK_CONFIG/config_sentinel ]]; then
    local project_id
    project_id=$(get_gcloud_config_property 'core' 'project')
    if [[ -z "${project_id}" ]]; then
      unset DEVSHELL_PROJECT_ID
      unset GOOGLE_CLOUD_PROJECT
    else
      export DEVSHELL_PROJECT_ID=${project_id}
      export GOOGLE_CLOUD_PROJECT=$DEVSHELL_PROJECT_ID
    fi

    # rm so we will not read the config each time.
    rm -f $CLOUDSDK_CONFIG/config_sentinel
  fi
}
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ; }"
export PROMPT_COMMAND+="update_devshell_project_id &> /dev/null"

# Flush commands to the history file on every prompt, but skip for the first
# prompt to improve startup performance.
ORIGINAL_PROMPT_COMMAND=$PROMPT_COMMAND
function enableHistoryAppend() {
  export PROMPT_COMMAND="history -a;$ORIGINAL_PROMPT_COMMAND"
}
export PROMPT_COMMAND="enableHistoryAppend &> /dev/null;$ORIGINAL_PROMPT_COMMAND"

onexit () {
  for FILE in /google/devshell/bash_exit.google.d/*; do
    if [ -x "$FILE" ]; then
      "$FILE"
    fi
  done
}
trap onexit EXIT

# Don't have `gcloud app browse` open lynx.
export BROWSER="echo"

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Disable first run experience for dotnet since users won't have permission to
# edit /opt/dotnet.
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

# Setup migctl (migrate CLI)
export PATH=$PATH:/google/migrate/anthos/

# Setup ruby env
export GEM_HOME=$HOME/.gems
export GEM_PATH=$HOME/.gems:/usr/local/lib/ruby/gems/2.7.0/
export PATH=${PATH}:${GEM_HOME}/bin:/usr/local/rvm/bin

# Setup golang env
# Keep this in sync with GOPATH set in /google/devshell/editor/editor_exec.sh
export GOPATH=${HOME}/gopath:/google/gopath
export PATH=${PATH}:${HOME}/gopath/bin:/google/gopath/bin

# Setup sdk env
export SDKMAN_DIR=/usr/local/sdkman/
source /usr/local/sdkman/bin/sdkman-init.sh

export V2V_GCP_V2V_IMAGE=projects/v2v-community/global/images/family/v2v-stable

# Setup docker env
export DOCKER_HOST=unix:///var/run/docker.sock

(gcloud auth configure-docker -q &>/dev/null &)

eval `cloudshell aliases`

# Apply colors to common commands.
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

FINISH_TIME=$(date +%s%3N)
report_timing () {
  if [[ "${CLOUDSHELL_METRICS_DIR:-}" != "" ]]; then
    GOOGLE_BASHRC_LATENCY=$((FINISH_TIME-START_TIME))
    sudo env CLOUDSHELL_METRICS_DIR=$CLOUDSHELL_METRICS_DIR GOOGLE_BASHRC_LATENCY=$GOOGLE_BASHRC_LATENCY \
      bash -c 'cat << EOF > $CLOUDSHELL_METRICS_DIR/google_bashrc_metrics
google_bashrc_time=$GOOGLE_BASHRC_LATENCY
EOF'
    return
  fi
  curl -s "${DEVSHELL_SERVER_URL}/devshell/vmevent?ip=$DEVSHELL_IP_ADDRESS&event=google_bashrc" \
       -H "Devshell-Vm-Ip-Address: $DEVSHELL_IP_ADDRESS" \
       -d type=google_bashrc \
       -d start=${START_TIME} \
       -d finish=${FINISH_TIME} &> /dev/null
}
(report_timing &)
