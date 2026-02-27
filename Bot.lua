local Rep = game:GetService("ReplicatedStorage")
local Inventory = require(Rep:WaitForChild("Modules"):WaitForChild("Inventory"))
local ItemsManager = require(Rep:WaitForChild("Managers"):WaitForChild("ItemsManager"))
local remotesFolder = Rep:WaitForChild("Remotes")
local placeRemote = Rep:WaitForChild("Remotes"):FindFirstChild("PlayerPlaceItem")
local fistRemote = Rep:WaitForChild("Remotes"):WaitForChild("PlayerFist") -- TAMBAH INI
local TILE = 4.5

local function GetPlayerTilePos()
    local player = game.Players.LocalPlayer
    if not player then return nil end

    local char = player.Character
    if not char then return nil end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local px = math.floor(hrp.Position.X / TILE + 0.5)
    local py = math.floor(hrp.Position.Y / TILE + 0.5)

    return px, py
end



local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/masterzbeware/peta-peta/refs/heads/main/petapeta"
))()

if not Venyx then
    warn("Gagal memuat pustaka Venyx")
    return
end

local venyx = Venyx.new("MasterZ UX", 5013109572)
-- PAGE AUTO
local autoPage = venyx:addPage("Auto", 5012544693)
local section = autoPage:addSection("Main")
local inventorySection = autoPage:addSection("Inventory")
local tilesSection = autoPage:addSection("Tiles")
local autoPlaceSection = autoPage:addSection("Auto Place")
local autoBreakSection = autoPage:addSection("Auto Break")
local speedSection = autoPage:addSection("Speed")

-- PAGE HARVEST (baru)
local harvestPage = venyx:addPage("Harvest", 5012544693)
local harvestMainSection = harvestPage:addSection("Main")

local selectedHarvestTarget = nil
local harvestDropdownObj = nil
local harvestDropdownListRef = {}
local harvestMap = {}

-- PAGE GROWSCAN
local growScanPage = venyx:addPage("GrowScan", 5012544693)
local growScanSection = growScanPage:addSection("Scanner")
local growScanInfoSection = growScanPage:addSection("Info")


local gemsCountDropdownList = {"Gems : 0"}
local gemsCountDropdown = growScanInfoSection:addDropdown("Gems Scanner", gemsCountDropdownList, gemsCountDropdownList[1], function()
end)
local UpdateDropdownVisibleText


growScanSection:addButton("Scan Gems", function()
    local gemsModel = game.Workspace:FindFirstChild("Gems")

    if not gemsModel then
        warn("Model 'Gems' tidak ditemukan di workspace")

        -- update isi dropdown jadi 0
        gemsCountDropdownList[1] = "Gems : 0"
        UpdateDropdownVisibleText(gemsCountDropdown, "Gems : 0")
        return
    end

    local totalParts = 0
    for _, obj in ipairs(gemsModel:GetDescendants()) do
        if obj:IsA("BasePart") then
            totalParts = totalParts + 1
        end
    end

    local resultText = "Gems : " .. tostring(totalParts)

    -- update item dropdown (biar datanya juga ikut berubah)
    gemsCountDropdownList[1] = resultText

    -- update teks yang tampil di UI
    UpdateDropdownVisibleText(gemsCountDropdown, resultText)

    print(resultText)
end)

-- default
local autoPlaceDelay = 0.15
local autoPlaceCycleDelay = 0.05

local autoBreakDelay = 0.10
local autoBreakCycleDelay = 0.05

-- =========================
-- SPEED INPUT (TEXTBOX)
-- =========================

local function clamp(n, min, max)
    if n < min then return min end
    if n > max then return max end
    return n
end

local function parseNumber(text)
    if typeof(text) ~= "string" then return nil end
    text = text:gsub(",", ".") -- biar 0,12 juga bisa
    return tonumber(text)
end

local function updatePlaceCycle()
    autoPlaceCycleDelay = math.max(0.03, autoPlaceDelay * 0.35)
