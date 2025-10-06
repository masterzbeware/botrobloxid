-- RoomVIP.lua
-- Bot1 dan Bot2 bergantian menuju titik-titik 1-9, lalu formasi baris di belakang pemain

return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local RunService = vars.RunService
      local player = vars.LocalPlayer

      if not RunService then
          warn("[RoomVIP] RunService tidak tersedia!")
          return
      end

      -- Reset mode
      vars.FollowAllowed = false
      vars.RowActive = false
      vars.FrontlineActive = false

      local humanoid, myRootPart, moving
      local function updateBotRefs()
          local character = player.Character or player.CharacterAdded:Wait()
          humanoid = character:WaitForChild("Humanoid")
          myRootPart = character:WaitForChild("HumanoidRootPart")
      end
      player.CharacterAdded:Connect(updateBotRefs)
      updateBotRefs()

      local function moveToPosition(targetPos)
          if not humanoid or not myRootPart then return end
          moving = true
          humanoid:MoveTo(targetPos)
          humanoid.MoveToFinished:Wait()
          moving = false
      end

      -- Koordinat posisi
      local positions = {
          Vector3.new(-105.11, 4.00, 9.90),
          Vector3.new(-105.08, 7.41, 3.38),
          Vector3.new(-105.12, 14.00, -6.82),
          Vector3.new(-110.16, 14.00, -8.37),
          Vector3.new(-112.38, 14.82, -4.89),
          Vector3.new(-112.73, 19.32, 1.75),
          Vector3.new(-112.01, 22.11, 5.86),
          Vector3.new(-113.37, 24.00, 9.48),
          Vector3.new(-122.51, 24.00, 11.29)
      }

      -- Urutan bot
      local orderedBots = {
          "8802945328", -- Bot1
          "8802949363", -- Bot2
      }

      local myUserId = tostring(player.UserId)
      local botIndex = 0
      for i, uid in ipairs(orderedBots) do
          if uid == myUserId then
              botIndex = i
              break
          end
      end

      -- Kalau bukan Bot1 atau Bot2, diam saja
      if botIndex == 0 then
          warn("[RoomVIP] Bot ini tidak termasuk dalam formasi RoomVIP.")
          return
      end

      print("[RoomVIP] Bot"..botIndex.." siap bergerak...")

      task.spawn(function()
          -- Bot1 & Bot2 bergerak bergantian
          for i = 1, #positions do
              if botIndex == 1 then
                  -- Bot1: langsung ke posisi i
                  moveToPosition(positions[i])
                  print("[RoomVIP] Bot1 ke Posisi "..i)
                  task.wait(1) -- beri waktu sedikit agar Bot2 bisa jalan
              elseif botIndex == 2 then
                  -- Bot2: tunggu Bot1 lebih dulu naik satu level
                  if i > 1 then
                      task.wait(3.5) -- waktu menunggu giliran Bot1
                      moveToPosition(positions[i-1])
                      print("[RoomVIP] Bot2 ke Posisi "..(i-1))
                  end
              end
          end

          -- Kalau Bot2 terakhir juga sudah selesai posisi 9 → masuk formasi
          if botIndex == 2 then
              print("[RoomVIP] Semua posisi selesai. Masuk formasi barisan...")
              vars.FollowAllowed = true
              vars.CurrentFormasiTarget = client

              if vars.FollowConnection then
                  pcall(function() vars.FollowConnection:Disconnect() end)
                  vars.FollowConnection = nil
              end

              vars.FollowConnection = RunService.Heartbeat:Connect(function()
                  if not vars.FollowAllowed or not client.Character then return end
                  local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
                  if not targetHRP then return end

                  local jarakIkut = tonumber(vars.JarakIkut) or 6
                  local followSpacing = tonumber(vars.FollowSpacing) or 4

                  local orderedFollowBots = {
                      "8802945328",
                      "8802949363",
                      "8802939883",
                      "8802998147",
                  }

                  local myUserId = tostring(player.UserId)
                  local index = 1
                  for i, uid in ipairs(orderedFollowBots) do
                      if uid == myUserId then
                          index = i
                          break
                      end
                  end

                  local backOffset = jarakIkut + (index - 1) * followSpacing
                  local targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * backOffset

                  humanoid:MoveTo(targetPos)
              end)
          end
      end)
  end
}
