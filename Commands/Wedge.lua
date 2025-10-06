-- Wedge.lua
-- Command !wedge: Bot membentuk formasi segitiga (Wedge) di belakang target VIP
-- Kompatibel dengan Stop.lua

return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local RunService = vars.RunService
      local player = vars.LocalPlayer

      if not RunService then
          warn("[Wedge] RunService tidak tersedia!")
          return
      end

      -- 🔹 Nonaktifkan mode lain sebelum mengaktifkan Wedge
      vars.WedgeActive = not vars.WedgeActive
      vars.FollowAllowed = false
      vars.RowActive = false
      vars.SquareActive = false
      vars.ShieldActive = false
      vars.FrontlineActive = false
      vars.CircleMoveActive = false
      vars.PushupActive = false
      vars.SyncActive = false
      vars.ReportingActive = false
      vars.RoomVIPActive = false
      vars.CurrentFormasiTarget = client

      -- 🔹 Jika dinonaktifkan, hentikan koneksi & keluar
      if not vars.WedgeActive then
          print("[WEDGE] Dinonaktifkan")
          if vars.WedgeConnection then
              pcall(function() vars.WedgeConnection:Disconnect() end)
              vars.WedgeConnection = nil
          end
          return
      end

      print("[WEDGE] Formasi Wedge diaktifkan. Target:", client.Name)

      -- 🔹 Referensi karakter bot
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
          if (myRootPart.Position - targetPos).Magnitude < 1 then return end

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

      -- 🔹 Putuskan koneksi Wedge lama jika ada
      if vars.WedgeConnection then
          pcall(function() vars.WedgeConnection:Disconnect() end)
          vars.WedgeConnection = nil
      end

      -- 🔹 Simpan koneksi baru ke vars.WedgeConnection
      if RunService.Heartbeat then
          vars.WedgeConnection = RunService.Heartbeat:Connect(function()
              if not vars.WedgeActive or not client.Character then return end
              local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
              if not targetHRP then return end

              -- 🔹 Mapping bot (UserId)
              local orderedBots = {
                  "8802945328", -- B1 kiri depan
                  "8802939883", -- B2 kiri belakang
                  "8802949363", -- B3 kanan depan
                  "8802998147", -- B4 kanan belakang
              }

              local myUserId = tostring(player.UserId)
              local index = 1
              for i, uid in ipairs(orderedBots) do
                  if uid == myUserId then
                      index = i
                      break
                  end
              end

              -- 🔹 Konfigurasi jarak
              local jarakDepan = tonumber(vars.JarakDepan) or 4
              local jarakBelakang = tonumber(vars.JarakBelakang) or 6
              local jarakSamping = tonumber(vars.SideSpacing) or 3

              -- 🔹 Offset posisi per bot (Z negatif = di belakang VIP)
              local offsetMap = {
                  [1] = Vector3.new(-jarakSamping, 0, -jarakDepan),      -- B1 kiri depan (dekat VIP)
                  [2] = Vector3.new(-jarakSamping*2, 0, -jarakBelakang), -- B2 kiri belakang
                  [3] = Vector3.new(jarakSamping, 0, -jarakDepan),       -- B3 kanan depan (dekat VIP)
                  [4] = Vector3.new(jarakSamping*2, 0, -jarakBelakang),  -- B4 kanan belakang
              }

              local offset = offsetMap[index] or Vector3.zero
              local cframe = targetHRP.CFrame
              local targetPos = (cframe.Position
                  + cframe.RightVector * offset.X
                  + cframe.UpVector * offset.Y
                  + cframe.LookVector * offset.Z)

              moveToPosition(targetPos, targetHRP.Position)
          end)
      else
          warn("[Wedge] RunService.Heartbeat tidak tersedia!")
      end
  end
}
