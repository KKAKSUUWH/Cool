local PlayerFarm:Folder = nil
local WantedPlant = nil
local WantedWeight = 0
local needed_plant = {
	"Tomato",
	"Strawberry",
	"Blueberry",
	"Orange Tulip",
	"Corn",
	"Daffodil",
	"Bamboo",
	"Apple",
	"Coconut",
	"Pumpkin",
	"Watermelon",
	"Cactus",
	"Dragon Fruit",
	"Mango",
	"Grape",
	"Mushroom",
	"Pepper",
	"Cacao"
}


function log(msg)
	print(msg)
end


-- finds player farm
for i,v in pairs(game.Workspace:WaitForChild("Farm"):GetChildren()) do
	if v.Important.Data.Owner.Value == game.Players.LocalPlayer.Name then
		PlayerFarm = v
	end
end

function parseItemInfo(itemString)
	-- Match the full name and the weight inside brackets
	local nameWithPrefix, weightWithUnit = string.match(itemString, "^(.-)%s%[(.-)%]$")
	if not nameWithPrefix or not weightWithUnit then
		return nil, nil -- Invalid format
	end

	-- Remove the first word (assumed prefix)
	local nameParts = {}
	for word in string.gmatch(nameWithPrefix, "%S+") do
		table.insert(nameParts, word)
	end
	table.remove(nameParts, 1)
	local itemName = table.concat(nameParts, " ")

	-- Remove "kg" from the weight
	local weight = string.match(weightWithUnit, "([%d%.]+)")

	return itemName, weight
end
function matchesCriteria(parsedItem, wantedName, wantedWeight, wantedMutations)
	if not parsedItem then return false end

	-- Match item name (case-insensitive, trim whitespace)
	local function clean(str)
		return string.lower(string.gsub(str, "^%s*(.-)%s*$", "%1"))
	end

	if clean(parsedItem.itemName) ~= clean(wantedName) then
		return false
	end

	-- ✅ Allow equal or more
	if tonumber(parsedItem.weight) < tonumber(wantedWeight) then
		return false
	end

	-- Check if any wanted mutation is present
	local hasMutation = false
	for _, wanted in ipairs(wantedMutations) do
		for _, actual in ipairs(parsedItem.mutations) do
			if wanted == actual then
				hasMutation = true
				break
			end
		end
		if hasMutation then break end
	end

	return hasMutation
end
function ParseToolName(itemString)
	-- Extract mutations, item name, and weight
	local mutationsStr, itemName, weightWithUnit = string.match(itemString, "^%[(.-)%]%s+(.-)%s+%[(.-)%]$")
	if not mutationsStr or not itemName or not weightWithUnit then
		return nil
	end

	-- Split mutations into a table
	local mutations = {}
	for mut in string.gmatch(mutationsStr, "[^,%s]+") do
		table.insert(mutations, mut)
	end

	-- Extract numeric weight
	local weight = tonumber(string.match(weightWithUnit, "([%d%.]+)"))
	if not weight then
		return nil
	end

	return {
		mutations = mutations,
		itemName = itemName,
		weight = weight,
	}
end
function compareCleanedNames(str1, str2)
	-- Remove all spaces and convert to lowercase
	local clean1 = string.lower(string.gsub(str1, "%s+", ""))
	local clean2 = string.lower(string.gsub(str2, "%s+", ""))

	return clean1 == clean2
end
function DumpFarm()
	local Fruits = {}
	for i,MotherPlant in pairs(PlayerFarm:WaitForChild("Important"):WaitForChild("Plants_Physical"):GetChildren()) do
		if MotherPlant:FindFirstChild("Fruits") then
			for i, plant:Instance in pairs(MotherPlant.Fruits:GetChildren()) do
				table.insert(Fruits, plant)
			end
		else
			table.insert(Fruits, MotherPlant)
		end
	end
	return Fruits
end
function DumpIventory()
	local iventory = {
		["Seeds"] = {},
		["Plants"] = {},
		["Tools"] = {}
	}
	for i, item in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
		if item:FindFirstChild("SprinklerHandler") then
			iventory["Tools"][item] = item
		elseif item:FindFirstChild("Seed Local Script") then
			iventory["Seeds"][item] = item
		elseif item:FindFirstChild("Item_String") then
			iventory["Plants"][item] = item
		end
	end
	return iventory -- <- ADD THIS
end
function ScanFarm()
	for i,MotherPlant in pairs(PlayerFarm:WaitForChild("Important"):WaitForChild("Plants_Physical"):GetChildren()) do
		if compareCleanedNames(MotherPlant.Name, WantedPlant) then
			log("Found a good plant")
			for i, plant:Instance in pairs(DumpFarm()) do
				if plant.Weight.Value >= tonumber(WantedWeight) then
					if plant:GetAttribute("Tranquil") then
						for i,part in pairs(plant:GetChildren()) do
							if part:FindFirstChild("ProximityPrompt") then
								fireproximityprompt(part:FindFirstChild("ProximityPrompt"))
								return
							end
						end
					end
				end
			end
		end
	end
end

function FetchTask()
	WantedPlant,WantedWeight = parseItemInfo(game.Workspace:WaitForChild("Interaction").UpdateItems["Corrupted Zen"]["Zen Platform"].BillboardPart.BillboardGui.ShecklesAmountFrame.ShecklesAmountLabel.Text)
end
function GetTranquil()
	for i, item in pairs(DumpIventory()["Plants"]) do
		if matchesCriteria(ParseToolName(item.Name), WantedPlant, tonumber(WantedWeight), {"Tranquil"}) then
			game.Players.LocalPlayer.Character.Humanoid:EquipTool(item)
			return
		end

	end
end
function SubmitToTheDickHead()
	local args = {
		"SubmitToCorruptedMonk"
	}
	game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("ZenQuestRemoteEvent"):FireServer(unpack(args))
end
function Plant(Seed:string)
	local args = {
		vector.create(24.67923355102539, 0.13552704453468323, -154.42941284179688),
		"Seed"
	}
	game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("Plant_RE"):FireServer(unpack(args))
end

--task.spawn(function()
--	-- Main Loop
--	while task.wait(1) do
--		FetchTask()
--		ClaimTranquilPlant()
--		ScanBackpack()
--		SubmitToTheDickHead()
--	end
--end)


-- check needed plants

function GetCleanName(str)
	return string.lower(string.gsub(str, "%s+", ""))
end

-- Get list of needed plants
local found = {}
local missing = {}
local plantedNames = {}
local inventorySeeds = {}

local farmPlants = DumpFarm()
local inventory = DumpIventory()

-- Collect all currently planted fruits
for _, plant in pairs(farmPlants) do
	local cleanedName = GetCleanName(plant.Name)
	plantedNames[cleanedName] = true
end

-- Collect all seeds from inventory
for seedItem, _ in pairs(inventory["Seeds"]) do
	local cleanedName = GetCleanName(seedItem.Name)
	inventorySeeds[cleanedName] = true
end

-- Check for each needed plant
for _, needed in ipairs(needed_plant) do
	local cleanedNeeded = GetCleanName(needed)
	if plantedNames[cleanedNeeded] then
		table.insert(found, needed)
	else
		local hasSeed = inventorySeeds[cleanedNeeded]
		table.insert(missing, { name = needed, hasSeed = hasSeed })
	end
end

log("❌ Missing plants:")
for _, entry in ipairs(missing) do
	local seedStatus = entry.hasSeed and "✅ yes" or "❌ no"
	log("  - " .. entry.name .. " (seed preset: " .. seedStatus .. ")")
end
