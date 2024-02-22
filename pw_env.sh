#!/bin/bash

# PWDIR is defined before entering this helper

TMPDIR=/tmp/
LOG_SPARSE=$TMPDIR/pw_sparse.log
LOG_SMATCH=$TMPDIR/pw_smatch.log
SENDMAIL=sendmail-ntlmv2.py
TMPMAIL=$TMPDIR/pw_mail_$(date +%Y%m%d-%s).txt
TMPTAG=$TMPDIR/pw_tag_msg.txt

MAIL_FOOTER="
---
https://github.com/pkshih/rtw.git
"

export PWDIR TMPDIR
export LOG_SPARSE LOG_SMATCH
export SENDMAIL TMPMAIL MAIL_FOOTER
export TMPTAG

