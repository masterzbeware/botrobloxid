-- RockPaper.lua (dengan debugging lengkap)
local vars = _G.BotVars
local Players = vars.Players
local TextChatService = vars.TextChatService
local localPlayer = vars.LocalPlayer

-- Mapping mode ke UserId bot
local botModes = {
    mode1 = "8802945328",
    mode2 = "8802949363",
    mode3 = "8802939883",
    mode4 = "8802998147",
}

-- Pilihan RPS
local choices = {"batu", "gunting", "kertas"}

-- Fungsi kirim chat global
local function sendGlobal(msg)
    local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
    if channel then
        pcall(function() channel:SendAsync(msg) end)
        print("[DEBUG][SendGlobal] " .. msg)
    else
        print("[DEBUG][SendGlobal] Channel RBXGeneral tidak ditemukan!")
    end
end

-- Cooldown table per pemain
if not vars.RPSCooldowns then
    vars.RPSCooldowns = {}
end

-- Listener tunggal
if not vars.RPSListenerSetup then
    vars.RPSListenerSetup = true

    print("[DEBUG] RockPaper listener diaktifkan.")

    Players.PlayerChatted:Connect(function(plr, message)
        message = message:lower()
        print("[DEBUG][PlayerChatted] " .. plr.Name .. " mengetik: " .. message)

        -- VIP mengaktifkan mode bot tertentu
        if message == "!modegame1" then
            vars.ActiveBot = botModes.mode1
            sendGlobal("Mode Game Bot1 diaktifkan oleh VIP!")
            print("[DEBUG] Bot1 diaktifkan")
        elseif message == "!modegame2" then
            vars.ActiveBot = botModes.mode2
            sendGlobal("Mode Game Bot2 diaktifkan oleh VIP!")
            print("[DEBUG] Bot2 diaktifkan")
        elseif message == "!modegame3" then
            vars.ActiveBot = botModes.mode3
            sendGlobal("Mode Game Bot3 diaktifkan oleh VIP!")
            print("[DEBUG] Bot3 diaktifkan")
        elseif message == "!modegame4" then
            vars.ActiveBot = botModes.mode4
            sendGlobal("Mode Game Bot4 diaktifkan oleh VIP!")
            print("[DEBUG] Bot4 diaktifkan")
        end

        -- Siapapun ketik !rockpaper
        if message == "!rockpaper" and vars.ActiveBot then
            local lastTime = vars.RPSCooldowns[plr.UserId] or 0
            local now = tick()
            if now - lastTime < 15 then
                print("[DEBUG] " .. plr.Name .. " masih cooldown: " .. math.floor(15 - (now - lastTime)) .. " detik tersisa")
                return
            end
            vars.RPSCooldowns[plr.UserId] = now
            print("[DEBUG] Cooldown direset untuk " .. plr.Name)

            -- Bot yang aktif merespon
            if tostring(localPlayer.UserId) == vars.ActiveBot then
                local botChoice = choices[math.random(1, #choices)]
                sendGlobal(plr.Name .. " Kamu memilih batu, Saya memilih " .. botChoice .. "!")
                print("[DEBUG] Bot " .. localPlayer.Name .. " merespon " .. plr.Name .. " dengan " .. botChoice)
            else
                print("[DEBUG] Bot " .. localPlayer.Name .. " tidak aktif, tidak merespon")
            end
        end
    end)
end

-- Execute tetap bisa kosong karena listener sudah berjalan
return {
    Execute = function(msg, client)
        print("[DEBUG][Execute] Command dipanggil: " .. tostring(msg))
    end
}
