# HeadUnit IVI System 


---

## 1. System Architecture Overview

```mermaid
graph TB
    subgraph "Raspberry Pi 4 - Yocto Linux"
        subgraph "Display Layer"
            GS[GearSelector<br/>Surface 1001<br/>1024x600]
            MP[MediaPlayer<br/>Surface 1002<br/>1024x600]
            TC[ThemeColor<br/>Surface 1003<br/>1024x600]
        end

        subgraph "Compositor Stack"
            IVI[IVI Compositor<br/>wayland-2<br/>Surface Manager]
            WESTON[Weston Compositor<br/>wayland-0<br/>DRM/KMS]
        end

        subgraph "Output"
            HDMI1[HDMI-A-1<br/>Display-0<br/>1024x600]
            HDMI2[HDMI-A-2<br/>Display-1<br/>1024x600]
        end

        subgraph "Application Framework"
            AFM[Application Framework Manager<br/>AFM Service<br/>Reads applications.json]
        end

        subgraph "D-Bus Layer"
            UDBUS[Unified D-Bus Service<br/>unified-dbus-service.py]

            subgraph "D-Bus Services"
                DASH[com.seame.Dashboard]
                MEDIA[com.seame.MediaPlayer]
                THEME[com.seame.ThemeColor]
                SETTINGS[com.seame.Settings]
                GEAR[com.seame.GearSelector]
            end
        end

        subgraph "Hardware Integration"
            CAN[CAN Bus Interface<br/>can0 + can1<br/>MCP2515]
            RC[RC PiRacer Service<br/>Gamepad Control]
            INA[INA219<br/>Battery Sensor]
        end

        subgraph "System Services"
            DBUS_SYS[dbus.service<br/>System Bus]
            SYSTEMD[systemd<br/>Service Manager]
        end
    end

    GS --> IVI
    MP --> IVI
    TC --> IVI
    IVI --> WESTON
    WESTON --> HDMI1
    WESTON --> HDMI2

    AFM --> GS
    AFM --> MP
    AFM --> TC

    GS -.D-Bus.-> UDBUS
    MP -.D-Bus.-> UDBUS
    TC -.D-Bus.-> UDBUS
    IVI -.D-Bus.-> UDBUS

    UDBUS --> DASH
    UDBUS --> MEDIA
    UDBUS --> THEME
    UDBUS --> SETTINGS
    UDBUS --> GEAR

    CAN --> UDBUS
    RC --> UDBUS
    INA --> UDBUS

    SYSTEMD --> AFM
    SYSTEMD --> UDBUS
    SYSTEMD --> IVI
    SYSTEMD --> WESTON
    SYSTEMD --> CAN
    SYSTEMD --> RC

    DBUS_SYS --> UDBUS

    style GS fill:#4CAF50
    style MP fill:#2196F3
    style TC fill:#FF9800
    style UDBUS fill:#E91E63
    style WESTON fill:#9C27B0
    style IVI fill:#673AB7
```

---

## 2. Display Layer Architecture

```mermaid
graph TB
    subgraph "Application Layer - Qt6 Wayland"
        subgraph "GearSelector App"
            GS_QML[Qt6 QML UI<br/>Gear Buttons P/R/N/D/S]
            GS_HANDLER[GS_Handler<br/>Gear Control Logic<br/>D-Bus calls]
            GS_ENV[Environment:<br/>WAYLAND_DISPLAY=wayland-2<br/>IVI_SURFACE_ID=1001]
        end

        subgraph "MediaPlayer App"
            MP_QML[Qt6 QML UI<br/>Controls + Playlist]
            MP_HANDLER[MP_Handler<br/>D-Bus Control<br/>Media operations]
            MP_USB[USB Playback<br/>GStreamer Backend]
            MP_YT[YouTube Support<br/>QtWebView]
            MP_KB[Virtual Keyboard<br/>qtvirtualkeyboard]
            MP_ENV[Environment:<br/>WAYLAND_DISPLAY=wayland-2<br/>IVI_SURFACE_ID=1002]
        end

        subgraph "ThemeColor App"
            TC_QML[Qt6 QML UI<br/>Color Wheel Picker]
            TC_CLIENT[ThemeColorClient<br/>D-Bus Publisher]
            TC_BROADCAST[Real-time Color<br/>Broadcast]
            TC_ENV[Environment:<br/>WAYLAND_DISPLAY=wayland-2<br/>IVI_SURFACE_ID=1003<br/>autostart=false]
        end
    end

    GS_QML --> GS_HANDLER
    GS_HANDLER --> GS_ENV

    MP_QML --> MP_HANDLER
    MP_QML --> MP_USB
    MP_QML --> MP_YT
    MP_QML --> MP_KB
    MP_HANDLER --> MP_ENV

    TC_QML --> TC_CLIENT
    TC_CLIENT --> TC_BROADCAST
    TC_BROADCAST --> TC_ENV

    style GS_QML fill:#4CAF50
    style MP_QML fill:#2196F3
    style TC_QML fill:#FF9800
```

