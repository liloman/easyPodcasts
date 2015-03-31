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
        Gtk.Toolbar {
            id = 'toolbarHeaderBar',
            orientation='HORIZONTAL',
            Gtk.ToolButton {stock_id="gtk-go-back"},
            Gtk.ToolButton {stock_id="gtk-go-forward"},
            Gtk.SeparatorToolItem {Expand=True},
            Gtk.ToggleToolButton {label="Programas"},
            Gtk.SeparatorToolItem {Expand=True},
            Gtk.ToolButton {stock_id="gtk-find"},
            Gtk.ToolButton {stock_id="gtk-preferences"},
        },
        Gtk.Box {
            id="boxUpper",
            orientation = 'HORIZONTAL',
            expand=true,
            Gtk.Box {
                id="boxPodCasts",
                orientation = 'VERTICAL',
                Gtk.ScrolledWindow {
                    id="scrolledwindowPodcasts",
                    min_content_width = 214,
                    shadow_type = Gtk.ShadowType.IN,
                    Gtk.ListBox {
                        id = "listboxPodcasts",
                    },
                },
                Gtk.Toolbar {
                    id = 'toolbarPodcasts',
                    Gtk.ToolButton { id = 'buttonAddPodcasts', icon_name="list-add"},
                    Gtk.ToolButton { id = 'buttonDelPodcasts', icon_name="list-remove"},
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
                Gtk.ToolButton { icon_name="gtk-media-previous"},
                Gtk.ToolButton { icon_name="gtk-media-play"},
                Gtk.ToolButton { icon_name="gtk-media-forward"},
            },
            Gtk.ProgressBar { id = 'progressBar', },
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
