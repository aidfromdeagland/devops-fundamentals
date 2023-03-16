#!/bin/bash

FULL_PATH=$(realpath "$0")
CURRENT_DIRECTORY=$(dirname "$FULL_PATH")
DATABASE_PATH_RELATIVE=../data
DATABASE_DIRECTORY="${CURRENT_DIRECTORY}/${DATABASE_PATH_RELATIVE}"
DATABASE_PATH="${CURRENT_DIRECTORY}/${DATABASE_PATH_RELATIVE}/users.db"
SCRIPT_COMMAND="$1"
COMMANDS=(help add backup restore find list help)
declare -A COMMANDS_DESCRIPTION_MAP
COMMANDS_DESCRIPTION_MAP[help]="Prints instructions on how to use this script. You can specify command to get help for"
COMMANDS_DESCRIPTION_MAP[add]="Adds new values to user database(one record consists of two propmts: username, role)."
COMMANDS_DESCRIPTION_MAP[backup]="Creates a new file, named %date%-users.db.backup which is a copy of current users.db."
COMMANDS_DESCRIPTION_MAP[restore]="Takes the last created backup file and replaces users.db with it. If there are no backups - informts about that"
COMMANDS_DESCRIPTION_MAP[find]="Returns all matched entries from user database based on input"
COMMANDS_DESCRIPTION_MAP[list]="Prints content of the users database in structured format. Arg --inverse reverses the order of the output"


isLatin() {
    local VALIDATED_STRING="$1"

    if [[ $VALIDATED_STRING =~ ^[a-zA-Z]+$ ]]; then
        return 0
    else 
        return 1
    fi
}

showGeneralHelp() {
    for key in "${!COMMANDS_DESCRIPTION_MAP[@]}"
        do
            echo "$key":  "${COMMANDS_DESCRIPTION_MAP[$key]}"
        done
}

showHelp() {
    if [ $# -eq 0 ]; then
        showGeneralHelp
    else
        local REQUESTED_COMMAND=$1
        if [[ "${COMMANDS[*]}" =~ ${REQUESTED_COMMAND} ]]; then
            echo "${COMMANDS_DESCRIPTION_MAP[$REQUESTED_COMMAND]}"
        else
            showGeneralHelp
        fi
    fi
}

addUserToDatabase() {
    local userName
    local userRole

    read -p "user name: " userName
    if ! isLatin "$userName"; then
        echo "user name should consists of latin letters only"
        return 1
    fi

    read -p "user role: " userRole
    if ! isLatin "$userRole"; then
        echo "user role should consists of latin letters only"
        return 1
    fi

    echo "$userName, $userRole" >> "$DATABASE_PATH"
}

getUserByName() {
    local userName
    local doesUserExist

    read -p "user name: " userName
    doesUserExist=$(cat "$DATABASE_PATH" | grep -c "^$userName")

    if ! [[ $doesUserExist -eq 0 ]]; then
        cat "$DATABASE_PATH" | grep "$userName"
    else
        echo "there is no user with this name"
    fi
}

showDataBaseContent() {
    if [ "$1" = "--inverse" ]; then
        cat "$DATABASE_PATH" | awk '{print NR". " $1 " " $2}' | perl -e 'print reverse <>'
    else
        cat "$DATABASE_PATH" | awk '{print NR". " $1 " " $2}'
    fi
}

backupDatabase() {
    local backupFileName
    backupFileName="$(date +'%Y_%m_%d_%H_%M')-users.db.backup"

    cat "$DATABASE_PATH" > "$DATABASE_DIRECTORY"/"$backupFileName"
    echo "Backup created: $backupFileName"
}

restoreDatabase() {
    local latestBackup
    latestBackup=$(find "$DATABASE_DIRECTORY" -type f -name "*.backup" | sort -n | tail -1)

    echo "$latestBackup"

    if [ ! "$latestBackup" ]; then
        echo "No backup file found"
    else
        cp -f "$latestBackup" "$DATABASE_PATH"
        echo "database restored based on the latest backup"
    fi
}

case $SCRIPT_COMMAND in
    add) addUserToDatabase;;
    find) getUserByName;;
    list) showDataBaseContent $2;;
    backup) backupDatabase;;
    restore) restoreDatabase;;
    help | '' | *) showHelp $2;;
esac