---

## 3. Compositor Stack

```mermaid
graph TB
    subgraph "Layer 3: Applications"
        APP1[Application 1<br/>Connect to wayland-2]
        APP2[Application 2<br/>Use IVI_SURFACE_ID]
        APP3[Application 3<br/>Managed by IVI]
    end

    subgraph "Layer 2: IVI Compositor"
        subgraph "IVI Components"
            SM[Surface Manager QML<br/>Maps surface IDs to windows]
            SWITCH[App Switching<br/>Ctrl+Tab]
            HOME[Home View<br/>App Tiles]
        end

        subgraph "IVI D-Bus"
            DBUS_MGR[DBusManager C++ Class<br/>Subscribe to unified-dbus<br/>Expose to QML]
        end

        subgraph "IVI Panels"
            RIGHT[Right Panel<br/>Battery, Speed, Gear Display]
        end

        IVI_COMP[IVI Compositor Process<br/>wayland-2 socket<br/>Nested Wayland]
    end

    subgraph "Layer 1: Weston"
        WESTON_COMP[Weston Compositor<br/>wayland-0 socket]
        DRM[DRM/KMS Backend<br/>Direct Rendering]
        CONFIG[Config: weston.ini<br/>Dual HDMI 1024x600]
    end

    subgraph "Hardware"
        HDMI1[HDMI-A-1 Port]
        HDMI2[HDMI-A-2 Port]
    end

    APP1 --> IVI_COMP
    APP2 --> IVI_COMP
    APP3 --> IVI_COMP

    IVI_COMP --> SM
    IVI_COMP --> SWITCH
    IVI_COMP --> HOME
    IVI_COMP --> DBUS_MGR
    IVI_COMP --> RIGHT

    SM --> WESTON_COMP
    SWITCH --> WESTON_COMP
    HOME --> WESTON_COMP
    RIGHT --> WESTON_COMP

    WESTON_COMP --> DRM
    WESTON_COMP --> CONFIG

    DRM --> HDMI1
    DRM --> HDMI2

    style IVI_COMP fill:#673AB7
    style WESTON_COMP fill:#9C27B0
    style DRM fill:#512DA8
```

---

## 4. D-Bus Architecture

```mermaid
graph TB
    subgraph "Unified D-Bus Service - unified-dbus-service.py"
        subgraph "com.seame.Dashboard"
            DASH_METHODS[Methods:<br/>GetSpeed, GetBatteryVoltage<br/>GetBatteryPercent, GetGear<br/>SetGear, SetTurnSignal<br/>GetTheme, SetAccentColor]
            DASH_SIGNALS[Signals:<br/>SpeedChanged<br/>BatteryVoltageChanged<br/>BatteryPercentChanged<br/>GearChanged<br/>TurnSignalChanged<br/>ThemeChanged<br/>AccentColorChanged]
            DASH_HW[Hardware:<br/>CAN Bus can0/can1<br/>Kalman Filter<br/>INA219 Battery]
        end

        subgraph "com.seame.MediaPlayer"
            MEDIA_METHODS[Methods:<br/>Play, Pause, Stop<br/>Next, Previous<br/>SetVolume, GetVolume<br/>IsPlaying]
            MEDIA_SIGNALS[Signals:<br/>PlaybackStateChanged<br/>VolumeChanged<br/>TrackChanged]
        end

        subgraph "com.seame.ThemeColor"
            THEME_METHODS[Methods:<br/>SetTheme, GetTheme<br/>SetAccentColor<br/>GetAccentColor]
            THEME_SIGNALS[Signals:<br/>ThemeChanged<br/>AccentColorChanged]
        end

        subgraph "com.seame.Settings"
            SETTINGS_METHODS[Methods:<br/>SetBrightness<br/>GetBrightness<br/>SetLanguage<br/>GetLanguage]
            SETTINGS_SIGNALS[Signals:<br/>BrightnessChanged<br/>LanguageChanged]
        end

        subgraph "com.seame.GearSelector"
            GEAR_METHODS[Methods:<br/>select_gear<br/>get_current_gear<br/>Legacy API]
        end
    end

    subgraph "System Bus"
        SYSBUS[D-Bus System Bus<br/>/var/run/dbus/system_bus_socket]
    end

    subgraph "Clients"
        APP_GS[GearSelector App<br/>GS_Handler]
        APP_MP[MediaPlayer App<br/>MP_Handler]
        APP_TC[ThemeColor App<br/>ThemeColorClient]
        APP_IVI[IVI Compositor<br/>DBusManager]
    end

    DASH_METHODS --> SYSBUS
    DASH_SIGNALS --> SYSBUS
    DASH_HW --> DASH_METHODS

    MEDIA_METHODS --> SYSBUS
    MEDIA_SIGNALS --> SYSBUS

    THEME_METHODS --> SYSBUS
    THEME_SIGNALS --> SYSBUS

    SETTINGS_METHODS --> SYSBUS
    SETTINGS_SIGNALS --> SYSBUS

    GEAR_METHODS --> SYSBUS

    SYSBUS --> APP_GS
    SYSBUS --> APP_MP
    SYSBUS --> APP_TC
    SYSBUS --> APP_IVI

    style SYSBUS fill:#E91E63
    style DASH_METHODS fill:#4CAF50
    style MEDIA_METHODS fill:#2196F3
    style THEME_METHODS fill:#FF9800
```

