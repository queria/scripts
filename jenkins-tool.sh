#!/bin/bash

### Example usage:
###  jenkins-tool.sh enable special-jobs [--do]
###   ~ enables all .*special-jobs.* on local(host) jenkins
###  jenkins-tool.sh -j stage queue [pattern] [--do]
###   ~ remove all (without pattern) job runs currently waiting in the queue on 'stage' jenkins
###
###
### Example config file:
### cat ~/.jenkins-tool.conf
###
### CLIOPTS="your-proxy:port"  # for all connections/servers
### JENKINS_local=http://localhost/jenkins
### CLIOPTS_local="-i $HOME/.ssh/id_rsa"
### JENKINS_stage="https://stage.jenkins.company.example.org:88/"
### CLIOPTS_stage="-noCertificateCheck -noKeyAuth"



set -e

PREVIEW="${PREVIEW:-true}"
SEARCHFOR="${SEARCHFOR:-}"
ACTION="${ACTION:-}"

JENKINS_local="http://localhost/"
JENKINS="${JENKINS:-local}"
CLIOPTS="${CLIOPTS:-}"

[[ -f $HOME/.jenkins-tool.conf ]] && source $HOME/.jenkins-tool.conf

while [[ $# -gt 0 ]]; do
    case $1 in
        enable)
            ACTION=enable
            ;;
        disable)
            ACTION=disable
            ;;
        queue)
            ACTION=queue
            ;;
        -j|--jenkins)
            shift
            JENKINS=$1
            ;;
        --do)
            PREVIEW="false"
            ;;
        *)
            SEARCHFOR="$1"
            ;;
    esac
    shift
done

URLVAR="JENKINS_${JENKINS}"
URL="${!URLVAR}"
if [[ -z "${URL}" ]]; then
    echo "$URLVAR does not contain jenkins base url!" >&2
    exit 1
else
    echo "Using jenkins $URL"
fi
OPTSVAR="CLIOPTS_${JENKINS}"
EXTRAOPTS="${!OPTSVAR}"
EXTRAOPTS="$CLIOPTS $EXTRAOPTS"

if [[ "$PREVIEW" = "true" ]]; then
    echo "Just preview, use --do to act. execute the change."
elif [[ -z "$SEARCHFOR" ]]; then
    read -p "Empty pattern, really run on all items? [yN]: " ANSWER
    [[ "$ANSWER" != "y" ]] && exit 0
fi

SCRIPT="$(mktemp)"
trap "rm -f $SCRIPT" EXIT


if [[ "$ACTION" = "enable" || "$ACTION" = "disable" ]]; then
    DISABLED="false"
    [[ "$ACTION" = "disable" ]] && DISABLED="true"

    cat > $SCRIPT <<EOF
for(item in hudson.model.Hudson.instance.items) {
    if( "${SEARCHFOR}" == "" || item.name.indexOf("${SEARCHFOR}") >= 0 ) {
        println("Disable=${DISABLED} (was " + item.disabled + ") for " + item.name + " was " + item.disabled)
        if( ! $PREVIEW ) {
            item.disabled = ${DISABLED}
            item.save()
        }
    }
}
EOF

elif [[ "$ACTION" = "queue" ]]; then
    cat > $SCRIPT <<EOF
    q = hudson.model.Hudson.instance.queue
    q.items.findAll {
      it.task.name.indexOf("$SEARCHFOR") >= 0
    }.each {
        if( ! $PREVIEW ) {
            q.cancel(it.task);
            print("Canceled " + it.task.name);
        } else {
            print("Would cancel " + it.task.name);
        }
    }
EOF
fi

CLIDIR=${CLIDIR:-"$HOME/.cache/jenkins-tool"}
if [[ ! -d "$CLIDIR" ]]; then
    mkdir -p "$CLIDIR"
fi

CLI="$CLIDIR/$JENKINS-cli.jar"
if [[ ! -x "$CLI" ]]; then
    echo "Fetching cli.jar"
    CLIURL="$URL/jnlpJars/jenkins-cli.jar"
    curl -o "$CLI" "$CLIURL"
    chmod +x "$CLI"
fi
if ! head -n2 "$CLI" | grep -q 'META-INF/PK'; then
    echo "$CLI from ${CLIURL:-??} does not look like jar file!" >&2
    exit 1
fi

java -jar "$CLI" $EXTRAOPTS -s $URL groovy $SCRIPT
