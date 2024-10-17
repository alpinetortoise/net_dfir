clear
export GREP_COLORS="01;35"

RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
CYAN='\033[35m'
RESET='\033[0m'
BOLD='\033[1m'
BOLD_PINK='\033[1;35m'
DIV="=============================="

PCAP_FILE="$1"
LOG_DIR="case001"

BANNER="

███╗   ██╗███████╗████████╗    ██████╗ ███████╗██╗██████╗ 
████╗  ██║██╔════╝╚══██╔══╝    ██╔══██╗██╔════╝██║██╔══██╗
██╔██╗ ██║█████╗     ██║       ██║  ██║█████╗  ██║██████╔╝
██║╚██╗██║██╔══╝     ██║       ██║  ██║██╔══╝  ██║██╔══██╗
██║ ╚████║███████╗   ██║       ██████╔╝██║     ██║██║  ██║
╚═╝  ╚═══╝╚══════╝   ╚═╝       ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝

Perform basic network analysis on network captures.
"

log_header() {
	local heading=$1
	local sub_heading=$2

	if [ -z "$sub_heading" ]; then
		echo -e "${BLUE}${DIV}|${BOLD}${GREEN} ${heading} ${RESET}${BLUE}|${DIV}${RESET}"
	else
		echo -e "${BLUE}${DIV}|${BOLD}${GREEN} ${heading} - ${sub_heading} ${RESET}${BLUE}|${DIV}${RESET}"
	fi
}

log_value() {
	local title=$1
	local val=$2

	echo -e "${RED}${BOLD}[+] ${BLUE}${title}: ${RESET}${val}"
}

log_banner() {
	echo "$BANNER"
}

find_pe_files() {
	echo $(log_header "EXECUTABLES")
	echo

	cat $LOG_DIR/http.log | \
	zeek-cut -u ts id.orig_h id.orig_p id.resp_h id.resp_p resp_mime_types host uri | \
	grep "application/x-dosexec" | \
	awk '{$1=$1; printf "%s %s:%s %s:%s http://%s%s\n", $1, $2, $3, $4, $5, $7, $8}' | \
	column -t -s " "
	
	echo
}

map_active_directory() {
	echo $(log_header "ACTIVE DIRECTORY")
	echo

	local domain=$(cat $LOG_DIR/kerberos.log | zeek-cut service | grep krbtgt | head -n 1 | cut -d "/" -f 2)
	local dc_name=$(cat $LOG_DIR/kerberos.log | zeek-cut id.resp_h service | grep LDAP | head -n 1 | cut -d'/' -f2 | cut -d'.' -f1)
	local dc_ip=$(cat $LOG_DIR/kerberos.log | zeek-cut id.resp_h service | grep LDAP | head -n 1 | awk '{$1=$1; print}' | cut -d " " -f 1)

	echo $(log_value "FQDN" $domain)
	echo $(log_value "DC Name" $dc_name)
	echo $(log_value "DC IP" $dc_ip)

	# cat case001/kerberos.log | zcut id.orig_h id.resp_h id.resp_p request_type client service | head -n 1

	echo
}

execute_all() {
	log_banner
    find_pe_files
	map_active_directory
}

execute_all