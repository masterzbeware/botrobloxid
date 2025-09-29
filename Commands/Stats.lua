-- Stats.lua
-- Command !stats untuk menampilkan UserId, AccountAge, Followers, Following, Join Date
-- Bisa cek pemain lain dengan !stats {username}
-- Menggunakan SystemMessage agar UserID tidak menjadi ####
-- Join Date menggunakan API RoProxy

return {
    Execute = function(msg, client)
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        local vars = _G.BotVars
        local StarterGui = game:GetService("StarterGui")

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

        -- Ambil Join Date via RoProxy
        pcall(function()
            local url = "https://users.roproxy.com/v1/users/" .. userId
            local response = HttpService:GetAsync(url)
            local data = HttpService:JSONDecode(response)
            if data and data.created then
                -- Format tanggal: YYYY-MM-DDTHH:MM:SS.000Z
                local year, month, day = data.created:match("^(%d+)%-(%d+)%-(%d+)")
                if year and month and day then
                    joinDate = day .. "/" .. month .. "/" .. year
                end
            end
        end)

        -- Buat message
        local messageText = string.format(
            "📊 Statistik %s:\n- User ID: %s\n- Account Age (days): %d\n- Followers: %d\n- Following: %d\n- Join Date: %s",
            targetPlayer.Name, tostring(userId), accountAge, followersCount, followingCount, joinDate
        )

        -- Kirim chat sebagai SystemMessage agar UserID tidak menjadi ####
        pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = messageText,
                Color = Color3.fromRGB(0, 255, 128),
                Font = Enum.Font.SourceSansBold,
                FontSize = Enum.FontSize.Size18
            })
        end)

        print("[Stats] " .. messageText)
    end
}
