local Rep = game:GetService("ReplicatedStorage")
local Inventory = require(Rep:WaitForChild("Modules"):WaitForChild("Inventory"))
local ItemsManager = require(Rep:WaitForChild("Managers"):WaitForChild("ItemsManager"))

local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/masterzbeware/peta-peta/refs/heads/main/petapeta"
))()

local venyx = Venyx.new("MasterZ UX", 5013109572)
local page = venyx:addPage("Auto", 5012544693)
local section = page:addSection("Main")

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

            local baseLabel = string.format("%s x%d", name, amount)
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

-- helper: coba update teks dropdown yang terlihat
local function UpdateDropdownVisibleText(dropdown, text)
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
end

section:addButton("Update Inventory", function()
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

venyx:SelectPage(page, true)

-- =========================
-- GRID KOTAK (PLAYER CENTER)
-- =========================
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")

-- hapus UI lama kalau sudah ada
local oldGui = PlayerGui:FindFirstChild("InventoryGridUI")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryGridUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

-- frame utama
local main = Instance.new("Frame")
main.Name = "MainGrid"
main.Size = UDim2.new(0, 360, 0, 180)
main.Position = UDim2.new(0.5, -180, 0.65, 0) -- agak bawah tengah
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 80)
stroke.Thickness = 1
stroke.Parent = main

-- judul kecil
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.Position = UDim2.new(0, 0, 0, 4)
title.BackgroundTransparency = 1
title.Text = "Grid Posisi Item / Player"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = main

-- helper bikin kotak
local function CreateBox(parent, text, x, y, isPlayer)
    local box = Instance.new("TextButton")
    box.Name = text
    box.Size = UDim2.new(0, 60, 0, 45)
    box.Position = UDim2.new(0, x, 0, y)
    box.Text = text
    box.Font = Enum.Font.GothamSemibold
    box.TextSize = 12
    box.AutoButtonColor = true
    box.BorderSizePixel = 0
    box.Parent = parent

    if isPlayer then
        box.BackgroundColor3 = Color3.fromRGB(65, 130, 255) -- biru utk player
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

-- koordinat layout (5 kotak baris tengah, 3 kotak baris bawah)
-- susunan tengah: [L2][L1][PLAYER][R1][R2]
local startX = 15
local gap = 8
local boxW = 60
local row1Y = 35
local row2Y = 95

local function X(index) -- index mulai 0
    return startX + (boxW + gap) * index
end

local gridButtons = {}

-- baris tengah (5)
gridButtons.L2     = CreateBox(main, "L2",     X(0), row1Y, false)
gridButtons.L1     = CreateBox(main, "L1",     X(1), row1Y, false)
gridButtons.Player = CreateBox(main, "PLAYER", X(2), row1Y, true)
gridButtons.R1     = CreateBox(main, "R1",     X(3), row1Y, false)
gridButtons.R2     = CreateBox(main, "R2",     X(4), row1Y, false)

-- baris bawah (3) ditengahin
-- pakai posisi kolom 1,2,3 biar center di bawah PLAYER
gridButtons.B1     = CreateBox(main, "B1",     X(1), row2Y, false)
gridButtons.B2     = CreateBox(main, "B2",     X(2), row2Y, false)
gridButtons.B3     = CreateBox(main, "B3",     X(3), row2Y, false)

-- contoh klik kotak (bisa kamu isi logic item placement nanti)
for key, btn in pairs(gridButtons) do
    btn.MouseButton1Click:Connect(function()
        print("Klik kotak:", key)

        if key == "Player" then
            print("Ini posisi player (tengah)")
            return
        end

        if selectedItem then
            print(string.format(
                "Akan pakai item '%s' (ID:%s, Slot:%s) ke kotak %s",
                tostring(selectedItem.Name),
                tostring(selectedItem.Id),
                tostring(selectedItem.Slot),
                key
            ))
        else
            print("Belum ada item dipilih dari dropdown.")
        end
    end)
end