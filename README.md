# 🛡️ Cyber Security Test Environment
 
## 📋 Pre-requisites
 
Before setting up the environment, please ensure the following:
 
### 🔧 Modify Network Rule File
 
You need to update the **Net Rule file** to map the correct network adapter.
 
- Templates are available at:  
  `/tmp/egen3-setup-tools/cyber_scripts/config`
 
- Modify the appropriate file based on your adapter type:
  - **USB LAN adapters** → `99-usb-lan.rules`
  - **PCI LAN adapters** → `10-network-custom-names.rules`
 
- After modification, copy the file to:  
  `/etc/udev/rules.d/`
 
> ✅ **Note:** Symbolic links for bridge utilities are created automatically, so you don't need to navigate to the bridge folder manually.
 
---
 
## ⚙️ Installing the Environment
 
We recommend completing the above steps **before** installing the environment.
 
- Run the setup by selecting **Option 1** when prompted.
- If rule file validation fails, please correct the file and try again.
 
### Example Menu
 
```
Enter 1 to Setup Environment  
Enter 2 to Start X11vnc  
Enter 3 to Install All (Setup + X11vnc)  
Enter 4 to Return to Master Script  
```
 
---
 
## 🧰 Installing Cyber Tools
 
This section installs recommended cybersecurity tools.
 
### Example Menu
 
```
Enter 1 to Install Burp Suite  
Enter 2 to Install Greenbone OpenVAS Scanner  
Enter 3 to Install Nessus Essentials  
Enter 4 to Install All Tools  
Enter 5 to Return to Master Script  
```
 
---
 
## 🧹 Uninstalling Cyber Tools
 
This section allows you to uninstall the tools.
 
### Example Menu
 
```
Enter 1 to Uninstall Greenbone OpenVAS Scanner  
Enter 2 to Uninstall Nessus Essentials  
Enter 3 to Uninstall All Tools  
Enter 4 to Return to Master Script  
```
