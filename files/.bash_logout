#!/usr/bin/env false bash

# The watch_ssh_agent function is smarter now, no need to run any checks on logout

# if [ "${SSH_AGENT_STARTED-}" = "1" ]; then
#   kill "${SSH_AGENT_PID}" >& /dev/null
# fi

# if [ "${SSH_AGENT_RUNNING-}" = "1" ]; then
#   if command -v pgrep &> /dev/null; then
#     if (( $(pgrep -u "$(id -u)" bash | wc -l) <= 2 )); then
#       kill "${SSH_AGENT_PID}" >& /dev/null
#     fi
#   #elif
#   else
#     ps -u andy | grep bash |  wc -l
#   fi
# fi
