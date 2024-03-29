--[[
Gobals we manage: 
    [Guild_Roster, Guild_Bank]
--]]

local function getCanonicalPlayerName(name_hyphen_realm, realm) 
    return string.sub(name_hyphen_realm, 0, -(string.len(realm) + 2))
end

local function getInventories(inventory, first_bag, end_bag) 
    if inventory == nil then
        inventory = {}
    end
    if not first_bag == nil then
        first_bag = 0
    end
    if not end_bag == nil then
        end_bag = 4
    end 
    for bag=first_bag, end_bag do
        for slot=0, GetContainerNumSlots(bag) do
            local _, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
            if link then
                local name,
                    _, --item_link,
                    rarity,
                    _, --ilvl,
                    _, --imin_lvl,
                    itype,
                    _, --isub_type,
                    stack_count,
                    equip_location,
                    _, --icon,
                    sell_price,
                    _, --class_id,
                    sub_class_id = GetItemInfo(link);
                if name ~= nil then
                    if inventory[name] ~= nil then
                        inventory[name]['count'] = inventory[name]['count'] + count;
                    else
                        inventory[name] = {
                            item_rarity = rarity
                            ,item_type = itype
                            ,count = count
                            ,stack_count = stack_count
                            ,equip_location = equip_location
                            ,sell_price = sell_price
                        }
                    end
                end
            end
        end
    end
    return inventory;
end

local function getGuildRoster(guild_roster) 
    local realm = GetRealmName();
    local guild_name, _, _, _ = GetGuildInfo("player")
    local current_timestamp = date("%Y-%m-%d %H:%M:%S");

    -- Default some things for security.
    if not guild_roster then 
        guild_roster = {}
    end
    if not guild_roster[realm] then
        guild_roster[realm] = {}
    end

    if not guild_roster[realm][guild_name] then
        guild_roster[realm][guild_name] = {}
    end

    for index=0, GetNumGuildMembers() do 
        local name,
        rank,
        rank_index,
        level,
        class,
        zone,
        note = GetGuildRosterInfo(index);
        if name ~= nil then
            name = getCanonicalPlayerName(name, realm)
            
            if guild_roster[realm][guild_name][name] == nil then
                guild_roster[realm][guild_name][name] = {}
            end
            local init = guild_roster[realm][guild_name][name].created == nil;


            guild_roster[realm][guild_name][name] = {
                name = name,
                index = index,
                rank = rank_index,
                level = level,
                class = class,
                note = note,
                created = init and current_timestamp or guild_roster[realm][guild_name][name].created,
                updated = current_timestamp,
                removed = nil
            }

            -- Log New Players
            if init then
                print(name, 'has joined the guild since last checked.')
            end
        end

    end

    -- Some find players that left.
    for player_name,player_data in pairs(guild_roster[realm][guild_name]) do
        if not player_data.removed and player_data.updated ~= current_timestamp then
            print(player_name, 'has left the guild since last checked.')
            guild_roster[realm][guild_name][player_name].removed = true
        end
    end
    return guild_roster
end

local function eventHandler(self, event, isInitialLogin, isReloadingUI) 
    if event == 'PLAYER_ENTERING_WORLD' then 
        Guild_Bank = getInventories({}, 0, 1);
        if not isInitialLogin then 
            Guild_Roster = getGuildRoster(Guild_Roster);
        end 

        if isInitialLogin or isReloadingUI then
        else -- When Zoning....
        end
    end
end

local GuildUtilities = CreateFrame('Frame', nil, UIParent);
GuildUtilities:RegisterEvent('PLAYER_ENTERING_WORLD');
GuildUtilities:SetScript('OnEvent', eventHandler);


hooksecurefunc(GameTooltip, "Show", function(self, one, two, three)
    --Getting started:
    -- https://authors.curseforge.com/forums/world-of-warcraft/general-chat/lua-code-discussion/225832-how-to-edit-a-certain-tooltip-where-do-i-begin
    if _G["GameTooltipTextLeft1"]:GetText() ~= 'Guild Member Options' then
        return -- Not the tooltip we want.
    end

    if GameTooltip:NumLines() > 2 then
        return -- We've already edited. Do not double tap.
    end


    local cursor = GetMouseFocus();

    local realm = GetRealmName();
    local guild_name, _, _, _ = GetGuildInfo("player")
    local name = getCanonicalPlayerName(GetGuildRosterInfo(cursor.guildIndex), realm)

    local function getCanonicalLastOnline(years, months, days, hours)
        if years == nil then
            return 'Now'
        end
        return hours .. ' H, ' 
            .. (days > 0 and days .. ' D, ' or '')
            .. (months > 0 and months .. ' M, ' or '') 
            .. (years > 0 and years .. ' Y, ' or '') 
    end

    GameTooltip:AddLine(name)
    GameTooltip:AddLine('Member since: '..Guild_Roster[realm][guild_name][name].created)
    GameTooltip:AddLine('Last seen on: '..
        getCanonicalLastOnline(GetGuildRosterLastOnline(cursor.guildIndex))
    )
    --[[
    for key,value in pairs() do
        print(key,value)
    end
    print(GetMouseFocus().userdata)
    ]]
end)
