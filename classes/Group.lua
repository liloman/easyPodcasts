local Class=require("classes.Class")
Group=Class("Group")

--Private variable
local listRSSSelectedRow=nil
local LB=builder:get_object('listboxRSS')
local selectedFirst=false

function Group:initialize(name)
    self.name=name
    self:UpdateAll()
end


function Group:UpdateAll()
    for _,child in ipairs(LB:get_children()) do child:destroy() end
    for group in db:select("SELECT name from Groups") do
        self:Update(group,'')
    end
end

function Group:Update(groupName,rss)
    local found=false
    local listLocal=nil
    for _,child in ipairs(LB:get_children()) do
        if child:get_child():get_label()  == groupName then found=true end
    end
    --Create the group (GtkExpander)
    if not found then 
        print("not found")
        listLocal=Gtk.ListBox()
        group=Gtk.Expander()
        group:set_label(groupName)
        group:set_expanded(true)
        group:set_margin_left(5)
        group:set_margin_right(5)
        group:set_margin_top(5)
        group:set_margin_bottom(5)
        group:add(listLocal)
        listRSSSelectedRow=listLocal

        function group:on_activate() 
            print("activate"..self:get_label()) 
            listRSSSelectedRow=self:get_child() 
        end

        function listLocal:on_row_activated() 
            local id=string.sub(self:get_selected_row():get_child():get_name(),string.len("idrss_")+1)
            podcast:ShowSelectedRSS(id)
            listRSSSelectedRow=self 
        end
        LB:insert(group,-1)
    end
    --Create its RSS
    for rss,id in db:select("SELECT rss,id from listRSSGroups where groupName='"..groupName.."'") do
        self:AddRSSToLB(rss,id)
    end
    if not selectedFirst then 
        LB:select_row(listRSSSelectedRow:get_children()[1])
        selectedFirst=true
    end
end

function Group:AddRSSToLB(rss,id)
    print("adding "..rss)
    local hbox=Gtk.HBox()
    hbox:set_name("idrss_"..id)
    local label=Gtk.Label()
    label:set_label(id)
    hbox:pack_start(label, false, false, 0)
    local label=Gtk.Label()
    label:set_label(rss)
    hbox:pack_end(label, false, false, 0)
    listRSSSelectedRow:insert(hbox,-1)
    LB:show_all()
end


function Group:AddGroup()
    local group=Gtk.Expander()
    local entry=Gtk.Entry()
    local clicked=false
    local listLocal=nil
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
    function group:on_activate() print("activate"..self:get_label()) listRSSSelectedRow=self:get_child() end
    listLocal=Gtk.ListBox()
    group:set_label_widget(entry)
    group:add(listLocal)
    listRSSSelectedRow=listLocal
    LB:insert(group,0)
    LB:show_all()
    entry:grab_focus()
end

function Group:DelGroup()
    if listRSSSelectedRow==nil then return end
    local count=0
    for _,_ in ipairs(listRSSSelectedRow:get_children()) do
        count=count+1
    end
    if count~=0 then return end
    local focused=LB:get_selected_row()
    local name=focused:get_child():get_label()
    if focused then focused:destroy() end
    db:sql("delete from Groups where name=('"..name.."')")
end


function Group:AddRSS()
    if listRSSSelectedRow==nil then return end
    local builder = Gtk.Builder()
    assert(builder:add_from_file((abDir..'ui/dialogAddRSS.ui')))
    local window = builder.objects.windowRSS
    local buttonCancel=builder:get_object('buttonCancel')
    function buttonCancel:on_clicked()
        window:destroy()
    end

    local buttonOk=builder:get_object('buttonOk')
    function buttonOk:on_clicked()
        local rssName=builder:get_object('name'):get_text()
        local url=builder:get_object('url'):get_text()
        if rssName=="" then builder:get_object('name'):grab_focus() return end
        if url=="" then builder:get_object('url'):grab_focus() return end

        db:sql("insert into rss(name,url) values ('"..rssName.."','"..url.."')") 
        local res=db:select("select max(id) max from RSS") 
        local idrss=res()
        local groupName=listRSSSelectedRow:get_parent():get_label()
        local res=db:select("select id from Groups where name='"..groupName.."'") 
        local idgroup=res()
        db:sql("insert into RSSGroups(idGroup,idRSS) values ("..idgroup..","..idrss..")") 
        Group:AddRSSToLB(rssName,idrss)
        local path=audioPath..idrss.."/"
        os.execute("mkdir -p  "..path)
        podcast:SetSelected(idrss)
    end
    window:show_all()
end

function Group:DelRSS()
    if listRSSSelectedRow==nil then return end
    if listRSSSelectedRow:get_selected_row()==nil then return end
    local rss=listRSSSelectedRow:get_selected_row():get_child().child[2]:get_text()
    local group=listRSSSelectedRow:get_parent():get_label()
    listRSSSelectedRow:get_selected_row():destroy()
    print("Deleting rss "..rss)
    local res=db:select("select id from RSS where name='"..rss.."'") 
    local idrss=res()
    local group=listRSSSelectedRow:get_parent():get_label()
    local res=db:select("select id from Groups where name='"..group.."'") 
    local idgroup=res()
    db:sql("delete from RSS where id="..idrss) 
    db:sql("delete from Podcasts where idRSS="..idrss) 
    db:sql("delete from RSSGroups where idGroup="..idgroup.." and idRSS="..idrss) 
    --Delete downloaded?
    os.execute("rm -rf '"..audioPath..idrss.."'")
    LB:show_all()
end



return Group
