#################
# PATHS/EXPORTS #
#################

export PATH=$PATH:/usr/local/go/bin:~/bin:~/go/bin
export GOPATH=~/go
export TERM=xterm-256color

##########################
# TERMINAL CONFIGURATION #
##########################

bind "set completion-ignore-case on"
stty -ixon #allows forward recursive search
#source ~/.gvm/scripts/gvm

#[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
###########
# ALIASES #
###########

alias ..='cd ..'
alias ...='cd ../..'

alias grep='ggrep --color'

alias bashrc='vim ~/.bash_aliases && . /etc/bashrc && echo Bash config editted and reloaded.'
alias vimrc='vim ~/.vimrc'
alias tmuxrc='vim ~/.tmux.conf && tmux source-file ~/.tmux.conf && echo tmux config editted and reloaded.'

alias sudo='sudo ' #allows sudo to expand aliases.
alias watch='watch ' #allows the same thing
alias psg='ps aux | grep -i'

alias please='sudo $(history -p !!)'

alias tmux='TERM=xterm-256color tmux'

alias g2g{,o}='cd $GOPATH'

####################
# HELPER FUNCTIONS #
####################
#outputs all golang function definitions in a file
#accepts multiple arguments (and hence, glob args)
gofuncs() {
	USAGE="usage: gofuncs FILENAME [FILENAME ...]"
	if [[ -z "$1" ]]
	then
		echo $USAGE && return 1
	fi

	for f in "$@"
	do
		echo $f;
		perl -wanle "print "'$1'" if /^func(.*){/" $f
		echo;
	done

}

##########
# DOCKER #
##########
#alias dps='docker container ps'
alias dps='docker container ps --format "table {{.Names}}\\t{{.Status}}"'

dexec() {
	USAGE="usage: dexec CONTAINER COMMAND [OPTIONS]"

	# needs two args: container we're exec'ing on, and command arg to exec
	if [[ -z "$1" || -z "${@:2}" ]]      #if name of container ($1), or the args we're passing it (${@:2}) are undef
	then
		echo $USAGE && return 1
	fi

	# launches a new docker container
	docker exec -it $1 ${@:2}
}

# Wraps dexec() function: is... lazy. also, shouldn't really
# validate its params for revalidation once it hits dexec
dbash() {
	USAGE="usage: dbash CONTAINER"

	if [ -z "$1" ]
	then
		echo $USAGE && return 1
	fi

	dexec $1 /bin/bash
}

# Stop and delete all containers, delete all images and prune volumes
# shellcheck disable=2046
dnuke() {
	docker kill $(docker ps --quiet)
	docker container prune --force
	docker rmi --force $(docker images --quiet --all)
	docker volume prune --force
}

########
# KOHO #
########
export KOHOAPI_BASE_PATH="${GOPATH}/src/github.com/kohofinancial/kohoapi"
export PROCESSORS_BASE_PATH="${GOPATH}/src/github.com/kohofinancial/processors"
export GO111MODULE=on # uses go modules; allows us to build kohoapi

alias g2k{,oho,ohoapi}='cd $KOHOAPI_BASE_PATH'
alias g2p='cd $PROCESSORS_BASE_PATH'
alias g2src='cd ~/go/src/github.com/kohofinancial/kohoapi/project/src'
alias g2ad='cd ~/go/src/bitbucket.org/koho/kohoadminweb/'

alias kdb='docker exec -it koho_postgres_1 psql koho koho'

# CLI access to bastion boxes
alias bstg='ssh ubuntu@ec2-34-219-19-179.us-west-2.compute.amazonaws.com'
alias bsand='ssh ubuntu@ec2-35-167-211-170.us-west-2.compute.amazonaws.com'

# CLI access to koho DBs
alias dbl='PGPASSWORD= PSQLRC=~/.config/psql/psqlrc_dbl psql service=localdb --quiet'
alias dbs='PGPASSWORD= PSQLRC=~/.config/psql/psqlrc_dbs psql service=stagingdb --quiet'
alias dbsb='PGPASSWORD= PSQLRC=~/.config/psql/psqlrc_dbsb psql service=sandboxdb --quiet'
alias dbr='PGPASSWORD= PSQLRC=~/.config/psql/psqlrc_dbr psql service=proddbreplica --quiet'
alias dbp='PSQLRC=~/.config/psql/psqlrc_dbp psql service=proddb --quiet'

