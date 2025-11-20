#!/bin/bash

# PWDIR is defined before entering this helper

TMPDIR=/tmp/
LOG_SPARSE=$TMPDIR/pw_sparse.log
LOG_SMATCH=$TMPDIR/pw_smatch.log
SENDMAIL=sendmail-ntlmv2.py
TMPMAIL=$TMPDIR/pw_mail_$(date +%Y%m%d-%s).txt
TMPTAG=$TMPDIR/pw_tag_msg.txt
PR_WORKURL=https://github.com/pkshih/rtw.git
PR_RECEIVER=linux-wireless@vger.kernel.org

PW_EAGAIN=203

MAIL_FOOTER="
---
https://github.com/pkshih/rtw.git
"

if [[ "$PWRTW" == "" ]]; then
PW_WIRELESS_TREE=wireless-next
PW_RTW_TREE=rtw-next
else
PW_WIRELESS_TREE=wireless
PW_RTW_TREE=rtw
fi

PR_UPSTREAM=$PW_WIRELESS_TREE/main

export PWDIR TMPDIR
export LOG_SPARSE LOG_SMATCH
export SENDMAIL TMPMAIL MAIL_FOOTER
export TMPTAG

