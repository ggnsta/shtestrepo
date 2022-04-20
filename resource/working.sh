#!/bin/bash
BITBUCKET_USERNAME=${1}
BITBUCKET_PASSWORD=${2}
GIT_URL=${3}
JENKINS_USERNAME=${4}
JENKINS_PASSWORD=${5}
JENKINS_URL=${6}
JENKINS_VIEW=${7}
TARGET_BRANCH=${8}
PR_DAY=${9}
BRANCH_NAME_PATTERN=${10}
COMMIT_MSG=${11}

if [[ -z "${BITBUCKET_USERNAME}" ]]; then
  echo "variable BITBUCKET_USERNAME is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${BITBUCKET_PASSWORD}" ]]; then
  echo "variable BITBUCKET_PASSWORD is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${GIT_URL}" ]]; then
  echo "variable GIT_URL is undefined. Script exits with an error."
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
if [[ -z "${JENKINS_URL}" ]]; then
  echo "variable JENKINS_URL is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${JENKINS_VIEW}" ]]; then
  echo "variable JENKINS_VIEW is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${TARGET_BRANCH}" ]]; then
  echo "variable SOURCE_BRANCH is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${PR_DAY}" ]]; then
  echo "variable PR_DAY is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${BRANCH_NAME_PATTERN}" ]]; then
  echo "variable BRANCH_NAME_PATTERN is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${COMMIT_MSG}" ]]; then
  echo "variable COMMIT_MSG is undefined. Script exits with an error."
  exit 1
fi

parse_git_url(){
  readarray -d @ -t strarr <<< "$GIT_URL"
  REMOTE_URL="${strarr[1]}"
  readarray -d / -t strarr <<< "$REMOTE_URL"
  VCS_HOST="${strarr[0]}"
  VCS_WORSPACE="${strarr[1]}"
  VCS_REPO="${strarr[2]}"
  echo "GIT_URL: ${GIT_URL}"
  echo "REMOTE_URL: ${REMOTE_URL}"
  echo "VCS_HOST: ${VCS_HOST}"
  echo "VCS_WORSPACE: ${VCS_WORSPACE}"
  echo "VCS_REPO: ${VCS_REPO}"
}

pull_github(){
  curl -s -o response.txt -w "%{http_code}"\
    -X POST \
    -H "Accept: application/json" \
    -H "Authorization: token $BITBUCKET_PASSWORD" \
    https://api.github.com/repos/$VCS_WORSPACE/$VCS_REPO/pulls \
    -d '{"title":"'$COMMIT_MSG-$TODAY_DATE'","body":"","head":"'$VCS_WORSPACE':'$SOURCE_BRANCH'","base":"'${TARGET_BRANCH:7}'"}'
}

pull_bitbucket(){
  curl -s -o response.txt -w "%{http_code}" https://api.bitbucket.org/2.0/repositories/${GIT_URL:24}/pullrequests \
  	    -u $BITBUCKET_USERNAME:$BITBUCKET_PASSWORD \
  	    --request POST \
  	    --header 'Content-Type: application/json' \
  	    --data '{"title": "'$COMMIT_MSG-$TODAY_DATE'","source": {"branch": {"name": "'$SOURCE_BRANCH'"}}, "destination": {"branch": {"name": "'${TARGET_BRANCH:7}'"}}}'
}

TODAY_DATE=$(date +"%m-%d-%Y")
SOURCE_BRANCH=$BRANCH_NAME_PATTERN-$TODAY_DATE
parse_git_url

response=$(java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USERNAME:$JENKINS_PASSWORD list-jobs "$JENKINS_VIEW")

for var in $response
do (java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USERNAME:$JENKINS_PASSWORD get-job $var > 2105/$var.xml)
done

git remote set-url origin https://$BITBUCKET_USERNAME:$BITBUCKET_PASSWORD${GIT_URL:9}

#PULL REQUEST#
if [ $(date +%A) = $PR_DAY ]; then
	git checkout -b $SOURCE_BRANCH

  cd 2105/
	for var in $response
	  do(git add $var.xml)
	done

	git commit -a -m "Jenkins configs backup from: $TODAY_DATE"

	git push -f origin $SOURCE_BRANCH

  echo 'https://api.github.com/repos/'$VCS_WORSPACE'/'$VCS_REPO'/pulls'
  echo '{"title":"'$COMMIT_MSG-$TODAY_DATE'","body":"","head":"'$VCS_WORSPACE':'$SOURCE_BRANCH'","base":"'${TARGET_BRANCH:7}'"}'
	statusCode=$(pull_github)

  if [ $statusCode != "201" ]; then
    echo "Something went wrong during the pull request:"
    cat response.txt
    exit 1
  else
    echo "Pull request created successfully"
  fi

else echo "Today is $(date +%A), but PR_DAY is set on $PR_DAY. Just kept backups, without pushing it to VCS"
fi

