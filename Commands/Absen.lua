-- Absen.lua
-- Command !absen: Bot maju satu per satu lapor ke depan Client

return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local RunService = vars.RunService
      local Players = game:GetService("Players")
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local player = vars.LocalPlayer

      if not RunService then
          warn("[Absen] RunService tidak tersedia!")
          return
      end

      vars.AbsenActive = true
      vars.FollowAllowed = false
      vars.ShieldActive = false
      vars.RowActive = false
      vars.FrontlineActive = false
      vars.CurrentFormasiTarget = client

      local humanoid, myRootPart, moving

      local function updateBotRefs()
          local character = player.Character or player.CharacterAdded:Wait()
          humanoid = character:WaitForChild("Humanoid")
          myRootPart = character:WaitForChild("HumanoidRootPart")
      end

      player.CharacterAdded:Connect(updateBotRefs)
      updateBotRefs()

      local function moveToPosition(targetPos, lookAtPos)
          if not humanoid or not myRootPart then return end
          if moving then return end
          if (myRootPart.Position - targetPos).Magnitude < 0.5 then return end

          moving = true
          humanoid:MoveTo(targetPos)
          humanoid.MoveToFinished:Wait()
          moving = false

          if lookAtPos then
              myRootPart.CFrame = CFrame.new(
                  myRootPart.Position,
                  Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z)
              )
          end
      end

      -- Ambil channel chat
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
      local function sendChat(text)
          if channel then
              pcall(function() channel:SendAsync(text) end)
          end
      end

      -- Bot Mapping untuk urutan lapor
      local orderedBots = {
          "8802945328", -- Bot1
          "8802949363", -- Bot2
          "8802939883", -- Bot3
          "8802998147", -- Bot4
      }

      local myUserId = tostring(player.UserId)
      local index = 1
      for i, uid in ipairs(orderedBots) do
          if uid == myUserId then
              index = i
              break
          end
      end

      -- Posisi formasi baris tetap di belakang Client
      local jarakBaris = tonumber(vars.JarakIkut) or 6
      local spacing = tonumber(vars.FollowSpacing) or 4
      local backOffset = jarakBaris + (index - 1) * spacing

      -- Tentukan posisi default di barisan
      local targetHRP = client.Character and client.Character:FindFirstChild("HumanoidRootPart")
      if not targetHRP then
          warn("[Absen] Client belum siap!")
          return
      end
      local defaultPos = targetHRP.Position - targetHRP.CFrame.LookVector * backOffset

      -- 🔹 Coroutine absen: maju satu per satu, lapor
      task.spawn(function()
          -- Gerak ke depan Client (jarak 3 stud dari VIP)
          local forwardPos = targetHRP.Position - targetHRP.CFrame.LookVector * 3
          moveToPosition(forwardPos, targetHRP.Position)

          -- Kirim chat lapor
          sendChat("Laporan Komandan, Barisan " .. index .. " hadir")

          task.wait(1) -- delay biar natural

          -- Kembali ke posisi default
          moveToPosition(defaultPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)

          vars.AbsenActive = false
      end)

      print("[COMMAND] Absen aktif, Bot barisan:", index)
  end
}
