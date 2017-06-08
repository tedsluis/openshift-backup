# Openshift Object backup tool  
  
## Table of contents  
   * [Openshift Object backup tool](openshift-object-backup-tool)  
      * [Table of contents](#table-of-contents)  
      * [Features](#features)  
      * [prerequisites](#prerequisites)  
      * [How to use](#how-to-use) 
      * [Object types](#object-types)  
      * [Help text](#help-text)  
      * [Example](#example)  
    
## Features  
  
This 'ose-backup.sh' script is meant to back up OpenShift 3.+ objects to files in yaml format. These files can later be used for debugging or restoring OpenShift components and applications. The yaml files will be stored in a git repo. The script does have the following features:  
* The ability to back up all OpenShift object types.  
* Stores each namespace in a different directory.  
* Stores each object type in a different subdirectory.  
* Each object will be a committed to the git repo, so changes in time can be tracked back.  
* A back up can be made of:  
    * objects in a single namespace or a list of namespaces.  
    * objects that are global (not related to a namespace).  
    * objects of a certain object type or a list of object types.  
    * objects with a certain object name.  
* Tokens, keys, certificates, passwords, etc can be removed from secret objects.  
* You can only back up those items to which you are entitled. Only cluster-admins can backup all namespaces.  
  
## Prerequisites  
  
This 'ose-backup.sh' script is written in bash and tested on RHEL7 and Fedora 25.  
It uses the '/etc/bash_completion.d/oc' file (which comes with the oc commandline tool) to obtain all known OpenShift object types. If this file is not available on your system, it will automaticly use the 'oc' file included in this repo. Note that is file may not contain the latest OpenShift Objects! 
  
Prerequisites:
* 'oc client' and 'git' installed on your system.  
* Https access to the OpenShift cluster.  
* Login credetieels for the OpenShift cluster.   
* Clone this repo on your system (or copy the 'ose-backup.sh' script and the 'oc' file).
   
## How to use  
  
By default the script will create a directory '&lt;your home directory&gt;/openshift-backup-files' and initialize a new git repository in there. If you prefer an other path for the backup files you can edit the default in the script or use the option ' --backup-directory=&lt;path&gt;'.  
 
Without any options the script will backup all your namespaces to which you are entitled. You can specify filter options to backup only specific namespaces, object types and/or object names.  
  
Only new and modified objects will be backed up. If no objects were changed nothing will be added to the backup repository.  

## Object types  
  
This list of OpenShift object types may not contain all known objects. Besure you use the latest oc client with auto completion!
  
|---|---|---|  
| appliedclusterresourcequota | build,buildconfig | certificatesigningrequest | cluster |   
| clusternetwork | clusterpolicy | clusterpolicybinding | clusterresourcequota |   
| clusterrole | clusterrolebinding | componentstatus | configmap |   
| daemonset | deployment | deploymentconfig | egressnetworkpolicy |   
| endpoints | event | group | horizontalpodautoscaler |   
| hostsubnet | identity | image | imagestream |   
| imagestreamimage | imagestreamtag | ingress | ispersonalsubjectaccessreview |   
| job | limitrange | namespace | netnamespace |   
| networkpolicy | node | oauthaccesstoken | oauthauthorizetoken |  
| oauthclient | oauthclientauthorization | persistentvolume | persistentvolumeclaim |  
| petset | pod | poddisruptionbudget | podsecuritypolicy |   
| podtemplate | policy | policybinding | project |   
| replicaset | replicationcontroller | resourcequota | role |  
| rolebinding | route | scheduledjob | secret |  
| securitycontextconstraints | service | serviceaccount | storageclass |  
| template | thirdpartyresource | thirdpartyresourcedata | user |  
| useridentitymapping| | |  
  
## Help text  
  
````
$ ./ose-backup.sh --help

OpenShift objects backup tool

Usage:
  ose-backup.sh --namespace=<namespace>,[<namespace>]...            Specify namespaces to backed up.
  ose-backup.sh --backup-global-objects=[true]|[false]              Backup global objects (no namespace).
  ose-backup.sh --object-type=<objecttype>,[<objecttype>]...        Specify object types to be backed up.
  ose-backup.sh --ignore-object-type=<objecttype>,[<objecttype>]... Specify object types to be ignored.
  ose-backup.sh --object-name=<[part of ]objectname>                Part of object name.
  ose-backup.sh --backup-directory=<path>                           Backup directory path.
  ose-backup.sh --remove-secrets=[true]|[false]                     Remove secrets from backup.
  ose-backup.sh --help                                              This help text.
  ose-backup.sh --debug                                             Displays debug logging.
  ose-backup.sh --version                                           Display version info.

Examples:
  ose-backup.sh --namespace=myapp --object-name=app2 --remove-secrets=true
  ose-backup.sh --backup-global-objects=true --ignore-object-type=events,pods --remove-secrets=true

Defaults:
  --namespace=cloudforms,default,kube-system,logging,management-infra,openshift,openshift3,openshift-infra,my-app,rabobank,red-yellow-and-blue,ted
  --backup-global-objects=false
  --backup-directory=/home/sluist/openshift-backup-files
  --remove-secrets=false
  --object-name=
  --ignore-object-type=event
  --object-type=appliedclusterresourcequota,build,buildconfig,certificatesigningrequest,cluster,clusternetwork,clusterpolicy,clusterpolicybinding,clusterresourcequota,clusterrole,clusterrolebinding,componentstatus,configmap,daemonset,deployment,deploymentconfig,egressnetworkpolicy,endpoints,event,group,horizontalpodautoscaler,hostsubnet,identity,image,imagestream,imagestreamimage,imagestreamtag,ingress,ispersonalsubjectaccessreview,job,limitrange,namespace,netnamespace,networkpolicy,node,oauthaccesstoken,oauthauthorizetoken,oauthclient,oauthclientauthorization,persistentvolume,persistentvolumeclaim,petset,pod,poddisruptionbudget,podsecuritypolicy,podtemplate,policy,policybinding,project,replicaset,replicationcontroller,resourcequota,role,rolebinding,route,scheduledjob,secret,securitycontextconstraints,service,serviceaccount,storageclass,template,thirdpartyresource,thirdpartyresourcedata,user,useridentitymapping
````
  
## Example
  
A backup of a single namespace (tokens, keys, certificates, password, etc removed from secrets):  
````
$ ./ose-backup.sh --namespace=my-app --remove-secrets=true
unchanged object: 1         my-app         build                           pizza-session-10
unchanged object: 2         my-app         build                           pizza-session-11
      new object: 1         my-app         build                           pizza-session-12
unchanged object: 3         my-app         buildconfig                     pizza-session
unchanged object: 4         my-app         deploymentconfig                pizza-session
unchanged object: 5         my-app         endpoints                       pizza-session
unchanged object: 6         my-app         imagestream                     pizza-session
unchanged object: 7         my-app         namespace                       my-app
unchanged object: 8         my-app         pod                             pizza-session-11-build
unchanged object: 9         my-app         pod                             pizza-session-12-build
      new object: 2         my-app         pod                             pizza-session-1-n99f3
unchanged object: 11        my-app         policybinding                   :default
unchanged object: 12        my-app         project                         my-app
unchanged object: 13        my-app         replicationcontroller           pizza-session-1
unchanged object: 14        my-app         rolebinding                     admin
unchanged object: 15        my-app         rolebinding                     system:deployers
unchanged object: 16        my-app         rolebinding                     system:image-builders
unchanged object: 17        my-app         rolebinding                     system:image-pullers
unchanged object: 18        my-app         rolebinding                     view
unchanged object: 19        my-app         secret                          builder-dockercfg-ozhjy
unchanged object: 20        my-app         secret                          builder-token-3ndh0
unchanged object: 21        my-app         secret                          builder-token-a71ue
unchanged object: 22        my-app         secret                          default-dockercfg-zlhnx
unchanged object: 23        my-app         secret                          default-token-gix87
unchanged object: 24        my-app         secret                          default-token-rav2c
unchanged object: 25        my-app         secret                          deployer-dockercfg-8jwos
unchanged object: 26        my-app         secret                          deployer-token-4n2le
unchanged object: 27        my-app         secret                          deployer-token-ejpxq
unchanged object: 28        my-app         service                         pizza-session
unchanged object: 29        my-app         serviceaccount                  builder
unchanged object: 30        my-app         serviceaccount                  default
unchanged object: 31        my-app         serviceaccount                  deployer
---------------------------------------------------
Number of objects in this namespace:          32
Number of new objects in this namespace:      1
Number of modified objects in this namespace: 0
---------------------------------------------------
Number of namespaces matched: 1
Number of objects matched:    32
Number of new objects:        1
Number of modified objects:   0
````
  
Result in the backup directory:
````
$ find openshift-backup-files/my-app -name '*'
openshift-backup-files/my-app
openshift-backup-files/my-app/replicationcontroller
openshift-backup-files/my-app/replicationcontroller/pizza-session-1
openshift-backup-files/my-app/deploymentconfig
openshift-backup-files/my-app/deploymentconfig/pizza-session
openshift-backup-files/my-app/rolebinding
openshift-backup-files/my-app/rolebinding/view
openshift-backup-files/my-app/rolebinding/system:image-builders
openshift-backup-files/my-app/rolebinding/system:image-pullers
openshift-backup-files/my-app/rolebinding/admin
openshift-backup-files/my-app/rolebinding/system:deployers
openshift-backup-files/my-app/service
openshift-backup-files/my-app/service/pizza-session
openshift-backup-files/my-app/endpoints
openshift-backup-files/my-app/endpoints/pizza-session
openshift-backup-files/my-app/project
openshift-backup-files/my-app/project/my-app
openshift-backup-files/my-app/imagestream
openshift-backup-files/my-app/imagestream/pizza-session
openshift-backup-files/my-app/serviceaccount
openshift-backup-files/my-app/serviceaccount/default
openshift-backup-files/my-app/serviceaccount/deployer
openshift-backup-files/my-app/serviceaccount/builder
openshift-backup-files/my-app/pod
openshift-backup-files/my-app/pod/pizza-session-1-js0zq
openshift-backup-files/my-app/pod/pizza-session-1-n99f3
openshift-backup-files/my-app/pod/pizza-session-1-jpkfq
openshift-backup-files/my-app/pod/pizza-session-12-build
openshift-backup-files/my-app/pod/pizza-session-11-build
openshift-backup-files/my-app/build
openshift-backup-files/my-app/build/pizza-session-11
openshift-backup-files/my-app/build/pizza-session-12
openshift-backup-files/my-app/policybinding
openshift-backup-files/my-app/policybinding/:default
openshift-backup-files/my-app/secret
openshift-backup-files/my-app/secret/deployer-token-4n2le
openshift-backup-files/my-app/secret/deployer-dockercfg-8jwos
openshift-backup-files/my-app/secret/deployer-token-ejpxq
openshift-backup-files/my-app/secret/builder-token-3ndh0
openshift-backup-files/my-app/secret/builder-dockercfg-ozhjy
openshift-backup-files/my-app/secret/default-token-rav2c
openshift-backup-files/my-app/secret/default-token-gix87
openshift-backup-files/my-app/secret/default-dockercfg-zlhnx
openshift-backup-files/my-app/secret/builder-token-a71ue
openshift-backup-files/my-app/namespace
openshift-backup-files/my-app/namespace/my-app
openshift-backup-files/my-app/buildconfig
openshift-backup-files/my-app/buildconfig/pizza-session
````
     
Example of a buildconfig yaml file:
````
$ cat ~/openshift-backup-files/my-app/buildconfig/pizza-session
apiVersion: v1
kind: BuildConfig
metadata:
  annotations:
    openshift.io/generated-by: OpenShiftNewApp
  creationTimestamp: 2017-05-17T14:20:07Z
  labels:
    app: pizza-session
  name: pizza-session
  namespace: my-app
  resourceVersion: "8506931"
  selfLink: /oapi/v1/namespaces/my-app/buildconfigs/pizza-session
  uid: ed5c727c-3b0b-11e7-b48d-005056bb0dc6
spec:
  nodeSelector:
    kubernetes.io/hostname: atom6014.linux.rabobank.nl
  output:
    to:
      kind: ImageStreamTag
      name: pizza-session:latest
  postCommit: {}
  resources: {}
  runPolicy: Serial
  source:
    contextDir: catch-them-all
    git:
      uri: https://git.eu.rabonet.com/my-app/pizza-session.git
    type: Git
  strategy:
    sourceStrategy:
      from:
        kind: ImageStreamTag
        name: nodejs:4
        namespace: openshift
    type: Source
  triggers:
  - github:
      secret: qM438RgWve3VXM7vW0AA
    type: GitHub
  - generic:
      secret: 
    type: Generic
  - type: ConfigChange
  - imageChange:
      lastTriggeredImageID: registry.access.redhat.com/rhscl/nodejs-4-rhel7@sha256:a7d1f9c3058c197a97eaca339dcbbba4596429df0fb1bcd1578a9ed6f523b2ee
    type: ImageChange
status:
  lastVersion: 12
````


