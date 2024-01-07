#!/usr/bin/env bash

#
# Script to fix permissions on $HOME directory
#
# Note: group permissions are removed
# 	701 on directories does not allow group read (751 would allow group read)
# 	g-rwx on filex
#

find $HOME -type d -exec chmod 0701 {} +
find $HOME -type f -exec chmod u+rw,g-rwx,o-rwx {} +
chmod 600 ~/.ssh/id_rsa 
chmod 644 ~/.ssh/id_rsa.pub