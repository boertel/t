#!/usr/bin/env bash

#set -x

TMUXP="$HOME/.tmuxp"
TMUXP_TEMPLATE="$TMUXP/templates"

function is_js {
    PACKAGE_JSON="$1/./package.json"
    if [[ -e $PACKAGE_JSON ]]; then
        if [[ $(jq ".scripts.start" -- "$PACKAGE_JSON") =~ "react-scripts start" ]]; then
            echo "create-react-app.yaml"
            return 0
        elif [[ $(jq ".scripts.start" -- "$PACKAGE_JSON") =~ "next start" ]]; then
            echo "create-next-app.yaml"
            return 0
        fi
    fi
    return 1
}

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h|--help] [-- path]

Create and attach tmux sessions depending on current location.
If run inside a git repository, it will create or attach to
the same session not matters where you are in the git repositoy

Available options:

-h, --help      Print this help and exit
-- <path>       Run this command on <path>
EOF
    exit
}

msg() {
  echo >&2 -e "${1-}"
}



if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    usage
elif [[ "$1" == "--" && -e "$2" ]]; then
    shift
    PARENT="$1"
elif git rev-parse --is-inside-work-tree &> /dev/null; then
    PARENT="$(git root)"
else
    PARENT="$(pwd)"
fi

CONF="$PARENT/tmuxp.yaml"
SESSION_NAME="$(basename "$PARENT")"
DEST="$TMUXP/$SESSION_NAME.yaml"

if [[ -f "$1" ]]; then
    CMD="tmuxp load $1"
elif [[ -e "$CONF" ]]; then
    CMD="tmuxp load $CONF"
elif [[ -e $DEST ]]; then
    CMD="tmuxp load $SESSION_NAME"
else
    if is_js "$PARENT"; then
        FILENAME="$(is_js "$PARENT")"
        TMUXP_CRA_TEMPLATE="$TMUXP_TEMPLATE/$FILENAME"
        CMD="cp $TMUXP_CRA_TEMPLATE $DEST && sed -i -e s/{{NAME}}/$SESSION_NAME/g $DEST && tmuxp load $SESSION_NAME"
    else
        # join or create a session
        EXISTS=$(tmux ls | cut -d ":" -f 1 | grep "^${SESSION_NAME}$")
        if [[ -z "$EXISTS" ]]; then
            CMD="tmux new -s \"$SESSION_NAME\""
        else
            CMD="tmux attach -t \"$SESSION_NAME\""
        fi
    fi
fi

msg "$CMD"
eval "$CMD"
