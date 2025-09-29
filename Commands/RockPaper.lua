local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local channel

if TextChatService.TextChannels then
    channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
end

-- Fungsi untuk memilih secara random
local function randomChoice()
    local choices = {"Batu", "Kertas", "Gunting"}
    return choices[math.random(1, #choices)]
end

-- Listener chat
if channel then
    channel.OnIncomingMessage = function(message)
        local senderUserId = message.TextSource and message.TextSource.UserId
        local sender = senderUserId and Players:GetPlayerByUserId(senderUserId)
        if sender and message.Text:lower():match("^!rockpaper") then
            local playerChoice = randomChoice()
            local botChoice = randomChoice()
            
            local resultText = string.format(
                "%s memilih %s, Saya memilih %s",
                sender.Name,
                playerChoice,
                botChoice
            )
            
            pcall(function()
                channel:SendAsync(resultText)
            end)
        end
    end
else
    warn("Channel RBXGeneral tidak ditemukan!")
end

-- Kirim pesan awal
if channel then
    pcall(function()
        channel:SendAsync("Siap laksanakan!")
    end)
end
