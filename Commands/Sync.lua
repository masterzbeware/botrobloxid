-- Sync.lua (versi fix, pakai commandHandler dari RemoteSpy)
return {
    Execute = function(msg, client)
        local Vars = _G.BotVars
        Vars.SyncActive = true

        -- ambil target dari pesan chat (misalnya: !sync namaPlayer)
        local targetName = msg:match("^!sync%s+(.+)")
        if not targetName then return end

        local found = nil
        for _, plr in ipairs(Vars.Players:GetPlayers()) do
            if plr.DisplayName:lower() == targetName:lower() or plr.Name:lower() == targetName:lower() then
                found = plr
                break
            end
        end

        if found then
            -- stop sync lama kalau masih jalan
            if Vars.SyncConnection then
                task.cancel(Vars.SyncConnection)
                Vars.SyncConnection = nil
            end

            -- buat loop sync baru via commandHandler
            Vars.SyncConnection = task.spawn(function()
                while Vars.SyncActive do
                    local success, err = pcall(function()
                        local args = { "sync", found.UserId }
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Connections")
                            :WaitForChild("dataProviders")
                            :WaitForChild("commandHandler")
                            :InvokeServer(unpack(args))
                    end)
                    if not success then
                        warn("Sync error:", err)
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
}
