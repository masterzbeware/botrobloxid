-- Reset.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local player = vars.LocalPlayer or Players.LocalPlayer

        if not player then
            warn("LocalPlayer tidak ditemukan!")
            return
        end

        -- Coba reset karakter dengan cara paling aman
        pcall(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.Health = 0
            end
        end)
    end
}
