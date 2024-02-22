#!/bin/bash

# Test examples
#    base: 42ffccd0a36e ("wifi: rtlwifi: rtl_usb: Store the endpoint addresses")
#    apply: pw_apply.sh 13559073 13559387 13561583

# Interactive mode to modify commit message and etc
#    PWINT=1 pw_apply.sh

PWDIR=`dirname $0`
. $PWDIR/pw_env.sh

ids=$@
firstid=
n=0
guess_n=`echo "$ids" | wc -w`

for id in $ids; do
	echo -e "\e[0;44m-------------------------------------------------- start $((n+1))/$guess_n: $id\e[0m"

	pwclient git-am $id
	[ "$?" != "0" ] && exit 1;
	[ "$n" == "0" ] && firstid=$id

	if [ "$PWINT" != "" ]; then
		while [ 1 ]; do
			read -p "Edit commit message by 'git commit --amend'? (y/n/s) " y
			if [ "$y" == "y" ]; then
				git commit --amend
			elif [ "$y" == "n" ]; then
				break
			elif [ "$y" == "s" ]; then
				PWINT=
				break
			fi
		done
	fi

	$PWDIR/pw_check_top.sh

	echo -e "\e[0;44m-------------------------------------------------- end $((n+1))/$guess_n: $id\e[0m"

	n=$((n+1))
done

echo -e "\e[0;44m-------------<< run checkers for all patchset >>------------------\e[0m"
$PWDIR/pw_check_patchset.sh $n
[ "$?" != "0" ] && exit 1

echo -e "\e[0;44m-------------<< for notification email >>------------------\e[0m"
notify_msg="$n patch(es) applied to rtw-next branch of rtw.git, thanks."
t=`git log --oneline -n $n --decorate=no --reverse`
notify_msg="$notify_msg

$t"

$PWDIR/pw_reply.sh $firstid "$notify_msg"

