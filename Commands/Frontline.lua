-- Commands/Frontline.lua
-- Admin-only frontline system with bots lined up in front of Admin in correct order

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

      local positioning = false
      local targetPlayer
      local followConnection

      local humanoid
      local myHRP
      local adminFrontDistance = 3 -- jarak di depan Admin
      local defaultBotFrontDistance = 2 -- jarak default antar bot

      -- Update references
      local function updateCharacter()
          local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
          humanoid = char:WaitForChild("Humanoid")
          myHRP = char:WaitForChild("HumanoidRootPart")
      end

      updateCharacter()
      LocalPlayer.CharacterAdded:Connect(updateCharacter)

      -- Stop positioning
      local function stopPositioning()
          positioning = false
          targetPlayer = nil
          if followConnection then
              followConnection:Disconnect()
              followConnection = nil
          end
      end

      -- Start positioning in front of target
      local function startPositioning(player)
          stopPositioning()
          targetPlayer = player
          positioning = true

          followConnection = RunService.Heartbeat:Connect(function()
              if not positioning or not humanoid or not myHRP then return end
              if not targetPlayer.Character then return end

              local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
              if hrp then
                  local distance = defaultBotFrontDistance

                  -- Admin jarak
                  if Admin:IsAdmin(targetPlayer) then
                      distance = adminFrontDistance
                  end

                  -- Pasangan bot jarak khusus
                  local specialDistance = Distance:GetDistance(tostring(LocalPlayer.UserId), tostring(targetPlayer.UserId))
                  if specialDistance then
                      distance = specialDistance
                  end

                  -- HITUNG POSISI BARISAN DI DEPAN ADMIN
                  local botOrder = {
                      "10191476366", -- Bot1
                      "10191480511", -- Bot2
                      "10191462654", -- Bot3
                      "10190853828", -- Bot4
                      "10191023081", -- Bot5
                      "10191070611", -- Bot6
                  }

                  local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId)) or 1
                  local totalBots = #botOrder
                  local spacing = 3 -- jarak antar bot

                  -- Bot di tengah lurus di depan admin
                  local middleIndex = math.ceil(totalBots / 2)
                  local horizontalOffset = (myIndex - middleIndex) * spacing

                  -- Posisi akhir
                  local targetPosition = hrp.Position
                  targetPosition = targetPosition + hrp.CFrame.LookVector * adminFrontDistance -- maju ke depan
                  targetPosition = targetPosition + hrp.CFrame.RightVector * horizontalOffset -- geser ke samping

                  humanoid:MoveTo(targetPosition)
              end
          end)
      end

      -- Handle chat commands
      local function handleCommand(msg, sender)
          msg = msg:lower()
          if Admin:IsAdmin(sender) then
              if msg == "!frontline" then
                  startPositioning(sender)
              elseif msg == "!stop" or msg == "!unfrontline" then
                  stopPositioning()
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
