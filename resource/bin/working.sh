#!/bin/bash
#This is a backup script for jenkins jobs.
#Which, using jenkins-cli.jar, gets the configs of all jobs in a specific view and saves them in the code base.
#Also, this script saves system configuration changes in VCS hosting.(GitHub or Bitbucket).
#Required parameters:
#1) $VCS_USERNAME-username in VCS hosting. (Not email)
#2) $VCS_PASSWORD-application password(token) in VCS hosting. You need token with write permission  for pushing and creating pull requests.
# Can create here:
          #1)https://bitbucket.org/account/settings/app-passwords/
          #2)https://github.com/settings/tokens
#3)$GIT_URL-Specify the URL of the git repository. This uses the same syntax as your git clone command.
  #Example: <git@bitbucket.org/pfistervkp/vkp-migration.git>
  #This parameter is taken from the "Source Code Management" section. In jenkins job configuration.
  #Also this parameter determines which VCS hosting is used to create the pull request.
#4)$JENKINS_USERNAME-jenkins account name. This account must have access to all jobs and their configurations.
#5)$JENKINS_PASSWORD-account password above.
#6)$JENKINS_URL-Full URL of Jenkins, like http://server:port/jenkins/
#7)$JENKINS_VIEW-Determines from which View in jenkins, the jobs will be backed up. If the view name contains spaces - wrap it in ' '
#8)$TARGET_BRANCH-The name of the remote branch into which the pull request will be created.
#9)$PR_DAY-The day of the week on which the pull request will be created. The day should start with a capital letter, like 'Monday'.
#10)$BRANCH_NAME_PATTERN-Specifies name of  generated branches.

VCS_USERNAME=${1}
VCS_PASSWORD=${2}
GIT_URL=${3}
JENKINS_USERNAME=${4}
JENKINS_PASSWORD=${5}
JENKINS_URL=${6}
JENKINS_VIEW=${7}
TARGET_BRANCH=${8}
PR_DAY=${9}
BRANCH_NAME_PATTERN=${10}

if [[ -z "${VCS_USERNAME}" ]]; then
  echo "variable VCS_USERNAME is undefined. Script exits with an error."
  exit 1
fi
if [[ -z "${VCS_PASSWORD}" ]]; then
  echo "variable VCS_PASSWORD is undefined. Script exits with an error."
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
  echo "variable TARGET_BRANCH is undefined. Script exits with an error."
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

parse_git_url(){
  SSH='ssh://'
  REMOTE_URL=$GIT_URL
  if [[ "$GIT_URL" == *"$SSH"* ]]; then
    REMOTE_URL=${STR:6}
  fi
  REMOTE_URL=${REMOTE_URL:4}

  ARRAY=($(awk -F '[:/@]' '{$1=$1} 1' <<< "${BUF}"))

  echo ${ARRAY[0]}
   echo ${ARRAY[1]}
    echo ${ARRAY[2]}
  VCS_HOST=${ARRAY[0]}
  VCS_WORSPACE=${ARRAY[1]}
  VCS_REPO=${ARRAY[2]}

  echo "Spliting GIT_URL: $GIT_URL"
  echo "1.REMOTE_URL: $REMOTE_URL"
  echo "2.VCS_HOST: $VCS_HOST"
  echo "3.VCS_WORSPACE: $VCS_WORSPACE"
  echo "4.VCS_REPO: $VCS_REPO"
}

pull_github(){
  curl -s -o response.txt -w "%{http_code}"\
    -X POST \
    -H "Accept: application/json" \
    -H "Authorization: token $VCS_PASSWORD" \
    https://api.github.com/repos/$VCS_WORSPACE/$VCS_REPO/pulls \
    -d '{"title":"JB-'$TODAY_DATE'","body":"","head":"'$VCS_WORSPACE':'$SOURCE_BRANCH'","base":"'${TARGET_BRANCH:7}'"}'
}

pull_bitbucket(){
  curl -s -o response.txt -w "%{http_code}" https://api.bitbucket.org/2.0/repositories/$VCS_WORSPACE/$VCS_REPO/pullrequests \
  	    -u $VCS_USERNAME:$VCS_PASSWORD \
  	    --request POST \
  	    --header 'Content-Type: application/json' \
  	    --data '{"title": "JB-'$TODAY_DATE'","source": {"branch": {"name": "'$SOURCE_BRANCH'"}}, "destination": {"branch": {"name": "'${TARGET_BRANCH:7}'"}}}'
}

#Begin of script
TODAY_DATE=$(date +"%m-%d-%Y")
SOURCE_BRANCH=$BRANCH_NAME_PATTERN-$TODAY_DATE
parse_git_url

response=$(java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USERNAME:$JENKINS_PASSWORD list-jobs "$JENKINS_VIEW")
echo "Getting a list of all jobs for '$JENKINS_VIEW':\n $response"

for var in $response
do
  (java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USERNAME:$JENKINS_PASSWORD get-job $var > ../2105/$var.xml)
  echo "Getting configuration for '$var'"
done

#PULL REQUEST#
if [ $(date +%A) = $PR_DAY ]; then

  echo "Setting remote origin to: https://$VCS_USERNAME:$VCS_PASSWORD@$REMOTE_URL"
  git remote set-url origin https://$VCS_USERNAME:$VCS_PASSWORD@$REMOTE_URL

	git checkout -b $SOURCE_BRANCH

  cd ../2105
	for var in $response
	  do(git add $var.xml)
	  echo "git add: $var.xml"
	done

  echo -n "Commit created: "
	git commit -a -m "Jenkins configs backup from: $TODAY_DATE"

  git push -f origin $SOURCE_BRANCH
  echo "Push finished."
  echo "$VCS_HOST is used."

  if [ $VCS_HOST == "github.com" ]; then
    statusCode=$(pull_github)
  elif [ $VCS_HOST == "bitbucket.org" ]; then
    statusCode=$(pull_bitbucket)
  else
    echo "Unknown VCS: $VCS_HOST"
    exit 1
  fi

  if [ $statusCode != "201" ]; then
    echo "Something went wrong during the pull request:"
    cat response.txt
    exit 1
  else
    echo "Pull request created successfully"
  fi

else echo "Today is $(date +%A), but PR_DAY is set on $PR_DAY. Just kept backups, without pushing it to VCS"
fi


