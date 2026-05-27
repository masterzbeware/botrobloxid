-- Commands/Reset.lua
-- Reset all formations/follow + reset character
-- Command:
-- !reset

return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------
        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then
            return
        end

        ----------------------------------------------------------------
        -- LOAD ADMIN MODULE
        ----------------------------------------------------------------
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- RESET CHARACTER
        ----------------------------------------------------------------
        local function resetCharacter()

            local character = LocalPlayer.Character

            if not character then
                return
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                humanoid.Health = 0
            end
        end

        ----------------------------------------------------------------
        -- HANDLE COMMAND
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)

            ------------------------------------------------------------
            -- ADMIN ONLY
            ------------------------------------------------------------
            if not Admin:IsAdmin(sender) then
                return
            end

            local lower = msg:lower()

            ------------------------------------------------------------
            -- !reset
            ------------------------------------------------------------
            if lower == "!reset" then

                resetCharacter()
            end
        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ----------------------------------------------------------------
        if TextChatService
        and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels
                :FindFirstChild("RBXGeneral")

            if channel then

                channel.OnIncomingMessage = function(message)

                    local userId =
                        message.TextSource
                        and message.TextSource.UserId

                    local sender =
                        userId
                        and Players:GetPlayerByUserId(userId)

                    if sender then
                        handleCommand(message.Text, sender)
                    end
                end
            end
        end

        ----------------------------------------------------------------
        -- LEGACY CHAT FALLBACK
        ----------------------------------------------------------------
        for _, player in ipairs(Players:GetPlayers()) do

            player.Chatted:Connect(function(msg)
                handleCommand(msg, player)
            end)
        end

        Players.PlayerAdded:Connect(function(player)

            player.Chatted:Connect(function(msg)
                handleCommand(msg, player)
            end)
        end)
    end
}