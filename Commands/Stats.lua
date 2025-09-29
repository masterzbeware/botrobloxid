-- Stats.lua
-- Command !stats untuk menampilkan UserId, AccountAge, Followers, Following, Join Date
-- Bisa cek pemain lain dengan !stats {username}

return {
    Execute = function(msg, client)
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        local vars = _G.BotVars

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

        local userId = targetPlayer.UserId
        local accountAge = targetPlayer.AccountAge -- dalam hari
        local followersCount, followingCount, joinDate = 0, 0, "Unknown"

        -- Ambil Followers
        pcall(function()
            local url = "https://friends.roproxy.com/v1/users/" .. userId .. "/followers/count"
            local response = HttpService:GetAsync(url)
            local data = HttpService:JSONDecode(response)
            followersCount = data.count or 0
        end)

        -- Ambil Following
        pcall(function()
            local url = "https://friends.roproxy.com/v1/users/" .. userId .. "/followings/count"
            local response = HttpService:GetAsync(url)
            local data = HttpService:JSONDecode(response)
            followingCount = data.count or 0
        end)

        -- Ambil Join Date (Account Creation) via API Roblox
        pcall(function()
            local url = "https://users.roblox.com/v1/users/" .. userId
            local response = HttpService:GetAsync(url)
            local data = HttpService:JSONDecode(response)
            if data and data.created then
                local year, month, day = data.created:match("^(%d+)%-(%d+)%-(%d+)")
                if year and month and day then
                    joinDate = day .. "/" .. month .. "/" .. year
                end
            end
        end)

        -- Buat message
        local messageText = string.format(
            "📊 Statistik %s:\n- User ID: %d\n- Account Age (days): %d\n- Followers: %d\n- Following: %d\n- Join Date: %s",
            targetPlayer.Name, userId, accountAge, followersCount, followingCount, joinDate
        )

        -- Kirim chat
        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then warn("Channel RBXGeneral tidak ditemukan!") return end

        pcall(function() channel:SendAsync(messageText) end)
        print("[Stats] " .. messageText)
    end
}
