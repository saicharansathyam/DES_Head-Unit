# Dual Display Configuration
# Display 0 (HDMI-0): 1024x600 (Main IVI)
# Display 1 (HDMI-1): 1024x600 (Instrument Cluster)

# Enable UART globally for bluetooth
ENABLE_UART = "1"

do_deploy:append() {
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# Dual HDMI Display Configuration" >> ${DEPLOYDIR}/bootfiles/config.txt
    
    # Enable KMS and dual display support
    echo "max_framebuffers=2" >> ${DEPLOYDIR}/bootfiles/config.txt
    
    # HDMI-0: Main IVI Display (1024x600)
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# HDMI-0: 1024x600" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_group:0=2" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_mode:0=87" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_cvt:0=1024 600 60 6 0 0 0" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_drive:0=2" >> ${DEPLOYDIR}/bootfiles/config.txt
    
    # HDMI-1: Instrument Cluster (1024x600)
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# HDMI-1: 1024x600" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_group:1=2" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_mode:1=87" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_cvt:1=1024 600 60 6 0 0 0" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_drive:1=2" >> ${DEPLOYDIR}/bootfiles/config.txt
    
    # Force both HDMI outputs
    echo "hdmi_force_hotplug:0=1" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_force_hotplug:1=1" >> ${DEPLOYDIR}/bootfiles/config.txt

    # Enable I2C for INA219 sensor
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# Enable I2C" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "dtparam=i2c_arm=on" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "dtparam=i2c1=on" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "dtparam=i2c_arm_baudrate=400000" >> ${DEPLOYDIR}/bootfiles/config.txt

    # Enable GPIO access (exclude GPIO 24,25 for CAN interrupts)
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# GPIO configuration" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "gpio=2-23=a0,26-27=a0" >> ${DEPLOYDIR}/bootfiles/config.txt

    # Enable Bluetooth UART
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# Bluetooth configuration" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "dtoverlay=pi3-miniuart-bt" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "enable_uart=1" >> ${DEPLOYDIR}/bootfiles/config.txt

    # Turn on spi
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# Turn on spi" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "dtparam=spi=on" >> ${DEPLOYDIR}/bootfiles/config.txt

    # Setting for 2-CH CAN FD Hat (MCP2518FD)
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# Setting for 2-CH CAN FD Hat (MCP2518FD)" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "dtoverlay=spi1-3cs" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "dtoverlay=mcp251xfd-spi0-0" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "dtoverlay=mcp251xfd-spi1-0" >> ${DEPLOYDIR}/bootfiles/config.txt
}