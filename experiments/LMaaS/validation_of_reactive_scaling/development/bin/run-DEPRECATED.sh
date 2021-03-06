#!/usr/bin/env bash
set -o pipefail
IFS=$'\n\t'

usage() {
echo -n "${BASH_SOURCE[0]} [OPTIONS] [ARGS]

 Performs an experiment to determine the threshhold to start scaling databases.
 
 Parameters:
   loop					Specify the start user load, end user load and incrementing interval. (Format: NN:NN:NN)

 Options:
   -d | --duration 		Specify the duration in seconds for each run. (Default: 60)
   -h | --help 			Display this message

 Note:
   This script MUST be executed from within the experiment directory.

 Examples:
   # Executes the experiment: 10 users for first run, 20 users for second run, .., 100 users for last run.
   ${BASH_SOURCE[0]} 10:100:10

"
exit 0;
}

## CONFIGURE VARIABLES
cassandra_pod="cassandra-0"

args_start_user_load=1
args_end_user_load=1
args_increment_user_load=1
flag_duration=30;

## HELPER FUNCTIONS
readonly LOG_FILE="/exp/var/logs/$(basename "$0").log"
info()    { echo "[INFO]    $@" | tee -a "$LOG_FILE" >&2 ; }
warning() { echo "[WARNING] $@" | tee -a "$LOG_FILE" >&2 ; }
error()   { echo "[ERROR]   $@" | tee -a "$LOG_FILE" >&2 ; }
fatal()   { echo "[FATAL]   $@" | tee -a "$LOG_FILE" >&2 ; exit 1 ; }
cleanup() {
	return
}
get_input() {
	# PARSE INPUT
	while [[ $1 = -?* ]]; do
	  case $1 in
		-d|--duration)
		    shift;
		    flag_duration=${1}
		    ;;
	  	-h|--help) usage >&2; exit 0 ;;
	    *)
			fatal "Flag provided but not defined: '$1'. Use --help to display usage."
	  esac
	  shift
	done
	args=$@

	# VALIDATE INPUT
	if [ -z flag_date ] && ! [[ $flag_date =~ $DATE_REGEX ]] ; then
		info $flag_date
		fatal "Date flag provided but expected date as YYYYMMDD (eg: 20160628)";
	fi

	# # Display help as default when no argument is given
	# if [ -z $args ] ; then
	# 	usage >&2;
	# fi
	return
}
setup_experiment() {
	rm -r /exp/var >&/dev/null
	mkdir /exp/var >&/dev/null
	mkdir -p /exp/var/results /exp/var/logs
	kubectl exec $cassandra_pod -- cqlsh -e "CREATE KEYSPACE IF NOT EXISTS scalar WITH replication = {'class':'SimpleStrategy', 'replication_factor':1};"
	kubectl exec $cassandra_pod -- cqlsh -e "CREATE TABLE IF NOT EXISTS scalar.logs (id text PRIMARY KEY, timestamp text, message text);"
}
setup_run() {
	local user_peak_load=$1
	local duration=$2

	# Create temporary files
	cp /exp/etc/experiment-template.properties /tmp/experiment.properties
	sed -ie "s@USER_PEAK_LOAD_TEMPLATE@${user_peak_load}@g" /tmp/experiment.properties
	sed -ie "s@USER_PEAK_DURATION_TEMPLATE@${duration}@g" /tmp/experiment.properties
}
teardown_run() {
	local user_peak_load=$1

	# Remove temporary files
	rm /tmp/experiment.properties

	# Remove unneeded run files.
	rm -f logfile-*.txt residence-times--tmp-experiment-properties.dat mythreaddump.txt

	# Gather results
	mv results--tmp-experiment-properties.dat /exp/var/results/run-${user_peak_load}.dat

	# Remove data added to database
	kubectl exec $cassandra_pod -- cqlsh -e "TRUNCATE scalar.logs;"
}
run() {
	local user_peak_load=$1
	local duration=$2

	setup_run $user_peak_load $duration
	java -jar /exp/lib/scalar-1.0.0.jar /exp/etc/platform.properties /tmp/experiment.properties >&/dev/null
	teardown_run $user_peak_load
}
teardown_experiment() {
	return
}

## MAIN
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
	fatal "Script may not be sourced."
fi
trap cleanup EXIT
get_input $@

setup_experiment
info "Stressing Cassandra with 250 requests per second"
run 250 30
info "Stressing Cassandra with 1000 requests per second"
run 1000 300
info "Finished stressing"

