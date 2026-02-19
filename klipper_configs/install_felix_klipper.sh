#!/bin/bash
echo "Script version V0.02."
echo "This script must be run as Root user."
DIRECTORY=`dirname ${BASH_SOURCE[0]}`
INSTALLER="$0"
#SERVER_FILE=klipper-configs.git
#INSTALL_DIR=new_klipper_configs
BACKUP_DIR=backups
cd "$DIRECTORY"
DIRECTORY="$( pwd )"
echo "Directory $DIRECTORY."
#PRINTER_DIR=/home/pi/Downloads/fake_klipper_configs
PRINTER_DIR=/var/lib/Repetier-Server/database/klipper_fake
echo "Printer directory $PRINTER_DIR."

# Show a list of the .cfg files in the klipper directory
shopt -s nullglob
cfg_files=($PRINTER_DIR/*.cfg)

if [ ${#cfg_files[@]} -eq 0 ]; then
    echo "WARNING: No .cfg files were found in the Klipper directory."
else
    echo "We found ${#cfg_files[@]} .cfg files" 
    echo "Found the following .cfg files:"
    for file in "${cfg_files[@]}"; do
        echo " - $(basename "$file")"
    done
fi

# Stop Repetier-Server
#service RepetierServer stop
#echo "Repetier-Server service stopped."

# Create backup of klipper folder 
date_time=$(date +"%Y%m%d_%H%M")
mkdir $DIRECTORY/$BACKUP_DIR
tar -zcf $DIRECTORY/$BACKUP_DIR/${date_time}.tar.gz --absolute-names  $PRINTER_DIR
if [ ! -s "$DIRECTORY/$BACKUP_DIR/${date_time}.tar.gz" ]; then
    echo "WARNING: No backup was created of the Klipper directory!"
    #exit 1
else
    echo "Backup of Klipper directory successful, filename: ${date_time}.tar.gz."
fi

# Create backup of unique.cfg file
if [ ! -s "$PRINTER_DIR/unique.cfg" ]; then
    echo "WARNING: unique.cfg was not found. If this is a new printer, you can ignore this warning."
    #exit 1
else
    cp $PRINTER_DIR/unique.cfg $PRINTER_DIR/unique.bkp
    echo "Temporary backup of unique.cfg successful."
fi

# Create backup of SAVE_CONFIG section in printer.cfg file
if [ ! -s "$PRINTER_DIR/FELIX_Pro_3.cfg" ]; then
    echo "No FELIX_Pro_3.cfg file was found. If this is a new printer, you can ignore this warning."
    save_config_saved=false
else
    sed -n '/#*# <---------------------- SAVE_CONFIG ---------------------->/, $ p' < $PRINTER_DIR/FELIX_Pro_3.cfg > /home/pi/Downloads/SAVE_CONFIG.txt
    echo "SAVE_CONFIG section is saved."
    save_config_saved=true
fi

# Remove all existing .cfg files from klipper directory
if [ ${#cfg_files[@]} -eq 0 ]; then
    echo "WARNING: No .cfg files were found in the Klipper directory. If this is a new printer, you can ignore this warning."
    #exit 1
else
    rm -f $PRINTER_DIR/*.cfg
    echo "All .cfg files were removed from the Klipper directory."
fi

# Copy new config files to klipper directory
cp ./new_configs/*.cfg $PRINTER_DIR
if [ -s "$PRINTER_DIR/*.cfg" ]; then
    echo "ERROR: No config files have been copied to the Klipper directory."
    echo "This installer will exit now."
    exit 1
else
    echo "Config files were successfully copied to the Klipper directory."
fi

# Restoring unique.cfg file in klipper directory
cp -fr $PRINTER_DIR/unique.bkp $PRINTER_DIR/unique.cfg
if [ ! -s "$PRINTER_DIR/unique.bkp" ]; then
    echo "WARNING: No unique.bkp file was not found. If this is a new printer, you can ignore this warning,"
    echo "otherwise restore the earlier made backup, filename: ${date_time}.tar.gz."
    #exit 1
else
    echo "Restoring unique.bkp into unique.cfg was successful."
fi

# Restore backup of SAVE_CONFIG section to Insolution_Go_One.cfg file
if [ "$save_config_saved" = true ]; then
    sed -i '$a\\
    ' $PRINTER_DIR/FELIX_Pro_3.cfg
    cat /home/pi/Downloads/SAVE_CONFIG.txt >> $PRINTER_DIR/FELIX_Pro_3.cfg
    echo "SAVE_CONFIG has been restored."
else
    echo "No SAVE_CONFIG section was found in the original FELIX_Pro_3.cfg file, so no SAVE_CONFIG section will be restored."
fi

# Change owner / group
chown -R repetierserver.dialout $PRINTER_DIR/*.cfg
echo "Ownership of .cfg files inside Klipper directory were updated."

# Start Repetier-Server service
#service RepetierServer restart
#echo "Repetier-Server service started."

# Cleanup files and folder
rm -r /var/lib/Repetier-Server/scripts/Test-repo/klipper_configs
#rm $PRINTER_DIR/unique.bkp
#rm /home/pi/Downloads/SAVE_CONFIG.txt
echo "Cleaning up files completed."

# Installation completed
echo "Klipper config file installation completed successfully."