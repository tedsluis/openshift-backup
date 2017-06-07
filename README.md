# Openshift Object backup tool  
  
## Table of contents  
   * [Openshift Object backup tool](openshift-object-backup-tool)  
      * [Table of contents](#table-of-contents)  
      * [Features](#features)  
      * [prerequisites](#prerequisites)  
      * [How to use](#how-to-use) 
      * [Help text](#help-text)  
    
## Features  
  
This 'ose-backup.sh' script is meant to back up OpenShift 3.+ objects to files in yaml format. These files can later be used for debugging or restoring OpenShift components or applications. The yaml files will be stored in a git repo. The script does have the following features:  
* The ability to back up all OpenShift object types.  
* Stores each namespace in a different directory.  
* Stores each object type in a different subdirectory.  
* Each object will be a committed to the git repo, so changes in time can be tracked back.  
* A back up can be made of:  
    * one or more namespaces.  
    * objects that are global (not related to a namespace).  
    * one or more object types.  
    * objects with a certain name.  
* Tokens, keys, certificates, passwords, etc can be removed from secret objects.  
  
## Prerequisites  
  
This 'ose-backup.sh' script is written in bash and tested on RHEL7 and Fedora 25.  
It uses the '/etc/bash_completion.d/oc' file (which comes with the oc commandline tool) to obtain all known OpenShift object types. If this file is not available on your system, it will automaticly use the 'oc' file included in this repo. Note that is file may not contain the latest OpenShift Objects! 
  
Prerequisites:
* 'oc client' and 'git' installed on your system.  
* Https access to the OpenShift cluster.  
* Login credetieels for the OpenShift cluster.   
* Clone the repo to your system (or copy the 'ose-backup.sh' script and the 'oc' file).
   
## How to use  
  
By default the script will create a directory '&lt;your home directory&gt;/openshift-backup-files' and initialize a new git repository in there. If you prefer an other path for the backup files you can edit the default in the script or use the option ' --backup-directory=&lt;path&gt;'.  
  
You can only back up those items to which you are entitled. Only cluster-admins can backup all namespaces.
  
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
  --namespace=cloudforms,default,kube-system,logging,management-infra,openshift,openshift3,openshift-infra,polaris,rabobank,red-yellow-and-blue,ted
  --backup-global-objects=false
  --backup-directory=/home/sluist/openshift-backup-files
  --remove-secrets=false
  --object-name=
  --ignore-object-type=event
  --object-type=appliedclusterresourcequota,build,buildconfig,certificatesigningrequest,cluster,clusternetwork,clusterpolicy,clusterpolicybinding,clusterresourcequota,clusterrole,clusterrolebinding,componentstatus,configmap,daemonset,deployment,deploymentconfig,egressnetworkpolicy,endpoints,event,group,horizontalpodautoscaler,hostsubnet,identity,image,imagestream,imagestreamimage,imagestreamtag,ingress,ispersonalsubjectaccessreview,job,limitrange,namespace,netnamespace,networkpolicy,node,oauthaccesstoken,oauthauthorizetoken,oauthclient,oauthclientauthorization,persistentvolume,persistentvolumeclaim,petset,pod,poddisruptionbudget,podsecuritypolicy,podtemplate,policy,policybinding,project,replicaset,replicationcontroller,resourcequota,role,rolebinding,route,scheduledjob,secret,securitycontextconstraints,service,serviceaccount,storageclass,template,thirdpartyresource,thirdpartyresourcedata,user,useridentitymapping
````
  
## Example
  
Backup of a single namespace (tokens, keys, certificates, password, etc removed from secrets):  
````
$ ./ose-backup.sh --namespace=polaris --remove-secrets=true
unchanged object: 1         polaris         build                           pizza-session-10
unchanged object: 2         polaris         build                           pizza-session-11
      new object: 1         polaris         build                           pizza-session-12
unchanged object: 3         polaris         buildconfig                     pizza-session
unchanged object: 4         polaris         deploymentconfig                pizza-session
unchanged object: 5         polaris         endpoints                       pizza-session
unchanged object: 6         polaris         imagestream                     pizza-session
unchanged object: 7         polaris         namespace                       polaris
unchanged object: 8         polaris         pod                             pizza-session-11-build
unchanged object: 9         polaris         pod                             pizza-session-12-build
      new object: 2         polaris         pod                             pizza-session-1-n99f3
unchanged object: 11        polaris         policybinding                   :default
unchanged object: 12        polaris         project                         polaris
unchanged object: 13        polaris         replicationcontroller           pizza-session-1
unchanged object: 14        polaris         rolebinding                     admin
unchanged object: 15        polaris         rolebinding                     system:deployers
unchanged object: 16        polaris         rolebinding                     system:image-builders
unchanged object: 17        polaris         rolebinding                     system:image-pullers
unchanged object: 18        polaris         rolebinding                     view
unchanged object: 19        polaris         secret                          builder-dockercfg-ozhjy
unchanged object: 20        polaris         secret                          builder-token-3ndh0
unchanged object: 21        polaris         secret                          builder-token-a71ue
unchanged object: 22        polaris         secret                          default-dockercfg-zlhnx
unchanged object: 23        polaris         secret                          default-token-gix87
unchanged object: 24        polaris         secret                          default-token-rav2c
unchanged object: 25        polaris         secret                          deployer-dockercfg-8jwos
unchanged object: 26        polaris         secret                          deployer-token-4n2le
unchanged object: 27        polaris         secret                          deployer-token-ejpxq
unchanged object: 28        polaris         service                         pizza-session
unchanged object: 29        polaris         serviceaccount                  builder
unchanged object: 30        polaris         serviceaccount                  default
unchanged object: 31        polaris         serviceaccount                  deployer
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
