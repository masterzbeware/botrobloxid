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

-- =========================
-- Ambil item dari inventory
-- =========================
local dropdownList = {}
local itemMap = {} -- buat simpan data item berdasarkan teks dropdown

for slot, stack in pairs(Inventory.Stacks) do
    if stack and next(stack) then
        local id = stack.Id
        local amount = stack.Amount or 1
        local info = ItemsManager.RequestItemData(id)
        local name = (info and info.Name) or ("Unknown (" .. tostring(id) .. ")")

        -- teks yang tampil di dropdown
        local label = string.format("%s x%d [Slot %s]", name, amount, tostring(slot))

        table.insert(dropdownList, label)

        -- simpan data aslinya biar gampang dipakai nanti
        itemMap[label] = {
            Slot = slot,
            Id = id,
            Name = name,
            Amount = amount,
            Stack = stack
        }
    end
end

-- Kalau inventory kosong
if #dropdownList == 0 then
    table.insert(dropdownList, "Inventory kosong")
end

-- (Opsional) urutkan biar rapi
table.sort(dropdownList)

-- =========================
-- Dropdown item inventory
-- =========================
local selectedItem = nil

section:addDropdown("Pilih Item", dropdownList, function(selectedLabel)
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

venyx:SelectPage(page, true)