---

## 5. Hardware Integration Flow

```mermaid
graph LR
    subgraph "Hardware Devices"
        ARD[Arduino Mega 2560<br/>Speed Sensor]
        GP[USB Gamepad<br/>HID Controller]
        BAT[INA219<br/>Battery Sensor I2C]
    end

    subgraph "CAN Interface"
        CAN_HAT[MCP2515 CAN HAT<br/>Waveshare 2-CH]
        CAN0[can0: SPI0 CE0<br/>GPIO 8<br/>500kbps]
        CAN1[can1: SPI1 CE0<br/>GPIO 18<br/>500kbps]
    end

    subgraph "System Services"
        CAN_SETUP[can-setup.service<br/>Auto-detect can0/can1<br/>Configure bitrate]
        RC_SERVICE[rc-piracer.service<br/>rc_piracer.py<br/>Read gamepad input]
    end

    subgraph "Unified D-Bus Service"
        CAN_READER[CAN Reader Thread<br/>Per Bus]
        KALMAN[Kalman Filter<br/>Speed Smoothing]
        BAT_POLLER[Battery Poller Thread<br/>INA219 I2C]
        DBUS_SIG[D-Bus Signal Broadcast<br/>All subscribers notified]
    end

    subgraph "CAN Messages"
        MSG_100[0x100: Speed<br/>2 bytes, cm/s]
        MSG_102[0x102: Gear<br/>1 byte, P/R/N/D/S]
        MSG_103[0x103: Turn Signal<br/>1 byte, 0-3]
    end

    ARD --> CAN_HAT
    CAN_HAT --> CAN0
    CAN_HAT --> CAN1

    CAN0 --> CAN_SETUP
    CAN1 --> CAN_SETUP

    CAN_SETUP --> CAN_READER

    CAN_READER --> MSG_100
    CAN_READER --> MSG_102
    CAN_READER --> MSG_103

    MSG_100 --> KALMAN
    MSG_102 --> DBUS_SIG
    MSG_103 --> DBUS_SIG

    KALMAN --> DBUS_SIG

    GP --> RC_SERVICE
    RC_SERVICE --> DBUS_SIG

    BAT --> BAT_POLLER
    BAT_POLLER --> DBUS_SIG

    style CAN_READER fill:#4CAF50
    style KALMAN fill:#2196F3
    style DBUS_SIG fill:#E91E63
```

---

## 6. CAN Bus Message Protocol

