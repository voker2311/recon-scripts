#!/bin/bash

target=$1

if [[ $# -eq 0 ]];then
	echo "[-] Please provide something to scan"
	echo "[*] Usage ./recon.sh <example.com>"
	exit 0
fi

startup_script(){
	if [ ! -d recon-files ];then
		echo "[*] Setting up a directory for recon files..."
		mkdir recon-files
	fi
}

subdomain_discovery(){
	# Subdomain discovery starts from here
	# Using findomain tool
	echo "[*] Scan started at $(date) (Make sure that the filename will be saved based on the target name given)"
	findomain=$(findomain -t "$target" --quiet | tee "recon-files/$target-findomain.txt")
	sleep 0.3
	echo "[*] Starting with subfinder tool"
	subfinder=$(subfinder -d "$target" -t 15 -o "recon-files/$target-domains.txt")
	# Recursive one (Third level subdomain/domain if any)
	subfinder_recursive=$(subfinder -d "$target" -t 10 -o "recon-files/$target-recursive-domains.txt" -recursive)
	sleep 0.3
	echo "[*] Amass scan started"
	amass=$(amass enum -d "$target" -o "recon-files/$target-amass-scan.txt")
	# Using crt.sh to get another set of subdomains
	# Hope you have provided a domain without http/https
	crt_sh=$(curl -s "https://crt.sh/?q=$target&output=json" | jq .[].name_value | tr '"' ' ' | awk '{gsub(/\\n/,"\n")}1' | awk '{print $1}' | sort -u | tee "recon-files/$target-crt-domains.txt")
	cat $findomain $subfinder $subfinder_recursive $amass $crt_sh | sort -u > recon-files/subdomains.final
	# Done with everything
	echo "[+] Subdomain discovery completed..."
}

http_discovery(){
	# Discovering alive HTTP sites
	echo "[*] Using httpx tool from project discovery"
	httpx -l recon-files/subdomains.final -silent -status-code -content-length -o recon-files/httpx-alive-urls.txt
	sleep 0.3
}


fetch_nuclei_scripts(){
	# Using basic nuclei scripts like .git,.env,robots.txt,conf files
	if [ ! -d nuclei-scripts ];then
		echo "[*] Nuclei scripts will stored in nuclei-scripts"
		mkdir nuclei-scripts
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposures/configs/git-config.yaml" -O nuclei-scripts/git.yaml
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposures/configs/docker-compose-config.yaml" -O nuclei-scripts/docker.yaml
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposures/files/ds_store.yaml" -O nuclei-scripts/ds_store.yaml
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposures/tokens/google/oauth-access-key.yaml" -O nuclei-scripts/oauth-key.yaml
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposed-panels/django-admin-panel.yaml" -O nuclei-scripts/django-admin.yaml
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposed-panels/wordpress-login.yaml" -O nuclei-scripts/wordpress-login.yaml
		echo "[*] Make sure to check others on httpx official github repo"
	fi
}

execute_nuclei_scripts(){
	# Using for loop to get all the yaml files
	for i in $(ls nuclei-scripts/*.yaml);do
		file=$(echo "$i" | awk -F\. '{print $1}')
		nuclei -l recon-files/httpx-alive-urls.txt -t $i -o recon-files/$file-output.txt
		sleep 0.3;
	done
}

wayback_for_everyone(){
	# Getting wayback archives for each domain
	if [ ! -d wayback-urls ];then
		echo "[*] Waaybackkkk OK..."
		mkdir wayback-urls
	fi
	for i in $(cat recon-files/subdomains.final);do
		waybackurls $i > wayback-urls/$i-wayback.url
		sleep 0.1;
	done
	echo "Wanna test again with gau tool? Reply with y/n: "
	read reply
	if [ "$reply" == "y" ] || [ "$reply" == "Y" ];then
		gau_if_required
	fi
}

gau_if_required(){
	# Same technique as that of waybackurls
	if [ ! -d gau_tool_files ];then
		echo "[*] You asked for gau, here I am.. :)"
		mkdir gau_tool_files
	fi
	for i in $(cat recon-files/subdomains.final);do
		gau -t 2 -o gau_tool_files/$i-gau.url $i
		sleep 0.1;
	done
}

echo "[*] Script started at `date`"
# Startup script
startup_script

#subdomain discovery
subdomain_discovery

# Sleeping for a bit
sleep 3

# Http discovery (Filtering alive targets)
http_discovery

echo "[*] Interested in demo nuclei recon. (Y/N)"
read reply
if [ "$reply" == "Y" ] || [ "$reply" == "y" ];then
	# Fetching nuclei scripts
	fetch_nuclei_scripts
	sleep 0.5
	# Executing each of them (Basic files)
	execute_nuclei_scripts
fi

# Wayback discovery
wayback_for_everyone

	


