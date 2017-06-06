#!/bin/bash

# Default settings
NAME_BACKUP_GIT_REPO="$HOME/openshift-backup-files"
DEBUG_MODE="false"
NAMESPACES=$(echo $(oc get projects -o name | sed 's/^project\///') | sed 's/\s/,/g') # all your namespaces
REMOVE_SECRETS="false"

# Initialize variables
SCRIPTNAME=$(basename $0)

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
     echo "   ${SCRIPTNAME} --namespace=<namespace>,[<namespace>]...  Specify namespaces to backed up."
     echo "   ${SCRIPTNAME} --backup-directory=<path>                 Backup directory path."
     echo "   ${SCRIPTNAME} --remove-secrets=true|false               Remove secrets from backup."
     echo "   ${SCRIPTNAME} --help                                    This help text."
     echo "   ${SCRIPTNAME} --debug                                   Displays debug logging."
     echo "   ${SCRIPTNAME} --version                                 Display version info."
     echo ""
     echo "Defaults:"
     echo "  --namespace=$NAMESPACES"
     echo "  --backup-directory=$NAME_BACKUP_GIT_REPO"
     echo "  --remove-secrets=$REMOVE_SECRETS"
     exit 0
}

function version {
     echo "\n${SCRIPTNAME}, version 0.1, Juni 2017\n"
     exit 0
}

# Parse input parameters
for PARAMETER in "$@" ; do
     #
     # Options
     debug $PARAMETER
     if [[ $PARAMETER == "--help" ]] || [[ $PARAMETER == "-help" ]] || [[ $PARAMETER == "-h" ]]; then
          help
     elif [[ $PARAMETER == "--version" ]] || [[ $PARAMETER == "-version" ]] || [[ $PARAMETER == "-v" ]]; then
          version 
     elif [[ $PARAMETER == "--debug" ]] ; then
          echo "Debug mode on!"
          DEBUG_MODE="true"
     elif [[ $PARAMETER =~ ^--namespaces?=[a-zA-Z,_\-/]{1,}$ ]]; then
          NAMESPACES=$(echo $PARAMETER | sed -r "s/^--namespaces?=//g")
     elif [[ $PARAMETER =~ ^--remove-secrets?=(true|false)$ ]]; then
          REMOVE_SECRETS=$(echo $PARAMETER | sed -r "s/^--remove-secrets?=//g")
     elif [[ $PARAMETER =~ ^--backup-directory=[a-zA-Z0-9_\-\/\.]+$ ]]; then
          NAME_BACKUP_GIT_REPO=$(echo $PARAMETER | sed -r "s/^--backup-directory=//g")
     else
          echo "Parameter '$PARAMETER' is invalid!"
          exit 1
     fi
done

debug "NAMESPACE='$NAMESPACES'"
debug "REMOVE_SECRETS='$REMOVE_SECRETS'"
debug "NAME_BACKUP_GIT_REPO='$NAME_BACKUP_GIT_REPO'"
debug "DEBUG='$DEBUG_MODE'"

# counters
OBJECTCOUNT=0
NEWOBJECTCOUNT=0
MODIFIEDOBJECTCOUNT=0
PROJECTCOUNT=0

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
     git --work-tree="$NAME_BACKUP_GIT_REPO" add "$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE/$OBJECTNAME" 1>/dev/null
     STATUS=$(git --work-tree="$NAME_BACKUP_GIT_REPO" status "$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE/$OBJECTNAME" | grep $OBJECTNAME | awk '{print $2}')
     if [ "$STATUS" == "new" ]; then
          NEWOBJECTCOUNT=$(($NEWOBJECTCOUNT + 1))
           printf "     new object: %-8s, %-30s  %-30s  %-50s" "$NEWOBJECTCOUNT" "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME"
          git --work-tree="$NAME_BACKUP_GIT_REPO" commit -m "$(date): project $PROJECT, object type $OBJECTTYPE, new object name $OBJECTNAME" 1>/dev/null
     elif [ "$STATUS" == "modified" ]; then
          MODIFIEDOBJECTCOUNT=$(($MODIFIEDOBJECTCOUNT + 1))
           printf "modified object: %-8s, %-30s  %-30s  %-50s" "$MODIFIEDOBJECTCOUNT" "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME"
          git --work-tree="$NAME_BACKUP_GIT_REPO" commit -m "$(date): project $PROJECT, object type $OBJECTTYPE, modified object name $OBJECTNAME" 1>dev/null
     else
          printf "unchanged object: %-8s  %-30s  %-30s  %-50s \n" "$OBJECTCOUNT" "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME"
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
rm $GLOBALOBJECTSFILE 2>/dev/null
rm $NAMESPACEOBJECTSFILE 2>/dev/null
touch $GLOBALOBJECTSFILE
touch $NAMESPACEOBJECTSFILE

