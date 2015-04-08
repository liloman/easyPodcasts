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

local group=Group:new()
podcast=Podcast:new()

EASYPATH=os.getenv("HOME")..'/.config/easyPodcasts/'
iconPath=EASYPATH..'icons/'
audioPath=EASYPATH..'audio/'
playlistsPath=EASYPATH..'playlists/'
wget="/usr/bin/env wget -U 'firefox' "


function updateProgressbar()
    podcast:UpdateBar()
    return true
end

--each 2 seconds
glib.timeout_add_seconds(0,2,updateProgressbar)


local button=builder:get_object('toolbuttonAddGroup')
function button:on_clicked() group:AddGroup() end

local button=builder:get_object('toolbuttonDelGroup')
function button:on_clicked() group:DelGroup() end

local button=builder:get_object('toolbuttonAddRSS')
function button:on_clicked() group:AddRSS() end

local button=builder:get_object('toolbuttonDelRSS')
function button:on_clicked() group:DelRSS() end

local button=builder:get_object('switchUpdateRSS')
function button:on_state_set() 
    if not button.state then
        podcast:ParsePodcasts() 
            db:sql("update RSS set autoupdate=1 where id="..podcast:GetSelected())
    else
        db:sql("update RSS set autoupdate=0 where id="..podcast:GetSelected())
    end 
end

local button=builder:get_object('toolbuttonPlayPause')
function button:on_clicked() podcast:Play() end

local button=builder:get_object('toolbuttonForward')
function button:on_clicked() podcast:Forward() end

local button=builder:get_object('toolbuttonPrevious')
function button:on_clicked() podcast:Previous() end

local button=builder:get_object('toggletoolbuttonProgramas')
function button:on_toggled()  builder:get_object('boxRSS'):set_visible(self:get_active()) end 

local bar=builder:get_object('volumebutton')
function bar:on_value_changed()  podcast:ChangeVolume(self:get_value())  end 

local bar = builder:get_object('scaleSong')
function bar:on_change_value()  podcast:MovePlaying()  end 

function window:on_destroy()
    Gtk.main_quit()
    db:close()
    podcast:close()
end

window:show_all()
Gtk.main()
