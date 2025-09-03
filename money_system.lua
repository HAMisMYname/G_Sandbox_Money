-- G_Sandbox_Money - Simple Money System by HAM (updated)
if SERVER then
    local moneyDataFolder = "g_sandbox_money"

    -- Ensure the data folder exists
    if not file.Exists(moneyDataFolder, "DATA") then
        file.CreateDir(moneyDataFolder)
    end

    -- Save a player's money
    local function SavePlayerMoney(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        local steamID = ply:SteamID64() or ply:SteamID()
        local filePath = moneyDataFolder .. "/" .. steamID .. ".txt"
        local data = util.TableToJSON({money = ply:GetNWInt("GSM_Money", 0)}, true)
        file.Write(filePath, data)
    end

    -- Load a player's money
    local function LoadPlayerMoney(ply)
        local steamID = ply:SteamID64() or ply:SteamID()
        local filePath = moneyDataFolder .. "/" .. steamID .. ".txt"

        if file.Exists(filePath, "DATA") then
            local fileContent = file.Read(filePath, "DATA")
            local data = util.JSONToTable(fileContent) or {}
            return data.money or 0
        end

        return 0
    end

    -- Define g_sandbox_money table
    g_sandbox_money = {}

    function g_sandbox_money:PlayerCanAfford(ply, amount)
        local currentMoney = ply:GetNWInt("GSM_Money", 0)
        return currentMoney >= amount
    end

    function g_sandbox_money:RemoveMoney(ply, amount)
        local currentMoney = ply:GetNWInt("GSM_Money", 0)
        local newAmount = math.max(0, currentMoney - amount)
        ply:SetNWInt("GSM_Money", newAmount)
        SavePlayerMoney(ply)
    end

    function g_sandbox_money:AddMoney(ply, amount)
        local currentMoney = ply:GetNWInt("GSM_Money", 0)
        local newAmount = currentMoney + amount
        ply:SetNWInt("GSM_Money", newAmount)
        SavePlayerMoney(ply)
    end

    -- Initialize player money
    local defaultMoney = 1000
    hook.Add("PlayerInitialSpawn", "GSM_InitPlayerMoney", function(ply)
        local money = LoadPlayerMoney(ply)

        -- If new player (no save data), give default money
        if money == 0 then
            money = defaultMoney
        end

        ply:SetNWInt("GSM_Money", money)
    end)

    -- Save money when player leaves
    hook.Add("PlayerDisconnected", "GSM_SavePlayerMoney", function(ply)
        SavePlayerMoney(ply)
    end)

    -- Autosave all players' money every 60 seconds
    timer.Create("GSM_AutoSave", 60, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:IsPlayer() then
                SavePlayerMoney(ply)
            end
        end
    end)

    -- Helper function to find player by partial name
    local function FindPlayerByName(name)
        name = string.lower(name)
        for _, target in ipairs(player.GetAll()) do
            if string.find(string.lower(target:Nick()), name, 1, true) then
                return target
            end
        end
        return nil
    end

    -- Add money to a player
    concommand.Add("gsm_add_money", function(ply, cmd, args)
        if not ply:IsAdmin() then
            ply:ChatPrint("You do not have permission to use this command.")
            return
        end

        if not args[1] or not args[2] then
            ply:ChatPrint("Usage: gsm_add_money <playername> <amount>")
            return
        end

        local target = FindPlayerByName(args[1])
        local amount = tonumber(args[2])

        if not target then
            ply:ChatPrint("No player found with that name.")
            return
        end
        if not amount or amount <= 0 then
            ply:ChatPrint("Invalid amount.")
            return
        end

        g_sandbox_money:AddMoney(target, amount)
        ply:ChatPrint("Added $" .. amount .. " to " .. target:Nick())
        target:ChatPrint("You have been given $" .. amount .. " by an admin.")
    end)

    -- Remove money from a player
    concommand.Add("gsm_remove_money", function(ply, cmd, args)
        if not ply:IsAdmin() then
            ply:ChatPrint("You do not have permission to use this command.")
            return
        end

        if not args[1] or not args[2] then
            ply:ChatPrint("Usage: gsm_remove_money <playername> <amount>")
            return
        end

        local target = FindPlayerByName(args[1])
        local amount = tonumber(args[2])

        if not target then
            ply:ChatPrint("No player found with that name.")
            return
        end
        if not amount or amount <= 0 then
            ply:ChatPrint("Invalid amount.")
            return
        end

        g_sandbox_money:RemoveMoney(target, amount)
        ply:ChatPrint("Removed $" .. amount .. " from " .. target:Nick())
        target:ChatPrint("An admin removed $" .. amount .. " from your account.")
    end)

    -- Check a player's money
    concommand.Add("gsm_check_money", function(ply, cmd, args)
        if not ply:IsAdmin() then
            ply:ChatPrint("You do not have permission to use this command.")
            return
        end

        if not args[1] then
            ply:ChatPrint("Usage: gsm_check_money <playername>")
            return
        end

        local target = FindPlayerByName(args[1])
        if not target then
            ply:ChatPrint("No player found with that name.")
            return
        end

        local money = target:GetNWInt("GSM_Money", 0)
        ply:ChatPrint(target:Nick() .. " has $" .. money)
    end)
end

if CLIENT then
    -- Display player money on screen
    hook.Add("HUDPaint", "GSM_DrawPlayerMoney", function()
        local money = LocalPlayer():GetNWInt("GSM_Money", 0)
        draw.SimpleText("Money: $" .. money, "Trebuchet24", 100, 100, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end)
end
