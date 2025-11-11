#!/bin/bash

# Test examples
#    base: 42ffccd0a36e ("wifi: rtlwifi: rtl_usb: Store the endpoint addresses")
#    apply: pw_apply.sh 13559073 13559387 13561583

# Interactive mode to modify commit message and etc
#    PWINT=1 pw_apply.sh
# Dry-run mode to apply all patches
#    PWDRY=1 pw_apply.sh
# Use 3-way git-am
#    PW3=1 pw_apply.sh

PWDIR=`dirname $0`
. $PWDIR/pw_env.sh

ids=$@
firstid=
n=0
guess_n=`echo "$ids" | wc -w`
[ "$PW3" == "1" ] && with_3way="-3"

for id in $ids; do
	echo -e "\e[0;44m-------------------------------------------------- start $((n+1))/$guess_n: $id\e[0m"

	pwclient git-am $with_3way $id
	[ "$?" != "0" ] && exit 1;
	[ "$n" == "0" ] && firstid=$id

	if [ "$PWINT" != "" ]; then
		while [ 1 ]; do
			read -p "Edit commit message by 'git commit --amend'? (e/n/s) " y
			if [ "$y" == "e" ]; then
				git commit --amend
			elif [ "$y" == "n" ]; then
				break
			elif [ "$y" == "s" ]; then
				PWINT=
				break
			fi
		done
	fi

	while [ 1 ]; do
		$PWDIR/pw_check_top.sh
		ret=$?
		if [ "$ret" == "0" ]; then
			break
		elif [ "$ret" == "$PW_EAGAIN" ]; then
			git commit --amend
		elif [ "$ret" != "0" ]; then
			exit 1
		fi
	done

	echo -e "\e[0;44m-------------------------------------------------- end $((n+1))/$guess_n: $id\e[0m"

	n=$((n+1))
done

echo -e "\e[0;44m-------------<< run checkers for all patchset >>------------------\e[0m"
$PWDIR/pw_check_patchset.sh $n
[ "$?" != "0" ] && exit 1

[ "$PWDRY" == "1" ] && exit 0
echo -e "\e[0;44m-------------<< for notification email >>------------------\e[0m"
notify_msg="$n patch(es) applied to rtw-next branch of rtw.git, thanks."
t=`git log --oneline -n $n --decorate=no --reverse`
notify_msg="$notify_msg

$t"

$PWDIR/pw_reply.sh $firstid "$notify_msg"

echo -e "\e[0;44m-------------<< remaining things >>------------------\e[0m"
echo "1. check commits and push out"
echo "2. set commits' states in patchwork"
