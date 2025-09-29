-- Stop.lua
-- Command !stop: Menghentikan semua aksi bot (follow, shield, row)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        -- Nonaktifkan semua formasi / follow
        vars.FollowAllowed = false
        vars.ShieldActive = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = nil

        -- Putuskan koneksi Heartbeat kalau ada
        if vars.FollowConnection then
            vars.FollowConnection:Disconnect()
            vars.FollowConnection = nil
        end

        -- Notifikasi menggunakan Library Obsidian
        local success, Library = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        end)

        if success and Library then
            Library:Notify("Bot stopped all actions", 3)
        else
            warn("[Stop.lua] Gagal load Library.lua untuk notifikasi")
        end

        print("[COMMAND] Bot stopped by client:", client and client.Name or "Unknown")
    end
}
