#!/bin/sh

COLOR_RED='\033[0;31m'
COLOR_DEFAULT='\033[0m'
COLOR_YELLOW='\033[0;33m'

# Prepare SSH connection
mkdir -p /root/.ssh/
echo "${INPUT_PRIVATE_SSH_KEY}" > /root/.ssh/id_rsa.key
chmod 600 /root/.ssh/id_rsa.key
ssh-keyscan -H ${INPUT_HOST} >> /root/.ssh/known_hosts
cat >>/root/.ssh/config <<END
Host server
    HostName ${INPUT_HOST}
    User ${INPUT_USER}
    Port ${INPUT_PORT}
    IdentityFile /root/.ssh/id_rsa.key
END

# Hardwired path checks to prevent accidents
if  [[ ! $INPUT_SERVER_PATH =~ "(public_html|vhosts)/(.*)/" ]]; then
   echo -e "${COLOR_RED} Path check failed for ${INPUT_SERVER_PATH} .${COLOR_DEFAULT}Please ensure that you use something inside public_html/*/ or vhost/*/ as a deploy target path"
   exit 1
fi

OPT_DRY_RUN=''
if [[ ${INPUT_DRY_RUN} == "true" ]]; then
    OPT_DRY_RUN='--dry-run'
    echo -e "${COLOR_YELLOW}DRY RUN MODE. Rsync will do nothing. Set the DRY_RUN option of this workflow to false to actually enable rsync.${COLOR_DEFAULT}"
fi

# The actual upload
echo "Uploading files..."
if [ ${INPUT_REPOSITORY_PATH:0:1} = "/" ]
then
  rsync $OPT_DRY_RUN --include='**.gitignore' --exclude='/public/*/' --exclude='/.git' --filter=':- .gitignore' --delete-after -avz $GITHUB_WORKSPACE/${INPUT_REPOSITORY_PATH:1} server:$INPUT_SERVER_PATH
else
  rsync $OPT_DRY_RUN --include='**.gitignore' --exclude='/public/*/' --exclude='/.git' --filter=':- .gitignore' --delete-after -avz $GITHUB_WORKSPACE/$INPUT_REPOSITORY_PATH server:$INPUT_SERVER_PATH
fi
echo "Upload finished."