```mermaid
graph TB
    subgraph "CAN ID: 0x100 - Speed"
        SPEED_DLC[DLC: 2 bytes]
        SPEED_H[Data0: High Byte]
        SPEED_L[Data1: Low Byte]
        SPEED_UNIT[Unit: cm/s Big-Endian]
        SPEED_EX[Example: 0x00 0x64<br/>= 100 cm/s = 1 m/s]
        SPEED_PROC[Processing:<br/>Kalman Filter<br/>→ SpeedChanged signal]
    end

    subgraph "CAN ID: 0x102 - Gear"
        GEAR_DLC[DLC: 1 byte]
        GEAR_ASCII[Data0: ASCII character]
        GEAR_P[P = 0x50: Park]
        GEAR_R[R = 0x52: Reverse]
        GEAR_N[N = 0x4E: Neutral]
        GEAR_D[D = 0x44: Drive]
        GEAR_S[S = 0x53: Sport]
        GEAR_PROC[Processing:<br/>Direct mapping<br/>→ GearChanged signal]
    end

    subgraph "CAN ID: 0x103 - Turn Signal"
        TURN_DLC[DLC: 1 byte]
        TURN_0[0x00: Off]
        TURN_1[0x01: Left]
        TURN_2[0x02: Right]
        TURN_3[0x03: Hazard]
        TURN_PROC[Processing:<br/>Map to string<br/>→ TurnSignalChanged signal]
    end

    SPEED_DLC --> SPEED_H
    SPEED_DLC --> SPEED_L
    SPEED_H --> SPEED_UNIT
    SPEED_L --> SPEED_UNIT
    SPEED_UNIT --> SPEED_EX
    SPEED_EX --> SPEED_PROC

    GEAR_DLC --> GEAR_ASCII
    GEAR_ASCII --> GEAR_P
    GEAR_ASCII --> GEAR_R
    GEAR_ASCII --> GEAR_N
    GEAR_ASCII --> GEAR_D
    GEAR_ASCII --> GEAR_S
    GEAR_P --> GEAR_PROC
    GEAR_R --> GEAR_PROC
    GEAR_N --> GEAR_PROC
    GEAR_D --> GEAR_PROC
    GEAR_S --> GEAR_PROC

    TURN_DLC --> TURN_0
    TURN_DLC --> TURN_1
    TURN_DLC --> TURN_2
    TURN_DLC --> TURN_3
    TURN_0 --> TURN_PROC
    TURN_1 --> TURN_PROC
    TURN_2 --> TURN_PROC
    TURN_3 --> TURN_PROC

    style SPEED_PROC fill:#4CAF50
    style GEAR_PROC fill:#2196F3
    style TURN_PROC fill:#FF9800
```

---

## 7. Kalman Filter Architecture

```mermaid
graph TB
    subgraph "Kalman Filter - Speed Smoothing"
        STATE[State Vector:<br/>x = velocity, acceleration]

        subgraph "Prediction Step"
            PRED_X[x⁻ₖ = F × xₖ₋₁<br/>Predict next state]
            PRED_P[P⁻ₖ = F × Pₖ₋₁ × Fᵀ + Q<br/>Predict covariance]
            F_MAT[F = 1  Δt<br/>    0   1<br/>State transition matrix]
        end

        subgraph "Update Step"
            INNOV[yₖ = zₖ - H × x⁻ₖ<br/>Innovation residual]
            INNOV_COV[Sₖ = H × P⁻ₖ × Hᵀ + R<br/>Innovation covariance]
            GAIN[Kₖ = P⁻ₖ × Hᵀ × Sₖ⁻¹<br/>Kalman gain]
            UPDATE_X[xₖ = x⁻ₖ + Kₖ × yₖ<br/>State update]
            UPDATE_P[Pₖ = I - Kₖ × H × P⁻ₖ<br/>Covariance update]
        end

        subgraph "Parameters"
            DT[Δt = 0.05s<br/>50ms default<br/>Dynamic from CAN timing]
            Q[Process Variance<br/>Q = 4.0]
            R[Measurement Variance<br/>R = 3.0]
            H[H = 1  0<br/>Observe velocity only]
        end

        subgraph "Input/Output"
            CAN_IN[CAN 0x100 Input<br/>Raw speed cm/s]
            SMOOTH_OUT[Smooth Speed Output<br/>Reduced noise & spikes]
        end
    end

    STATE --> PRED_X
    PRED_X --> F_MAT
    F_MAT --> PRED_P
    PRED_P --> DT

    CAN_IN --> INNOV
    PRED_X --> INNOV
    PRED_P --> INNOV_COV
    INNOV --> GAIN
    INNOV_COV --> GAIN

    GAIN --> UPDATE_X
    INNOV --> UPDATE_X
    GAIN --> UPDATE_P

    UPDATE_X --> SMOOTH_OUT

    DT --> Q
    Q --> PRED_P
    R --> INNOV_COV
    H --> INNOV
    H --> UPDATE_P

    style SMOOTH_OUT fill:#4CAF50
    style CAN_IN fill:#FF9800
```

---

## 8. Data Flow - Theme Color Change

```mermaid
sequenceDiagram
    participant User
    participant ThemeColor as ThemeColor App<br/>(QML)
    participant TC_Client as ThemeColorClient<br/>(C++ Class)
    participant DBus as com.seame.ThemeColor<br/>(D-Bus Service)
    participant Signal as AccentColorChanged<br/>(Broadcast Signal)
    participant GS as GearSelector<br/>(GS_Handler)
    participant MP as MediaPlayer<br/>(MP_Handler)
    participant IVI as IVI Compositor<br/>(DBusManager)
    participant IC as Instrument Cluster<br/>(PiRacerBridge)

    User->>ThemeColor: Click Color Wheel<br/>(Select #FF5722)
    ThemeColor->>TC_Client: setAccentColor("#FF5722")
    TC_Client->>DBus: SetAccentColor("#FF5722")
    Note over DBus: Store new color<br/>self.accent_color = "#FF5722"
    DBus->>Signal: Emit AccentColorChanged("#FF5722")

    par Broadcast to All Subscribers
        Signal->>GS: AccentColorChanged("#FF5722")
        Signal->>MP: AccentColorChanged("#FF5722")
        Signal->>IVI: AccentColorChanged("#FF5722")
        Signal->>IC: AccentColorChanged("#FF5722")
    end

    Note over GS: Update UI<br/>gear buttons border
    Note over MP: Update UI<br/>controls accent
    Note over IVI: Update UI<br/>panel highlights
    Note over IC: Update UI<br/>gauge colors

    Note over User: All UIs updated<br/>in real-time (<50ms)
```

