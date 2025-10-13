-- JoinServer.lua (Auto-detect & fix for Roblox environments)
-- Command: !joinserver <displayname/username>
-- Bot akan mencari server tempat pemain target berada dan teleport ke sana.

return {
    Execute = function(msg, client)
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        local vars = _G.BotVars or {}
        local player = vars.LocalPlayer

        if not player then
            warn("[JoinServer] LocalPlayer tidak ditemukan!")
            return
        end

        local targetName = msg:match("^!joinserver%s+(.+)")
        if not targetName then
            warn("[JoinServer] Format salah. Gunakan: !joinserver <nama>")
            return
        end

        print("[JoinServer] Mencari pemain '" .. targetName .. "' ...")

        -- Coba cari di server saat ini
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Name:lower() == targetName:lower() or plr.DisplayName:lower() == targetName:lower() then
                if game.JobId == plr.JobId then
                    print("[JoinServer] Sudah di server yang sama dengan " .. plr.Name)
                    return
                else
                    print("[JoinServer] Target ditemukan di server berbeda, teleport...")
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, plr.JobId, player)
                    return
                end
            end
        end

        -- Jika target tidak ditemukan di server ini, kita cari di daftar server publik Roblox
        local function makeRequest(url)
            local requestFunc = syn and syn.request or http_request or request
            if requestFunc then
                return requestFunc({
                    Url = url,
                    Method = "GET"
                })
            else
                local HttpService = game:GetService("HttpService")
                return { Body = HttpService:GetAsync(url) }
            end
        end

        local placeId = game.PlaceId
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
        local response

        local success, err = pcall(function()
            response = makeRequest(url)
        end)

        if not success or not response or not response.Body then
            warn("[JoinServer] Gagal mengambil daftar server Roblox: " .. tostring(err))
            return
        end

        local HttpService = game:GetService("HttpService")
        local data = HttpService:JSONDecode(response.Body)

        if not data or not data.data then
            warn("[JoinServer] Response server kosong.")
            return
        end

        -- Cari server yang berisi nama target
        local targetJobId
        for _, server in ipairs(data.data) do
            if server.playing > 0 and server.playerIds then
                for _, id in ipairs(server.playerIds) do
                    local success2, username = pcall(function()
                        return Players:GetNameFromUserIdAsync(id)
                    end)
                    if success2 and username and username:lower() == targetName:lower() then
                        targetJobId = server.id
                        break
                    end
                end
            end
            if targetJobId then break end
        end

        if not targetJobId then
            warn("[JoinServer] Tidak dapat menemukan pemain atau JobId target.")
            return
        end

        print("[JoinServer] Server ditemukan! Teleporting ke JobId: " .. targetJobId)
        local ok, err2 = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, targetJobId, player)
        end)
        if not ok then
            warn("[JoinServer] Gagal teleport: " .. tostring(err2))
        end
    end
}
