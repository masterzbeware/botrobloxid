-- Stats.lua
-- Command !stats untuk menampilkan statistik pemain (VIP bebas cooldown)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")

        vars.StatsCooldowns = vars.StatsCooldowns or {}
        local playerCooldowns = vars.StatsCooldowns
        local currentTime = tick()

        -- Cek apakah sender VIP/Client
        local isVIP = (client.Name == vars.ClientName)

        -- Non-VIP kena cooldown
        if not isVIP then
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
            targetName = client.Name -- default ke self
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

        -- Tanggal akun dibuat
        local joinDate = targetPlayer.AccountAge and os.date("%d %b %Y", os.time() - (targetPlayer.AccountAge * 24 * 60 * 60)) or "Unknown"

        -- Kirim message
        local messageText = string.format(
            "📊 Statistik %s:\n- Friends: %d\n- Followers: %d\n- Following: %d\n- Akun dibuat: %s",
            targetPlayer.Name, friendsCount, followersCount, followingCount, joinDate
        )

        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then warn("Channel RBXGeneral tidak ditemukan!") return end

        pcall(function() channel:SendAsync(messageText) end)
        print("[Stats] " .. messageText)
    end
}
