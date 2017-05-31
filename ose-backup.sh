#!/bin/bash

for PROJECT in `oc get project --no-headers | awk '{print $1}' `
     do
     if [ ! -d "$PROJECT" ] ; then
          mkdir $PROJECT
     fi
     for OBJECT in $(cat /etc/bash_completion.d/oc | grep 'must_have_one_noun+=' | sort -u | sed 's/must_have_one_noun+=("//' | sed 's/")//' | sed 's/\s*//')
     do
          for OBJECTNAME in `oc get $OBJECT -n $PROJECT  --no-headers 2>/dev/null| awk '{print $1}' ` 
          do
              CHECKNAMESPACE=""
              if grep  -q "^$OBJECT$" globalobjects ; then 
                   CHECKNAMESPACE=""
              elif grep -q "^$OBJECT$" namespaceobjects ; then
                   CHECKNAMESPACE=$PROJECT
              #     echo "debug: OBJECT=$OBJECT, PROJECT=$PROJECT, CHECKNAMESPACE=$CHECKNAMESPACE"
              else
                   CHECKNAMESPACE=$(oc export -n $PROJECT $OBJECT $OBJECTNAME --raw | grep -P '^\s*namespace:' | awk '{print $2}' | grep  "$PROJECT")
               #  echo "debug --> NAMESPACE=$PROJECT: $OBJECT $OBJECTNAME                  ---> $CHECKNAMESPACE"
                   if [ -z "$CHECKNAMESPACE" ] || [ "$CHECKNAMESPACE" == "" ] ; then
                        echo $OBJECT >> globalobjects
                   else
                        echo $OBJECT >> namespaceobjects
                   fi
              fi
              if [ -z "$CHECKNAMESPACE" ] || [ "$CHECKNAMESPACE" == "" ] ; then
                   if grep -q "^$OBJECT$" globalobjects ; then
                        COUNTGLOBALOBJECTS=$COUNTGLOBALOBJECTS+1
                   else
               #         echo "GLOBAL: $OBJECT $OBJECTNAME      ($COUNTGLOBALOBJECTS)"
                         printf "%-30s  %-30s  %-50s\n" "GLOBAL" "$OBJECT" "$OBJECTNAME" 
                   fi
              else
                # echo "NAMESPACE=$PROJECT: $OBJECT $OBJECTNAME                  ---> $CHECKNAMESPACE"
                  printf "%-30s  %-30s  %-50s\n" "$PROJECT" "$OBJECT" "$OBJECTNAME" 
              fi 
          done
     done
done
