#!/bin/bash

set -e

function usage() {
    cat <<USAGE
    Usage: $0 <options>
    Options:
        [-p|--functionapp-path] Function app path, relative to the repository root. It can be the project directory or compiled app directory.
                                Default: '.'
        [-u|--base-uri]         Base URI of the function app.
                                Default: 'http://localhost:7071/api/'
        [-e|--endpoint]         OpenAPI document endpoint.
                                Default: 'swagger.json'
        [-d|--delay]            Delay in second between the function app run and document generation.
                                Default: 30
        [-c|--use-codespaces]   Switch indicating whether to use GitHub Codespaces or not.
        [-h|--help]             Show this message.
USAGE

    exit 1
}

functionapp_path="."
base_uri="http://localhost:7071/api/"
endpoint="swagger.json"
delay=30
repository_root=$GITHUB_WORKSPACE

if [[ $# -eq 0 ]]; then
    functionapp_path="."
    base_uri="http://localhost:7071/api/"
    endpoint="swagger.json"
    delay=30
    repository_root=$GITHUB_WORKSPACE
fi

while [[ "$1" != "" ]]; do
    case $1 in
    -p | --functionapp-path)
        shift
        functionapp_path=$1
        ;;

    -u | --base-uri)
        shift
        base_uri=$1
        ;;

    -e | --endpoint)
        shift
        endpoint=$1
        ;;

    -d | --delay)
        shift
        delay=$1
        ;;

    -c | --use_codespaces)
        repository_root=$CODESPACE_VSCODE_FOLDER
        ;;

    -h | --help)
        usage
        exit 1
        ;;

    *)
        usage
        exit 1
        ;;
    esac

    shift
done

current_directory=$(pwd)

cd "$repository_root/$functionapp_path"

# Run the function app in the background
func start --verbose false &

sleep $delay

request_uri="$(echo "$base_uri" | sed 's:/*$::')/$(echo "$endpoint" | sed 's:^/*::')"

# Download the OpenAPI document
openapi=$(curl $request_uri)

# Stop the function app
PID=$(lsof -nP -i4TCP:7071 | grep LISTEN | awk '{print $2}')
if [[ "" !=  "$PID" ]]; then
    kill -9 $PID
fi

cd $current_directory

echo $openapi
