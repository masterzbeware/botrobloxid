-- Commands/Follow.lua
-- Admin-only follow system with bot spacing

return {
  Execute = function()
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")
      local TextChatService = game:GetService("TextChatService")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      -- 🔗 LOAD ADMIN MODULE (DARI FOLDER Administrator)
      local Admin = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
      ))()

      local following = false
      local targetPlayer
      local followConnection

      local humanoid
      local myHRP
      local adminFollowDistance = 3 -- jarak untuk mengikuti Admin
      local botFollowDistance = 2   -- jarak antar Bot

      local function updateCharacter()
          local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
          humanoid = char:WaitForChild("Humanoid")
          myHRP = char:WaitForChild("HumanoidRootPart")
      end

      updateCharacter()
      LocalPlayer.CharacterAdded:Connect(updateCharacter)

      local function stopFollow()
          following = false
          targetPlayer = nil
          if followConnection then
              followConnection:Disconnect()
              followConnection = nil
          end
      end

      local function startFollow(player)
          stopFollow()
          targetPlayer = player
          following = true

          followConnection = RunService.Heartbeat:Connect(function()
              if not following or not humanoid or not myHRP then return end
              if not targetPlayer.Character then return end

              local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
              if hrp then
                  -- Tentukan jarak: Admin = 3, Bot = 2
                  local distance
                  if Admin:IsAdmin(targetPlayer) then
                      distance = adminFollowDistance
                  else
                      distance = botFollowDistance
                  end

                  local direction = (hrp.Position - myHRP.Position).Unit
                  local targetPosition = hrp.Position - direction * distance
                  humanoid:MoveTo(targetPosition)
              end
          end)
      end

      local function handleCommand(msg, sender)
          msg = msg:lower()
          if Admin:IsAdmin(sender) then
              if msg == "!follow" then
                  startFollow(sender)
              elseif msg == "!stop" or msg == "!unfollow" then
                  stopFollow()
              end
          end
      end

      -- TextChatService (baru)
      if TextChatService and TextChatService.TextChannels then
          local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if channel then
              channel.OnIncomingMessage = function(message)
                  local userId = message.TextSource and message.TextSource.UserId
                  local sender = userId and Players:GetPlayerByUserId(userId)
                  if sender then
                      handleCommand(message.Text, sender)
                  end
              end
          end
      end

      -- Fallback lama
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