for PROJECT in $(echo $(oc get project --no-headers | awk '{print $1}' | sort) "GLOBAL")
do
     PROJECTCOUNT=$(($PROJECTCOUNT + 1))
     MAKE_DIRECTORY "$NAME_BACKUP_GIT_REPO/$PROJECT"
     for OBJECTTYPE in $(sed -n -e '/^_oc_get/,/^}/ p' /etc/bash_completion.d/oc | grep -P 'must_have_one_noun\+=\(\"' | sed 's/\s*must_have_one_noun+=("//' | sed 's/")//' | sort -u | grep -v event)
     do
          for OBJECTTYPENAME in `oc get $OBJECTTYPE -n $PROJECT  -o name --no-headers 2>/dev/null| awk '{print $1}' | sort` 
          do
              OBJECTNAME=$(echo $OBJECTTYPENAME | sed "s/^$OBJECTTYPE\///")
              CHECKNAMESPACE=""
              if grep  -q "^$OBJECTTYPE$" $GLOBALOBJECTSFILE ; then 
                   CHECKNAMESPACE=""
              elif grep -q "^$OBJECTTYPE$" $NAMESPACEOBJECTSFILE ; then
                   CHECKNAMESPACE=$PROJECT
              else
                   CHECKNAMESPACE=$(oc describe -n $PROJECT $OBJECTTYPE $OBJECTNAME  2>/dev/null | grep -P '^Namespace:' | awk '{print $2}' | grep  "^$PROJECT$")
                   if [ -z "$CHECKNAMESPACE" ] || [ "$CHECKNAMESPACE" == "" ] ; then
                        echo $OBJECTTYPE >> $GLOBALOBJECTSFILE
                   else
                        echo $OBJECTTYPE >> $NAMESPACEOBJECTSFILE
                   fi
              fi
              if [ -z "$CHECKNAMESPACE" ] || [ "$CHECKNAMESPACE" == "" ] ; then
                   if grep -q "^$OBJECTTYPE$" $GLOBALOBJECTSFILE ; then
                        if [ "$PROJECT" == "GLOBAL" ] ; then
                             MAKE_DIRECTORY "$NAME_BACKUP_GIT_REPO/GLOBAL/$OBJECTTYPE"
                             oc export --raw $OBJECTTYPE $OBJECTNAME > "$NAME_BACKUP_GIT_REPO/GLOBAL/$OBJECTTYPE/$OBJECTNAME"
                             COMMIT_CHANGES "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME" 
                        fi
                   fi
              else
                  MAKE_DIRECTORY "$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE"
                  if [[ $OBJECTTYPE == "secret" ]]; then
                       # Remove secrets
                       oc export --raw -n $PROJECT $OBJECTTYPE $OBJECTNAME \
                          | sed 's/\(token\|openshift.io\/token-secret.value\):.*$/\1: ===Token has been removed due to security risks===/' \
                          | sed 's/.\(ce\?rt\|ca\|certificate\):.*$/.\1: ===Certificate has been removed due to security risks===/' \
                          | sed 's/value:.*$/value: ===Value has been removed due to security risks===/' \
                          | sed 's/key:.*$/key: ===Key has been removed due to security risks===/' \
                          | sed 's/store:.*$/store: ===Store has been removed due to security risks===/' \
                          | sed 's/password:.*$/password: ===Key store has been removed due to security risks===/' \
                          | sed 's/pem:.*$/pem: ===Pem has been removed due to security risks===/' \
                          | sed 's/.dockercfg:.*$/.dockercfg: ===.dockercfg has been removed due to security risks===/' \
                          | sed 's/alias:.*$/alias: ===Alias has been removed due to security risks===/' \
                          > "$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE/$OBJECTNAME"
                  else
                       oc export --raw -n $PROJECT $OBJECTTYPE $OBJECTNAME > "$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE/$OBJECTNAME"
                  fi
                  COMMIT_CHANGES "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME" 
              fi 
          done
     done
done

debug "Number of projects:         $PROJECTCOUNT"
debug "Number of objects:          $OBJECTCOUNT"
debug "Number of new objects:      $NEWOBJECTCOUNTS"
debug "Number of modified objects: $MODIFIEDOBJECTS"