end

local function updateBreakCycle()
    autoBreakCycleDelay = math.max(0.03, autoBreakDelay * 0.35)
end

-- sinkron default
updatePlaceCycle()
updateBreakCycle()

-- Textbox SPEED PLACE (hanya 0.10 - 0.15)
speedSection:addTextbox("Place[0.10-0.15]", tostring(autoPlaceDelay), function(text)
    local n = parseNumber(text)
    if not n then
        warn("Speed Place harus angka. Contoh: 0.12")
        return
    end

    n = clamp(n, 0.10, 0.15)
    autoPlaceDelay = n
    updatePlaceCycle()

    print(string.format("Speed Place diset ke: %.2f", autoPlaceDelay))
end)

-- Textbox SPEED BREAK (hanya 0.05 - 0.10)
speedSection:addTextbox("Break[0.05-0.10]", tostring(autoBreakDelay), function(text)
    local n = parseNumber(text)
    if not n then
        warn("Speed Break harus angka. Contoh: 0.08")
        return
    end

    n = clamp(n, 0.05, 0.10)
    autoBreakDelay = n
    updateBreakCycle()

    print(string.format("Speed Break diset ke: %.2f", autoBreakDelay))
end)

local selectedItem = nil
local itemMap = {}
local dropdownObj = nil
local dropdownListRef = {} -- <<< penting: table yang dipakai dropdown

local function BuildInventoryList()
    local dropdownList = {}
    local newItemMap = {}
    local labelCount = {}

    for slot, stack in pairs(Inventory.Stacks) do
        if stack and next(stack) then
            local id = stack.Id
            local amount = stack.Amount or 1
            local info = ItemsManager.RequestItemData(id)
            local name = (info and info.Name) or ("Unknown (" .. tostring(id) .. ")")

            local baseLabel = string.format("%s [%s] x%d", name, tostring(id), amount)
            labelCount[baseLabel] = (labelCount[baseLabel] or 0) + 1

            local label = baseLabel
            if labelCount[baseLabel] > 1 then
                label = string.format("%s (%d)", baseLabel, labelCount[baseLabel])
            end

            table.insert(dropdownList, label)
            newItemMap[label] = {
                Slot = slot,
                Id = id,
                Name = name,
                Amount = amount,
                Stack = stack
            }
        end
    end

    if #dropdownList == 0 then
        table.insert(dropdownList, "Inventory kosong")
    end

    table.sort(dropdownList)
    return dropdownList, newItemMap
end

-- helper: overwrite isi table lama (biar referensi tetap sama)
local function ReplaceTableContents(target, source)
    table.clear(target)
    for i, v in ipairs(source) do
        target[i] = v
    end
end

local function BuildHarvestList()
    local dropdownList = {}
    local newHarvestMap = {}
    local labelCount = {}

    -- scan semua object di workspace
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name then
            local lowerName = string.lower(obj.Name)

            -- filter: nama object mengandung "tree"
            if string.find(lowerName, "tree") then
                local pos = nil
                local posText = ""

                -- ambil posisi object
                if obj:IsA("Model") then
                    local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if pp then
                        pos = pp.Position
                    end
                elseif obj:IsA("BasePart") then
                    pos = obj.Position
                end

                -- ubah jadi tile biar enak dibaca
                if pos then
                    local tx = math.floor(pos.X / TILE + 0.5)
                    local ty = math.floor(pos.Y / TILE + 0.5)
                    posText = string.format(" (%d,%d)", tx, ty)
                end

                local baseLabel = obj.Name .. posText
                labelCount[baseLabel] = (labelCount[baseLabel] or 0) + 1

                local label = baseLabel
                if labelCount[baseLabel] > 1 then
                    label = string.format("%s (%d)", baseLabel, labelCount[baseLabel])
                end

                table.insert(dropdownList, label)
                newHarvestMap[label] = {
                    Object = obj,
                    Name = obj.Name,
                    Position = pos
                }
            end
        end
    end

    if #dropdownList == 0 then
        table.insert(dropdownList, "Tidak ada Tree")
    end

    table.sort(dropdownList)
    return dropdownList, newHarvestMap
