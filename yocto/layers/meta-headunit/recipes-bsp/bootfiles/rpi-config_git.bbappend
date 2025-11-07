FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

do_deploy:append() {
    # Add custom config.txt settings
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# ====================================" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# HeadUnit Custom Display Configuration" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# ====================================" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# Force HDMI output" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_force_hotplug=1" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_drive=2" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# Custom resolution 1024x600" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_group=2" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_mode=87" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "hdmi_cvt=1024 600 60 3 0 0 0" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# Framebuffer" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "framebuffer_width=1024" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "framebuffer_height=600" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "framebuffer_depth=32" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "framebuffer_ignore_alpha=0" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# Overscan" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "disable_overscan=1" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "overscan_left=0" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "overscan_right=0" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "overscan_top=0" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "overscan_bottom=0" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# Video" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "dtoverlay=vc4-fkms-v3d" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "max_framebuffers=2" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "gpu_mem=256" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "# Audio off" >> ${DEPLOYDIR}/bootfiles/config.txt
    echo "dtparam=audio=off" >> ${DEPLOYDIR}/bootfiles/config.txt
}
