# Windows Power Optimization Script
# Run as Administrator for full effect

# Set high performance power plan for development
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Optimize processor power management
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100

# Optimize USB selective suspend
powercfg /setacvalueindex SCHEME_CURRENT SUB_USB USBSELECTIVESUSPEND 0

# Optimize hard disk timeout
powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0

# Apply settings
powercfg /setactive SCHEME_CURRENT

Write-Host "Windows power settings optimized for development performance"