end

-- helper: coba update teks dropdown yang terlihat
UpdateDropdownVisibleText = function(dropdown, text)
    if not dropdown or not text then return end

    -- scan semua object yg mungkin
    local function scan(obj)
        if typeof(obj) == "Instance" then
            for _, c in ipairs(obj:GetDescendants()) do
                if (c:IsA("TextLabel") or c:IsA("TextButton")) then
                    -- biasanya label utama dropdown mengandung nama pilihan
                    c.Text = tostring(text)
                    return true
                end
            end
        elseif typeof(obj) == "table" then
            for _, v in pairs(obj) do
                if typeof(v) == "Instance" then
                    for _, c in ipairs(v:GetDescendants()) do
                        if (c:IsA("TextLabel") or c:IsA("TextButton")) then
                            c.Text = tostring(text)
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    scan(dropdown)
end
-- init pertama
do
    local firstList, firstMap = BuildInventoryList()
    itemMap = firstMap
    ReplaceTableContents(dropdownListRef, firstList)

    dropdownObj = section:addDropdown("Pilih Item", dropdownListRef, dropdownListRef[1], function(selectedLabel)
        selectedItem = itemMap[selectedLabel]

        if selectedItem then
            print("=== ITEM DIPILIH ===")
            print("Nama  :", selectedItem.Name)
            print("ID    :", selectedItem.Id)
            print("Slot  :", selectedItem.Slot)
            print("Jumlah:", selectedItem.Amount)
        else
            print("Tidak ada item valid dipilih.")
        end
    end)

    selectedItem = itemMap[dropdownListRef[1]]
end

