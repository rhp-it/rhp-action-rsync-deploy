#!/bin/sh

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
   echo "Path check failed. Please ensure that you use something inside public_html/*/ or vhost/*/ as a deploy target path"
   exit 1
fi

# The actual upload
echo "Uploading files..."
if [ ${INPUT_REPOSITORY_PATH:0:1} = "/" ]
then
  rsync --dry-run --delete-after -avz $GITHUB_WORKSPACE/${INPUT_REPOSITORY_PATH:1} server:$INPUT_SERVER_PATH
else
  rsync --dry-run --delete-after -avz $GITHUB_WORKSPACE/$INPUT_REPOSITORY_PATH server:$INPUT_SERVER_PATH
fi
echo "Upload finished."
