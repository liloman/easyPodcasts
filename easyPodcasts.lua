package.path = package.path .. ';classes/?.lua'
local lgi = require 'lgi'
local assert = lgi.assert
Gtk = lgi.Gtk
db=require("db")

builder = Gtk.Builder()
assert(builder:add_from_file(('limpio.ui')))
local window = builder.objects.mainWindow

require("classes.Group")
local group=Group:new()

local button=builder:get_object('toolbuttonAddGroup')
function button:on_clicked() group:AddGroup() end

local button=builder:get_object('toolbuttonDelGroup')
function button:on_clicked() group:DelGroup() end

local button=builder:get_object('toolbuttonAddRSS')
function button:on_clicked() group:AddRSS() end

local button=builder:get_object('toolbuttonDelRSS')
function button:on_clicked() group:DelRSS() end


function window:on_destroy()
    Gtk.main_quit()
    db:close()
end

window:show_all()
Gtk.main()
