#!/bin/bash

# arguments:
#    $1: commit ID from patchwork
#    $2: message you want to reply to author, such as "thanks"

PWDIR=`dirname $0`
. $PWDIR/pw_env.sh

# 13566773
id=$1
reply_msg="$2"

debug=

# Original mail:
#    From: Ping-Ke Shih <pkshih@realtek.com>
#    To: kvalo@kernel.org
#    Cc: timlee@realtek.com,
#    	damon.chen@realtek.com,
#    	linux-wireless@vger.kernel.org
#    Subject: [PATCH 3/3] wifi: rtw89: pci: implement PCI CLK/ASPM/L1SS for WiFi 7 chips
#    Date: Thu, 22 Feb 2024 14:42:58 +0800
#    Message-Id: <20240222064258.59782-4-pkshih@realtek.com>
#    X-Mailer: git-send-email 2.25.1
#    In-Reply-To: <20240222064258.59782-1-pkshih@realtek.com>
#    References: <20240222064258.59782-1-pkshih@realtek.com>
#    MIME-Version: 1.0
#    Content-Transfer-Encoding: 8bit
#    
#    
# Reply mail:
#    From: Ping-Ke Shih <pkshih@realtek.com>
#    To: Ping-Ke Shih <pkshih@realtek.com>
#    Subject: Re: [PATCH 3/3] wifi: rtw89: pci: implement PCI CLK/ASPM/L1SS for WiFi 7 chips
#    In-Reply-To: <20240222064258.59782-4-pkshih@realtek.com>   
#    References: <20240222064258.59782-1-pkshih@realtek.com>
#     <20240222064258.59782-4-pkshih@realtek.com>
#    MIME-Version: 1.0
#    Content-Transfer-Encoding: 8bit
#    
# Key points:
#    reply[In-Reply-To] = original[Message-Id]
#    reply[References] = original[References] + original[Message-Id]
#

# body:
#    cat patch_from_pwclient.patch | sed -n "/^$/,/---/p" | sed  "/---/,/---/d" | tail -n +2 - | sed "s/^/> /"
#

# main fields: "From: ", "To: ", "Subject: ", "Message-Id: ", "In-Reply-To: ", "References: "
#    cat patch_from_pwclient.patch | sed -n "/^From:/,/^ /p" | sed "N; s/\n / /" | head -n 1 -
#

function get_fields()
{
	local mhdr_l="$1"
	local field_l="$2"

	# Cc: Jes Sorensen <Jes.Sorensen@gmail.com>,
	# 	Kalle Valo <kvalo@kernel.org>,
	# 	Ping-Ke Shih <pkshih@realtek.com>,
	# 	Bitterblue Smith <rtl8821cerfe2@gmail.com>,
	# 	Sebastian Andrzej Siewior <bigeasy@linutronix.de>

	echo "$mhdr_l" | sed -n "s/^$field_l: //pI; t again; b end; :again; n; s/^[ \t]\+//p; t again; :end" |
		sed ":again; N; s/\n/ /; t again"
}

echo "Getting $id from patchwork..."
full=`pwclient view $id`
mhdr=`echo "$full" | sed -n ":again; s/^$//; t end; p; n; b again; :end; n; b end"`

#################################################################
# parse fields

field_list="From To Cc Subject Message-Id In-Reply-To References"
declare -A original

[ "$debug" == "2" ] && echo -e "full: [[[[\n$full\n]]]]"

for f in $field_list; do
	original[$f]=`get_fields "$mhdr" "$f"`

	[ "$debug" == "1" ] && echo "$f: ${original[$f]}"
done

#################################################################
# generate reply fields

my_name=`git config --get user.name`
my_email=`git config --get user.email`

declare -A reply

reply["From"]="$my_name <$my_email>"
reply["To"]="${original["From"]}, ${original["To"]}"
reply["Cc"]="${original["Cc"]}"
reply["Subject"]="Re: ${original["Subject"]}"
reply["In-Reply-To"]="${original["Message-Id"]}"
reply["References"]="${original["References"]} ${original["Message-Id"]}"

#################################################################
# collect all receivers

function get_plain_email_addr()
{
	local complex="$1"

	# Martin Kaistra <martin.kaistra@linutronix.de>, linux-wireless@vger.kernel.org
	# --> martin.kaistra@linutronix.de linux-wireless@vger.kernel.org
	# linux-wireless@vger.kernel.org, <abc>abc@abc.com, <bcd>bcd@bcd.com
	# --> linux-wireless@vger.kernel.org abc@abc.com bcd@bcd.com
	echo $complex | sed "s/^[^<,]*<//" | sed "s/,[^<,]*</,/g" | sed "s/>[ ]*$//g" | sed "s/>[ ]*,/ /g" | sed "s/[ ]*,[ ]*/ /g"
}

t=`get_plain_email_addr "${reply["To"]}"`
receivers="$receivers $t"
[ "$debug" == "1" ] && echo "receivers=$receivers +To:${reply["To"]}"
t=`get_plain_email_addr "${reply["Cc"]}"`
receivers="$receivers $t"
[ "$debug" == "1" ] && echo "receivers=$receivers +Cc:${reply["Cc"]}"

#################################################################
# make body, and add wrote at beginning of body

body=`echo "$full" | sed -n "/^$/,/^---$/p" | sed -n "/^---$/q;p" | tail -n +2 - | sed "s/^/> /"`
body="${original["From"]} wrote:

$body"

#################################################################
# show reply for debugging

if [ "$debug" == "1" ]; then

echo ">>>>>>>>>>>>>>>>> Reply"

echo "receivers=$receivers"

for f in $field_list; do
	echo "$f: ${reply[$f]}"
done

echo -e "body:\n$body"

fi

#################################################################
# create template email body

for f in $field_list; do
	[ "${reply[$f]}" == "" ] && continue
	reply_body="$reply_body$f: ${reply[$f]}
"
done

reply_body="$reply_body
$body"

#echo -e "Final:\n$reply_body"

echo "$reply_body" > $TMPMAIL
echo -e "\n$reply_msg" >> $TMPMAIL
echo "$MAIL_FOOTER" >> $TMPMAIL

#################################################################
# edit mail content

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
