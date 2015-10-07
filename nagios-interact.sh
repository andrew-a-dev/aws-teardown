#!/usr/bin/env bash

# Command-line script to enable/disable checks and notifications on
# nagios (e.g., for terminating EC2 instances)

# Intended usage (e.g.):
#   ./nagios-interact enable-notifications staging-server1
#   ./nagios-interact disable-active-checks thumbor-aws-i5678402

# References:
#   http://docs.icinga.org/latest/en/cgiparams.html#cgiparams-commands
#   http://eggsonbread.com/2011/03/18/disable-enable-nagios-notifications-via-command-line-curl

nagios_host="https://nagios.voxops.net"
nagios_path="/cgi-bin/nagios3/cmd.cgi"

usage() {
    #echo -e "$0 uses curl to enable/disable settings for a host, on Nagios"
    echo -e "Usage:\n  $0 nagios_command host_name [other_curl_options...]\n"
    echo -e "  nagios_command can be one of: enable-notifications, disable-notifications, enable-active-checks, disable-active-checks"
    echo -e "  host_name is the name of the host in Nagios"
    echo -e "  any following [other_curl_options...] are passed directly to curl"
    echo -e "\ncurl is invoked with -n to allow use of .netrc file, but can also pass --user (etc.) as trailing options"
    echo -e "The response is just the HTTP status code, which is not necessarily an indicator of overall success."
}

# Check that we have a valid command
case "$1" in
    enable-notifications)
        cmd_typ=24
        ;;
    disable-notifications)
        cmd_typ=25
        ;;
    enable-active-checks)
        cmd_typ=47
        ;;
    disable-active-checks)
        cmd_typ=48
        ;;
    *)
        usage
        exit 1
        ;;
esac

# We must have a hostname
if [ -z "$2" ]; then
    usage
    exit 2
fi

# Make sure curl is available (there's only a million ways to do this,
# I never know how to pick one)
hash curl || {
    echo "Could not find curl. Exiting."
    exit $?
}

nagios_query_string="cmd_typ=${cmd_typ}&cmd_mod=2&host=$2"

curl -s -i -n "${nagios_host}${nagios_path}" -d "${nagios_query_string}" ${*:3} | head -n1

# We return curl's exit status this way, because $? is from the last
# command in the pipe. [Although curl's exit status values don't look
# especially useful to us...]
exit ${PIPESTATUS[0]}
