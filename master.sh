#!/bin/bash
set -e

figlet -f slant "Cyber Tools & Packages"

#-----------------------------------------------------------------------------------------------------------------------------------------------------
REPO_URL="https://bitbucket.devops.aws.md-man.biz/rest/api/latest/projects/EEEABB/repos/egen3-setup-tools/archive?at=refs%2Fheads%2Fmaso&format=zip" 
CYBER_SCRIPT="/tmp/egen3-setup-tools.zip"
LOG="var/log/master.sh"
# Fetching and extracting files for installation
echo "Fetching and extracting files for installation" | tee -a $LOG
wget -O $CYBER_SCRIPT $REPO_URL  
unzip $CYBER_SCRIPT -d /tmp/egen3-setup-tools
cd /tmp/egen3-setup-tools/cyber_scripts

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
        1) run_script_from_list "install tools" "$INSTALL_DIR_TOOLS" ;; | tee -a $LOG
        2) run_script_from_list "install packages" "$INSTALL_DIR_PACKAGES" ;; | tee -a $LOG
        3) run_script_from_list "uninstall" "$UNINSTALL_DIR" ;; | tee -a $LOG
        4) echo "Goodbye!"; exit 0 ;; | tee -a $LOG
        *) echo " Invalid choice. Please enter 1–4." ;;
    esac
done
