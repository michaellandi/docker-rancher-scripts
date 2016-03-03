#!/bin/bash
# Author : Karim Vaes
# Github : kvaes
# Version : 0.1

# Variable Check
echo "# Checking Variables"
if [ -z "$1" ];
then
  echo "!!! no hosturl was supplied"
  exit 2
else
  echo "### Host Url detected"
fi

#Setup Variables
echo "# Setting Variables"
HOST_URL=$1
AGENT_VERSION="v0.9.2"
LOCAL_IP=`ifconfig eth0 | awk '/inet addr/{print substr($2,6)}'`
echo "### Server   = $HOST_URL"
echo "### Version  = $AGENT_VERSION"
echo "### Agent IP = $LOCAL_IP"

echo "# Deploying Rancher Agent"
sudo docker run -d –e "CATTLE_AGENT_IP=$LOCAL_IP" --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:$AGENT_VERSION $HOST_URL