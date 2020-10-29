#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9/10 or CentOS Hardening
#

#
# 8.1.6 Record Events That Modify the System's Network Environment (Scored)
# Modify by: Samson-W (sccxboy@gmail.com)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

ARCH64_AUDIT_PARAMS='-a exit,always -F arch=b64 -S sethostname -S setdomainname -k system-locale
-a exit,always -F arch=b32 -S sethostname -S setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/network -p wa -k system-locale'
ARCH32_AUDIT_PARAMS='-a exit,always -F arch=b32 -S sethostname -S setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/network -p wa -k system-locale'

FILE='/etc/audit/rules.d/audit.rules'
FILESET='/etc/audit/rules.d/*.rules'

# This function will be called if the script status is on enabled / audit mode
audit () {
    # define custom IFS and save default one
    d_IFS=$IFS
    IFS=$'\n'
    is_64bit_arch
    if [ $FNRET=0 ]; then 
	AUDIT_PARAMS=$ARCH64_AUDIT_PARAMS			
    else
	AUDIT_PARAMS=$ARCH32_AUDIT_PARAMS
    fi
    for AUDIT_VALUE in $AUDIT_PARAMS; do
        debug "$AUDIT_VALUE should be in file $FILESET"
        does_valid_line_exist_in_fileset "$FILESET" "$AUDIT_VALUE"
        if [ $FNRET != 0 ]; then
            crit "$AUDIT_VALUE is not in file $FILESET"
        else
            ok "$AUDIT_VALUE is present in $FILESET"
        fi
    done
    IFS=$d_IFS
}

# This function will be called if the script status is on enabled mode
apply () {
    d_IFS=$IFS
    IFS=$'\n'
    for AUDIT_VALUE in $AUDIT_PARAMS; do
        debug "$AUDIT_VALUE should be in file $FILESET"
        does_valid_line_exist_in_fileset $FILESET "$AUDIT_VALUE"
        if [ $FNRET != 0 ]; then
            warn "$AUDIT_VALUE is not in file $FILESET, adding it to $FILE"
            add_end_of_file $FILE $AUDIT_VALUE
	    check_auditd_is_immutable_mode
        else
            ok "$AUDIT_VALUE is present in $FILESET"
        fi
    done
    IFS=$d_IFS
}

# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ -r /etc/default/cis-hardening ]; then
    . /etc/default/cis-hardening
fi
if [ -z "$CIS_ROOT_DIR" ]; then
    echo "There is no /etc/default/cis-hardening file nor cis-hardening directory in current environment."
    echo "Cannot source CIS_ROOT_DIR variable, aborting."
    exit 128
fi

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r $CIS_ROOT_DIR/lib/main.sh ]; then
    . $CIS_ROOT_DIR/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi
