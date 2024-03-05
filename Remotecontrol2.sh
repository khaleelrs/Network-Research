#!/bin/bash
log_file="log.txt"

# Function to check if a package is installed
is_package_installed() {
  dpkg -s "$1" >/dev/null 2>&1
}


installer_function() {
    echo 'Checking for installed applications...'
    
    # Check if nipe.pl is installed
    find_nipe=$(find ~ -type f -name nipe.pl | wc -l)
    nipe_full_path=$(find ~ -type f -name nipe.pl)
    nipe_directory=$(dirname "$nipe_full_path")
    
    if [ "$find_nipe" -eq 0 ]; then
        echo "Installing Nipe..."
        
         
        # Clone nipe repository from GitHub and install dependencies
        git clone https://github.com/htrgouvea/nipe && cd nipe
        sudo cpanm --installdeps .
        
        # Install and restart nipe
        sudo perl nipe.pl install
        cd "$nipe_directory" && sudo perl nipe.pl restart
        sleep 2
        
        echo 'Nipe has been installed successfully. Starting nipe...'
    else
        echo 'Nipe is already installed'
        echo 'Starting nipe...'
        cd "$nipe_directory"
        sudo perl nipe.pl restart
    fi
# Check and install nmap
if is_package_installed nmap; then
  echo "[#] nmap is already installed."
else
  echo "Installing nmap..."
  sudo apt-get install nmap
fi




# Check and install whois
if is_package_installed whois; then
  echo "[#] whois is already installed."
else
  echo "Installing whois..."
  sudo apt-get install whois
fi


# Check and install geoip-bin
if is_package_installed geoip-bin; then
  echo "[#] geoip-bin is already installed."
else
  echo "Installing geoip-bin..."
  sudo apt-get install geoip-bin
fi

# Check and install tor
if is_package_installed tor; then
  echo "[#] tor is already installed."
  sudo service tor start
else
  echo "Installing tor..."
  sudo apt-get install tor
fi

# Check and install sshpass
if is_package_installed sshpass; then
  echo "[#] sshpass is already installed."
else
  echo "Installing sshpass..."
  sudo apt-get install sshpass
fi   
# Check and install jq
if is_package_installed jq; then
  echo "[#] jq is already installed."
else
  echo "Installing jq..."
  sudo apt-get install jq
fi
			
}

anonymous_function() {
    # Get the actual public IP address
    echo -e "\n Checking if connection is anonymous"
    actual_ip=$(curl -s ifconfig.io)

    # Use geoiplookup to match the IP address with its corresponding country
    IPCountry=$(geoiplookup "$actual_ip" | awk '{print $4}')

    if [ "$IPCountry" != "Singapore" ]; then
        echo "[*] You're connection is anonymous. Your spoofed country is: $IPCountry and the ip is $actual_ip"
    else
        echo "This connection is not anoymous.Script will stop here"
        exit 1
    fi
}

remote_server_connection() {
	
  echo "[?] Specify a Domain/ IP address to scan: "
read domain
 
sshpass -p '123' ssh -t -o StrictHostKeyChecking=no remoteuser@192.168.30.136 "(cd /home/kali/nipe && sudo perl nipe.pl restart)" 2>/dev/null
sleep 2
machine_name=$(sshpass -p '123' ssh -t -o StrictHostKeyChecking=no remoteuser@192.168.30.136 "whoami" 2>/dev/null)
ip_address=$(sshpass -p '123' ssh -t -o StrictHostKeyChecking=no remoteuser@192.168.30.136 "curl -s ifconfig.io" 2>/dev/null)
country=$(geoiplookup "$ip_address" | awk '{print $5}')
sys_uptime=$(sshpass -p '123' ssh remoteuser@192.168.30.136 uptime -p|awk '{print $2}' )
 

  echo "The user is $machine_name"
  echo "The IP is $ip_address"
  echo "Machine is located in $country"
  echo "system is up for $sys_uptime minutes"

whois_info=$(sshpass -p '123' ssh -t -o StrictHostKeyChecking=no remoteuser@192.168.30.136 whois "${domain}" 2>/dev/null)

  output_file_whois="whois_${domain}.txt"
  echo -e "\n"
  echo "[*] whoising victim's address: "
  echo "${whois_info}" > "${output_file_whois}"
  file_path=$(realpath "${output_file_whois}")
  echo "[@] whois data was saved into ${file_path}"
  echo "$(date) -[*] whois data collected for ${domain}" >> log_file
  
  nmap_info=$(sshpass -p '123' ssh -t -o StrictHostKeyChecking=no remote@192.168.30.136 nmap "${domain}" 2>/dev/null)
  output_file_nmap="nmap_${domain}.txt"
  echo -e "\n"
  echo "[*] Scanning victim's address:"
  echo "${nmap_info}" > "${output_file_nmap}"
  file_path=$(realpath "${output_file_nmap}")
  echo "[@] whois data was saved into ${file_path}"
  echo "$(date) -[*] Nmap data collected for ${domain}" >> log_file
    
}
installer_function
anonymous_function
remote_server_connection
is_package_installed

