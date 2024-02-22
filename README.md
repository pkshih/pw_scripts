A set of scripts to manage Realtek WiFi drivers to get merged into rtw.git.

It uses pwclient basically to manage patches, and shell scripts as helpers to acheieve workflow.

# Workflow - apply patches
* pwclient
  * search for patch IDs
* pw_apply.sh
  * apply IDs --> check patch (checpath, build, sparse/smatch) --> send notification mail
  * manually push to git
* pw_state.sh
  * set patch state

# Workflow -- notify failed to apply patches
* pw_state.sh
  * set patch state & send notification mail

# Workflow - send pull request
* pw_add_tag.sh
  * send pull request
* copy-paste and send email


# Other helpers:
* pw_check_patchset.sh
  * run sparse/smatch for whole patchset
* pw_check_top.sh
  * run checkpatch/build driver for every patch on the top 
* pw_env.sh
  * evnironement variables
* pw_reply.sh
  * send notification mail 
