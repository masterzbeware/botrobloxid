-- Commands/Diamond.lua
-- Admin-only diamond formation system with bots around Admin
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
      local defaultSpacing = 3 -- jarak antar bot

      -- Flag untuk mengirim chat sekali
      local hasChatted = false

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
          hasChatted = false
          if followConnection then
              followConnection:Disconnect()
              followConnection = nil
          end
      end

      -- Fungsi untuk mengirim chat
      local function sendChat(message)
          local success, err = pcall(function()
              local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
              if channel then
                  channel:SendAsync(message)
              else
                  game:GetService("ReplicatedStorage")
                      .DefaultChatSystemChatEvents
                      :SayMessageRequest
                      :FireServer(message, "All")
              end
          end)
          if not success then
              warn("Gagal mengirim chat: "..tostring(err))
          end
      end

      -- Start positioning in diamond formation
      local function startPositioning(player)
          stopPositioning()
          targetPlayer = player
          positioning = true

          followConnection = RunService.Heartbeat:Connect(function()
              if not positioning or not humanoid or not myHRP then return end
              if not targetPlayer.Character then return end

              local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
              if hrp then
                  local botOrder = {
                      "10191476366", -- Bot1
                      "10191480511", -- Bot2
                      "10191462654", -- Bot3
                      "10190853828", -- Bot4
                      "10191023081", -- Bot5
                      "10191070611"  -- Bot6
                  }

                  -- Cari index bot secara manual
                  local myIndex = 1
                  for i, id in ipairs(botOrder) do
                      if id == tostring(LocalPlayer.UserId) then
                          myIndex = i
                          break
                      end
                  end

                  -- Diamond formation offsets
                  local offsets = {
                      [1] = Vector3.new(-defaultSpacing/2, 0, defaultSpacing),   -- F1
                      [2] = Vector3.new(defaultSpacing/2, 0, defaultSpacing),    -- F2
                      [3] = Vector3.new(-defaultSpacing, 0, 0),                  -- L1
                      [4] = Vector3.new(defaultSpacing, 0, 0),                   -- R1
                      [5] = Vector3.new(-defaultSpacing/2, 0, -defaultSpacing),  -- B1
                      [6] = Vector3.new(defaultSpacing/2, 0, -defaultSpacing)    -- B2
                  }

                  local offset = offsets[myIndex] or Vector3.new(0,0,0)
                  local targetPosition = hrp.Position 
                      + hrp.CFrame.RightVector * offset.X
                      + Vector3.new(0, offset.Y, 0)
                      + hrp.CFrame.LookVector * offset.Z

                  -- Kirim chat sekali saat mulai bergerak
                  if not hasChatted then
                      sendChat("Siap, Laksanakan!")
                      hasChatted = true
                  end

                  humanoid:MoveTo(targetPosition)
              end
          end)
      end

      -- Handle chat commands
      local function handleCommand(msg, sender)
          msg = msg:lower()
          if Admin:IsAdmin(sender) then
              if msg == "!diamond" then
                  startPositioning(sender)
              elseif msg == "!stop" or msg == "!undiamond" then
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
