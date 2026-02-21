local Rep = game:GetService("ReplicatedStorage")
local Inventory = require(Rep:WaitForChild("Modules"):WaitForChild("Inventory"))
local ItemsManager = require(Rep:WaitForChild("Managers"):WaitForChild("ItemsManager"))

-- Load Venyx
local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"
))()

local venyx = Venyx.new("MasterZ UX", 5013109572)

local selectedItem = nil
local currentPage = nil
local function BuildInventoryList()
    local dropdownList = {}
    local itemMap = {}
    local labelCount = {}

    for slot, stack in pairs(Inventory.Stacks) do
        if stack and next(stack) then
            local id = stack.Id
            local amount = stack.Amount or 1
            local info = ItemsManager.RequestItemData(id)
            local name = (info and info.Name) or ("Unknown (" .. tostring(id) .. ")")

            -- label tanpa slot
            local baseLabel = string.format("%s x%d", name, amount)

            -- handle duplikat (item sama + jumlah sama)
            labelCount[baseLabel] = (labelCount[baseLabel] or 0) + 1
            local label = baseLabel
            if labelCount[baseLabel] > 1 then
                label = string.format("%s (%d)", baseLabel, labelCount[baseLabel])
            end

            table.insert(dropdownList, label)

            itemMap[label] = {
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
    return dropdownList, itemMap
end
local function RenderInventoryUI()
    local dropdownList, itemMap = BuildInventoryList()

    -- Buat page baru
    local page = venyx:addPage("Auto", 5012544693)
    local section = page:addSection("Main")
    section:addDropdown("Pilih Item", dropdownList, function(selectedLabel)
        selectedItem = itemMap[selectedLabel]

        if selectedItem then
        else
            print("Tidak ada item valid dipilih.")
        end
    end)
    section:addButton("Update Inventory", function()
        pcall(function()
            if currentPage and venyx.pages and venyx.pages[currentPage] then
                venyx.pages[currentPage] = nil
            end
        end)
        RenderInventoryUI()
    end)

    currentPage = page
    venyx:SelectPage(page, true)
end

RenderInventoryUI()