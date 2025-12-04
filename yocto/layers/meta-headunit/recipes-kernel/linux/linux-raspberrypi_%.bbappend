FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://mcp251xfd-spi0-0.dts \
    file://mcp251xfd-spi1-0.dts \
"

DEPENDS += "dtc-native"

do_compile:append() {
    # Compile custom device tree overlays
    for dts in ${WORKDIR}/mcp251xfd-*.dts; do
        if [ -f "$dts" ]; then
            dtbo=$(basename "$dts" .dts).dtbo
            dtc -@ -I dts -O dtb -o ${B}/arch/${ARCH}/boot/dts/overlays/$dtbo "$dts"
        fi
    done
}

do_deploy:append() {
    # Deploy custom overlays to separate directory (not bootfiles to avoid WIC issues)
    # These will be manually copied to SD card after flashing
    install -d ${DEPLOYDIR}/can-overlays

    if [ -f ${B}/arch/${ARCH}/boot/dts/overlays/mcp251xfd-spi0-0.dtbo ]; then
        install -m 0644 ${B}/arch/${ARCH}/boot/dts/overlays/mcp251xfd-spi0-0.dtbo ${DEPLOYDIR}/can-overlays/
    fi
    if [ -f ${B}/arch/${ARCH}/boot/dts/overlays/mcp251xfd-spi1-0.dtbo ]; then
        install -m 0644 ${B}/arch/${ARCH}/boot/dts/overlays/mcp251xfd-spi1-0.dtbo ${DEPLOYDIR}/can-overlays/
    fi
}
