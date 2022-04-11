#!/bin/bash
TODAY_DATE=$(date +"%m-%d-%Y")
JENKINS_URL="http://localhost:8080"
JENKINS_USERNAME="egor"
JENKINS_PASSWORD="123456"
FORMAT=".xml"
GIT_URL="git@bitbucket.org:egorkluev/shtestrepo.git"
BRANCH_NAME_PATTERN="ABC/DEF"
JENKINS_VIEW="1. VKP - D"
SOURCE_BRANCH=$BRANCH_NAME_PATTERN-$TODAY_DATE
PR_DAY=1


response=$(java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USERNAME:$JENKINS_PASSWORD list-jobs "$JENKINS_VIEW")

for var in $response
do (java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USERNAME:$JENKINS_PASSWORD get-job $var > 2105/$var.xml)
done

#PULL REQUEST#
if [ $(date +%w) = $PR_DAY ]; then
	git checkout -b $SOURCE_BRANCH

	for var in $response
	do(git add $var.xml)
	done

	git commit -a -m "Jenkins configs backup from: $TODAY_DATE"

	git push origin $SOURCE_BRANCH

	curl https://api.bitbucket.org/2.0/repositories/${GIT_URL:18}/pullrequests \
	    -u $BITBUCKET_USERNAME:$BITBUCKET_PASSWORD \
	    --request POST \
	    --header 'Content-Type: application/json' \
	    --data '{"title": "JB-'$TODAY_DATE'","source": {"branch": {"name": "'$SOURCE_BRANCH'"}}, "destination": {"branch": {"name": "'${GIT_BRANCH:7}'"}}}'
fi
