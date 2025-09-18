-- Internationalization support
local S = minetest.get_translator(minetest.get_current_modname())


math.randomseed(os.time())

local MODNAME = "mesecons_remote"
local REMOTE_ITEM = MODNAME..":remote"
local RECEIVER_OFF = MODNAME..":receiver"
local RECEIVER_ON  = MODNAME..":receiver_on"

mesecons_remote = mesecons_remote or {}
mesecons_remote.receivers = mesecons_remote.receivers or {}

local world_meta_file = minetest.get_worldpath().."/mesecons_remote_receivers.data"

-- Helper to normalize input ID
local function normalize_id_field(f)
    if not f or f=="" then return "" end
    local digits = f:match("%d%d%d%d")
    if not digits then return "" end
    return "R"..digits
end

-- Save receivers table to file
local function save_receivers_to_file()
    local data = minetest.serialize(mesecons_remote.receivers)
    local file = io.open(world_meta_file,"w")
    if file then
        file:write(data)
        file:close()
    end
end

-- Load receivers table from file
local function load_receivers_from_file()
    local file = io.open(world_meta_file,"r")
    if file then
        local content = file:read("*a")
        local t = minetest.deserialize(content)
        if type(t)=="table" then
            mesecons_remote.receivers = t
        end
        file:close()
    end
end

-- Set receiver node state (ON/OFF) and update infotext
local function set_receiver_state(pos,is_on)
    if not pos then return end
    local node = minetest.get_node_or_nil(pos)
    if not node then return end
    local meta = minetest.get_meta(pos)
    if is_on then
        if node.name~=RECEIVER_ON then
            minetest.swap_node(pos,{name=RECEIVER_ON})
        end
        meta:set_string("infotext", S(("Receiver ID: %s (ON)"):format(meta:get_string("id"))))
        if mesecon and mesecon.receptor_on then mesecon.receptor_on(pos) end
    else
        if node.name~=RECEIVER_OFF then
            minetest.swap_node(pos,{name=RECEIVER_OFF})
        end
        meta:set_string("infotext", S(("Receiver ID: %s (OFF)"):format(meta:get_string("id"))))
        if mesecon and mesecon.receptor_off then mesecon.receptor_off(pos) end
    end
end

-- Trigger receiver by ID using either button (momentary) or lever (toggle)
local function trigger_receiver_by_id(id,mode)
    local pos_serial = mesecons_remote.receivers[id]
    if not pos_serial then return false end
    local pos = minetest.deserialize(pos_serial)
    if not pos then return false end
    if mode=="button" then
        set_receiver_state(pos,true)
        minetest.after(3,function()
            local n = minetest.get_node_or_nil(pos)
            if n and (n.name==RECEIVER_OFF or n.name==RECEIVER_ON) then
                set_receiver_state(pos,false)
            end
        end)
    elseif mode=="lever" then
        local node = minetest.get_node_or_nil(pos)
        if node then set_receiver_state(pos,node.name==RECEIVER_OFF) end
    end
    return true
end

-- Register receiver nodes (OFF state)
minetest.register_node(RECEIVER_OFF,{
    description=S("Remote Receiver (OFF)"),
    tiles={"receiver_off.png"},
    groups={cracky=2},
    mesecons={receptor={state=mesecon and mesecon.state and mesecon.state.off or 0}},
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local id
        repeat
            id = "R"..string.format("%04d", math.random(0,9999))
        until not mesecons_remote.receivers[id]

        meta:set_string("id", id)
        meta:set_string("infotext", S("Receiver ID: "..id.." (OFF)"))
        mesecons_remote.receivers[id] = minetest.serialize(pos)
        save_receivers_to_file()
    end,
    on_destruct=function(pos)
        local meta = minetest.get_meta(pos)
        local id = meta:get_string("id")
        if id then mesecons_remote.receivers[id] = nil; save_receivers_to_file() end
    end,
    on_rightclick=function(pos,node,clicker,itemstack,pointed_thing)
        if not clicker then return end
        local pname = clicker:get_player_name()
        local wielded = clicker:get_wielded_item()
        local controls = clicker:get_player_control()
        local meta = minetest.get_meta(pos)
        local id = meta:get_string("id")

        if wielded and wielded:get_name()==REMOTE_ITEM then
            local wmeta = wielded:get_meta()
            if controls.sneak then
                wmeta:set_string("id2",id)
                wmeta:set_string("pos2", minetest.serialize(pos))
                clicker:set_wielded_item(wielded)
                minetest.chat_send_player(pname, S(("ID %s saved to right channel."):format(id)))
                return
            end
            local id2 = wmeta:get_string("id2")
            local mode2 = wmeta:get_string("mode2") or "button"
            if id2==id then
                local ok = trigger_receiver_by_id(id2,mode2)
                if ok then
                    minetest.chat_send_player(pname,S(string.format("ID %s, %s (right click)",id2,mode2=="button" and "button" or "lever")))
                else
                    minetest.chat_send_player(pname,S("No receiver found for this ID."))
                end
            else
                minetest.chat_send_player(pname, S(("Remote right channel: %s (this receiver is %s)"):format(id2~="" and id2 or "<not set>",id)))
            end
        else
            minetest.chat_send_player(pname,S("Receiver ID: "..id))
        end
    end,
})

