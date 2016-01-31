#!/usr/bin/env lua
abDir=arg[0]:match("(.*/)")
package.path = package.path .. ';'..abDir..'?.lua;'
local lgi = require 'lgi'
local assert = lgi.assert
Gtk = lgi.Gtk
Gdk = lgi.Gdk
local glib = lgi.GLib
db=require("classes.db")

builder = Gtk.Builder()
assert(builder:add_from_file((abDir..'ui/limpio.ui')))
local window = builder.objects.mainWindow
local Group=require("classes.Group")
local Podcast=require("classes.Podcast")
local Playlist=require("classes.Playlist")
local group=Group:new()

--Global variables
podcast=Podcast:new()
playlist=Playlist:new()
EASYPATH=os.getenv("HOME")..'/.config/easyPodcasts/'
iconPath=EASYPATH..'icons/'
audioPath=EASYPATH..'audio/'
playlistsPath=EASYPATH..'playlists/'
wget="/usr/bin/env wget -U 'firefox' "
playlistmode=false

function updateStatusBar(msg)
    statusbar:pop(0)
    statusbar:push(0,msg)
end

function playlistActive()
    return builder:get_object('toolbuttonPlaylist'):get_active() 
end

function updateProgressbar()
    if not playlistActive() and not playlistmode then podcast:UpdateBar()
    else playlist:UpdateBar() end
    return true
end

function download(play)
    print("wgetting... "..play.url)
    os.execute(wget.." "..play.url.." -p -O "..play.path.." -o /tmp/downloaded-wget.log &")
    db:sql("update Podcasts set downloaded=1 where id="..play.idpodcast)
    updateStatusBar("Downloading "..play.path)
    --Let's wait some time to download something
    socket.sleep(10)
end

--each 3 seconds
glib.timeout_add_seconds(0,3,updateProgressbar)


statusbar=builder:get_object('statusbar')
statusbar:push(0,"Started")

local button=builder:get_object('toolbuttonAddGroup')
function button:on_clicked() group:AddGroup() end

local button=builder:get_object('toolbuttonDelGroup')
function button:on_clicked() group:DelGroup() end

local button=builder:get_object('toolbuttonAddRSS')
function button:on_clicked() 
    if not playlistActive() then group:AddRSS()
    else playlist:AddPlaylist() end
end

local button=builder:get_object('toolbuttonDelRSS')
function button:on_clicked() 
    if not playlistActive() then group:DelRSS() 
    else playlist:DelPlaylist() end
end

local button=builder:get_object('switchUpdateRSS')
function button:on_state_set() 
    print("update state...")
    local selected=podcast:GetSelected()
    if not selected then return end
    if not button.state then
        podcast:ParsePodcasts() 
        db:sql("update RSS set autoupdate=1 where id="..selected)
    else
        db:sql("update RSS set autoupdate=0 where id="..selected)
    end 
end

local  function play(new)
    if not playlistActive() then
        podcast:Play(new)
        playlist:ResetPlay()
        playlistmode=false
    else 
        playlist:Play()
        podcast:ResetPlay()
        playlistmode=true
    end
end

local button=builder:get_object('toolbuttonPlayPause')
function button:on_clicked() 
    play(false)
end

local button=builder:get_object('toolbuttonNext')
function button:on_clicked() 
    if not playlistmode then podcast:Next()
    else playlist:Next() end
end

local button=builder:get_object('toolbuttonPrevious')
function button:on_clicked() 
    if not playlistmode then podcast:Previous()
    else playlist:Previous() end
end

local button=builder:get_object('toggletoolbuttonProgramas')
function button:on_toggled()  builder:get_object('boxRSS'):set_visible(self:get_active()) end 

local bar=builder:get_object('volumebutton')
function bar:on_value_changed()  podcast:ChangeVolume(self:get_value())  end 

local barSongs = builder:get_object('scaleSong')
function barSongs:on_change_value()  podcast:MovePlaying()  end 
-- Problems with updatebar if activated
-- function barSongs:on_value_changed()  podcast:MovePlaying()  end 

local button=builder:get_object('toolbuttonPlaylist')
function button:on_clicked() 
    local b={"toolbuttonAddGroup", "toolbuttonDelGroup"}
    local bTooltip={"Add", "Del"}
    if self:get_active() then 
        for _,v in pairs(b) do builder:get_object(v):set_visible(false) end
        for _,v in pairs(bTooltip) do 
            builder:get_object("toolbutton"..v.."RSS"):set_tooltip_text(v.." Playlist") 
        end
        playlist:ShowPlaylists()
    else
        for _,v in pairs(b) do builder:get_object(v):set_visible(true) end
        for _,v in pairs(bTooltip) do 
            builder:get_object("toolbutton"..v.."RSS"):set_tooltip_text(v.." RSS") 
        end
        group:UpdateAll()
    end
end

function window:on_key_press_event(event)
    if event.keyval == Gdk.KEY_KP_Enter or event.keyval==Gdk.KEY_Return then   
        play(true)
    end

    if event.keyval == Gdk.KEY_space then   
        play(false)
    end

    if event.keyval == Gdk.KEY_Right then   
        podcast:MovePlaying(20,1)
    end

    if event.keyval == Gdk.KEY_Left then   
        podcast:MovePlaying(20,0)
    end

    if event.keyval == Gdk.KEY_Tab then   
        print("TABS")
    end

    if event.keyval == Gdk.KEY_u then   
        print("u")
        local button=builder:get_object('switchUpdateRSS')
        button:set_active(not button:get_active())
    end

    return false
end

function window:on_destroy()
    Gtk.main_quit()
    db:close()
    podcast:close()
end


window:show_all()
Gtk.main()
