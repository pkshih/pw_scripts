#!/bin/bash

# This is to check the last commit (top of tree)

# To run all checks unconditionally, use 'yes ./pw_check.sh'

# ----------------------------------------------------------------------
# check subject prefix -- wifi: rtl
#
# $ git log --oneline -1 --decorate=no 
#   e43d69e3c759 wifi: rtlwifi: Fix setting the basic rates

subject_sha1=`git log --oneline -1 --decorate=no`
subject=`echo $subject_sha1 | cut -f 2- -d ' '`

match=`echo $subject | sed -n "s/\(wifi: \(rtw89\|rtw88\|rtlwifi\|rtl8xxxu\)\): .*/\2/p"`
dirmatch=`git diff HEAD^ --name-only | grep drivers/net/wireless/realtek/$match`
extra_msg=""
[ "$dirmatch" == "" ] && extra_msg="(because of mismatch of directory)"

if [ "$match" == "" ] || [ "$dirmatch" == "" ]; then
	echo -e "\e[0;33minvalid subject: $subject $extra_msg\e[0m"
	if [ "$PWDRY" == "" ]; then
		echo -n "Continue? (y) "
		read y && [ "$y" != "y" ] && exit 1
	fi
fi

# ----------------------------------------------------------------------
# checkpatch
./scripts/checkpatch.pl <(git show --pretty=email)
ret=$?

if [ "$PWDRY" == "" ] && [ $ret != 0 ]; then
	echo -n "Continue? (y) "
	read y && [ "$y" != "y" ] && exit 1
fi


# ----------------------------------------------------------------------
# build
pushd .

cd drivers/net/wireless/realtek/
make -f Makefile-rtw -j8
ret=$?

popd

if [ "$PWDRY" == "" ] && [ $ret != 0 ]; then
	echo -n "Continue? (y) "
	read y && [ "$y" != "y" ] && exit 1
fi

