-- Simple RockPaper Chat Response
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer

-- Ambil channel RBXGeneral
local channel
if TextChatService.TextChannels then
    channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
end

-- Fungsi kirim chat
local function sendChat(msg)
    if channel then
        pcall(function()
            channel:SendAsync(msg)
        end)
    else
        warn("Channel RBXGeneral tidak ditemukan!")
    end
end

-- Listen chat LocalPlayer
LocalPlayer.Chatted:Connect(function(msg)
    if msg:lower():match("^!rockpaper") then
        sendChat("Siap laksanakan!")
    end
end)

-- Listen chat dari semua pemain (opsional, jika ingin semua pemain bisa trigger)
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        if player == LocalPlayer and msg:lower():match("^!rockpaper") then
            sendChat("Siap laksanakan!")
        end
    end)
end)
