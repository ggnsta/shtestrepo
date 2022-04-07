#!/bin/bash

export PATH=$JAVA_HOME2:$PATH
export HOME=/home/egor
#path_to_key="~/.ssh/id_rsa.pub"
#export GIT_SSH_COMMAND="ssh -i "$path_to_key""
#git config --add --local core.sshCommand 'ssh -i /home/egor/.ssh/id_rsa.pub'
export GIT_SSH_COMMAND='ssh -i /home/egor/.ssh/id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'


TODAY_DATE=$(date +"%m-%d-%Y")
SOURCE_BRANCH=$BRANCH_NAME_PATTERN-$TODAY_DATE


#Get list of jobs#
response=$(java -jar jenkins-cli.jar -s $JENKINS_IP -auth $JENKINS_USERNAME:$JENKINS_PASSWORD list-jobs "$JENKINS_VIEW")

#Get jobs config#
for var in $response
do (java -jar jenkins-cli.jar -s $JENKINS_IP -auth $JENKINS_USERNAME:$JENKINS_PASSWORD get-job $var > $var.xml)
done


#git config --global user.name "Egor Kliuev"
#git config --global user.email "user.email=egor.kliuev@bilateral.group"
#Pull request#
GIT_SSH_COMMAND='ssh -i /home/egor/.ssh/id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'


ssh -T git@bitbucket.org