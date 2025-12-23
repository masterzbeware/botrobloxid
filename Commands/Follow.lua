-- Commands/Follow.lua
-- Admin-only follow system with bot spacing via Distance.lua

return {
  Execute = function()
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")
      local TextChatService = game:GetService("TextChatService")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      -- 🔗 LOAD ADMIN MODULE
      local Admin = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
      ))()

      -- 🔗 LOAD DISTANCE MODULE
      local Distance = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
      ))()

      local following = false
      local targetPlayer
      local followConnection

      local humanoid
      local myHRP
      local adminFollowDistance = 3 -- jarak untuk mengikuti Admin
      local defaultBotFollowDistance = 2 -- jarak default antar bot

      -- Update references
      local function updateCharacter()
          local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
          humanoid = char:WaitForChild("Humanoid")
          myHRP = char:WaitForChild("HumanoidRootPart")
      end

      updateCharacter()
      LocalPlayer.CharacterAdded:Connect(updateCharacter)

      -- Stop following
      local function stopFollow()
          following = false
          targetPlayer = nil
          if followConnection then
              followConnection:Disconnect()
              followConnection = nil
          end
      end

      -- Start following target
      local function startFollow(player)
          stopFollow()
          targetPlayer = player
          following = true

          followConnection = RunService.Heartbeat:Connect(function()
              if not following or not humanoid or not myHRP then return end
              if not targetPlayer.Character then return end

              local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
              if hrp then
                  -- Tentukan jarak
                  local distance = defaultBotFollowDistance

                  if Admin:IsAdmin(targetPlayer) then
                      distance = adminFollowDistance
                  elseif Distance:IsBot(LocalPlayer.UserId) and Distance:IsBot(targetPlayer.UserId) then
                      local specialDistance = Distance:GetDistance(tostring(LocalPlayer.UserId), tostring(targetPlayer.UserId))
                      if specialDistance then
                          distance = specialDistance
                      end
                  end

                  -- Hitung posisi follow
                  local direction = (hrp.Position - myHRP.Position).Unit
                  local targetPosition = hrp.Position - direction * distance

                  humanoid:MoveTo(targetPosition)
              end
          end)
      end

      -- Handle chat commands
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

      -- TextChatService listener
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
