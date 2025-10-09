return {
    Execute = function(msg, client)
        _G.BotVars = _G.BotVars or {
            Players = game:GetService("Players"),
            CommandFiles = {},
            ActiveClient = "FiestaGuardVip"
        }

        local vars = _G.BotVars
        local Players = vars.Players
        local commandFiles = vars.CommandFiles
        local mainClientName = "FiestaGuardVip"
        local activeClient = vars.ActiveClient or mainClientName

        local clientCommand = msg:lower():match("^!client%s+")
        if clientCommand then
            local targetName = msg:match("^!client%s+(.+)%s*$")

            if client.Name:lower() == mainClientName:lower() and targetName then
                local targetPlayer = nil
                local lowerTarget = targetName:lower()

                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.DisplayName:lower() == lowerTarget or plr.Name:lower() == lowerTarget then
                        targetPlayer = plr
                        break
                    end
                end

                if targetPlayer then
                    vars.ActiveClient = targetPlayer.Name
                    print("Client aktif sekarang: " .. targetPlayer.Name)
                else
                    print("Player '" .. targetName .. "' tidak ditemukan.")
                end
            else
                if client.Name:lower() ~= mainClientName:lower() then
                    print("Hanya main client (" .. mainClientName .. ") yang bisa mengganti client aktif.")
                end
            end
            return
        end

        if client.Name:lower() == (vars.ActiveClient or ""):lower() then
            local lowerMsg = msg:lower()
            for name, cmd in pairs(commandFiles) do
                if lowerMsg:match("^!" .. name) and cmd.Execute then
                    local success, err = pcall(function()
                        cmd.Execute(msg, client)
                    end)
                    if not success then
                        warn("Gagal menjalankan command '" .. name .. "': " .. tostring(err))
                    end
                end
            end
        end
    end
}
