-- Stop.lua
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

        local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        Library:Notify("Bot stopped all actions", 3)

        print("[COMMAND] Bot stopped by client:", client and client.Name or "Unknown")
    end
}
