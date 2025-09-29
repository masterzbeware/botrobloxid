-- Stop.lua
-- Command !stop: Menghentikan semua aksi bot (follow, shield, row, sync, topdown)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        -- Nonaktifkan semua formasi / follow / sync / topdown
        vars.FollowAllowed = false
        vars.ShieldActive = false
        vars.RowActive = false
        vars.TopdownActive = false   -- Tambahkan ini untuk menghentikan Topdown
        vars.CurrentFormasiTarget = nil
        vars.SyncActive = false      -- Tambahkan ini untuk menghentikan sync

        -- Putuskan koneksi Heartbeat kalau ada
        if vars.FollowConnection then
            vars.FollowConnection:Disconnect()
            vars.FollowConnection = nil
        end
        if vars.ShieldConnection then
            vars.ShieldConnection:Disconnect()
            vars.ShieldConnection = nil
        end
        if vars.RowConnection then
            vars.RowConnection:Disconnect()
            vars.RowConnection = nil
        end
        if vars.TopdownConnection then
            vars.TopdownConnection:Disconnect()
            vars.TopdownConnection = nil
        end

        -- Notifikasi menggunakan Library Obsidian
        local success, Library = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        end)

        if success and Library then
            Library:Notify("Bot stopped all actions (including Topdown & sync)", 3)
        else
            warn("[Stop.lua] Gagal load Library.lua untuk notifikasi")
        end

        print("[COMMAND] Bot stopped by client:", client and client.Name or "Unknown")
    end
}
