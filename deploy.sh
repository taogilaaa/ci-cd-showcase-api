#!/bin/bash
# Split on "/", ref: http://stackoverflow.com/a/5257398/689223
REPO_SLUG_ARRAY=(${TRAVIS_REPO_SLUG//\// })
REPO_OWNER=${REPO_SLUG_ARRAY[0]}
REPO_NAME=${REPO_SLUG_ARRAY[1]}

DEPLOY_SUBDOMAIN_UNFORMATTED_LIST=()
if [ "$TRAVIS_PULL_REQUEST" != "false" ]
then
  DEPLOY_SUBDOMAIN_UNFORMATTED_LIST+=(${TRAVIS_PULL_REQUEST}-pr)
elif [ -n "${TRAVIS_TAG// }" ] #TAG is not empty
then
  #sorts the tags and picks the latest
  #sort -V does not work on the travis machine
  #sort -V              ref: http://stackoverflow.com/a/14273595/689223
  #sort -t ...          ref: http://stackoverflow.com/a/4495368/689223
  #reverse with sed     ref: http://stackoverflow.com/a/744093/689223
  #git tags | ignore release candidates | sort versions | reverse | pick first line
  LATEST_TAG=`git tag | grep -v rc | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '1!G;h;$!d' | sed -n 1p`
  echo $LATEST_TAG
  if [ "$TRAVIS_TAG" == "$LATEST_TAG" ]
  then
    DEPLOY_SUBDOMAIN_UNFORMATTED_LIST+=(latest)
  fi
  DEPLOY_SUBDOMAIN_UNFORMATTED_LIST+=(${TRAVIS_TAG}-tag)
else
  DEPLOY_SUBDOMAIN_UNFORMATTED_LIST+=(${TRAVIS_BRANCH}-branch)
fi


for DEPLOY_SUBDOMAIN_UNFORMATTED in "${DEPLOY_SUBDOMAIN_UNFORMATTED_LIST[@]}"
do
  # Here we check if the repo owner is the same as original owner
  # Concerning availability of environment variables on pull request from another repo
  # https://docs.travis-ci.com/user/environment-variables/
  echo $TRAVIS_REPO_SLUG - $TRAVIS_PULL_REQUEST_SLUG
  echo $DEPLOY_SUBDOMAIN_UNFORMATTED
  if [ "${TRAVIS_REPO_SLUG}" = "${TRAVIS_PULL_REQUEST_SLUG}" ] || [ "${TRAVIS_PULL_REQUEST_SLUG}" = "" ]
  then
    # replaces "/" or "." with "-"
    # sed -r is only supported in linux, ref http://stackoverflow.com/a/2871217/689223
    # Domain names follow the RFC1123 spec [a-Z] [0-9] [-]
    # The length is limited to 253 characters
    # https://en.wikipedia.org/wiki/Domain_Name_System#Domain_name_syntax
    DEPLOY_SUBDOMAIN=`echo "$DEPLOY_SUBDOMAIN_UNFORMATTED" | sed -r 's/[\/|\.]+/\-/g'`
    DEPLOY_ALIAS=${DEPLOY_SUBDOMAIN}-${REPO_NAME}-${REPO_OWNER}
    
    NOW_URL="$(npx now --public --token=$NOW_SECRET --no-clipboard)"
    echo "Deployed: ${NOW_URL}"

    npx now alias --token=$NOW_SECRET $NOW_URL $DEPLOY_ALIAS
    echo "Aliased: ${DEPLOY_ALIAS}.now.sh"

    if [ "$TRAVIS_PULL_REQUEST" != "false" ]
    then
      # Using the Issues api instead of the PR api
      # Done so because every PR is an issue, and the issues api allows to post general comments,
      # while the PR api requires that comments are made to specific files and specific commits
      GITHUB_PR_COMMENTS=https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments
      curl -H "Authorization: token ${GITHUB_API_TOKEN}" --request POST ${GITHUB_PR_COMMENTS} --data '{"body":"Travis automatic deployment: '${DEPLOY_ALIAS}', commit unique url: '${NOW_URL}'"}'
    fi
  fi
done