minetest.register_node(RECEIVER_ON,{
    description=S("Remote Receiver (ON)"),
    tiles={"receiver_on.png"},
    groups={cracky=2,not_in_creative_inventory=1},
    drop=RECEIVER_OFF,
    mesecons={receptor={state=mesecon and mesecon.state and mesecon.state.on or 1}},
})

minetest.register_on_mods_loaded(function()
    load_receivers_from_file()
end)

-- Register remote tool
minetest.register_tool(REMOTE_ITEM, {
    description = S("Mesecons Remote"),
    inventory_image = "remote.png",

    on_use = function(itemstack, user, pointed_thing)
        if not user then return itemstack end
        local meta = itemstack:get_meta()
        local controls = user:get_player_control()
        local pname = user:get_player_name()

        local function mode_to_index(mode)
            return (mode == "lever") and 2 or 1
        end

        if controls.aux1 then
            local formspec = "size[8,7]" ..
                             "label[0,0;"..S("Remote Configuration").."]" ..
                             "field[0.5,1;6.5,1;id1;"..S("Left Channel ID")..";" .. minetest.formspec_escape(meta:get_string("id1") or "") .. "]" ..
                             "dropdown[6.8,1;1.2,1;mode1;button,lever;" .. mode_to_index(meta:get_string("mode1") or "button") .. "]" ..
                             "field[0.5,2.5;6.5,1;id2;"..S("Right Channel ID")..";" .. minetest.formspec_escape(meta:get_string("id2") or "") .. "]" ..
                             "dropdown[6.8,2.5;1.2,1;mode2;button,lever;" .. mode_to_index(meta:get_string("mode2") or "button") .. "]" ..
                             "field[0.5,4;6.5,1;id3;"..S("Shift+Left Click ID")..";" .. minetest.formspec_escape(meta:get_string("id3") or "") .. "]" ..
                             "dropdown[6.8,4;1.2,1;mode3;button,lever;" .. mode_to_index(meta:get_string("mode3") or "button") .. "]" ..
                             "field[0.5,5.5;6.5,1;id4;"..S("Shift+Right Click ID")..";" .. minetest.formspec_escape(meta:get_string("id4") or "") .. "]" ..
                             "dropdown[6.8,5.5;1.2,1;mode4;button,lever;" .. mode_to_index(meta:get_string("mode4") or "button") .. "]" ..
                             "button_exit[3,6.5;2,1;save;"..S("Save").."]"
            minetest.show_formspec(pname, MODNAME..":config", formspec)
            return itemstack
        end

        if controls.sneak then
            local id3 = meta:get_string("id3")
            local mode3 = meta:get_string("mode3") or "button"
            if id3 ~= "" then
                local ok = trigger_receiver_by_id(id3, mode3)
                minetest.chat_send_player(pname, ok and string.format("ID %s, %s "..S("(Shift+Left Click)"), id3, mode3=="button" and "button" or "lever")
                    or S("No receiver found for this ID."))
            else
                minetest.chat_send_player(pname,S("Shift+Left Click channel not set."))
            end
            return itemstack
        end

        local id1 = meta:get_string("id1")
        local mode1 = meta:get_string("mode1") or "button"
        if id1 ~= "" then
            local ok = trigger_receiver_by_id(id1, mode1)
            minetest.chat_send_player(pname, ok and string.format("ID %s, %s "..S("(Left Click)"), id1, mode1=="button" and "button" or "lever")
                or S("No receiver found for this ID."))
        else
            minetest.chat_send_player(pname,S("Left Click channel not set."))
        end
        return itemstack
    end,

    on_place = function(itemstack, user, pointed_thing)
        if not user then return itemstack end
        local meta = itemstack:get_meta()
        local controls = user:get_player_control()
        local pname = user:get_player_name()

        local id2 = meta:get_string("id2")
        local mode2 = meta:get_string("mode2") or "button"
        local id4 = meta:get_string("id4")
        local mode4 = meta:get_string("mode4") or "button"

        if controls.sneak then
            if id4 ~= "" then
                local ok = trigger_receiver_by_id(id4, mode4)
                minetest.chat_send_player(pname, ok and string.format("ID %s, %s " .. S("(Shift+Right Click)"), id4, mode4=="button" and "button" or "lever")
                    or S("No receiver found for this ID."))
            else
                minetest.chat_send_player(pname,S("Shift+Right Click channel not set."))
            end
            return itemstack
        end

        if id2 ~= "" then
            local ok = trigger_receiver_by_id(id2, mode2)
            minetest.chat_send_player(pname, ok and string.format("ID %s, %s "..S("(Right Click)"), id2, mode2=="button" and "button" or "lever")
                or S("No receiver found for this ID."))
        else
            minetest.chat_send_player(pname,S("Right Click channel not set."))
        end

        return itemstack
    end,

    on_secondary_use = function(itemstack, user, pointed_thing)
        if not user then return itemstack end
        local meta = itemstack:get_meta()
        local controls = user:get_player_control()
        local pname = user:get_player_name()

        local id2 = meta:get_string("id2")
        local mode2 = meta:get_string("mode2") or "button"
        local id4 = meta:get_string("id4")
        local mode4 = meta:get_string("mode4") or "button"

        if not pointed_thing or pointed_thing.type == "nothing" then
            if controls.sneak then
                if id4 ~= "" then
                    local ok = trigger_receiver_by_id(id4, mode4)
                    minetest.chat_send_player(pname, ok and S(string.format("ID %s, %s (Shift+Right Click)", id4, mode4=="button" and "button" or "lever"))
                        or S("No receiver found for this ID."))
                else
                    minetest.chat_send_player(pname,S("Shift+Right Click channel not set."))
                end
                return itemstack
            end

            if id2 ~= "" then
                local ok = trigger_receiver_by_id(id2, mode2)
                minetest.chat_send_player(pname, ok and S(string.format("ID %s, %s (Right Click)", id2, mode2=="button" and "button" or "lever"))
                    or S("No receiver found for this ID."))
            else
                minetest.chat_send_player(pname,S("Right Click channel not set."))
            end
            return itemstack
        end

        return itemstack
    end,
})

