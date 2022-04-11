#!/bin/bash
###### JENKINS CONFIG ######
JENKINS_IP="http://localhost:8080"
JENKINS_USERNAME="egor"
JENKINS_PASSWORD="123456"
JENKINS_VIEW="1. VKP - D"
PR_DAY="4"
##############################
###### BITBUCKET CONFIG ######
BITBUCKET_USERNAME="egorkluev"
BITBUCKET_PASSWORD="CEQcYMprjy2y5H7PcUFs"
BITBUCKET_WORKSPACEID="egorkluev"
BITBUCKET_REPO="shtestrepo"
TARGET_BRANCH="develop"
###################################

TODAY_DATE=$(date +"%m-%d-%Y")
BRANCH_NAME_PATTERN=JenkinsJobConfigBackUp/JenkinsBackup
BRANCH=$BRANCH_NAME_PATTERN-$TODAY_DATE

response=$(java -jar jenkins-cli.jar -s $JENKINS_IP -auth $JENKINS_USERNAME:$JENKINS_PASSWORD list-jobs "$JENKINS_VIEW")

for var in $response
do (java -jar jenkins-cli.jar -s $JENKINS_IP -auth $JENKINS_USERNAME:$JENKINS_PASSWORD get-job $var > $var.xml)
done

#PULL REQUEST#
if [ $(date +%w) = $PR_DAY ]; then
	git checkout -b $BRANCH

	for var in $response
	do(git add $var.xml)
	done

	git commit -a -m "Jenkins configs backup from: $TODAY_DATE"

	git push origin $BRANCH

	curl https://api.bitbucket.org/2.0/repositories/$BITBUCKET_WORKSPACEID/$BITBUCKET_REPO/pullrequests \
	    -u $BITBUCKET_USERNAME:$BITBUCKET_PASSWORD \
	    --request POST \
	    --header 'Content-Type: application/json' \
	    --data '{"title": "JB-'$TODAY_DATE'","source": {"branch": {"name": "'$BRANCH'"}}, "destination": {"branch": {"name": "'$TARGET_BRANCH'"}}}'
fi
