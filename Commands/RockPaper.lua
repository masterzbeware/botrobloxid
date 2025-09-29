local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

-- Cari channel RBXGeneral
local channel
if TextChatService.TextChannels then
    channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
end

if not channel then
    warn("Channel RBXGeneral tidak ditemukan!")
end

-- Fungsi untuk mengirim pesan ke channel
local function sendMessage(msg)
    if channel then
        pcall(function()
            channel:SendAsync(msg)
        end)
    end
end

-- Listener chat untuk semua pemain
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        if msg:lower():match("^!rockpaper") then
            sendMessage("Siap laksanakan testing")
        end
    end)
end)

-- Listener untuk pemain yang sudah ada saat script dijalankan
for _, player in ipairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(msg)
        if msg:lower():match("^!rockpaper") then
            sendMessage("Siap laksanakan testing")
        end
    end)
end
