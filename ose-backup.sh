#!/bin/bash

function MAKE_DIRECTORY {
     DIRECTORY=$1
     if [ ! -d "$DIRECTORY" ] ; then
          mkdir "$DIRECTORY"
     fi
}

for PROJECT in $(echo $(oc get project --no-headers | awk '{print $1}' | sort) "GLOBAL")
do
     MAKE_DIRECTORY "$PROJECT"
     for OBJECTTYPE in $(sed -n -e '/^_oc_get/,/^}/ p' /etc/bash_completion.d/oc | grep -P 'must_have_one_noun\+=\(\"' | sed 's/\s*must_have_one_noun+=("//' | sed 's/")//' | sort -u | grep -v event)
     do
          for OBJECTTYPENAME in `oc get $OBJECTTYPE -n $PROJECT  -o name --no-headers 2>/dev/null| awk '{print $1}' | sort` 
          do
              OBJECTNAME=$(echo $OBJECTTYPENAME | sed "s/^$OBJECTTYPE\///")
              CHECKNAMESPACE=""
              if grep  -q "^$OBJECTTYPE$" globalobjects ; then 
                   CHECKNAMESPACE=""
              elif grep -q "^$OBJECTTYPE$" namespaceobjects ; then
                   CHECKNAMESPACE=$PROJECT
              else
                   CHECKNAMESPACE=$(oc describe -n $PROJECT $OBJECTTYPE $OBJECTNAME  2>/dev/null | grep -P '^Namespace:' | awk '{print $2}' | grep  "^$PROJECT$")
                   if [ -z "$CHECKNAMESPACE" ] || [ "$CHECKNAMESPACE" == "" ] ; then
                        echo $OBJECTTYPE >> globalobjects
                   else
                        echo $OBJECTTYPE >> namespaceobjects
                   fi
              fi
              if [ -z "$CHECKNAMESPACE" ] || [ "$CHECKNAMESPACE" == "" ] ; then
                   if grep -q "^$OBJECTTYPE$" globalobjects ; then
                        if [ "$PROJECT" == "GLOBAL" ] ; then
                             MAKE_DIRECTORY "GLOBAL/$OBJECTTYPE"
                             printf "%-30s  %-30s  %-50s\n" "$PROJECT/GLOBAL" "$OBJECTTYPE" "$OBJECTNAME"
                             oc export --raw $OBJECTTYPE $OBJECTNAME > "GLOBAL/$OBJECTTYPE/$OBJECTNAME"
                        fi
                   fi
              else
                  MAKE_DIRECTORY "$PROJECT/$OBJECTTYPE"
                  printf "%-30s  %-30s  %-50s\n" "$PROJECT" "$OBJECTTYPE" "$OBJECTNAME" 
                  #if [ $OBJECTTYPE == "pod" ]; then
                  #     OBJECTNAME=$(echo $OBJECTNAME | sed 's/\(pizza-session\)-[0-9]\+-build/\1-build/' | sed 's/\(pizza-session\)-\([0-9]\+\)-[a-z][a-z][a-z][a-z][a-z]$/\1-\2/')
                  #fi
                  oc export --raw -n $PROJECT $OBJECTTYPE $OBJECTNAME > "$PROJECT/$OBJECTTYPE/$OBJECTNAME"
              fi 
          done
     done
done