---

## 9. Data Flow - Gear Selection (Gamepad)

```mermaid
sequenceDiagram
    participant GP as USB Gamepad<br/>(HID Device)
    participant RC as rc-piracer.service<br/>(rc_piracer.py)
    participant DBus as com.seame.Dashboard<br/>(D-Bus Service)
    participant CAN as CAN Bus<br/>(can0/can1)
    participant Signal as GearChanged<br/>(Broadcast Signal)
    participant GS as GearSelector App
    participant IVI as IVI Compositor
    participant ARD as Arduino<br/>(CAN Receiver)

    GP->>RC: Button Press<br/>(D Button)
    Note over RC: Detect button mapping<br/>Button → 'D' gear
    RC->>DBus: SetGear("D")

    Note over DBus: Update internal state<br/>self.current_gear = "D"

    par D-Bus Signal and CAN Message
        DBus->>Signal: Emit GearChanged("D")
        DBus->>CAN: Send CAN 0x102<br/>Data: [0x44] ('D')
    end

    par Notify Subscribers
        Signal->>GS: GearChanged("D")
        Signal->>IVI: GearChanged("D")
    end

    CAN->>ARD: CAN Message 0x102<br/>Data: 0x44

    Note over GS: Update UI<br/>Highlight D button
    Note over IVI: Update right panel<br/>Show "D" gear
    Note over ARD: Process gear change<br/>(vehicle control)
```

---

## 10. Data Flow - Speed Update (CAN Bus)

```mermaid
sequenceDiagram
    participant ARD as Arduino<br/>(Speed Sensor)
    participant CAN as MCP2515 CAN<br/>(SocketCAN)
    participant Reader as CAN Reader Thread<br/>(unified-dbus)
    participant Kalman as Kalman Filter<br/>(2-state)
    participant DBus as unified-dbus-service
    participant Signal as SpeedChanged<br/>(Broadcast)
    participant IVI as IVI Compositor<br/>(Right Panel)

    ARD->>CAN: Send CAN 0x100<br/>Data: [0x01, 0xF4]<br/>(500 cm/s)
    Note over CAN: SocketCAN Interface<br/>can0 or can1

    CAN->>Reader: recv() message
    Note over Reader: Parse CAN message<br/>ID: 0x100<br/>Data: 500 cm/s raw

    Reader->>Kalman: update(500, dt=0.048)
    Note over Kalman: Prediction Step<br/>x⁻ = F × xₖ₋₁<br/>P⁻ = F × P × Fᵀ + Q
    Note over Kalman: Update Step<br/>K = P⁻ × Hᵀ × S⁻¹<br/>x = x⁻ + K × y<br/>P = (I - K×H) × P⁻
    Kalman-->>Reader: Filtered: 498.7 cm/s

    Reader->>DBus: Update speed value<br/>self.speed = 498.7

    DBus->>Signal: SpeedChanged(498.7)
    Signal->>IVI: SpeedChanged(498.7)

    Note over IVI: Update speed display<br/>Convert to km/h<br/>Show: 17.9 km/h
```

---

## 11. Data Flow - Media Control

```mermaid
sequenceDiagram
    participant User
    participant MP_QML as MediaPlayer QML<br/>(UI)
    participant MP_Handler as MP_Handler<br/>(C++ Class)
    participant DBus as com.seame.MediaPlayer<br/>(D-Bus Service)
    participant Signal as PlaybackStateChanged<br/>(Broadcast)
    participant GStreamer as GStreamer Backend<br/>(QtMultimedia)
    participant RC as rc-piracer<br/>(Gamepad)

    User->>MP_QML: Click Play Button
    MP_QML->>MP_Handler: play()
    MP_Handler->>DBus: Play()

    Note over DBus: Update state<br/>self.playing = True

    par Notify and Control
        DBus->>Signal: PlaybackStateChanged(true)
        DBus->>GStreamer: Start playback
    end

    Signal->>MP_QML: PlaybackStateChanged(true)
    Note over MP_QML: Update UI<br/>Play → Pause icon

    Note over GStreamer: Begin audio/video<br/>rendering

    opt Gamepad Control
        RC->>DBus: Pause() via gamepad
        DBus->>Signal: PlaybackStateChanged(false)
        Signal->>MP_QML: PlaybackStateChanged(false)
        Note over MP_QML: Update UI<br/>Pause → Play icon
    end
```

