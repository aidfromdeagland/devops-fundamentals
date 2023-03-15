#!/bin/bash

DATABASE_PATH='../data/users.db'
SCRIPT_COMMAND="$1"
SCRIPT_COMMAND_ARGUMENT="$2"

declare -A COMMANDS_DESCRIPTION_MAP
COMMANDS_DESCRIPTION_MAP[help]="Prints instructions on how to use this script. You can specify command to get help for"
COMMANDS_DESCRIPTION_MAP[add]="Adds new values to user database(one record consists of two propmts: username, role)."
COMMANDS_DESCRIPTION_MAP[backup]="Creates a new file, named %date%-users.db.backup which is a copy of current users.db."
COMMANDS_DESCRIPTION_MAP[restore]="Takes the last created backup file and replaces users.db with it. If there are no backups - informts about that"
COMMANDS_DESCRIPTION_MAP[find]="Returns all matched entries from user database based on input"
COMMANDS_DESCRIPTION_MAP[list]="Prints content of the users database in structured format. Arg --inverse reverses the order of the output"

validateLatin() {
    local VALIDATED_STRING="$1"
    if [[ $VALIDATED_STRING =~ ^[a-zA-Z]+$ ]]; then
        return 1
    else 
        return 0
    fi
}

showHelp() {
    if [ $# -eq 0 ]; then
    for key in "${!COMMANDS_DESCRIPTION_MAP[@]}"
        do
            echo "$key":  "${COMMANDS_DESCRIPTION_MAP[$key]}"
        done
    else
        local REQUESTED_COMMAND=$1
        echo "${COMMANDS_DESCRIPTION_MAP[$REQUESTED_COMMAND]}"
    fi
}

