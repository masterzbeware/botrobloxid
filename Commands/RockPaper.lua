local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- Ambil channel RBXGeneral
local channel
if TextChatService.TextChannels then
    channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
end

local function sendChat(msg)
    if channel then
        pcall(function()
            channel:SendAsync(msg)
        end)
    else
        warn("Channel RBXGeneral tidak ditemukan!")
    end
end

-- Listener untuk setiap pemain
local function setupPlayer(player)
    if TextChatService.TextChannels and channel then
        channel.OnIncomingMessage = function(message)
            local senderUserId = message.TextSource and message.TextSource.UserId
            local sender = senderUserId and Players:GetPlayerByUserId(senderUserId)
            if sender and message.Text:lower():match("^!rockpaper") then
                sendChat("Siap laksanakan!")
            end
        end
    else
        -- Fallback jika TextChatService tidak tersedia
        player.Chatted:Connect(function(msg)
            if msg:lower():match("^!rockpaper") then
                sendChat("Siap laksanakan!")
            end
        end)
    end
end

-- Terapkan ke semua pemain yang sudah ada
for _, plr in ipairs(Players:GetPlayers()) do
    setupPlayer(plr)
end

-- Listener untuk pemain baru
Players.PlayerAdded:Connect(setupPlayer)
