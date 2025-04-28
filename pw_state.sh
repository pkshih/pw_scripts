#!/bin/bash

# test example:
#   "" 13576795 13576796

# update state of patch
# $1="State"
# $2-: ID(s)

PWDIR=`dirname $0`
. $PWDIR/pw_env.sh

state="$1"
ids="${@:2}"
firstid=
n=0

declare -A patch

for id in $ids; do
	x=`pwclient info $id`
	[ "$?" != "0" ] && exit 1

	[ "$n" == "0" ] && firstid=$id

	# Information for patch id 13576796
	# ---------------------------------
	# - archived      : False
	# - commit_ref    :
	# - date          : 2024-02-29 07:45:08
	# - delegate      : kvalo
	# - delegate_id   : 25621
	# - filename      : 2-8-wifi-rtw89-8922a-add-coexistence-helpers-of-SW-grant
	# - hash          : 237864049ebdccab94b036050d3cdf4ae62c2974
	# - id            : 13576796
	# - msgid         : <20240229074514.219276-3-pkshih@realtek.com>
	# - name          : [2/8] wifi: rtw89: 8922a: add coexistence helpers of SW grant
	# - project       : Linux Wireless Mailing List
	# - project_id    : 15
	# - state         : New
	# - state_id      : 1
	# - submitter     : Ping-Ke Shih <pkshih@realtek.com>
	# - submitter_id  : 175699

	patch["$n,id"]=`echo "$x" | grep "^- id " | cut -f 2 -d ":"`
	patch["$n,name"]=`echo "$x" | grep "^- name " | sed "s/^[^:]*:[ ]*//"`
	patch["$n,state"]=`echo "$x" | grep "^- state " | cut -f 2 -d ":"`
	patch["$n,submitter"]=`echo "$x" | grep "^- submitter " | cut -f 2 -d ":"`

	n=$((n+1))
done

echo -e "\e[0;44m-------------<< select states >>------------------\e[0m"

states=(
	"Accepted"
	"Changes Requested"
	"Rejected"
	"Under Review"
	"Not Applicable"
	"Superseded"
	"Deferred"
	"Mainlined"
)

PS3=$'\n'"Target: $ids"$'\nDo #? '

if [ "$state" == "" ]; then
	select s in "${states[@]}"
	do
		echo $s && state="$s" && break
	done
fi

for i in `seq 0 $((n-1))`; do
	echo -e "${patch["$i,id"]} ${patch["$i,state"]}\t${patch["$i,name"]} (${patch["$i,submitter"]})"
done

read -p "Apply state ($state) to $n patch(es)? (y) " y
[ "$y" != "y" ] && exit 1

echo "Applying state ($state) to $ids ..."

pwclient update -s "$state" $ids

echo -e "\e[0;44m-------------<< for notification email >>------------------\e[0m"

read -p "Send notification to $firstid? (y) " y
[ "$y" != "y" ] && exit 1

notify_msg="Set patchset state to $state
"

for i in `seq 0 $((n-1))`; do
	notify_msg="$notify_msg\n${patch["$i,name"]}"
done

$PWDIR/pw_reply.sh $firstid "$notify_msg"