inventorySection:addButton("Update Inventory", function()
    local newList, newMap = BuildInventoryList()
    itemMap = newMap

    -- penting: update isi table yg sama (dropdownListRef)
    ReplaceTableContents(dropdownListRef, newList)

    -- reset selected kalau item lama hilang
    local selectedLabel = nil
    if selectedItem then
        for _, label in ipairs(dropdownListRef) do
            local data = itemMap[label]
            if data and data.Id == selectedItem.Id and data.Slot == selectedItem.Slot then
                selectedLabel = label
                break
            end
        end
    end

    if not selectedLabel then
        selectedLabel = dropdownListRef[1]
        selectedItem = itemMap[selectedLabel]
    end

    -- update teks yg tampil (visual)
    UpdateDropdownVisibleText(dropdownObj, selectedLabel or "Pilih Item")

    print("Update Inventory diklik. Jumlah item dropdown:", #dropdownListRef)
    for i, v in ipairs(dropdownListRef) do
        print(i, v)
    end
end)

local main = nil
local autoPlaceEnabled = false
local autoBreakEnabled = false -- TAMBAH
local selectedGridKeys = {}
local autoPlaceThread = nil
local autoBreakThread = nil -- TAMBAH
local gridButtons = {}


local function IsGridSelected(key)
    return selectedGridKeys[key] == true
end

local function ToggleGridSelection(key)
    if selectedGridKeys[key] then
        selectedGridKeys[key] = nil
        print("Grid unselected:", key)
    else
        selectedGridKeys[key] = true
        print("Grid selected:", key)
    end
end

local function HasAnyGridSelected()
    for _ in pairs(selectedGridKeys) do
        return true
    end
    return false
end

local function UpdateGridButtonVisual(key)
    local btn = gridButtons[key]
    if not btn then return end

    local stroke = btn:FindFirstChildOfClass("UIStroke")
    local selected = IsGridSelected(key)

    if selected then
        btn.BackgroundColor3 = Color3.fromRGB(35, 120, 65)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        if stroke then stroke.Color = Color3.fromRGB(90, 255, 150) end
    else
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        btn.TextColor3 = Color3.fromRGB(230, 230, 230)
        if stroke then stroke.Color = Color3.fromRGB(90, 90, 90) end
    end
end

local gridOffsets = {
    T1 = Vector2.new(-1,  1), -- tombol 1
    T2 = Vector2.new( 0,  1), -- tombol 2
    T3 = Vector2.new( 1,  1), -- tombol 3

    L2 = Vector2.new(-2,  0), -- tombol 4
    L1 = Vector2.new(-1,  0), -- tombol 5
    R1 = Vector2.new( 1,  0), -- tombol 6
    R2 = Vector2.new( 2,  0), -- tombol 7

    B1 = Vector2.new(-1, -1), -- tombol 8
    B2 = Vector2.new( 0, -1), -- tombol 9
    B3 = Vector2.new( 1, -1), -- tombol 10
}

-- urutan sesuai nomor di UI (1 s/d 10)
local gridOrder = {
    "T1", -- 1
    "T2", -- 2
    "T3", -- 3
    "L2", -- 4
    "L1", -- 5
    "R1", -- 6
    "R2", -- 7
    "B1", -- 8
    "B2", -- 9
    "B3", -- 10
}

-- ambil grid yang dipilih, sudah urut sesuai nomor
local function GetSelectedGridKeysInOrder()
    local ordered = {}
    for _, gridKey in ipairs(gridOrder) do
        if selectedGridKeys[gridKey] then
            table.insert(ordered, gridKey)
        end
    end
    return ordered
end

local function AutoPlaceToGridKey(gridKey, basePx, basePy)
    if not selectedItem then
        warn("Belum ada item dipilih.")
        return
    end

    if not placeRemote then
        warn("placeRemote nil")
        return
    end

    local offset = gridOffsets[gridKey]
    if not offset then
        warn("Offset grid tidak ada:", gridKey)
        return
    end

    local target = Vector2.new(basePx + offset.X, basePy + offset.Y)
    placeRemote:FireServer(target, selectedItem.Slot)

    print("Auto Place ke:", gridKey, "Target:", target, "Slot:", selectedItem.Slot)
end

local function AutoBreakToGridKey(gridKey, basePx, basePy)
    local offset = gridOffsets[gridKey]
    if not offset then
        warn("Offset grid tidak ada:", gridKey)
        return
    end

    local target = Vector2.new(basePx + offset.X, basePy + offset.Y)
    fistRemote:FireServer(target)

    print("Auto Break ke:", gridKey, "Target:", target)
end


-- =========================
-- TILE DETECTOR (biar tau kapan tile udah hancur)
-- =========================
local function FindTileInstanceAt(tx, ty)
    -- Coba beberapa container umum
    local roots = {
        workspace:FindFirstChild("WorldTiles"),
        workspace:FindFirstChild("Tiles"),
        workspace:FindFirstChild("Map"),
        workspace
    }

    local patterns = {
        tostring(tx) .. "_" .. tostring(ty),
        tostring(tx) .. "," .. tostring(ty),
        "X" .. tostring(tx) .. "Y" .. tostring(ty),
        "[" .. tostring(tx) .. "," .. tostring(ty) .. "]",
    }

    for _, root in ipairs(roots) do
        if root then
            -- Cari berdasarkan nama (lebih cepat)
            for _, name in ipairs(patterns) do
                local inst = root:FindFirstChild(name, true)
                if inst then
                    if inst:IsA("BasePart") then
                        return inst
                    elseif inst:IsA("Model") then
                        return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
                    end
                end
            end

            -- Fallback: cari berdasarkan attribute (lebih berat, tapi universal)
            for _, inst in ipairs(root:GetDescendants()) do
                if inst:IsA("BasePart") then
                    local ax = inst:GetAttribute("X") or inst:GetAttribute("TileX") or inst:GetAttribute("tx")
                    local ay = inst:GetAttribute("Y") or inst:GetAttribute("TileY") or inst:GetAttribute("ty")
                    if ax == tx and ay == ty then
                        return inst
                    end
                end
            end
        end
    end

    return nil
end

local function IsTileDestroyed(tx, ty)
    local inst = FindTileInstanceAt(tx, ty)
    return (inst == nil) or (inst.Parent == nil)
end

-- =========================
-- MODE GABUNGAN (HARUS DI ATAS)
-- =========================
local combinedMode = false
local autoPBThread = nil
local breakTimeoutSec = 3

local function StartAutoPlaceLoop()
    if autoPlaceThread then return end

    autoPlaceThread = task.spawn(function()
        while autoPlaceEnabled and not combinedMode do
            if selectedItem then
                local basePx, basePy = GetPlayerTilePos()
                if not basePx then
                    task.wait(0.2)
                    continue
                end
                local keys = GetSelectedGridKeysInOrder()

                for _, gridKey in ipairs(keys) do
                    if not autoPlaceEnabled then break end
                    AutoPlaceToGridKey(gridKey, basePx, basePy)
                    task.wait(autoPlaceDelay)
                end
            end

            task.wait(autoPlaceCycleDelay)
        end

        autoPlaceThread = nil
    end)
end

local function StartAutoBreakLoop()
    if autoBreakThread then return end

    autoBreakThread = task.spawn(function()
        while autoBreakEnabled and not combinedMode do
            local basePx, basePy = GetPlayerTilePos()
            if not basePx then
                warn("Gagal ambil posisi player.")
                task.wait(0.2)
                continue
            end

            local keys = GetSelectedGridKeysInOrder()

            for _, gridKey in ipairs(keys) do
                if not autoBreakEnabled then break end
                AutoBreakToGridKey(gridKey, basePx, basePy)
                task.wait(autoBreakDelay)
            end

            task.wait(autoBreakCycleDelay)
        end

        autoBreakThread = nil
    end)
end

local function StartAutoPlaceBreakLoop()
    if autoPBThread then return end

    autoPBThread = task.spawn(function()
        while combinedMode and autoPlaceEnabled and autoBreakEnabled do
            if not selectedItem then
                warn("Auto PB stop: item belum dipilih.")
                break
            end

            if not HasAnyGridSelected() then
                warn("Auto PB stop: belum pilih grid.")
                break
            end

            local keys = GetSelectedGridKeysInOrder()
            for _, gridKey in ipairs(keys) do
                if not (combinedMode and autoPlaceEnabled and autoBreakEnabled) then break end

                -- update base tile tiap target (biar kalau player geser dikit tetap akurat)
                local basePx, basePy = GetPlayerTilePos()
                local offset = gridOffsets[gridKey]
                local tx = basePx + offset.X
                local ty = basePy + offset.Y
                local targetVec2 = Vector2.new(tx, ty)

                -- 1) PLACE dulu
                placeRemote:FireServer(targetVec2, selectedItem.Slot)
                -- jeda place
                task.wait(autoPlaceDelay)

                -- 2) BREAK pelan2 sampai hancur
                local t0 = os.clock()
                while combinedMode and autoPlaceEnabled and autoBreakEnabled do
                    fistRemote:FireServer(targetVec2)
                    task.wait(autoBreakDelay)

                    -- kalau tile udah hilang, lanjut tile berikutnya
                    if IsTileDestroyed(tx, ty) then
                        break
                    end

                    -- safety timeout biar gak loop selamanya
                    if os.clock() - t0 >= breakTimeoutSec then
                        -- kalau detector gak cocok sama gamenya, ini mencegah nyangkut
                        warn(("Break timeout di tile (%d,%d). Lanjut tile berikutnya."):format(tx, ty))
                        break
                    end
                end

                task.wait(autoBreakCycleDelay)
            end

            -- setelah semua tile selesai -> ulang lagi dari place
            task.wait(autoPlaceCycleDelay)
        end

        autoPBThread = nil
    end)
