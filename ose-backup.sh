#!/bin/bash

NAME_BACKUP_GIT_REPO="~/openshift-backup-file"

function MAKE_DIRECTORY {
     DIRECTORY=$1
     if [ ! -d "$DIRECTORY" ] ; then
          mkdir "$DIRECTORY"
     fi
}

function COMMIT_CHANGES {
     $PROJECT=$1
     $OBJECTTYPE=$2
     $OBJECTNAME=$3
     git -C $NAME_BACKUP_GIT_REPO add "$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE/$OBJECTNAME"
}

MAKE_DIRECTORY "$NAME_BACKUP_GIT_REPO"
if [ ! -d "$NAME_BACKUP_GIT_REPO/.git" ]; then
     git -C $NAME_BACKUP_GIT_REPO init
fi

GLOBALOBJECTSFILE="$NAME_BACKUP_GIT_REPO/globalobjects"
NAMESPACEOBJECTSFILE="$NAME_BACKUP_GIT_REPO/namespaceobjects"
rm $GLOBALOBJECTSFILE 2>/dev/null
rm $NAMESPACEOBJECTSFILE 2>/dev/null
touch $GLOBALOBJECTSFILE
touch $NAMESPACEOBJECTSFILE

for PROJECT in $(echo $(oc get project --no-headers | awk '{print $1}' | sort) "GLOBAL")
do
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
                             printf "%-30s  %-30s  %-50s\n" "$PROJECT/GLOBAL" "$OBJECTTYPE" "$OBJECTNAME"
                             oc export --raw $OBJECTTYPE $OBJECTNAME > "$NAME_BACKUP_GIT_REPO/GLOBAL/$OBJECTTYPE/$OBJECTNAME"
                        fi
                   fi
              else
                  MAKE_DIRECTORY "$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE"
                  printf "%-30s  %-30s  %-50s\n" "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME" 
                  oc export --raw -n $PROJECT $OBJECTTYPE $OBJECTNAME > "$NAME_BACKUP_GIT_REPO/$PROJECT/$OBJECTTYPE/$OBJECTNAME"
              fi 
          done
     done
done
