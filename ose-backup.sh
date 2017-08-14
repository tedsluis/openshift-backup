#!/bin/bash

# Default backup direcory:
NAME_BACKUP_GIT_REPO="$HOME/openshift-backup-files"
# Debug mode:
DEBUG_MODE="false"
# Remove tokens, certificates, passwords, keys, etc from secrets:
REMOVE_SECRETS="false"
# Specify object types that should be ignored (seperated by commas):
IGNORE_OBJECTTYPES="event"
# Backup global objects
BACKUP_GLOBALOBJECTS="false"
# (Part of) objectname:
OBJECTNAMEPART=""

# Check login OpenShift
LOGIN=$(oc whoami)
if [[ $? > 0 ]]; then
     exit 1
fi

# Path to oc completion file for object types
CURRENT_DIRECTORY=$(pwd)
OC_COMPLETION_FILE="/etc/bash_completion.d/oc"
if [ ! -f "$OC_COMPLETION_FILE" ]; then
     if [ ! -f "$CURRENT_DIRECTORY/oc" ]; then
          echo "No '$OC_COMPLETION_FILE' or '$CURRENT_DIRECTORY/oc' file found. Can not continue!"
          exit 1
     fi
     echo "No '$OC_COMPLETION_FILE' file found. Now using '$CURRENT_DIRECTORY/oc' to get object types."
     OC_COMPLETION_FILE="$CURRENT_DIRECTORY/oc"
fi

# Get all your namespaces:
NAMESPACES=$(echo $(oc get projects -o name | sed 's/^project\///' | \
                                              sort -u) | \
                                              sed 's/\s/,/g')
# Get all object types:
OBJECTTYPES=$(echo $(sed -n -e '/^_oc_get/,/^}/ p' "$OC_COMPLETION_FILE" | \
                     grep -P 'must_have_one_noun\+=\(\"' | \
                     sed 's/\s*must_have_one_noun+=("//' | \
                     sed 's/")//' | \
                     sort -u) | \
                     sed 's/\s/,/g')

# Initialize variables
SCRIPTNAME=$(basename "$0")

function debug {
     TEXT=$1
     if [[ $DEBUG_MODE == "true" ]]; then
          echo "DEBUG: $TEXT"
     fi
}

function help {
     echo ""
     echo "OpenShift objects backup tool"
     echo ""
     echo "Usage:"
     echo "  ${SCRIPTNAME} --namespace=<namespace>,[<namespace>]...            Specify namespaces to backed up."
     echo "  ${SCRIPTNAME} --backup-global-objects=[true]|[false]              Backup global objects (no namespace)."
     echo "  ${SCRIPTNAME} --object-type=<objecttype>,[<objecttype>]...        Specify object types to be backed up."
     echo "  ${SCRIPTNAME} --ignore-object-type=<objecttype>,[<objecttype>]... Specify object types to be ignored."
     echo "  ${SCRIPTNAME} --object-name=<[part of ]objectname>                Part of object name."
     echo "  ${SCRIPTNAME} --backup-directory=<path>                           Backup directory path."
     echo "  ${SCRIPTNAME} --remove-secrets=[true]|[false]                     Remove secrets from backup."
     echo "  ${SCRIPTNAME} --help                                              This help text."
     echo "  ${SCRIPTNAME} --debug                                             Displays debug logging."
     echo "  ${SCRIPTNAME} --version                                           Display version info."
     echo ""
     echo "Examples:"
     echo "  ${SCRIPTNAME} --namespace=myapp --object-name=app2 --remove-secrets=true"
     echo "  ${SCRIPTNAME} --backup-global-objects=true --ignore-object-type=events,pods --remove-secrets=true"
     echo ""
     echo "Defaults:"
     echo "  --namespace=$NAMESPACES"
     echo "  --backup-global-objects=$BACKUP_GLOBALOBJECTS"
     echo "  --backup-directory=$NAME_BACKUP_GIT_REPO"
     echo "  --remove-secrets=$REMOVE_SECRETS"
     echo "  --object-name=$OBJECTNAMEPART"
     echo "  --ignore-object-type=$IGNORE_OBJECTTYPES"
     echo "  --object-type=$OBJECTTYPES"
     echo ""
     exit 0
}

function version {
     echo ""
     echo "${SCRIPTNAME}, version 0.1, Juni 2017"
     echo ""
     exit 0
}

