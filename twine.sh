#!/bin/bash

# Reset previous log file
rm -f ~/.twine.log

# Set text colors
COLOR_YELLOW="\033[0;33m" # Yellow
COLOR_RED="\033[0;31m" # Red
COLOR_GREEN="\033[1;32m" # Green
NO_COLOR="\033[0m" # Reset color

# Get option about environment
OPTION_ENV=""
if [ "$1" == "--no-staging" ]; then
  OPTION_ENV="no-staging"
fi;

# Get project name
printf "\n ${COLOR_GREEN}Insert project name ${NO_COLOR}[${COLOR_YELLOW}e.g. example.com${NO_COLOR}]:\n"
printf " > "
read PROJECT_NAME
PROJECT_NAME_NO_TLD=$(echo "${PROJECT_NAME}" | sed -e "s/\.[a-z]*$//")

# Get project path
printf "\n ${COLOR_GREEN}Insert project path ${NO_COLOR}[${COLOR_YELLOW}e.g. /Users/username/Projects${NO_COLOR}]:\n"
printf " > "
read PROJECT_PATH
if [ ! -d "$PROJECT_PATH" ]; then
  printf "\n ${COLOR_RED}Error: wrong path!${NO_COLOR}\n"
  exit
fi

# Get project repository URL
printf "\n ${COLOR_GREEN}Insert repo URL ${NO_COLOR}[${COLOR_YELLOW}e.g. git@bitbucket.org:user/repository.git${NO_COLOR}]:\n"
printf " > "
read REPO_URL

# Get theme directory name
THEME_DEFAULT_NAME="sage"
printf "\n ${COLOR_GREEN}Theme directory name ${NO_COLOR}[${COLOR_YELLOW}${THEME_DEFAULT_NAME}${NO_COLOR}]:\n"
printf " > "
read THEME_NAME
if [ "$THEME_NAME" == "" ]; then
  THEME_NAME=$THEME_DEFAULT_NAME
fi;

# Print message
printf "\n ${COLOR_GREEN}Creating project subtrees...${NO_COLOR}"
printf "\n "
printf "\n "

# Initialize repository
PROJECT="${PROJECT_PATH}/${PROJECT_NAME}"
mkdir ${PROJECT}
git -C ${PROJECT} init >> ~/.twine.log 2>&1
git -C ${PROJECT} remote add origin ${REPO_URL} >> ~/.twine.log 2>&1
touch ${PROJECT}/.gitignore >> ~/.twine.log 2>&1
git -C ${PROJECT} add . >> ~/.twine.log 2>&1
git -C ${PROJECT} commit -m "Initial commit" >> ~/.twine.log 2>&1

# Set tools from roots.io
TOOLS=(trellis bedrock sage)
# Set official tools name from roots.io
TOOLS_NAME=(Trellis Bedrock Sage)
# Set folder structure for the tools
SUBTREES=(trellis site site/web/app/themes/${THEME_NAME})

# Create project subtrees
COUNT=0
for TOOL in ${TOOLS[@]}; do
  git -C ${PROJECT} remote add ${TOOL} https://github.com/roots/${TOOL}.git >> ~/.twine.log 2>&1
  git -C ${PROJECT} fetch ${TOOL} >> ~/.twine.log 2>&1
  git -C ${PROJECT} checkout -b ${TOOL} ${TOOL}/master >> ~/.twine.log 2>&1
  git -C ${PROJECT} checkout master >> ~/.twine.log 2>&1
  git -C ${PROJECT} read-tree --prefix=${SUBTREES[$COUNT]}/ -u ${TOOL}/master >> ~/.twine.log 2>&1
  git -C ${PROJECT} commit -m "Add ${TOOLS_NAME[$COUNT]} subtree" >> ~/.twine.log 2>&1
  COUNT=$(( $COUNT + 1 ))
done

