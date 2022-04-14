#!/bin/bash

if [[ -z "${BRANCH_NAME_PATTERN}" ]]; then
  echo "variable BRANCH_NAME_PATTERN is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${PR_DAY}" ]]; then
  echo "variable PR_DAY is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${JENKINS_USERNAME}" ]]; then
  echo "variable JENKINS_USERNAME is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${JENKINS_PASSWORD}" ]]; then
  echo "variable JENKINS_PASSWORD is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${JENKINS_VIEW}" ]]; then
  echo "variable JENKINS_VIEW is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${BITBUCKET_USERNAME}" ]]; then
  echo "variable BITBUCKET_USERNAME is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${BITBUCKET_PASSWORD}" ]]; then
  echo "variable BITBUCKET_PASSWORD is undefined. Script exits with an error."
  exit 1
fi

TODAY_DATE=$(date +"%m-%d-%Y")
SOURCE_BRANCH=$BRANCH_NAME_PATTERN-$TODAY_DATE


response=$(java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USERNAME:$JENKINS_PASSWORD list-jobs "$JENKINS_VIEW")

for var in $response
do (java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USERNAME:$JENKINS_PASSWORD get-job $var > 2105/$var.xml)
done

git remote set-url origin https://$BITBUCKET_USERNAME:$BITBUCKET_PASSWORD@bitbucket.org/egorkluev/shtestrepo.git

#PULL REQUEST#
if [ $(date +%w) = $PR_DAY ]; then
	git checkout -b $SOURCE_BRANCH

  cd 2105/
	for var in $response
	do(git add $var.xml)
	done

	git commit -a -m "Jenkins configs backup from: $TODAY_DATE"

	git push -f origin $SOURCE_BRANCH

  echo $GIT_URL
  echo ${GIT_URL:18}
	curl https://api.bitbucket.org/2.0/repositories/${GIT_URL:18}/pullrequests \
	    -u $BITBUCKET_USERNAME:$BITBUCKET_PASSWORD \
	    --request POST \
	    --header 'Content-Type: application/json' \
	    --data '{"title": "JB-'$TODAY_DATE'","source": {"branch": {"name": "'$SOURCE_BRANCH'"}}, "destination": {"branch": {"name": "'${GIT_BRANCH:7}'"}}}'
fi
