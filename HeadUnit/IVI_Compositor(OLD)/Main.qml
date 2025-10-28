import QtQuick
import QtQuick.Controls
import QtWayland.Compositor
import QtWayland.Compositor.XdgShell
import "../"

WaylandCompositor{
    id: compositor
    socketName: "wayland-1"

    property var items: [];
    property int navBarHeight: 50
    property int statusBarHeight: 24
    property int gearSelectorWidth: 200

    // Seat {
    //     id: seat0
    //     name: "seat0"
    //     capabilities: Seat.Pointer | Seat.Keyboard | Seat.Touch
    // }

    // Surface item component with proper scaling for 1024x600
    Component {
        id: surfaceItemComponent
        WaylandQuickItem {
            id: wqi
            focusOnClick: true
            touchEventsEnabled: true
            // fill the parent so the Wayland buffer is rendered to the available area
            anchors.fill: parent
            clip: true
            // track the buffer size reported by the Wayland surface
            property int bufferWidth: 0
            property int bufferHeight: 0

            // When the surface buffer arrives, size this item to the parent so
            // it renders into the WindowApp area. If parent is not yet set, fall
            // back to the buffer size.
            onSurfaceChanged: {
                if (surface && surface.size) {
                    console.debug("surfaceChanged: buffer size=", surface.size, "parent=", parent);
                    bufferWidth = surface.size.width || 0;
                    bufferHeight = surface.size.height || 0;
                    // rely on anchors.fill for sizing; make item visible when buffer arrives
                    visible = true;
                }
            }
            Component.onCompleted: {
                if (surface && surface.size) {
                    visible = true;
                }
            }
        }
    }

    // Place surfaces based on application type
    function placeItemByTitle(item, title, toplevelOrShell) {
        if (!title || title.length === 0)
            return false;

    console.debug("placeItemByTitle called for title=", title, "item=", item);

        if (title.indexOf("GearSelector") !== -1) {
            if (toplevelOrShell && toplevelOrShell.setMinSize) {
                var sz = Qt.size(leftPanel.width, leftPanel.height);
                toplevelOrShell.setMinSize(sz);
                toplevelOrShell.setMaxSize(sz);
                if (toplevelOrShell.sendConfigure)
                    toplevelOrShell.sendConfigure(sz, []);
            }
            // parent into the inner placeholder if available so the icon sits
            // centered above the background; fall back to the panel itself.
            var lpTarget = leftPanel.leftPanelRef ? leftPanel.leftPanelRef : leftPanel;
            item.parent = lpTarget;
            console.debug("Placed GearSelector into leftPanel", item);
            try { item.anchors.fill = lpTarget; } catch(e) {}
            item.visible = true;
            item.z = 1;
            try { if (leftPanel.leftPanelRef) leftPanel.leftPanelRef.visible = false; } catch(e) {}
            return true;
        } else {
            // All other applications (MediaPlayer, ThemeColor, etc.)
            // If we have a toplevel (shell) we should configure the client to
            // the app area's size so it renders at the expected resolution.
            var appArea = appPlaceholder.areaPlacerHolderRef;
            if (toplevelOrShell && toplevelOrShell.setMinSize) {
                var sz = Qt.size(appArea.width, appArea.height);
                toplevelOrShell.setMinSize(sz);
                toplevelOrShell.setMaxSize(sz);
                if (toplevelOrShell.sendConfigure)
                    toplevelOrShell.sendConfigure(sz, []);
            }
            item.parent = appArea;
            console.debug("Placed app into appContainerRef", item, "appContainerRef=", appArea);
            try { item.anchors.fill = appArea; } catch(e) {}
            // also set explicit size so the WaylandQuickItem knows the render area
            try { item.width = appArea.width; item.height = appArea.height; } catch(e) {}
            item.visible = true;
            item.z = 1;
            // hide only the area placeholder content (not the container) so the nav bar remains visible
            try { appPlaceholder.areaPlacerContentRef.visible = false; } catch(e) { console.debug('could not hide areaPlacerContentRef', e); }
            return true;
        }
    }

    function placeItemByWidth(item) {
        console.debug("placeItemByWidth called for item=", item, "item.width=", item.width);
        // If item.width is 0 or not set yet, treat it as unknown and prefer placing
        // into the application area. Only consider leftPanel when we have a
        // positive width small enough to fit in the left panel.
        var wantLeft = (item.width > 0) && (item.width <= leftPanel.width + 20);
        var p = wantLeft ? leftPanel : appPlaceholder.areaPlacerHolderRef;
        if (item.parent !== p) {
            item.parent = p;
            try { item.anchors.fill = p; } catch(e) {}
            item.z = 1;
            // ensure visibility after parenting
            item.visible = true;
        }
        if (p === leftPanel) {
            if (leftPanel.leftPanelRef) {
                leftPanel.leftPanelRef.visible = false;
            }
        }
        if (p === appPlaceholder.areaPlacerHolderRef) {
            try {
                appPlaceholder.areaPlacerContentRef.visible = false;
            } catch(e) {
                console.debug('could not hide areaPlacerContentRef', e);
            }
        }
    console.debug("post-place: item=", item, "parent=", item.parent, "parent.children=", item.parent ? item.parent.children.length : 0, "parent.visible=", item.parent ? item.parent.visible : "?", "placeholderContent.visible=", (appPlaceholder && appPlaceholder.areaPlacerContentRef) ? appPlaceholder.areaPlacerContentRef.visible : "?", "visible=", item.visible, "w=", item.width, "h=", item.height);
    }

    // XDG Shell support
    XdgShell {
        id: xdg
        // declare formal parameters on the handler to avoid deprecated
        // parameter injection into the handler body
        onToplevelCreated: function(xdgSurface, toplevel) {
            handleToplevelCreated(xdgSurface, toplevel);
        }
    }

    // Use a named JS function with formal parameters instead of relying on
    // parameter injection inside the signal handler (deprecated).
    // Track placement state for dynamic items (avoid adding properties to QQuickItem)
    // Use an array of weak references (store item ids) to avoid assigning properties to QQuickItem
    property var placedItems: [];
    // diagnostics: list of tracked items { item, title, appId }
    property var itemInfo: [];
    function getInfoFor(item) {
        for (var i=0;i<itemInfo.length;i++) {
            if (itemInfo[i] && itemInfo[i].item === item) return itemInfo[i];
        }
        return null;
    }
    function setPlaced(item, val) {
        if (!item) return;
        var id = item.__objectId__ || item;
        if (val) {
            if (placedItems.indexOf(id) === -1) placedItems.push(id);
        } else {
            var idx = placedItems.indexOf(id);
            if (idx !== -1) placedItems.splice(idx, 1);
        }
    }
    function isPlaced(item) {
        if (!item) return false;
        var id = item.__objectId__ || item;
        return placedItems.indexOf(id) !== -1;
    }
    function handleToplevelCreated(xdgSurface, toplevel) {
        // defensive: some runtimes pass parameters in different order. Detect and normalize.
        var surf = xdgSurface;
        var top = toplevel;
        if (!(surf && surf.surface) && top && top.surface) {
            // parameters are swapped
            surf = toplevel;
            top = xdgSurface;
        }
        console.debug("handleToplevelCreated: raw params=", xdgSurface, toplevel, "-> surf=", surf, "top=", top);
        try { console.debug("toplevel.title=", top && top.title, "toplevel.appId=", top && top.appId); } catch(e) {}
        // prefer parenting new items to the app container when available, otherwise parent to mainWindow;
        var parentForItem = (appPlaceholder && appPlaceholder.areaPlacerHolderRef) ? appPlaceholder.areaPlacerHolderRef : mainWindow;
        console.debug("Creating surface item; parentForItem=", parentForItem);
        var item = surfaceItemComponent.createObject(parentForItem, { visible: true });
        if (item && surf && surf.surface) {
            console.debug("Assigning surface to item; has surface size=", surf.surface.size);
            item.surface = surf.surface;
            // store diagnostic info (use normalized 'top' for title/appId)
            try {
                var t = (top && top.title) ? top.title : "";
                var appid = (top && top.appId) ? top.appId : "";
                itemInfo.push({ item: item, title: t, appId: appid, toplevelRef: top });
                console.debug("diagnostic: pushed itemInfo", itemInfo[itemInfo.length-1]);
            } catch (e) {}
            // if the buffer already has a size, apply it to the item so placement works
            try {
                if (surf.surface.size && surf.surface.size.width && surf.surface.size.height) {
                    item.width = surf.surface.size.width;
                    item.height = surf.surface.size.height;
                    console.debug("Assigned initial buffer size to item", item.width, item.height);
                }
            } catch(e) {}
        }
        if (!item)
            return;

        // Immediate placement attempt: maybe buffer already present or title known
        try {
            var info = getInfoFor(item);
            var bufw = item.bufferWidth || (item.surface && item.surface.size && item.surface.size.width ? item.surface.size.width : 0);
            if (bufw > 0 && bufw <= (leftPanel.width + 20)) {
                // treat small buffer as GearSelector; parent immediately
                if (info && info.toplevelRef && info.toplevelRef.setMinSize) {
                    var s = Qt.size(leftPanel.width, leftPanel.height);
                    info.toplevelRef.setMinSize(s); info.toplevelRef.setMaxSize(s);
                    if (info.toplevelRef.sendConfigure) info.toplevelRef.sendConfigure(s, []);
                }
                var lp = leftPanel.leftPanelRef ? leftPanel.leftPanelRef : leftPanel;
                item.parent = lp;
                try { item.anchors.fill = lp; } catch(e) {}
                item.visible = true; item.z = 1; try { if (leftPanel.leftPanelRef) leftPanel.leftPanelRef.visible = false; } catch(e) {} setPlaced(item, true);
                console.debug("immediate placed by buffer into leftPlaceholder", item, "bufw=", bufw);
            } else if (info && info.title && info.title.length>0) {
                if (placeItemByTitle(item, info.title, info.toplevelRef)) { setPlaced(item, true); console.debug('immediate placed by title', item); }
            }
        } catch(e) { console.debug('immediate placement attempt error', e); }

        compositor.items.push(item);
        try {
            console.debug("post-create: parentForItem.children.length=", parentForItem.children ? parentForItem.children.length : "(no children)", "item.visible=", item.visible, "item.width=", item.width, "item.height=", item.height, "itemInfo=", itemInfo.length ? itemInfo[itemInfo.length-1] : undefined);
        } catch(e) {}

        // Try to place by title; if not immediately available, retry a few times
        if (!placeItemByTitle(item, toplevel.title || "", toplevel)) {
            var tries = 0;
            // allow more retries before falling back; smaller interval for responsiveness
            var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 80; repeat: true }', compositor);
                    timer.triggered.connect(function() {
                tries++;
                if (placeItemByTitle(item, toplevel.title || "", toplevel)) {
                console.debug("placed after retry: ", item, "parent=", item.parent, "visible=", item.visible);
                    timer.stop();
                    timer.destroy();
                    return;
                }
                if (tries >= 50) {
                    // fallback: place by width (simple heuristic)
                    placeItemByWidth(item);
                    console.debug("placed by width fallback: ", item, "parent=", item.parent, "visible=", item.visible);
                    timer.stop();
                    timer.destroy();
                }
            });
                    timer.start();
        }

        // Attach a handler so when the item's surface actually arrives and its size is set
        // we re-run placement. This avoids placing while width/height are still 0.
        try {
            // Do not assign arbitrary properties on QQuickItem (item._placementDone) — instead
            // use setPlaced/isPlaced which track items in _placedItems.
            if (item.surfaceChanged && typeof item.surfaceChanged.connect === 'function') {
                item.surfaceChanged.connect(function() {
                    console.debug("item.surfaceChanged signal for", item, "surface=", item.surface ? item.surface.size : null, "width=", item.width, "height=", item.height);
                            if (isPlaced(item)) return;
                            // If the surface reported a small buffer width, prefer the leftPanel
                            try {
                                var bufw = item.bufferWidth || (item.surface && item.surface.size && item.surface.size.width ? item.surface.size.width : 0);
                                if (bufw > 0 && bufw <= (leftPanel.width + 20)) {
                                    // configure the toplevel to leftPanel size if possible
                                    if (toplevel && toplevel.setMinSize) {
                                        var sz = Qt.size(leftPanel.width, leftPanel.height);
                                        toplevel.setMinSize(sz);
                                        toplevel.setMaxSize(sz);
                                        if (toplevel.sendConfigure) toplevel.sendConfigure(sz, []);
                                    }
                                    // parent into the inner placeholder so the icon sits above
                                    var lp3 = leftPanel.leftPanelRef ? leftPanel.leftPanelRef : leftPanel;
                                    item.parent = lp3;
                                    try { item.anchors.fill = lp3; } catch(e) {}
                                    item.visible = true;
                                    item.z = 1;
                                    try { if (leftPanel.leftPanelRef) leftPanel.leftPanelRef.visible = false; } catch(e) {}
                                    setPlaced(item, true);
                                    console.debug("placed on surfaceChanged by buffer-width into leftPanel", item, "bufw=", bufw);
                                    return;
                                }
                            } catch(e) { console.debug('surfaceChanged buffer check error', e); }
                            if (placeItemByTitle(item, toplevel.title || "", toplevel)) {
                                setPlaced(item, true);
                                console.debug("placed on surfaceChanged by title", item, "parent=", item.parent, "parent.children=", item.parent ? item.parent.children.length : 0);
                                return;
                            }
                            if (item.width && item.width > 0) {
                                placeItemByWidth(item);
                                setPlaced(item, true);
                                console.debug("placed on surfaceChanged by width", item, "parent=", item.parent, "parent.children=", item.parent ? item.parent.children.length : 0);
                                return;
                            }
                });
            } else {
                // fallback: poll a few times for width to become non-zero
                var pollTries = 0;
                var pollTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 100; repeat: true }', compositor);
                pollTimer.triggered.connect(function() {
                    pollTries++;
                    console.debug('polling item size', item, 'width=', item.width, 'tries=', pollTries);
                    if (item.width && item.width > 0) {
                        if (!isPlaced(item)) placeItemByWidth(item);
                        setPlaced(item, true);
                        console.debug('placed on poll by width', item, 'parent=', item.parent, 'parent.children=', item.parent ? item.parent.children.length : 0);
                        pollTimer.stop();
                        pollTimer.destroy();
                        return;
                    }
                    if (pollTries >= 20) { pollTimer.stop(); pollTimer.destroy(); }
                });
                pollTimer.start();
            }
        } catch(e) { console.debug('error attaching surfaceChanged', e); }
    }

    // Debug helper to print counts and tracked items
    function dumpDiagnostics() {
        try {
            var leftCount = leftPanel ? leftPanel.children.length : -1;
            var appCount = appPlaceholder && appPlaceholder.areaPlacerHolderRef ? appPlaceholder.areaPlacerHolderRef.children.length : -1;
            console.debug("DIAG: leftCount=", leftCount, "appCount=", appCount, "trackedItems=", Object.keys(itemInfo).length);
            for (var k in itemInfo) {
                console.debug("DIAG: item=", k, "info=", itemInfo[k], "parent=", k.parent ? k.parent : "(no parent)");
            }
        } catch(e) { console.debug('dumpDiagnostics error', e); }
    }

    // Main output
    WaylandOutput {
        id: output
        sizeFollowsWindow: true

        window: Window {
            id: mainWindow
            width: 1024
            height: 600
            visible: true
            color: "#0a0e1a"
            title: "IVI Compositor - HeadUnit"

            // Main content area
            Row {

                width: parent.width
                height: parent.height
                spacing: 0

                LeftPanel{
                    id: leftPanel
                    width: compositor.gearSelectorWidth
                    height: parent.height
                }

                // Divider
                Rectangle {
                    width: 2
                    height: parent.height
                    color: "#1e293b"
                }

                // Right panel - Applications area
                RightPanel {
                    id: appPlaceholder
                    width: parent.width - leftPanel.width - 2
                    height: parent.height
                    // forward compositor values so WindowApp can sync sizes
                    Component.onCompleted: {
                        // assign once to avoid binding loops
                        appPlaceholder.navBarH = compositor.navBarHeight;
                        appPlaceholder.statusBarH = compositor.statusBarHeight;
                    }
                }
            }
        }
    }
}