alias pdbs='PGPASSWORD= PSQLRC=~/.config/psql/psqlrc_dbs psql service=pstagingdb --quiet'
alias pdbsb='PGPASSWORD= PSQLRC=~/.config/psql/psqlrc_dbsb psql service=psandboxdb --quiet'

alias erl='psql service=localer --quiet'
alias erp='psql service=proder --quiet'

alias pdbl='PGPASSWORD= PSQLRC=~/.config/psql/psqlrc_dbl psql service=processorsdb --quiet'

src() {
	BASE_PATH="$KOHOAPI_BASE_PATH"

	TARGET_PATH="project/src/$1"
	FULL_PATH="$BASE_PATH/$TARGET_PATH"

	if [[ ! -d "$FULL_PATH" ]]
	then
		echo "couldn't find $TARGET_PATH (full path: $FULL_PATH)" && return 1
	fi

	cd $FULL_PATH
}

getdbpass() {
	# shellcheck disable=SC1004
	PGPASSWORD=$(
		aws rds generate-db-auth-token \
			--hostname postgres-9-6-prod-v2.csjphcki1km6.us-west-2.rds.amazonaws.com \
			--port 5432 \
			--region us-west-2 \
			--username koho_script_runner \
			--profile kohodba
	)
	export PGPASSWORD
	printf '%s' "$PGPASSWORD" | pbcopy
}

shortlink() {
	curl --location --request POST "https://link.koho.app/shorturl" --form "url=$1"
}

# Open an SSH tunnel for databases
tunnel() {
	local db dbname bastion hostip
	db=$1
	case $db in
		dbs)
			dbname='stagingdb'
			bastion='stagingbastion'
			;;
		dbsb)
			dbname='sandboxdb'
			bastion='sandboxbastion'
			;;
		pdbs)
			dbname='pstagingdb'
			bastion='stagingbastion'
			;;
		pdbsb)
			dbname='psandboxdb'
			bastion='sandboxbastion'
			;;
		#ers)
		#	dbname='staginger'
		#	bastion='stagingbastion'
		#	;;
		#ersb)
		#	dbname='sandboxer'
		#	bastion='sandboxbastion'
		#	;;
		*)
			echo "invalid DB name $db" >&2
			return 1
			;;
	esac

	hostip=$(dig +short "$(awk -v d="$dbname" '$3 == d { print $2 }' /etc/hosts)")

	ssh -L localhost:5432:"$hostip":5432 "$bastion"
}
complete -W 'dbs dbsb pdbs pdbsb' tunnel
#complete -W 'dbs ers dbsb ersb' tunnel


function aws_signin() {
    MFA_SERIAL_NUMBER="arn:aws:iam::509657956559:mfa/mohammad"
    read -sp "Enter MFA Code: " MFA_CODE
    echo

    [[ -e ~/.aws/credentials ]] && rm -f ~/.aws/credentials

    ROLE_ARN="arn:aws:iam::917738755337:role/ProductionDeveloperRole"
    AWS_GST_RES=$(aws sts assume-role --role-session-name "staging" --role-arn ${ROLE_ARN} --duration-seconds 3600 --serial-number="${MFA_SERIAL_NUMBER}" --token-code="${MFA_CODE}")
    export AWS_ACCESS_KEY_ID=$(jq -r .Credentials.AccessKeyId <<< "$AWS_GST_RES")
    export AWS_SECRET_ACCESS_KEY=$(jq -r .Credentials.SecretAccessKey <<< "$AWS_GST_RES")
    export AWS_SESSION_TOKEN=$(jq -r .Credentials.SessionToken <<< "$AWS_GST_RES")

    cat >~/.aws/credentials <<EOF
    [default]
    aws_access_key_id=${AWS_ACCESS_KEY_ID}
    aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
    aws_session_token=${AWS_SESSION_TOKEN}
EOF

    chmod 400 ~/.aws/credentials
}

function aws_docker_login() {
    aws --profile=production ecr get-login-password \
        | docker login --username AWS --password-stdin 917738755337.dkr.ecr.us-west-2.amazonaws.com
}