# Setup theme
cd ${PROJECT}/${SUBTREES[2]}
composer install >> ~/.twine.log 2>&1
php vendor/bin/sage meta
php vendor/bin/sage config
php vendor/bin/sage preset
printf "\n${COLOR_GREEN}Running yarn tasks...${NO_COLOR}\n\n"
yarn -s >> ~/.twine.log 2>&1
yarn -s build >> ~/.twine.log 2>&1
wait
git -C ${PROJECT} add . >> ~/.twine.log 2>&1
git -C ${PROJECT} commit -m "Initial Sage configuration" >> ~/.twine.log 2>&1

# Partial Trellis configuration
printf "\n${COLOR_GREEN}Configuring Trellis...${NO_COLOR}\n\n"
if [ "$OPTION_ENV" == "no-staging" ]; then
  # Development
  sed -i "" -e "/^#/! s|example.com|${PROJECT_NAME}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/development/vault.yml
  sed -i "" -e "/^#/! s|example.com|${PROJECT_NAME}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/development/wordpress_sites.yml
  sed -i "" -e "/^#/! s|example.test|${PROJECT_NAME_NO_TLD}.test|g" ${PROJECT}/${SUBTREES[0]}/group_vars/development/wordpress_sites.yml

  # Production
  sed -i "" -e "s|git@github.com:example/example.com.git|${REPO_URL}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/production/wordpress_sites.yml
  sed -i "" -e "s|branch: master|branch: production|g" ${PROJECT}/${SUBTREES[0]}/group_vars/production/wordpress_sites.yml
  sed -i "" -e "/^#/! s|example.com|${PROJECT_NAME}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/production/vault.yml
  sed -i "" -e "/^#/! s|example.com|${PROJECT_NAME}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/production/wordpress_sites.yml
else
  # Development
  sed -i "" -e "/^#/! s|example.com|${PROJECT_NAME}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/development/vault.yml
  sed -i "" -e "/^#/! s|example.com|${PROJECT_NAME}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/development/wordpress_sites.yml
  sed -i "" -e "/^#/! s|example.test|${PROJECT_NAME_NO_TLD}.test|g" ${PROJECT}/${SUBTREES[0]}/group_vars/development/wordpress_sites.yml

  # Staging
  sed -i "" -e "s|git@github.com:example/example.com.git|${REPO_URL}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/staging/wordpress_sites.yml
  sed -i "" -e "s|branch: master|branch: staging|g" ${PROJECT}/${SUBTREES[0]}/group_vars/staging/wordpress_sites.yml
  sed -i "" -e "/^#/! s|example.com|${PROJECT_NAME}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/staging/vault.yml
  sed -i "" -e "/^#/! s|example.com|${PROJECT_NAME}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/staging/wordpress_sites.yml

  # Production
  sed -i "" -e "s|git@github.com:example/example.com.git|${REPO_URL}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/production/wordpress_sites.yml
  sed -i "" -e "s|branch: master|branch: production|g" ${PROJECT}/${SUBTREES[0]}/group_vars/production/wordpress_sites.yml
  sed -i "" -e "/^#/! s|example.com|${PROJECT_NAME}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/production/vault.yml
  sed -i "" -e "/^#/! s|example.com|${PROJECT_NAME}|g" ${PROJECT}/${SUBTREES[0]}/group_vars/production/wordpress_sites.yml
fi;
git -C ${PROJECT} add . >> ~/.twine.log 2>&1
git -C ${PROJECT} commit -m "Partial Trellis configuration" >> ~/.twine.log 2>&1

# Rename branch and push to origin
printf "${COLOR_GREEN}Renaming branch production and pushing it to origin...${NO_COLOR}\n\n"
git -C ${PROJECT} branch -m production >> ~/.twine.log 2>&1
git -C ${PROJECT} push origin production >> ~/.twine.log 2>&1

if [ "$OPTION_ENV" == "" ]; then
  # Rename branch and push to origin
  printf "${COLOR_GREEN}Creating branch staging and pushing it to origin...${NO_COLOR}\n\n"
  git -C ${PROJECT} checkout -b staging >> ~/.twine.log 2>&1
  git -C ${PROJECT} push origin staging >> ~/.twine.log 2>&1
fi;

# Print message
printf "${COLOR_GREEN}Project created!${NO_COLOR}\n"
