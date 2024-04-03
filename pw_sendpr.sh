#!/bin/bash

PWDIR=`dirname $0`
. $PWDIR/pw_env.sh

tag_name=$1
[ "$tag_name" == "" ] && exit 1

echo "Process tag - $tag_name..."

################################################################
# mail header
my_name=`git config --get user.name`
my_sname=`git config --get user.name | cut -f 1 -d ' '`
my_email=`git config --get user.email`

echo "From: $my_name <$my_email>
To: $PR_RECEIVER
Subject: pull-request: $tag_name

Hi,

A pull-request of rtw-next to wireless-next tree, more info below. Please
let me know if any problems.

Thanks
$my_sname

---
" > $TMPMAIL

################################################################
# mail content of pull-request
start_point=`git merge-base $tag_name $PR_UPSTREAM`

git request-pull $start_point https://github.com/pkshih/rtw.git $tag_name >> $TMPMAIL

#################################################################
# edit mail content

receivers=$PR_RECEIVER

while [ 1 ]; do
	read -p "Send to $receivers? (y/e/n) " y
	case "$y" in
	'y')
		break
		;;
	'n')
		exit 1
		;;
	'e')
		vim $TMPMAIL
		;;
	esac
done

#################################################################
# send out

while [ 1 ]; do
	cat $TMPMAIL | $SENDMAIL -i $receivers
	[ "$?" == "0" ] && break

	while [ 1 ]; do
		read -p "failed to send. Try again? (y/n) " y
		if [ "$y" == "y" ]; then
			break
		elif [ "$y" == "n" ]; then
			exit 1;
		fi
	done
done