# Parse input parameters
for PARAMETER in "$@" ; do
     #
     # options
     if [[ $PARAMETER == "--help" ]] || [[ $PARAMETER == "-help" ]] || [[ $PARAMETER == "-h" ]]; then
          help
     elif [[ $PARAMETER == "--version" ]] || [[ $PARAMETER == "-version" ]] || [[ $PARAMETER == "-v" ]]; then
          version 
     elif [[ $PARAMETER == "--debug" ]] ; then
          debug "Debug mode is on!"
          DEBUG_MODE="true"
     elif [[ $PARAMETER =~ ^--namespaces?=[0-9a-zA-Z,\._\-]{1,}$ ]]; then
          NAMESPACES=$(echo "$PARAMETER" | sed -r "s/^--namespaces?=//g")
          debug "--namespace=$NAMESPACES"
     elif [[ $PARAMETER =~ ^--backup-global-objects?=(true|false)$ ]]; then
          BACKUP_GLOBALOBJECTS=$(echo "$PARAMETER" | sed -r "s/^--backup-global-objects?=//g")
          debug "--backup-global-object=$BACKUP_GLOBALOBJECTS"
     elif [[ $PARAMETER =~ ^--object-types?=[a-zA-Z,]{1,}$ ]]; then
          OBJECTTYPES=$(echo "$PARAMETER" | sed -r "s/^--object-types?=//g")
          debug "--object-type=$OBJECTTYPES"
     elif [[ $PARAMETER =~ ^--ignore-object-types?=[a-zA-Z,]{1,}$ ]]; then
          IGNORE_OBJECTTYPES=$(echo "$PARAMETER" | sed -r "s/^--ignore-object-types?=//g")
          debug "--ignore-object-type=$IGNORE_OBJECTTYPES"
     elif [[ $PARAMETER =~ ^--object-name?=[0-9a-zA-Z,\._\-]{1,}$ ]]; then
          OBJECTNAMEPART=$(echo "$PARAMETER" | sed -r "s/^--object-name?=//g")
          debug "--object-name=$OBJECTNAMEPART"
     elif [[ $PARAMETER =~ ^--remove-secrets?=(true|false)$ ]]; then
          REMOVE_SECRETS=$(echo "$PARAMETER" | sed -r "s/^--remove-secrets?=//g")
          debug "--remove-secret=$REMOVE_SECRETS"
     elif [[ $PARAMETER =~ ^--backup-directory=[a-zA-Z0-9_\-\/\.]+$ ]]; then
          NAME_BACKUP_GIT_REPO=$(echo "$PARAMETER" | sed -r "s/^--backup-directory=//g")
          debug "--backup-directory=$NAME_BACKUP_GIT_REPO"
     else
          echo "Parameter '$PARAMETER' is invalid!"
          exit 1
     fi
done

debug "NAMESPACE='$NAMESPACES'"
debug "BACKUP_GLOBALOBJECTS='$BACKUP_GLOBALOBJECTS'"
debug "REMOVE_SECRETS='$REMOVE_SECRETS'"
debug "NAME_BACKUP_GIT_REPO='$NAME_BACKUP_GIT_REPO'"
debug "DEBUG='$DEBUG_MODE'"
debug "OBJECTNAMEPART='$OBJECTNAMEPART'"
debug "IGNORE_OBJECTTYPES='$IGNORE_OBJECTTYPES'"
debug "OBJECTTYPES='$OBJECTTYPES'"

# counters
OBJECTCOUNT=0
NEWOBJECTCOUNT=0
MODIFIEDOBJECTCOUNT=0
PROJECTCOUNT=0
OBJECTCOUNTPROJECT=0
NEWOBJECTCOUNTPROJECT=0
MODIFIEDOBJECTCOUNTPROJECT=0


# Create directory if not exists
function MAKE_DIRECTORY {
     DIRECTORY=$1
     if [ ! -d "$DIRECTORY" ] ; then
          mkdir -p "$DIRECTORY"
          debug "Create directory '$DIRECTORY'."
     fi
}

