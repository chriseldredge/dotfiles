SSH_ENV=$HOME/.ssh/environment

if [ -n "$SSH_CONNECTION" ]; then
     return
fi

function start_agent {
     echo -n "Initialising new SSH agent... "
     /usr/bin/ssh-agent > ${SSH_ENV}
     chmod 600 ${SSH_ENV}
     source ${SSH_ENV}
}

if [ -x "${HOME}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh" ]; then
     export SSH_AUTH_SOCK="${HOME}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
elif [ -f "${SSH_ENV}" ]; then
     source ${SSH_ENV} > /dev/null
     #cygwin: ps -efp ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
     ps ${SSH_AGENT_PID} > /dev/null || {
         start_agent;
     }
else
     start_agent;
fi