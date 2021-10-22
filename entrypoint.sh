#!/bin/sh -l

set -e

# check values
if [ -n "${PUBLISH_REPOSITORY}" ]; then
    PRO_REPOSITORY=${PUBLISH_REPOSITORY}
else
    PRO_REPOSITORY=${GITHUB_REPOSITORY}
fi

if [ -z "$PUBLISH_DIR" ]
then
  echo "You must provide the action with the folder path in the repository where your compiled page generate at, example public."
  exit 1
fi

if [ -z "$BRANCH" ]
then
  echo "You must provide the action with a branch name it should deploy to, for example master."
  exit 1
fi

if [ -z "$PERSONAL_TOKEN" ]
then
  echo "You must provide the action with either a Personal Access Token or the GitHub Token secret in order to deploy."
  exit 1
fi

if [ -z "$HEXO_ALGOLIA_INDEXING_KEY" ]
then
  echo "You must provide the action with a HEXO_ALGOLIA_INDEXING_KEY."
  exit 1
fi

REPOSITORY_PATH="https://x-access-token:${PERSONAL_TOKEN}@github.com/${PRO_REPOSITORY}.git"

# deploy to 
echo "Deploy to ${PRO_REPOSITORY}"

# Installs Git and jq.
apt-get update && \
apt-get install -y git && \

# Directs the action to the the Github workspace.
cd $GITHUB_WORKSPACE 

echo "npm install ..." 
npm install


echo "Clean folder ..."
./node_modules/hexo/bin/hexo clean

echo "Generate file ..."
./node_modules/hexo/bin/hexo generate 

echo "Update record to algolia"
export HEXO_ALGOLIA_INDEXING_KEY=${HEXO_ALGOLIA_INDEXING_KEY}
./node_modules/hexo/bin/hexo algolia 

cd $PUBLISH_DIR

echo "Config git ..."

# Configures Git.
git init
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git remote add origin "${REPOSITORY_PATH}"

# Checks to see if the remote exists prior to deploying.
# If the branch doesn't exist it gets created here as an orphan.
# if [ "$(git ls-remote --heads "$REPOSITORY_PATH" "$BRANCH" | wc -l)" -eq 0 ];
# then
#   echo "Creating remote branch ${BRANCH} as it doesn't exist..."
#   git checkout --orphan $BRANCH
# fi

git checkout --orphan $BRANCH

git add --all

echo 'Start Commit'
git commit --allow-empty -m "Deploying to branch '${BRANCH}'"

echo 'Start Push'
git push origin "${BRANCH}" --force

echo "Deployment succesful!"
