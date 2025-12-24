-- Commands/Sidecover.lua
-- Admin-only side cover system: 2 di samping, sisanya di belakang Admin

return {
  Execute = function()
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")
      local TextChatService = game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
      local sideDistance = 3   -- jarak samping Admin
      local backDistance = 2   -- jarak belakang Admin
      local spacing = 2        -- jarak antar bot belakang

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
                  ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
                      :FireServer(message, "All")
              end
          end)
          if not success then warn("Gagal chat: "..tostring(err)) end
      end

      -- Start sidecover positioning
      local function startPositioning(player)
          stopPositioning()
          targetPlayer = player
          positioning = true

          followConnection = RunService.Heartbeat:Connect(function()
              if not positioning or not humanoid or not myHRP then return end
              if not targetPlayer.Character then return end

              local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
              if not hrp then return end

              local botOrder = {
                  "10191476366", -- Bot1 (kiri)
                  "10191480511", -- Bot2 (kanan)
                  "10191462654", -- Bot3
                  "10190853828", -- Bot4
                  "10191023081", -- Bot5
                  "10191070611", -- Bot6
                  "10191489151", -- Bot7
                  "10191571531", -- Bot8
                  "10192469244", -- Bot9
                  "10192474291", -- Bot10
              }

              local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId))
              if not myIndex then return end

              local targetPosition = hrp.Position

              -- 🔹 Bot 1 & 2 di samping Admin
              if myIndex == 1 then
                  targetPosition = targetPosition - hrp.CFrame.RightVector * sideDistance
              elseif myIndex == 2 then
                  targetPosition = targetPosition + hrp.CFrame.RightVector * sideDistance
              else
                  -- 🔹 Sisanya di belakang admin, seperti frontline tapi mundur
                  local backIndex = myIndex - 2
                  local rows = math.ceil(backIndex / 2)
                  local isLeft = backIndex % 2 == 1

                  local sideOffset = (isLeft and -1 or 1) * spacing
                  local backOffset = -hrp.CFrame.LookVector * (backDistance * rows)

                  targetPosition = targetPosition + sideOffset * hrp.CFrame.RightVector + backOffset
              end

              -- Kirim chat sekali
              if not hasChatted then
                  sendChat("Side cover ready!")
                  hasChatted = true
              end

              humanoid:MoveTo(targetPosition)
          end)
      end

      -- Handle chat commands
      local function handleCommand(msg, sender)
          msg = msg:lower()
          if Admin:IsAdmin(sender) then
              if msg == "!sidecover" then
                  startPositioning(sender)
              elseif msg == "!stop" or msg == "!unsidecover" then
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

      -- Fallback chat
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