---

## 12. Service Dependencies Graph

```mermaid
graph TB
    subgraph "Boot Sequence Order"
        DBUS[dbus.service<br/>System Bus]

        subgraph "Level 2: Base Services"
            WESTON[weston.service<br/>Wayland wl-0]
            CAN_SETUP[can-setup.service<br/>CAN Interfaces]
        end

        UDBUS[unified-dbus.service<br/>All D-Bus Interfaces<br/>Hardware Mode]

        subgraph "Level 4: App Services"
            COMP[compositor.service<br/>IVI Layer wl-2]
            RC[rc-piracer.service<br/>Gamepad Control]
            IC[instrument-cluster.service<br/>Dashboard Display]
        end

        AFM[afm.service<br/>Application Framework<br/>Manager]

        subgraph "Level 6: Applications"
            GS[gearselector.service<br/>autostart=true]
            MP[mediaplayer.service<br/>autostart=true]
            TC[themecolor.service<br/>autostart=false]
        end
    end

    DBUS --> WESTON
    DBUS --> CAN_SETUP
    WESTON --> UDBUS
    CAN_SETUP --> UDBUS
    UDBUS --> COMP
    UDBUS --> RC
    UDBUS --> IC
    COMP --> AFM
    AFM --> GS
    AFM --> MP
    AFM --> TC

    style DBUS fill:#E91E63
    style UDBUS fill:#9C27B0
    style COMP fill:#673AB7
    style AFM fill:#3F51B5
    style GS fill:#4CAF50
    style MP fill:#2196F3
    style TC fill:#FF9800
```

---

## 13. Service Restart Policies

```mermaid
graph LR
    subgraph "Critical Services - Always Restart"
        WESTON[weston.service<br/>Restart=always<br/>RestartSec=2]
        UDBUS[unified-dbus.service<br/>Restart=always<br/>RestartSec=5]
        COMP[compositor.service<br/>Restart=always<br/>RestartSec=3]
        RC[rc-piracer.service<br/>Restart=always<br/>RestartSec=5<br/>Gamepad may disconnect]
        GS[gearselector.service<br/>Restart=always<br/>RestartSec=5]
        MP[mediaplayer.service<br/>Restart=always<br/>RestartSec=5]
    end

    subgraph "Standard Services - On Failure"
        AFM[afm.service<br/>Restart=on-failure<br/>RestartSec=3]
        TC[themecolor.service<br/>Restart=on-failure<br/>RestartSec=3]
        IC[instrument-cluster.service<br/>Restart=on-failure<br/>RestartSec=3]
    end

    subgraph "One-Shot Services - No Restart"
        CAN_SETUP[can-setup.service<br/>Type=oneshot<br/>RemainAfterExit=yes]
        BOOT_ANIM[boot-animation.service<br/>Type=oneshot]
    end

    style WESTON fill:#E91E63
    style UDBUS fill:#E91E63
    style COMP fill:#E91E63
    style AFM fill:#FF9800
    style CAN_SETUP fill:#4CAF50
```

---

## 14. File System Structure

```mermaid
graph TB
    subgraph "Root Filesystem /"
        subgraph "usr/"
            subgraph "usr/bin/"
                UDBUS_PY[unified-dbus-service.py]
                RC_PY[rc_piracer.py]
                GS_BIN[gearselector]
                MP_BIN[mediaplayer]
                TC_BIN[themecolor]
                COMP_BIN[compositor]
            end

            subgraph "usr/lib/systemd/system/"
                DBUS_SVC[dbus.service]
                WESTON_SVC[weston.service]
                CAN_SVC[can-setup.service]
                UDBUS_SVC[unified-dbus.service]
                COMP_SVC[compositor.service]
                RC_SVC[rc-piracer.service]
                AFM_SVC[afm.service]
                GS_SVC[gearselector.service]
                MP_SVC[mediaplayer.service]
                TC_SVC[themecolor.service]
            end
        end

        subgraph "etc/"
            subgraph "etc/headunit/"
                APP_JSON[applications.json<br/>AFM Configuration]
            end

            subgraph "etc/xdg/weston/"
                WESTON_INI[weston.ini<br/>Compositor Config]
            end

            subgraph "etc/dbus-1/system.d/"
                DBUS_CONF[com.seame.conf<br/>D-Bus Permissions]
            end

            subgraph "etc/tmpfiles.d/"
                TMP_CONF[headunit-tmpfiles.conf<br/>Runtime Dirs]
            end
        end

        subgraph "run/"
            subgraph "run/user/0/"
                BUS_SOCK[bus<br/>Session Socket<br/>Redirected]
            end

            subgraph "run/dbus/"
                SYS_SOCK[system_bus_socket<br/>System Bus]
            end
        end
    end

    style APP_JSON fill:#4CAF50
    style UDBUS_SVC fill:#E91E63
    style UDBUS_PY fill:#9C27B0
```

