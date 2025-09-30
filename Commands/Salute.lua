-- Salute.lua (animasi hormat dari catalog + chat)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local player = vars.LocalPlayer or Players.LocalPlayer

        vars.SaluteActive = true

        -- Ambil channel chat
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        local function sendChat(text)
            if channel then
                pcall(function() channel:SendAsync(text) end)
            end
        end

        -- Jalankan coroutine untuk animasi + chat
        vars.SaluteConnection = task.spawn(function()
            sendChat("Siap hormat, Komandan!")
            task.wait(1.5)
            if not vars.SaluteActive then return end

            -- 🔹 Play animasi salute dari catalog
            local success, err = pcall(function()
                local character = player.Character or player.CharacterAdded:Wait()
                local humanoid = character:WaitForChild("Humanoid")

                -- pastikan ada Animator
                local animator = humanoid:FindFirstChildOfClass("Animator")
                if not animator then
                    animator = Instance.new("Animator")
                    animator.Parent = humanoid
                end

                -- buat animasi
                local saluteAnim = Instance.new("Animation")
                saluteAnim.AnimationId = "rbxassetid://3360689775" -- Salute dari catalog

                -- load & play
                local track = animator:LoadAnimation(saluteAnim)
                track.Priority = Enum.AnimationPriority.Action
                track:Play()

                -- Simpan track biar bisa dihentikan dari Stop.lua
                vars.SaluteTrack = track
            end)
            if not success then warn("[Salute] gagal play animasi:", err) end

            -- Chat tambahan saat hormat
            task.wait(2.5) if not vars.SaluteActive then return end sendChat("Hormat untuk Komandan!")
            task.wait(2.5) if not vars.SaluteActive then return end sendChat("Kami siap menerima perintah!")

            -- Diamkan sebentar sebelum stop
            task.wait(2)
            if vars.SaluteTrack then
                vars.SaluteTrack:Stop()
                vars.SaluteTrack = nil
            end

            vars.SaluteActive = false
            vars.SaluteConnection = nil
        end)
    end
}
