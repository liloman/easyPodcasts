package.path = package.path .. ';classes/?.lua'
local lgi = require 'lgi'
local assert = lgi.assert
Gtk = lgi.Gtk
db=require("db.db")

builder = Gtk.Builder()
assert(builder:add_from_file(('limpio.ui')))
local window = builder.objects.mainWindow
local Group=require("classes.Group")
local Podcast=require("classes.Podcast")

EASYPATH=os.getenv("HOME")..'/.config/easyPodcasts/'
iconPath=EASYPATH..'icons/'
audioPath=EASYPATH..'audio/'

local group=Group:new()
podcast=Podcast:new()

local button=builder:get_object('toolbuttonAddGroup')
function button:on_clicked() group:AddGroup() end

local button=builder:get_object('toolbuttonDelGroup')
function button:on_clicked() group:DelGroup() end

local button=builder:get_object('toolbuttonAddRSS')
function button:on_clicked() group:AddRSS() end

local button=builder:get_object('toolbuttonDelRSS')
function button:on_clicked() group:DelRSS() end

local button=builder:get_object('switchUpdateRSS')
function button:on_state_set() if not button.state then podcast:UpdatePodcasts() end end

local button=builder:get_object('toolbuttonPlayPause')
function button:on_clicked() podcast:Play() end

function window:on_destroy()
    Gtk.main_quit()
    db:close()
end

window:show_all()
Gtk.main()
