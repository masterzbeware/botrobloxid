-- RoomVIP.lua
-- Bot1–4 bergerak bergantian ke posisi 1–9, lalu formasi baris.
-- Destroy vipDoor hanya sekali dan bisa dihentikan kapan saja lewat !stop

return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local RunService = vars.RunService
      local player = vars.LocalPlayer

      if not RunService then
          warn("[RoomVIP] RunService tidak tersedia!")
          return
      end

      -- 🔹 Reset mode sebelum mulai
      vars.FollowAllowed = false
      vars.RowActive = false
      vars.FrontlineActive = false

      -- 🔹 Hentikan RoomVIP sebelumnya (kalau masih aktif)
      if vars.RoomVIPTask then
          pcall(function() task.cancel(vars.RoomVIPTask) end)
          vars.RoomVIPTask = nil
      end
      if vars.RoomVIPConnection then
          pcall(function() vars.RoomVIPConnection:Disconnect() end)
          vars.RoomVIPConnection = nil
      end

      -- 🔹 Destroy vipDoor sekali saja
      task.spawn(function()
          if vars.VipDoorsCleared then
              print("[RoomVIP] Semua vipDoor sudah dihancurkan sebelumnya.")
              return
          end

          local detectorsFolder = game.Workspace:FindFirstChild("Detectors")
          if detectorsFolder then
              local vipFolder = detectorsFolder:FindFirstChild("vipDoors")
              if vipFolder then
                  local destroyed = 0
                  for _, obj in ipairs(vipFolder:GetDescendants()) do
                      if obj:IsA("Part") and obj.Name == "vipDoor" and obj.Parent then
                          obj:Destroy()
                          destroyed += 1
                      end
                  end
                  print("[RoomVIP] vipDoor dihancurkan:", destroyed)
                  vars.VipDoorsCleared = true
              else
                  warn("[RoomVIP] Folder vipDoors tidak ditemukan.")
              end
          else
              warn("[RoomVIP] Folder Detectors tidak ditemukan.")
          end
      end)

      -- 🔹 Referensi bot
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
          if not vars or vars.FollowAllowed == false then return end
          moving = true
          humanoid:MoveTo(targetPos)
          humanoid.MoveToFinished:Wait()
          moving = false
      end

      -- 🔹 Daftar posisi koordinat RoomVIP
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

      -- 🔹 Urutan bot (sesuai ID)
      local orderedBots = {
          "8802945328", -- Bot1
          "8802949363", -- Bot2
          "8802939883", -- Bot3
          "8802998147", -- Bot4
      }

      local myUserId = tostring(player.UserId)
      local botIndex = 0
      for i, uid in ipairs(orderedBots) do
          if uid == myUserId then
              botIndex = i
              break
          end
      end

      if botIndex == 0 then
          warn("[RoomVIP] Bot ini tidak terdaftar dalam RoomVIP.")
          return
      end

      print("[RoomVIP] Bot" .. botIndex .. " mulai menjalankan rute RoomVIP...")

      -- 🔹 Jalankan rute dengan task (agar bisa dihentikan !stop)
      vars.RoomVIPTask = task.spawn(function()
          for i = 1, #positions do
              if not vars or vars.FollowAllowed == false then
                  print("[RoomVIP] Dihentikan oleh !stop.")
                  return
              end

              local targetStep = i - (botIndex - 1)
              if targetStep > 0 and targetStep <= #positions then
                  task.wait((botIndex - 1) * 2)
                  moveToPosition(positions[targetStep])
                  print("[RoomVIP] Bot" .. botIndex .. " ke posisi " .. targetStep)
              end
              task.wait(1.5)
          end

          -- 🔹 Setelah semua bot selesai, aktifkan mode barisan (ikuti)
          if botIndex == #orderedBots then
              print("[RoomVIP] Semua bot selesai, aktifkan formasi barisan.")
              vars.FollowAllowed = true
              vars.CurrentFormasiTarget = client

              -- Bersihkan koneksi lama
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

                  local myUserId = tostring(player.UserId)
                  local index = 1
                  for i, uid in ipairs(orderedBots) do
                      if uid == myUserId then
                          index = i
                          break
                      end
                  end

                  local backOffset = jarakIkut + (index - 1) * followSpacing
                  local targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * backOffset
                  humanoid:MoveTo(targetPos)
              end)

              vars.RoomVIPConnection = vars.FollowConnection
          end
      end)
  end
}
