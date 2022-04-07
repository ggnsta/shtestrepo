#!/bin/bash

export PATH=$JAVA_HOME2:$PATH
export HOME=/home/egor
path_to_key="/home/egor/.ssh/id_rsa"
export GIT_SSH_COMMAND="ssh -i "$path_to_key""
#git config --add --local core.sshCommand 'ssh -i /home/egor/.ssh/id_rsa.pub'



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
if [ $(date +%w) = $PR_DAY ]; then
	git checkout -b $SOURCE_BRANCH
			echo "checkouted succ"

	for var in $response
	do(git add $var.xml)
	done

	echo "git add succ"

	git commit -a -m "Jenkins configs backup from: $TODAY_DATE"
	echo "git commit succ"

	git push origin $SOURCE_BRANCH
	echo "push succ"

	curl https://api.bitbucket.org/2.0/repositories/$BITBUCKET_WORKSPACEID/$BITBUCKET_REPO/pullrequests \
	    -u egorkluev:CEQcYMprjy2y5H7PcUFs \
	    --request POST \
	    --header 'Content-Type: application/json' \
	    --data '{"title": "JB-'$TODAY_DATE'","source": {"branch": {"name": "'$SOURCE_BRANCH'"}}, "destination": {"branch": {"name": "'$TARGET_BRANCH'"}}}'
	echo "pr succ"
fi

