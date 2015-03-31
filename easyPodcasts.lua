local lgi = require 'lgi'
local Gtk = lgi.Gtk

local w = Gtk.Window {
    width_request=769,
    height_request=430,
    title="easyPodcasts",
    decorated=True,
    Gtk.Box {
        id="boxMain",
        orientation = 'VERTICAL',
        valign='FILL',halign='FILL',
        Gtk.Toolbar {
            id = 'toolbarHeaderBar',
            orientation='HORIZONTAL',
            valign='FILL',halign='FILL',
            expand=false,
            -- valign='START',
            -- halign='FILL',
            -- expand=true,
            Gtk.ToolButton {stock_id="gtk-go-back"},
            Gtk.ToolButton {stock_id="gtk-go-forward"},
            Gtk.SeparatorToolItem {visible_horizontal=true,expand=true,draw=false},
            Gtk.ToggleToolButton {label="Programas"},
            Gtk.SeparatorToolItem {visible_horizontal=true,draw=false,expand=true},
            Gtk.ToolButton {stock_id="gtk-find"},
            Gtk.ToolButton {stock_id="gtk-preferences"},
        },
        Gtk.Box {
            id="boxUpper",
            orientation = 'HORIZONTAL',
            expand=true,
            valign='FILL',halign='FILL',
            Gtk.Box {
                id="boxPodCasts",
                orientation = 'VERTICAL',
                expand=false,
                Gtk.ScrolledWindow {
                    id="scrolledwindowPodcasts",
                    min_content_width = 214,
                    shadow_type = Gtk.ShadowType.IN,
                    expand=true,
                    Gtk.ListBox { id = "listboxPodcasts", },
                },
                Gtk.Toolbar {
                    id = 'toolbarPodcasts',
                    orientation = 'HORIZONTAL',
                    icon_size = 'SMALL_TOOLBAR',
                    -- hexpand=true, halign='FILL',
                    expand=false,-- halign='FILL',
                    Gtk.ToolButton { id = 'buttonAddPodcasts', icon_name="list-add"},
                    Gtk.ToolButton { id = 'buttonDelPodcasts', icon_name="list-remove"},
                    Gtk.SeparatorToolItem {visible_horizontal=true,draw=false,hexpand=true },
                    -- Gtk.SeparatorToolItem {draw=true,expand=false},
                    -- Gtk.SeparatorToolItem {draw=false,hexpand=true},
                    Gtk.ToolButton { id = 'buttonAddGroup', icon_name="folder-new"},
                    Gtk.ToolButton { id = 'buttonDelGroup', icon_name="user-trash"},
                },
            },
            Gtk.ScrolledWindow {
                id = 'scrolledwindowRSS',
                expand = true,
                Gtk.Viewport {
                    id = 'viewportRSS',
                    Gtk.ListBox {
                        id = "listboxRSS",
                        Gtk.Box {
                            id = "boxRSSHeader",
                            orientation = 'HORIZONTAL',
                            Gtk.Image {
                                id = "imageRSSHeader",
                                icon_name = "images/sateli3.png",
                            },
                            Gtk.TextView {
                                id = "textviewRSSHeader",
                            },
                        },
                    },
                },
            },
        },
        Gtk.Box {
            id="boxControls",
            orientation = 'HORIZONTAL',
            Gtk.Toolbar {
                id = 'toolbarControls',
                toolbar_style = 'BOTH',
                Gtk.ToolButton { label="Previous", icon_name="gtk-media-previous"},
                Gtk.ToolButton {label="Play/Pause",  icon_name="gtk-media-play"},
                Gtk.ToolButton {label="Forward",  icon_name="gtk-media-forward"},
            },
            Gtk.ProgressBar { 
                id = 'progressBar',
                valign='FILL',halign='FILL',
                hexpand = true,
                margin = 15,
                show_text=true,
                text ="titulo podcast/cancion",
            },
            Gtk.LevelBar { id = 'levelbarVolume', },
        }
    }
}

-- function w.child.button:on_clicked(...) print('clicked1_cb', w.child.label, ...) end
-- function w.child.button:on_clicked(...) print('clicked2_cb', self, ...) end
-- function w.child.button:on_key_press_event(...) print('keypress', ...) end

w.on_destroy = Gtk.main_quit
w:show_all()

Gtk.main()
