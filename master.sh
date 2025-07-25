#!/bin/bash
set -e

figlet -f slant "Cyber Tools & Packages"

#-----------------------------------------------------------------------------------------------------------------------------------------------------
REPO_URL="https://github.com/manishsonje/Cyber_scripts/archive/refs/heads/main.zip" 
CYBER_SCRIPT="/tmp/Cyber_scripts-main.zip"
LOG="/var/log/master.sh"
# Fetching and extracting files for installation
echo "Fetching and extracting files for installation" | tee -a $LOG
wget -O $CYBER_SCRIPT $REPO_URL  
unzip $CYBER_SCRIPT -d /tmp/
cd /tmp/Cyber_scripts-main

echo "-------------------------------------------README ME FIRST-------------------------------------------"
cat /tmp/Cyber_scripts-main/README.md
echo "-------------------------------------------README ME FIRST-------------------------------------------"
echo "Modify LAN settings file according to above steps"
retry=0
while true; do
    read -p "Files Modified? (yes/no): " RESPONSE
    case "$RESPONSE" in
        [Yy][Ee][Ss] )
            echo "[INFO] Continuing with the script..."
            break
            ;;
        [Nn][Oo] )
            if [ $retry -eq 2 ]; then
                echo "[WARNING] Setup is incomplete, terminating "
				exit 1
            fi
            retry=$((retry+1))
            echo "[WARNING] Please modify the LAN settings file before continuing."
            ;;
        * )
            echo "[ERROR] Invalid input. Please type yes or no."
            ;;
    esac
done

#-----------------------------------------------------------------------------------------------------------------------------------------------------
echo "##########################"
echo " Run SetupEnvironment.sh  "
echo " From Install Tools       "
echo " First to setup the       "
echo " System and rules         "
echo "##########################"
#------------------------------------------------------------------------------------------------------------------------------------------------------

# one file to excute
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR_TOOLS="$SCRIPT_DIR/tools"
INSTALL_DIR_PACKAGES="$SCRIPT_DIR/packages"
UNINSTALL_DIR="$SCRIPT_DIR/uninstall"

run_script_from_list() {
    ACTION=$1
    DIR=$2

    echo ""
    echo "Available scripts for $ACTION from $DIR:" | tee -a $LOG  
    scripts=("$DIR"/*.sh) 

    if [ "${scripts[0]}" == "$DIR/*.sh" ]; then
        echo "  No $ACTION scripts found in: $DIR"
        return
    fi

    i=1
    options=()
    for script in "${scripts[@]}"; do
        script_name=$(basename "$script")
        echo "  $i. $script_name"
        options+=("$script")
        ((i++))
    done
    
	all_option=$i
    back_option=$((i + 1))
	
    echo "  $all_option. Install All"
    echo "  $back_option. Back"
    read -p "Enter the script number to run: " selection

    if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#options[@]} )); then
        echo "  Running: ${options[$((selection - 1))]}" | tee -a $LOG
        sudo bash "${options[$((selection - 1))]}"
    elif (( selection == all_option )); then
		echo "Installing all files" | tee -a $LOG
	    for script in "${scripts[@]}"; do
			script_name=$(basename "$script")
			sudo bash $script_name | tee -a $LOG
		done
    elif (( selection == back_option)); then
        echo " Returning to main menu..."
        return
    else
        echo " Invalid selection."
    fi
}


while true; do
    echo ""
    echo "========== Main Menu =========="
    echo "1. Install Tools"
    echo "2. Install Packages"
    echo "3. Uninstall"
    echo "4. Exit"
    echo "==============================="
    read -p "Enter your choice [1-4]: " main_choice

    case "$main_choice" in
        1) run_script_from_list "install tools" "$INSTALL_DIR_TOOLS" ;; 
        2) run_script_from_list "install packages" "$INSTALL_DIR_PACKAGES" ;; 
        3) run_script_from_list "uninstall" "$UNINSTALL_DIR" ;; 
        4) echo "[ATTENTION] If you have executed installed tools, it is recommended to reboot."; exit 0 ;; 
        *) echo " Invalid choice. Please enter 1–4." ;;
    esac
done
