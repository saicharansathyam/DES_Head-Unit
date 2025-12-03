# Dual Display Configuration
# Display 0 (HDMI-0): 1024x600 (Main IVI)
# Display 1 (HDMI-1): 1024x600 (Instrument Cluster)

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
}