end

local function RefreshAutomationMode()
    combinedMode = (autoPlaceEnabled and autoBreakEnabled)

    -- STOP semua thread lama dulu
    autoPlaceEnabled = autoPlaceEnabled
    autoBreakEnabled = autoBreakEnabled

    -- force stop individual threads
    if autoPlaceThread then
        autoPlaceEnabled = false
        task.wait()
        autoPlaceThread = nil
        autoPlaceEnabled = true
    end

    if autoBreakThread then
        autoBreakEnabled = false
        task.wait()
        autoBreakThread = nil
        autoBreakEnabled = true
    end

    if combinedMode then
        StartAutoPlaceBreakLoop()
    else
        if autoPlaceEnabled then StartAutoPlaceLoop() end
        if autoBreakEnabled then StartAutoBreakLoop() end
    end
end


tilesSection:addButton("Tiles Selector", function()
    if main then
        main.Visible = not main.Visible
        print("Tiles Selector:", main.Visible and "OPEN" or "CLOSE")
    else
        print("Grid belum dibuat.")
    end
end)

--[[
harvestMainSection:addToggle("Auto Harvest", false, function(value)
    if value then
        print("Auto Harvest: ON")
        StartAutoHarvest()
    else
        print("Auto Harvest: OFF")
        StopAutoHarvest()
    end
end)
]]

