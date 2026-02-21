local Rep = game:GetService("ReplicatedStorage")
local Inventory = require(Rep:WaitForChild("Modules"):WaitForChild("Inventory"))
local ItemsManager = require(Rep:WaitForChild("Managers"):WaitForChild("ItemsManager"))

-- Load Venyx
local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"
))()

local venyx = Venyx.new("MasterZ UX", 5013109572)
local page = venyx:addPage("Auto", 5012544693)
local section = page:addSection("Main")

local selectedItem = nil
local itemMap = {}
local dropdownObj = nil

-- =========================
-- Build list inventory
-- =========================
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

            -- handle label duplikat
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

-- =========================
-- Coba refresh isi dropdown (internal Venyx)
-- =========================
local function RefreshDropdownOptions(dropdown, newOptions)
    if not dropdown then return false end

    -- Simpan option baru ke object dropdown (beberapa fork pakai .options / .list)
    dropdown.options = newOptions
    dropdown.list = newOptions

    -- Cari TextLabel/Button utama buat ubah teks default
    local holder = dropdown.button or dropdown.dropdown or dropdown.frame or dropdown.holder or dropdown
    local textObj = nil

    -- Cari object text yang umum dipakai Venyx
    local candidates = {"Title", "TextLabel", "Label", "Button"}
    for _, key in ipairs(candidates) do
        if typeof(holder) == "table" and holder[key] and holder[key].Text ~= nil then
            textObj = holder[key]
            break
        end
    end

    -- Fallback scan child instance
    if not textObj and typeof(holder) == "Instance" then
        for _, c in ipairs(holder:GetDescendants()) do
            if c:IsA("TextLabel") or c:IsA("TextButton") then
                textObj = c
                break
            end
        end
    end

    if textObj and newOptions[1] then
        -- Hanya ubah text kalau item lama sudah tidak valid
        if textObj.Text == nil or textObj.Text == "" or not table.find(newOptions, textObj.Text) then
            textObj.Text = tostring(newOptions[1])
        end
    end

    -- Coba rebuild list option internal (nama method beda-beda tiap fork)
    local possibleMethods = {
        "Refresh", "refresh",
        "Update", "update",
        "SetOptions", "setOptions",
        "Build", "build"
    }

    for _, m in ipairs(possibleMethods) do
        if type(dropdown[m]) == "function" then
            local ok = pcall(function()
                dropdown[m](dropdown, newOptions)
            end)
            if ok then
                return true
            end
        end
    end

    -- Kalau tidak ada method, tetap return true karena options sudah diubah.
    -- Di beberapa fork, daftar baru kebaca saat dropdown dibuka lagi.
    return true
end

-- =========================
-- Init dropdown pertama kali
-- =========================
local firstList, firstMap = BuildInventoryList()
itemMap = firstMap

dropdownObj = section:addDropdown("Pilih Item", firstList, firstList[1], function(selectedLabel)
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

-- =========================
-- Button update inventory
-- =========================
section:addButton("Update Inventory", function()
    local newList, newMap = BuildInventoryList()
    itemMap = newMap

    local ok = RefreshDropdownOptions(dropdownObj, newList)

    -- Reset selected item kalau item lama sudah hilang
    if selectedItem then
        local stillExists = false
        for _, label in ipairs(newList) do
            local data = itemMap[label]
            if data and data.Id == selectedItem.Id and data.Slot == selectedItem.Slot then
                stillExists = true
                break
            end
        end
        if not stillExists then
            selectedItem = nil
        end
    end

    if ok then
        print("Inventory dropdown berhasil di-update.")
    else
        print("Gagal update dropdown (fork Venyx kamu beda struktur).")
    end
end)

venyx:SelectPage(page, true)