# Git add & commit new and modified files
function COMMIT_CHANGES {
     PROJECT=$1
     OBJECTTYPE=$2
     OBJECTNAME=$3
     OBJECTCOUNT=$(($OBJECTCOUNT + 1))
     OBJECTCOUNTPROJECT=$(($OBJECTCOUNTPROJECT + 1))
     OPTIONS="--git-dir=${NAME_BACKUP_GIT_REPO}/.git --work-tree=${NAME_BACKUP_GIT_REPO}"
     OBJECT="$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE/$OBJECTNAME"
     # Add object file to repo and get status (new, modified, unchanged)
     git ${OPTIONS} add ${OBJECT} 1>/dev/null
     STATUS=$(git ${OPTIONS} status ${OBJECT} \
                  | grep -P "(new\sfile:|modified:)" \
                  | grep "$OBJECTNAME" \
                  | sed 's/:.*$//' \
                  | sed 's/file//' \
                  | sed 's/ //g' )
     debug "2: PROJECT=$PROJECT, OBJECTTYPE=$OBJECTTYPE, OBJECTNAME=$OBJECTNAME, STATUS=$STATUS."
     if [[ $STATUS =~ new ]]; then
          NEWOBJECTCOUNT=$(($NEWOBJECTCOUNT + 1))
          NEWOBJECTCOUNTPROJECT=$(($NEWOBJECTCOUNTPROJECT + 1))
          printf "      new objects: %-8s  %-30s  %-50s\n" "$NEWOBJECTCOUNTPROJECT" "$OBJECTTYPE" "$OBJECTNAME"
          git ${OPTIONS} commit -m "$(date): project $PROJECT, object type $OBJECTTYPE, new object name $OBJECTNAME" 1>/dev/null
     elif [[ $STATUS =~ modified ]]; then
          MODIFIEDOBJECTCOUNT=$(($MODIFIEDOBJECTCOUNT + 1))
          MODIFIEDOBJECTCOUNTPROJECT=$(($MODIFIEDOBJECTCOUNTPROJECT + 1))
          printf " modified objects: %-8s  %-30s  %-50s\n" "$MODIFIEDOBJECTCOUNTPROJECT" "$OBJECTTYPE" "$OBJECTNAME"
          git ${OPTIONS} commit -m "$(date): project $PROJECT, object type $OBJECTTYPE, modified object name $OBJECTNAME" 1>/dev/null
     elif [[ $DEBUG_MODE == "true" ]]; then
          printf "unchanged objects: %-8s  %-30s  %-50s \n" "$OBJECTCOUNTPROJECT" "$OBJECTTYPE" "$OBJECTNAME"
     else
          echo -en "processing objects: $OBJECTCOUNTPROJECT \r"
     fi
}

# Create backup repo if not exists
MAKE_DIRECTORY "$NAME_BACKUP_GIT_REPO"
cd "$NAME_BACKUP_GIT_REPO"
if [ ! -d "$NAME_BACKUP_GIT_REPO/.git" ]; then
     git init
fi

# House keeping 
GLOBALOBJECTSFILE="$NAME_BACKUP_GIT_REPO/globalobjects"
NAMESPACEOBJECTSFILE="$NAME_BACKUP_GIT_REPO/namespaceobjects"
rm "$GLOBALOBJECTSFILE" 2>/dev/null
rm "$NAMESPACEOBJECTSFILE" 2>/dev/null
touch "$GLOBALOBJECTSFILE"
touch "$NAMESPACEOBJECTSFILE"

# turn variables into regular expressions: convert commas into pipes
NAMESPACES=$(echo  "$NAMESPACES"  | sed 's/,/$|^/g')
OBJECTTYPES=$(echo "$OBJECTTYPES" | sed 's/,/$|^/g')
IGNORE_OBJECTTYPES=$(echo "$IGNORE_OBJECTTYPES" | sed 's/,/$|^/g')
OBJECTNAMEPART=$(echo "$OBJECTNAMEPART" | sed 's/^\s*$/.*/')
BACKUP_GLOBALOBJECTS=$(echo "$BACKUP_GLOBALOBJECTS" | sed 's/true/GLOBAL/' | sed 's/false//')

debug "namespace regular expression:   ^$NAMESPACES$"
debug "object type regular expression: ^$OBJECTTYPES$"
debug "ignore object type regular expression: ^$IGNORE_OBJECTTYPES$"
debug "object name part regular expression: $OBJECTNAMEPART"
debug "backup global objects: $BACKUP_GLOBALOBJECTS"

for PROJECT in $(echo $(oc get project --no-headers | awk '{print $1}' | \
                                                      grep -P "(^$NAMESPACES$)" | \
                                                      sort) "$BACKUP_GLOBALOBJECTS")
