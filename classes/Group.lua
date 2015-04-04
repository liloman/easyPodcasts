local Class=require("Class")
Group=Class("Group")

--Private variable
local listLocal=nil
local listRSSSelected=nil
local LB=builder:get_object('listboxPodcasts')

function Group:initialize(name)
    self.name=name
    self:UpdateAll()
end


function Group:UpdateAll()
    for group in db:select("SELECT name from Groups") do
        self:Update(group,'')
    end
end

function Group:Update(groupName,rss)
    local found=false
    for _,child in ipairs(LB:get_children()) do
        if child:get_child():get_label() == groupName then 
            listLocal=child:get_child():get_child()
            found=true 
        end
    end
    --Create the group (GtkExpander)
    if not found then 
        print("not found")
        listLocal=Gtk.ListBox()
        local label=Gtk.Label()
        label:set_label(rss)
        if rss~='' then listLocal:insert(label,-1) end
        group=Gtk.Expander()
        group:set_label(groupName)
        group:add(listLocal)
        function group:on_activate() listRSSSelected=self:get_child() end
        function listLocal:on_row_activated() listRSSSelected=self end
        LB:insert(group,-1)
    end
    --Create its RSS
    for rss,img in db:select("SELECT rss,img from listRSSGroups where groupName='"..groupName.."'") do
        self:UpdateRSS(rss,img)
    end
end

-- local function currentDir()
--     local file_name = debug.getinfo(1).short_src
--     local p = io.popen("dirname $(readlink -f " .. file_name .. ")")
--     local pwd
--     if p then
--         pwd = p:read("*l").."/"
--         p:close()
--     end
--     return pwd
-- end

function Group:UpdateRSS(rss,img)
    print("adding "..rss.." with "..img)
    local hbox=Gtk.HBox()
    local label=Gtk.Label()
    label:set_label(rss)
    local image=Gtk.Image()
    -- local path=currentDir().."../icons/sateli3.png"
    image.new_from_resource(img)
    hbox:pack_start(image, false, false, 0)
    hbox:pack_start(label, false, false, 0)
    listLocal:insert(hbox,-1)
    LB:show_all()
end


function Group:AddGroup()
    local group=Gtk.Expander()
    local entry=Gtk.Entry()
    local clicked=false
    entry:set_text("undefined")

    local function updateGroup(text)
        if clicked==true then return end
        clicked=true
        local label=Gtk.Label()
        label:set_label(text) 
        group:set_label_widget(label)
        entry:destroy()
        db:sql("insert into Groups(name) values('"..text.."')")
        LB:show_all()
    end

    function entry:on_activate() updateGroup(self.text) end
    function entry:on_focus_out_event() updateGroup(self.text) end
    function group:on_activate() listRSSSelected=self:get_child() end

    local listLocal=Gtk.ListBox()
    group:set_label_widget(entry)
    group:add(listLocal)
    LB:insert(group,0)
    LB:show_all()
    entry:grab_focus()
end

function Group:DelGroup()
    local count=0
    for _,_ in ipairs(listRSSSelected:get_children()) do
        count=count+1
    end
    if count~=0 then return end
    local focused=LB:get_selected_row()
    local name=focused:get_child():get_label()
    if focused then focused:destroy() end
    db:sql("delete from Groups where name=('"..name.."')")
end


function Group:AddRSS()
    if listRSSSelected==nil then return end
    print("si seleccionado")
    local builder = Gtk.Builder()
    assert(builder:add_from_file('dialogAddRSS.ui'))
    local window = builder.objects.windowRSS
    local buttonCancel=builder:get_object('buttonCancel')
    function buttonCancel:on_clicked()
        window:destroy()
    end

    local buttonOk=builder:get_object('buttonOk')
    function buttonOk:on_clicked()
        local iconPath=os.getenv("HOME")..'/.config/easyPodcasts/icons/'
        local rssName=builder:get_object('name'):get_text()
        local desc=builder:get_object('desc'):get_text()
        local url=builder:get_object('url'):get_text()

        local getPath=function(str,sep)
            sep=sep or'/'
            return str:match("(.*"..sep..")")
        end

        if rssName=="" then builder:get_object('name'):grab_focus() return end
        if url=="" then builder:get_object('url'):grab_focus() return end
        local iconChooser=builder:get_object('iconchooser')
        local currentFilename=iconChooser:get_filename()
        local filename=""

        if currentFilename then
            --get_uri works for last selected also
            local currentPath=getPath(iconChooser:get_uri())
            if currentPath~="file://"..iconPath then
                local cmd="mkdir -p '"..iconPath.."'"
                os.execute(cmd)
                local cmd="cp -v '"..currentFilename.."' '"..iconPath.."'"
                os.execute(cmd)
            end
            if currentFilename then
                filename=iconPath..string.sub(currentFilename,string.len(currentPath)-6) 
            end
        end

        db:sql("insert into rss(name,desc,url,img) values ('"..rssName.."','"..desc.."','"..url.."','"..filename.."')") 
        local res=db:select("select max(id) max from RSS") 
        local idrss=res()
        local groupName=listRSSSelected:get_parent():get_label()
        local res=db:select("select id from Groups where name='"..groupName.."'") 
        local idgroup=res()
        db:sql("insert into RSSGroups(idGroup,idRSS) values ("..idgroup..","..idrss..")") 
        Group:Update(groupName,rssName)
    end
    window:show_all()
end

function Group:DelRSS()
    if listRSSSelected==nil then return end
    if listRSSSelected:get_selected_row()==nil then return end
    local rss=listRSSSelected:get_selected_row():get_child().child[2]:get_text()
    local group=listRSSSelected:get_parent():get_label()
    listRSSSelected:get_selected_row():destroy()
    print("Deleting rss "..rss)
    local res=db:select("select id from RSS where name='"..rss.."'") 
    local idrss=res()
    local group=listRSSSelected:get_parent():get_label()
    local res=db:select("select id from Groups where name='"..group.."'") 
    local idgroup=res()
    db:sql("delete from RSSGroups where idGroup="..idgroup.." and idRSS="..idrss) 
    db:sql("delete from RSS where id="..idrss) 
    LB:show_all()
end

return Group