---

## 15. Yocto Build Architecture

```mermaid
graph TB
    subgraph "Yocto Build System"
        subgraph "Base Layers"
            POKY[poky/<br/>Yocto Reference Distro<br/>Scarthgap 5.0.12]
            META_OE[meta-openembedded/<br/>meta-oe<br/>meta-python<br/>meta-multimedia<br/>meta-networking]
        end

        subgraph "Hardware Layer"
            META_RPI[meta-raspberrypi/<br/>BSP Layer<br/>Raspberry Pi 4 Support]
        end

        subgraph "Framework Layer"
            META_QT6[meta-qt6/<br/>Qt 6.5.0<br/>QML + Wayland]
        end

        subgraph "Custom Layer: meta-headunit"
            subgraph "recipes-apps/"
                APP_GS[gearselector/]
                APP_MP[mediaplayer/]
                APP_TC[themecolor/]
                APP_IVI[ivi-compositor/]
                APP_MOCK[mock-dbus/]
                APP_RC[rc-piracer/]
                APP_AFM[application-framework-manager/]
            end

            subgraph "recipes-core/"
                CORE_IMG[images/headunit-image.bb]
                CORE_SYS[systemd/]
            end

            subgraph "recipes-graphics/"
                GFX_WESTON[weston/]
            end

            subgraph "recipes-connectivity/"
                CONN_CAN[can-setup/]
            end

            subgraph "recipes-kernel/"
                KERNEL_CAN[linux/ CAN Overlays<br/>mcp251xfd-spi0-0.dts<br/>mcp251xfd-spi1-0.dts]
            end
        end

        subgraph "Build Output"
            OUTPUT[tmp/deploy/images/<br/>raspberrypi4-64/]
            WIC[headunit-image-*.wic.bz2<br/>SD Card Image]
            MANIFEST[*.manifest<br/>Package List]
            OVERLAYS[can-overlays/<br/>Device Tree Overlays]
        end
    end

    POKY --> META_OE
    POKY --> META_RPI
    POKY --> META_QT6
    POKY --> CORE_IMG

    META_OE --> CORE_IMG
    META_RPI --> CORE_IMG
    META_QT6 --> APP_GS
    META_QT6 --> APP_MP
    META_QT6 --> APP_TC
    META_QT6 --> APP_IVI

    APP_GS --> CORE_IMG
    APP_MP --> CORE_IMG
    APP_TC --> CORE_IMG
    APP_IVI --> CORE_IMG
    APP_MOCK --> CORE_IMG
    APP_RC --> CORE_IMG
    APP_AFM --> CORE_IMG

    CORE_IMG --> OUTPUT
    OUTPUT --> WIC
    OUTPUT --> MANIFEST
    OUTPUT --> OVERLAYS
    KERNEL_CAN --> OVERLAYS

    style CORE_IMG fill:#E91E63
    style WIC fill:#4CAF50
    style META_QT6 fill:#2196F3
```

---

## 16. Feature Matrix

