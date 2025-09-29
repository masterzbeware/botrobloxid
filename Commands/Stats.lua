-- Stats.lua
-- Command !stats untuk menampilkan statistik pemain (VIP bebas cooldown)
-- Bisa cek pemain lain dengan !stats {username}

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")

        vars.StatsCooldowns = vars.StatsCooldowns or {}
        local playerCooldowns = vars.StatsCooldowns
        local currentTime = tick()

        -- Cek apakah sender VIP/Client
        local isSenderVIP = (client.Name == vars.ClientName)

        -- Non-VIP kena cooldown
        if not isSenderVIP then
            local lastUsedPlayer = playerCooldowns[client.UserId] or 0
            if currentTime - lastUsedPlayer < 10 then
                print("[Stats] Tunggu " .. math.ceil(10 - (currentTime - lastUsedPlayer)) .. " detik lagi untuk " .. client.Name)
                return
            end

            vars.StatsGlobalCooldown = vars.StatsGlobalCooldown or 0
            if currentTime - vars.StatsGlobalCooldown < 5 then
                print("[Stats] Tunggu " .. math.ceil(5 - (currentTime - vars.StatsGlobalCooldown)) .. " detik lagi untuk semua pemain")
                return
            end

            playerCooldowns[client.UserId] = currentTime
            vars.StatsGlobalCooldown = currentTime
        end

        -- Ambil target dari command
        local targetName = msg:match("^!stats%s+(%S+)")
        if not targetName then
            targetName = client.Name -- default ke diri sendiri
        end

        -- Cari pemain
        local targetPlayer = Players:FindFirstChild(targetName)
        if not targetPlayer then
            print("[Stats] Player '" .. targetName .. "' tidak ditemukan!")
            return
        end

        -- Cek friends/followers/following via HttpService
        local friendsCount, followersCount, followingCount = 0, 0, 0
        pcall(function()
            local url = "https://friends.roblox.com/v1/users/" .. targetPlayer.UserId .. "/friends"
            local data = HttpService:GetAsync(url)
            local json = HttpService:JSONDecode(data)
            friendsCount = #json.data
        end)

        pcall(function()
            local url = "https://friends.roblox.com/v1/users/" .. targetPlayer.UserId .. "/followers"
            local data = HttpService:GetAsync(url)
            local json = HttpService:JSONDecode(data)
            followersCount = json.count or 0
        end)

        pcall(function()
            local url = "https://friends.roblox.com/v1/users/" .. targetPlayer.UserId .. "/followings"
            local data = HttpService:GetAsync(url)
            local json = HttpService:JSONDecode(data)
            followingCount = json.count or 0
        end)

        -- Join Date (tanggal akun dibuat) menggunakan Roblox API
        local joinDate = "Unknown"
        pcall(function()
            local url = "https://users.roblox.com/v1/users/" .. targetPlayer.UserId
            local response = HttpService:GetAsync(url)
            local data = HttpService:JSONDecode(response)
            if data.created then
                local t = os.date("*t", os.time())
                local year = tonumber(data.created:sub(1,4))
                local month = tonumber(data.created:sub(6,7))
                local day = tonumber(data.created:sub(9,10))
                local hour = tonumber(data.created:sub(12,13))
                local min = tonumber(data.created:sub(15,16))
                local sec = tonumber(data.created:sub(18,19))
                joinDate = os.date("%d %B %Y", os.time({year=year, month=month, day=day, hour=hour, min=min, sec=sec}))
            end
        end)

        -- Kirim message
        local messageText = string.format(
            "📊 Statistik %s:\n- Friends: %d\n- Followers: %d\n- Following: %d\n- Join Date: %s",
            targetPlayer.Name, friendsCount, followersCount, followingCount, joinDate
        )

        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then warn("Channel RBXGeneral tidak ditemukan!") return end

        pcall(function() channel:SendAsync(messageText) end)
        print("[Stats] " .. messageText)
    end
}