autoPlaceSection:addToggle("Auto Place", false, function(value)
    autoPlaceEnabled = value
    print("Auto Place:", autoPlaceEnabled and "ON" or "OFF")

    if autoPlaceEnabled then
        if not selectedItem then
            warn("Pilih item dulu.")
            autoPlaceEnabled = false
            RefreshAutomationMode()
            return
        end
        if not HasAnyGridSelected() then
            warn("Klik minimal 1 grid dulu.")
            autoPlaceEnabled = false
            RefreshAutomationMode()
            return
        end
    end

    RefreshAutomationMode()
end)

autoBreakSection:addToggle("Auto Break", false, function(value)
    autoBreakEnabled = value
    print("Auto Break:", autoBreakEnabled and "ON" or "OFF")

    if autoBreakEnabled then
        if not HasAnyGridSelected() then
            warn("Klik minimal 1 grid dulu.")
            autoBreakEnabled = false
            RefreshAutomationMode()
            return
        end
    end

    RefreshAutomationMode()
end)


venyx:SelectPage(autoPage, true)



-- =========================
-- VERSION LABEL (KANAN TOPBAR Venyx)
-- =========================
task.spawn(function()
    local pgui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    -- cari UI Venyx berdasarkan nama title
    local venyxGui = pgui:FindFirstChild("MasterZ UX")
    if not venyxGui then
        warn("UI Venyx 'MasterZ UX' tidak ketemu")
        return
    end

    -- ambil TopBar
    local topBar = venyxGui:FindFirstChild("Main") and venyxGui.Main:FindFirstChild("TopBar")
    if not topBar then
        warn("TopBar Venyx tidak ketemu")
        return
    end

    -- hapus label lama kalau ada (biar gak dobel kalau script dijalankan ulang)
    local old = topBar:FindFirstChild("VersionLabel")
    if old then
        old:Destroy()
    end

    -- bikin text versi di kanan
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Name = "VersionLabel"
    versionLabel.BackgroundTransparency = 1
    versionLabel.AnchorPoint = Vector2.new(1, 0.5)
    versionLabel.Position = UDim2.new(1, -12, 0, 19) -- kanan, sejajar title
    versionLabel.Size = UDim2.new(0, 90, 0, 16)
    versionLabel.ZIndex = 6
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.Text = "Version 1.0.1"
    versionLabel.TextSize = 12
    versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    versionLabel.TextTransparency = 0.2
    versionLabel.TextXAlignment = Enum.TextXAlignment.Right
    versionLabel.Parent = topBar
end)