```mermaid
graph LR
    subgraph "Implemented Features ✅"
        subgraph "Display & UI"
            DUAL[Dual HDMI Output<br/>1024x600 each]
            QT6[Qt6 QML Apps]
            TOUCH[Touchscreen Support]
            THEME_SYNC[Real-time Theme Sync<br/><50ms latency]
            SWITCH[App Switching<br/>Ctrl+Tab]
            CUSTOM_COMP[Custom Compositor<br/>Surface Management]
        end

        subgraph "Hardware"
            DUAL_CAN[Dual CAN Bus<br/>can0 + can1<br/>Auto-detection]
            CAN_PROC[CAN Message Processing<br/>0x100, 0x102, 0x103]
            KALMAN_F[Kalman Filter<br/>Speed Smoothing]
            INA219[INA219 Battery Monitor<br/>I2C Sensor]
            GAMEPAD[USB Gamepad Control]
            MCP2515[MCP2515 CAN HAT<br/>Support]
        end

        subgraph "Communication"
            UNIFIED[Unified D-Bus Service<br/>5 Interfaces]
            SYSBUS[System Bus Architecture]
            SIGNALS[Signal-based Events]
            LOW_LAT[Low-latency IPC<br/><5ms]
            THREAD_SAFE[Thread-safe Hardware<br/>Readers]
        end

        subgraph "Media"
            USB_PLAY[USB Media Playback<br/>MP3, MP4, etc.]
            YOUTUBE[YouTube Support<br/>QtWebView]
            VOL_CTL[Volume Control<br/>via D-Bus]
            PLAYLIST[Playlist Management]
            VIRT_KB[Virtual Keyboard<br/>Search Input]
        end

        subgraph "System"
            AFM_MGR[Application Framework<br/>Manager]
            SYSTEMD[Systemd Orchestration]
            AUTO_START[Auto-start Apps]
            RESTART[Service Restart Policies]
            BOOT_ANIM[Boot Animation]
            FAST_BOOT[~15 Second Boot Time]
        end
    end

    subgraph "Future Enhancements ⚠️"
        COLOR_PERSIST[Color Persistence<br/>Across Reboots]
        SETTINGS_APP[Settings App<br/>WiFi, Bluetooth, etc.]
        NAV_APP[Navigation App<br/>Map View]
        MORE_CAN[More CAN Message<br/>Types]
        OTA[OTA Updates]
    end

    style UNIFIED fill:#E91E63
    style DUAL_CAN fill:#4CAF50
    style QT6 fill:#2196F3
    style AFM_MGR fill:#9C27B0
```

---

## 17. Performance Metrics

```mermaid
graph TB
    subgraph "System Performance"
        subgraph "Boot Performance"
            BOOT[Boot Time: ~15 seconds<br/>Power-on to app launch]
            SERVICES[Service Start Order:<br/>5 levels, sequential]
        end

        subgraph "Communication Performance"
            DBUS_LAT[D-Bus Latency: <5ms<br/>Local signal delivery]
            THEME_LAT[Theme Update: <50ms<br/>All apps synchronized]
            CAN_PROC_RATE[CAN Processing: 50 Hz<br/>20ms intervals]
        end

        subgraph "Display Performance"
            FPS[Frame Rate: 60 FPS<br/>Wayland vsync]
            VSYNC[V-Sync Enabled<br/>Tear-free rendering]
        end

        subgraph "Resource Usage"
            MEM[Memory: ~400 MB<br/>All services running]
            CPU[CPU: 15-25%<br/>Idle with apps]
            STORAGE[Image Size: 1.2 GB<br/>Compressed<br/>3.5 GB Installed]
        end

        subgraph "Hardware Performance"
            KALMAN_DT[Kalman Filter dt: 0.05s<br/>Dynamic timing]
            BAT_POLL[Battery Polling: 1 Hz<br/>1 second intervals]
            CAN_BITRATE[CAN Bitrate: 500 kbps<br/>Both interfaces]
        end
    end

    style DBUS_LAT fill:#4CAF50
    style THEME_LAT fill:#4CAF50
    style FPS fill:#2196F3
```

---

## 18. System Statistics Summary

```mermaid
mindmap
  root((HeadUnit IVI<br/>System Stats))
    Hardware
      Raspberry Pi 4 8GB
      Dual 7" 1024x600 HDMI
      Waveshare 2-CH CAN HAT
      INA219 Battery Sensor
      USB HID Gamepad
    Software Stack
      Yocto Scarthgap 5.0.12
      Poky Linux Custom
      Linux Kernel 6.1.x
      Weston 10.0.1
      Qt 6.5.0
      D-Bus 1.14.x
      Python 3.11.x
    Applications
      GearSelector 67KB
      MediaPlayer 131KB
      ThemeColor 67KB
      Total Image 1.2GB
    Performance
      Boot Time 15s
      D-Bus <5ms
      Theme Update <50ms
      CAN Processing 50Hz
      Frame Rate 60FPS
      Memory 400MB
    Network
      WiFi BCM43455
      Bluetooth 5.0
      CAN0 500kbps SPI0
      CAN1 500kbps SPI1
    Development
      3 Months
      Team 2-3 Devs
      15000 Lines of Code
      Image Size 3.5GB
```

---

**Presentation Date:** Monday, December 9, 2025
**Project:** HeadUnit IVI System - SEAME
**Status:** ✅ Working Image (Previous Stable Version)

---

## Usage Notes:

1. **Copy any diagram** and paste it into:
   - Mermaid Live Editor: https://mermaid.live
   - GitHub README (renders automatically)
   - VS Code (with Mermaid extension)
   - Notion, Confluence, GitLab (native support)

2. **Export options:**
   - PNG/SVG from Mermaid Live
   - PDF via browser print
   - PowerPoint via copy-paste

3. **Customize:**
   - Change colors: `style NodeName fill:#HEX`
   - Adjust layout: `TB` (top-bottom), `LR` (left-right)
   - Add more details as needed