-- Handle formspec submissions
minetest.register_on_player_receive_fields(function(player,formname,fields)
    if formname~=MODNAME..":config" then return end
    local stack = player:get_wielded_item()
    if not stack or stack:get_name()~=REMOTE_ITEM then return end
    local meta = stack:get_meta()
    local pname = player:get_player_name()

    if fields.save then
        for i=1,4 do
            local fid = "id"..i
            local fmode = "mode"..i
            if fields[fid] then meta:set_string(fid,normalize_id_field(fields[fid])) end
            if fields[fmode] then meta:set_string(fmode,fields[fmode]) end
            local id = meta:get_string(fid)
            if id~="" and not mesecons_remote.receivers[id] then
                minetest.chat_send_player(pname,S("Warning: no receiver found for ID "..id))
            end
        end
        player:set_wielded_item(stack)
        minetest.chat_send_player(pname,S("Remote: configuration saved."))
    end
end)

-- Chat command to locate a receiver by ID
minetest.register_chatcommand("receiver", {
    params = "<ID>",
    description = S("Shows position and state of a receiver by ID"),
    func = function(name, param)
        local id = normalize_id_field(param)
        if id == "" then
            return false, S("Please provide a valid ID, e.g., /receiver R0001")
        end

        local pos_serial = mesecons_remote.receivers[id]
        if not pos_serial then
            return false, S("No receiver found for ID " .. id)
        end

        local pos = minetest.deserialize(pos_serial)
        if not pos then
            return false, S("Invalid position for ID " .. id)
        end

        local node = minetest.get_node_or_nil(pos)
        if not node then
            return false, S("Receiver ID " .. id .. " not found in world (node missing)")
        end

        local state = (node.name == RECEIVER_ON) and "ON" or "OFF"
        local msg = S(string.format("Receiver %s : (%d, %d, %d), %s", id, pos.x, pos.y, pos.z, state))
        return true, msg
    end
})

minetest.register_craft({
    output = "mesecons_remote:remote",
    recipe = {
        {"mesecons:wire_00000000_off", "mesecons_torch:mesecon_torch_on", "mesecons:wire_00000000_off"},
        {"mesecons_detector:node_detector_off", "default:steel_ingot", "mesecons_switch:mesecon_switch_off"},
        {"mesecons_luacontroller:luacontroller0000", "mesecons_materials:silicon", "mesecons_luacontroller:luacontroller0000"},
    }
})

minetest.register_craft({
    output = "mesecons_remote:receiver",
    recipe = {
        {"mesecons:wire_00000000_off", "mesecons_torch:mesecon_torch_on", "mesecons:wire_00000000_off"},
        {"mesecons_detector:node_detector_off", "default:steelblock", "mesecons_switch:mesecon_switch_off"},
        {"mesecons:wire_00000000_off", "mesecons_luacontroller:luacontroller0000", "mesecons:wire_00000000_off"},
    }
})
