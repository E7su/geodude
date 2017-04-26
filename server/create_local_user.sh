#!/bin/bash
# Script to add a user to Linux system
if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	egrep -q "^$username" /etc/passwd 
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
		useradd -m $username
		passwd $username
		usermod -a -G sudo $username

		# generate ssh key
		mkdir /home/$username/.ssh
		ssh-keygen -q -t rsa -b 4096 -f /home/$username/.ssh/id_rsa -N ""

		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may add a user to the system"
	exit 2
fi

exit 0
