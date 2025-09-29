-- Stop.lua
-- Command !stop: Menghentikan semua aksi bot (follow, shield, row, sync, pushup)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}

        -- Nonaktifkan semua mode
        vars.FollowAllowed = false
        vars.ShieldActive = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = nil
        vars.SyncActive = false
        vars.PushupActive = false  -- hentikan pushup

        -- Putuskan semua koneksi Heartbeat / loop kalau ada
        if vars.FollowConnection then pcall(function() vars.FollowConnection:Disconnect() end) vars.FollowConnection = nil end
        if vars.ShieldConnection then pcall(function() vars.ShieldConnection:Disconnect() end) vars.ShieldConnection = nil end
        if vars.RowConnection then pcall(function() vars.RowConnection:Disconnect() end) vars.RowConnection = nil end
        if vars.PushupConnection then pcall(function() task.cancel(vars.PushupConnection) end) vars.PushupConnection = nil end

        -- 🔹 Stop animasi push-up kalau masih jalan
        pcall(function()
            local args = { "stopAnimation", "Push Up" }
            game:GetService("ReplicatedStorage")
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("animationHandler")
                :InvokeServer(unpack(args))
        end)

        print("[COMMAND] Bot stopped by client:", client and client.Name or "Unknown")
    end
}