do
     echo -e "\n$PROJECT:"
     # counters
     OBJECTCOUNTPROJECT=0
     NEWOBJECTCOUNTPROJECT=0
     MODIFIEDOBJECTCOUNTPROJECT=0
     PROJECTCOUNT=$(($PROJECTCOUNT + 1))
     MAKE_DIRECTORY "$NAME_BACKUP_GIT_REPO/$PROJECT"
     for OBJECTTYPE in $(sed -n -e '/^_oc_get/,/^}/ p' "$OC_COMPLETION_FILE" | \
                         grep -P 'must_have_one_noun\+=\(\"' | \
                         sed 's/\s*must_have_one_noun+=("//' | \
                         sed 's/")//' | \
                         sort -u | \
                         grep -vP "(^$IGNORE_OBJECTTYPES$)" | \
                         grep -P "(^$OBJECTTYPES$)" )
     do
          for OBJECTTYPENAME in `oc get "$OBJECTTYPE" -n "$PROJECT"  -o name --no-headers 2>/dev/null| awk '{print $1}' \
                                                                                                     | grep -P "$OBJECTNAMEPART" \
                                                                                                     | sort` 
          do
		  OBJECTNAME=$(echo "$OBJECTTYPENAME" | sed "s/^$OBJECTTYPE\///" | sed "s/^.*\/(.*)$/\1/")
              # Check if this object type is GLOBAL or belongs to a namespace
              CHECKNAMESPACE=""
              # Namespace or project:
              if [[ "$OBJECTTYPE" == "namespace" ]] || [[ "$OBJECTTYPE" == "project" ]]; then
                   if [[ "$OBJECTNAME" != "$PROJECT" ]]; then
                        continue
                   fi
                   CHECKNAMESPACE=$PROJECT
              # try to match object type with GLOBAL object type cache file
              elif grep  -q "^$OBJECTTYPE$" "$GLOBALOBJECTSFILE" ; then 
                   CHECKNAMESPACE=""
              # try to match object type with NAMESPACE object type cache file
              elif grep -q "^$OBJECTTYPE$" "$NAMESPACEOBJECTSFILE" ; then
                   CHECKNAMESPACE=$PROJECT
              # Find out whether this object type has a namespace
              else
                   CHECKNAMESPACE=$(oc describe -n "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME"  2>/dev/null | grep -P '^Namespace:' | \
                                                                                                         awk '{print $2}' | \
                                                                                                         grep  "^$PROJECT$")
                   # Store object types as cache
                   if [ -z "$CHECKNAMESPACE" ] || [ "$CHECKNAMESPACE" == "" ] ; then
                        # GLOBAL object type
                        echo "$OBJECTTYPE" >> "$GLOBALOBJECTSFILE"
                   else
                        # NAMESPACE object type
                        echo "$OBJECTTYPE" >> "$NAMESPACEOBJECTSFILE"
                   fi
              fi
              debug "1: PROJECT=$PROJECT, CHECKNAMESPACE=$CHECKNAMESPACE, OBJECTTYPE=$OBJECTTYPE, OBJECTNAME=$OBJECTNAME"
              if [ -z "$CHECKNAMESPACE" ] || [ "$CHECKNAMESPACE" == "" ] ; then
                   # Must be a GLOBAL object type (none namespace)
                   if grep -q "^$OBJECTTYPE$" "$GLOBALOBJECTSFILE" ; then
                        if [ "$PROJECT" == "GLOBAL" ] ; then
                             MAKE_DIRECTORY "$NAME_BACKUP_GIT_REPO/GLOBAL/$OBJECTTYPE"
                             oc export --raw $OBJECTTYPE $OBJECTNAME > "$NAME_BACKUP_GIT_REPO/GLOBAL/$OBJECTTYPE/$OBJECTNAME"
                             COMMIT_CHANGES "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME" 
                        fi
                   fi
              else
                  # Object type belongs to a namespace
                  MAKE_DIRECTORY "$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE"
                  if [[ "$OBJECTTYPE" == "secret" ]]; then
                       # Remove secrets
                       oc export --raw -n "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME" \
                          | sed 's/\(token\|openshift.io\/token-secret.value\):.*$/\1: ===Token has been removed due to security risks===/' \
                          | sed 's/\(ce\?rt\|ca\|certificate\):.*$/.\1: ===Certificate has been removed due to security risks===/' \
                          | sed 's/value:.*$/value: ===Value has been removed due to security risks===/' \
                          | sed 's/key:.*$/key: ===Key has been removed due to security risks===/' \
                          | sed 's/store:.*$/store: ===Store has been removed due to security risks===/' \
                          | sed 's/password:.*$/password: ===Key store has been removed due to security risks===/' \
                          | sed 's/pem:.*$/pem: ===Pem has been removed due to security risks===/' \
                          | sed 's/.dockercfg:.*$/.dockercfg: ===.dockercfg has been removed due to security risks===/' \
                          | sed 's/alias:.*$/alias: ===Alias has been removed due to security risks===/' \
                          > "$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE/$OBJECTNAME"
                  else
                       oc export --raw -n "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME" > "$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE/$OBJECTNAME"
                  fi
                  COMMIT_CHANGES "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME"
              fi
          done
     done
     echo "---------------------------------------------------"
     echo "Number of objects in this namespace:          $OBJECTCOUNTPROJECT"
     echo "Number of new objects in this namespace:      $NEWOBJECTCOUNTPROJECT"
     echo "Number of modified objects in this namespace: $MODIFIEDOBJECTCOUNTPROJECT"
done
echo -e "\nTotal:"
echo "---------------------------------------------------"
echo "Number of namespaces matched: $PROJECTCOUNT"
echo "Number of objects matched:    $OBJECTCOUNT"
echo "Number of new objects:        $NEWOBJECTCOUNT"
echo "Number of modified objects:   $MODIFIEDOBJECTCOUNT"
