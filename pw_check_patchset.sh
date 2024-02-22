#!/bin/bash

# This is to check the last N commits ($1)

ncommits=$1

# ----------------------------------------------------------------------
function remove_uncessary_log()
{
	logfile=$1

	# WARNING: Module.symvers is missing.                                             
	#          Modules may not have dependencies or modversions.                      
	#          You may get many unresolved symbol errors.                             
	#          You can set KBUILD_MODPOST_WARN=1 to turn errors into warning          
	#          if you want to proceed at your own risk.                               
	sed -i "/^WARNING: Module.symvers/,+4d" $logfile

	# WARNING: modpost: "__usecs_to_jiffies" [/work/linux-src/linux-stable/drivers/net/wireless/realtek/rtl818x/rtl8180/rtl818x_pci.ko] undefined!
	sed -i "/^WARNING: modpost:/d" $logfile
}

function check_sparse_log()
{
	remove_uncessary_log $LOG_SPARSE

	x=`grep "\(warn\|err\)" $LOG_SPARSE`

	[ -z "$x" ] && return 0

	echo -e "\e[0;43mvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv sparse warning/error:\e[0m"
	echo "$x"
	echo -e "\e[0;43m^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\e[0m"

	return 1
}

function check_smatch_log()
{
	remove_uncessary_log $LOG_SMATCH

	x=`grep "\(warn\|err\)" $LOG_SMATCH`

	[ -z "$x" ] && return 0

	echo -e "\e[0;43mvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv smatch warning/error:\e[0m"
	echo "$x"
	echo -e "\e[0;43m^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\e[0m"

	return 1
}

# ----------------------------------------------------------------------
# sparse
git diff HEAD~$ncommits --name-only | xargs touch

pushd .

cd drivers/net/wireless/realtek/
make -f Makefile-rtw sparse -j8 2>&1 | tee $LOG_SPARSE
ret=$?
#echo "ret = $ret"
[ "$ret" == "0" ] && check_sparse_log
ret=$?
#echo "ret = $ret"

popd

if [ $ret != 0 ]; then
	echo -n "Continue? (y) "
	read y && [ $y != "y" ] && exit 1
fi

# ----------------------------------------------------------------------
# smatch
git diff HEAD~$ncommits --name-only | xargs touch

pushd .

cd drivers/net/wireless/realtek/
make -f Makefile-rtw smatch -j8 2>&1 | tee $LOG_SMATCH
ret=$?
#echo "ret = $ret"
[ "$ret" == "0" ] && check_smatch_log
ret=$?
#echo "ret = $ret"

popd

# ----------------------------------------------------------------------
# spatch (cost a lot of time)
#make coccicheck MODE=report SPFLAGS="--use-patch-diff 652c9642eda662b337b2408f81a2b4966c3e6d82^..2422c2158fb51b7ba94e0a8b4ac280c88e0c73a6"

# ----------------------------------------------------------------------

if [ $ret != 0 ]; then
	echo -n "Continue? (y) "
	read y && [ $y != "y" ] && exit 1
fi

exit 0

