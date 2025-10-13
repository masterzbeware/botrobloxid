-- JoinServer.lua
-- Command: !joinserver <displayname/username>
-- Bot akan mencari server tempat pemain target berada dan teleport ke sana.

return {
    Execute = function(msg, client)
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")

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

        -- Cari di server saat ini dulu
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Name:lower() == targetName:lower() or plr.DisplayName:lower() == targetName:lower() then
                if game.JobId == plr.JobId then
                    print("[JoinServer] Sudah di server yang sama dengan " .. plr.Name)
                    return
                else
                    print("[JoinServer] Target ditemukan di server berbeda. Teleporting...")
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, plr.JobId, player)
                    return
                end
            end
        end

        -- Fungsi request universal (termasuk Delta)
        local function universalRequest(url)
            local req = nil

            if typeof(request) == "function" then
                req = request -- ✅ Delta mendukung fungsi 'request'
            elseif syn and syn.request then
                req = syn.request
            elseif http_request then
                req = http_request
            elseif fluxus and fluxus.request then
                req = fluxus.request
            end

            if req then
                local success, response = pcall(function()
                    return req({
                        Url = url,
                        Method = "GET"
                    })
                end)
                if success and response and response.Body then
                    return response.Body
                end
            end

            -- Fallback (tidak direkomendasikan untuk Delta)
            local success, body = pcall(function()
                return HttpService:GetAsync(url)
            end)
            if success then
                return body
            else
                warn("[JoinServer] Request gagal: " .. tostring(body))
                return nil
            end
        end

        -- Ambil daftar server publik Roblox
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local rawData = universalRequest(url)

        if not rawData then
            warn("[JoinServer] Tidak bisa mengambil daftar server publik.")
            return
        end

        local success, data = pcall(function()
            return HttpService:JSONDecode(rawData)
        end)
        if not success or not data or not data.data then
            warn("[JoinServer] Gagal decode response.")
            return
        end

        -- Cari server yang mengandung player target
        local targetJobId = nil
        for _, server in ipairs(data.data) do
            if server.playing > 0 and server.playerIds then
                for _, id in ipairs(server.playerIds) do
                    local ok, name = pcall(function()
                        return Players:GetNameFromUserIdAsync(id)
                    end)
                    if ok and name:lower() == targetName:lower() then
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

        print("[JoinServer] Server ditemukan! Teleporting ke JobId:", targetJobId)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, targetJobId, player)
    end
}
