-- Sync.lua (Optimized & Anti-Lag)
return {
    Execute = function(msg, client)
        local Vars = _G.BotVars
        Vars.SyncActive = true

        local targetName = msg:match("^!sync%s+(.+)")
        if not targetName then return end

        local found
        for _, plr in ipairs(Vars.Players:GetPlayers()) do
            if plr.DisplayName:lower() == targetName:lower() or plr.Name:lower() == targetName:lower() then
                found = plr
                break
            end
        end

        if not found then
            warn("Target tidak ditemukan:", targetName)
            return
        end

        -- hentikan sync lama
        if Vars.SyncConnection then
            task.cancel(Vars.SyncConnection)
            Vars.SyncConnection = nil
        end

        -- caching references biar gak ulang2 WaitForChild
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local commandHandler = ReplicatedStorage:WaitForChild("Connections")
            :WaitForChild("dataProviders")
            :WaitForChild("commandHandler")

        Vars.SyncConnection = task.spawn(function()
            while Vars.SyncActive and found and found.Parent do
                local success, err = pcall(function()
                    commandHandler:InvokeServer("sync", found.UserId)
                end)

                if not success then
                    warn("[Sync] Error:", err)
                end

                -- gunakan interval lebih aman (1 detik) biar tidak spam
                task.wait(1)
            end
        end)
    end
}
