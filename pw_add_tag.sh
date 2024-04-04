#!/bin/bash

PWDIR=`dirname $0`
. $PWDIR/pw_env.sh

today=`date +%Y-%m-%d`
start_commit=`git merge-base HEAD wireless-next/main`
tagname=rtw-next-$today

echo "rtw-next patches for v6.x

<add some short description>

Major changes:

rtl8xxxu:

rtlwifi:

rtw88:

rtw89:

" > $TMPTAG

echo "###################### Summary for reference" >> $TMPTAG
git log $start_commit...HEAD --oneline --decorate=no | cut -f 2- -d ' ' | sort | sed "s/^/# /" >> $TMPTAG
echo "# -----------" >> $TMPTAG
git shortlog $start_commit...HEAD | sed "s/^/# /" >> $TMPTAG


############################################################################
# enter editor to add message

echo "Going to add tag: $tagname"

git tag $tagname -s -F $TMPTAG -e
[ "$?" != "0" ] && exit 1

# tag is added
echo "New tag is added: $tagname"

# push?
read -p "Push $tagname to rtw.git? (y) " y

if [ "$y" == "y" ]; then
	git push rtw $tagname
	git fetch rtw-https
	echo "Ready to generate request-pull"
else
	echo "Remember to push before generate request-pull by:"
	echo "	git push rtw $tagname"
	exit 0
fi

