TODAY_DATE=$(date +"%m-%d-%Y-%H-%M")
BRANCH_NAME_PATTERN=JenkinsJobConfigBackUp/JenkinsBackup
BRANCH=$BRANCH_NAME_PATTERN-$TODAY_DATE
git checkout -b $BRANCH
touch 32.txt
git add .
git commit -a -m "Jenkins configs backup from: $TODAY_DATE"
git push origin $BRANCH