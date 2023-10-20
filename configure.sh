#!/bin/bash
# Made by gabrieltsants

if [ -z "$1" ]; then
    echo "Usage: ./configure /dev/sdXX";
    exit 1;
fi

# Verify if docker is installed
if ! docker --version; then
	echo "'docker' command not found"
	exit 1
fi

# Verify if docker-compose is installed
if ! docker-compose --version; then
	echo "'docker-compose' command not found"
	exit 1
fi

cd $(dirname $0);

LABEL=$(lsblk -no label $1);
MOUNTPOINT=$(findmnt -n -o TARGET $1);
ACTUALPATH=$(pwd);
DOCKERFILE="docker-compose.yml";
ROOTPASSWORD='5iveL!fe'

function installGitlabOnDevice() {
    
    if [ -d gitlab ]; then sudo rm -Rf gitlab; fi
    
    mkdir -p gitlab/{config,logs,data};
    cp -rf $ACTUALPATH/$DOCKERFILE gitlab/;
    sed -i "s|MOUNTDEVICENAME|$MOUNTPOINT|g" "gitlab/$DOCKERFILE";
    cd gitlab;
    docker-compose up;
    exit 0;
}

if [ -z "$MOUNTPOINT" ]; then
    echo "Mount point '$1' not found";
    exit 1;
else
    cd $MOUNTPOINT;
    if [ -f "gitlab/$DOCKERFILE" ]; then
        read -p "A gitlab docker file exists ON '$MOUNTPOINT/gitlab', do you want to just run your server? (Y to continue, any other key to jump to installation) ";
        echo;
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd gitlab && docker-compose up;
            exit 0;
        fi
    fi
fi

echo -e "\nDevice: $LABEL\n";
echo -e "Mounted on $MOUNTPOINT\n";
read -p "Is this corret? (Y to continue, any other key to cancel) ";

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ "$(ls -A $MOUNTPOINT)" ]; then
        echo
        read -p "The directory '$MOUNTPOINT' not empty, do you want to continue? (Y to continue, any other key to cancel) ";
        echo 
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            installGitlabOnDevice;
        else
            echo "Installation canceled";
            exit 0;
        fi
    else
        installGitlabOnDevice;
    fi
else
    echo "Installation canceled";
    exit 0;
fi