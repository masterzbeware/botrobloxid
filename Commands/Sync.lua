-- Sync.lua
-- Command !sync: Bot melakukan sinkronisasi posisi/aksi ke target
-- Optimized & Anti-Lag, menggunakan task.spawn dan interval aman

return {
    Execute = function(msg, client)
        local Vars = _G.BotVars
        Vars.SyncActive = true

        -- 🔹 Tentukan target (default = client)
        local targetName = msg:match("^!sync%s+(.+)")
        local target = client

        if targetName then
            local found
            for _, plr in ipairs(Vars.Players:GetPlayers()) do
                if plr.DisplayName:lower() == targetName:lower() or plr.Name:lower() == targetName:lower() then
                    found = plr
                    break
                end
            end

            if not found then
                warn("[Sync] Target tidak ditemukan:", targetName)
                return
            end

            target = found
        end

        -- 🔹 Hentikan koneksi Sync lama jika ada
        if Vars.SyncConnection then
            pcall(function()
                task.cancel(Vars.SyncConnection)
            end)
            Vars.SyncConnection = nil
        end

        -- 🔹 Cache references untuk efisiensi
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local commandHandler = ReplicatedStorage:WaitForChild("Connections")
            :WaitForChild("dataProviders")
            :WaitForChild("commandHandler")

        -- 🔹 Heartbeat sync loop
        Vars.SyncConnection = task.spawn(function()
            while Vars.SyncActive and target and target.Parent do
                local success, err = pcall(function()
                    commandHandler:InvokeServer("sync", target.UserId)
                end)

                if not success then
                    warn("[Sync] Error:", err)
                end

                -- interval aman 1.5 detik untuk anti-lag
                task.wait(1.5)
            end
        end)

        print("[Sync] Sinkronisasi aktif ke target:", target.Name)
    end
}
