#!/usr/bin/env lua
abDir=arg[0]:match("(.*/)")
package.path = package.path .. ';'..abDir..'?.lua;'
local lgi = require 'lgi'
local assert = lgi.assert
Gtk = lgi.Gtk
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

function playlistActive()
    return builder:get_object('toolbuttonPlaylist'):get_active() 
end

function updateProgressbar()
    if not playlistActive() and not playlistmode then podcast:UpdateBar()
    else playlist:UpdateBar() end
    return true
end

function download(play)
        print("wget "..play.url)
        os.execute(wget.." "..play.url.." -nc -O "..play.path.." -o "..os.tmpname().."-wget.log &")
        --Let's wait some time to download something
        socket.sleep(10)
end

--each 2 seconds
glib.timeout_add_seconds(0,2,updateProgressbar)


local button=builder:get_object('toolbuttonAddGroup')
function button:on_clicked() group:AddGroup() end

local button=builder:get_object('toolbuttonDelGroup')
function button:on_clicked() group:DelGroup() end

local button=builder:get_object('toolbuttonAddRSS')
function button:on_clicked() 
    if not playlistmode() then group:AddRSS()
    else playlist:AddPlaylist() end
end

local button=builder:get_object('toolbuttonDelRSS')
function button:on_clicked() 
    if not playlistmode() then group:DelRSS() 
    else playlist:DelPlaylist() end
end

local button=builder:get_object('switchUpdateRSS')
function button:on_state_set() 
    local selected=podcast:GetSelected()
    if not selected then return end
    if not button.state then
        podcast:ParsePodcasts() 
        db:sql("update RSS set autoupdate=1 where id="..selected)
    else
        db:sql("update RSS set autoupdate=0 where id="..selected)
    end 
end

local  function play()
    if not playlistActive() then
        podcast:Play()
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
    play()
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

local bar = builder:get_object('scaleSong')
function bar:on_change_value()  podcast:MovePlaying()  end 

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
    local Gdk = lgi.Gdk
    if event.keyval == Gdk.KEY_space then   
        play()
    end

    if event.keyval == Gdk.KEY_Right then   
        local barSong = builder:get_object('progressAdjust')
        podcast:MovePlaying(0.10,1)
    end

    print("hola "..event.keyval.." y "..Gdk.KEY_Right)
end

function window:on_destroy()
    Gtk.main_quit()
    db:close()
    podcast:close()
end


window:show_all()
Gtk.main()