-- =========================
-- GRID KOTAK (PLAYER CENTER)
-- =========================
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")

local oldGui = PlayerGui:FindFirstChild("InventoryGridUI")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryGridUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

main = Instance.new("Frame")
main.Name = "MainGrid"
main.Size = UDim2.new(0, 235, 0, 150)
main.Position = UDim2.new(0.5, -117, 0.5, -75)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 0
main.Parent = gui
main.Visible = false

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 80)
stroke.Thickness = 1
stroke.Parent = main

local title = Instance.new("TextButton")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 6)
title.BackgroundTransparency = 1
title.Text = "Grid Posisi Item / Player"
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = main

local UIS = game:GetService("UserInputService")

title.Active = true -- penting biar bisa nangkep input

local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function updateDrag(input)
    local delta = input.Position - dragStart
    main.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        updateDrag(input)
    end
end)

local function CreateBox(parent, key, text, x, y, isPlayer)
    local box = Instance.new("TextButton")
    box.Name = key
    box.Size = UDim2.new(0, 42, 0, 30)
    box.Position = UDim2.new(0, x, 0, y)
    box.Text = text
    box.Font = Enum.Font.GothamSemibold
    box.TextSize = 9
    box.AutoButtonColor = true
    box.BorderSizePixel = 0
    box.Parent = parent

    if isPlayer then
        box.BackgroundColor3 = Color3.fromRGB(65, 130, 255)
        box.TextColor3 = Color3.fromRGB(255,255,255)
    else
        box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        box.TextColor3 = Color3.fromRGB(230,230,230)
    end

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = box

    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = isPlayer and Color3.fromRGB(120, 180, 255) or Color3.fromRGB(90, 90, 90)
    s.Parent = box

    return box
end

local startX = 9
local gap = 4
local boxW = 42
local row0Y = 32
local row1Y = 72
local row2Y = 112

local function X(index)
    return startX + (boxW + gap) * index
end

gridButtons.T1     = CreateBox(main, "T1", "1",  X(1), row0Y, false)
gridButtons.T2     = CreateBox(main, "T2", "2",  X(2), row0Y, false)
gridButtons.T3     = CreateBox(main, "T3", "3",  X(3), row0Y, false)

gridButtons.L2     = CreateBox(main, "L2", "4",  X(0), row1Y, false)
gridButtons.L1     = CreateBox(main, "L1", "5",  X(1), row1Y, false)
gridButtons.Player = CreateBox(main, "Player", "PLAYER", X(2), row1Y, true)
gridButtons.R1     = CreateBox(main, "R1", "6",  X(3), row1Y, false)
gridButtons.R2     = CreateBox(main, "R2", "7",  X(4), row1Y, false)

gridButtons.B1     = CreateBox(main, "B1", "8",  X(1), row2Y, false)
gridButtons.B2     = CreateBox(main, "B2", "9",  X(2), row2Y, false)
gridButtons.B3     = CreateBox(main, "B3", "10", X(3), row2Y, false)


for key, btn in pairs(gridButtons) do
    btn.MouseButton1Click:Connect(function()
        print("Klik kotak:", key)

        if key == "Player" then
            print("Ini posisi player (tengah)")
            return
        end

        ToggleGridSelection(key)
        UpdateGridButtonVisual(key)
        print("Grid toggle:", key, IsGridSelected(key) and "ON" or "OFF")

-- refresh supaya mode pakai grid terbaru
if autoPlaceEnabled or autoBreakEnabled then
    RefreshAutomationMode()
end

-- kalau mode gabungan aktif, stop jalur lama
if combinedMode then
    return
end

        -- =========================
        -- AUTO PLACE (butuh item)
        -- =========================
        if selectedItem then
            print(string.format(
                "Akan pakai item '%s' (ID:%s, Slot:%s) ke kotak %s",
                tostring(selectedItem.Name),
                tostring(selectedItem.Id),
                tostring(selectedItem.Slot),
                key
            ))
        end
    end)
end
