local PlayerFarm:Folder = nil
local WantedPlant = nil
local WantedWeight = 0

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
function parseBackpackItemInfo(itemString)
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
	if parsedItem.weight >= wantedWeight then
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
function compareCleanedNames(str1, str2)
	-- Remove all spaces and convert to lowercase
	local clean1 = string.lower(string.gsub(str1, "%s+", ""))
	local clean2 = string.lower(string.gsub(str2, "%s+", ""))

	return clean1 == clean2
end
function ClaimTranquilPlant()
	if PlayerFarm == nil then
		log("Player farm not found")
	end
	for i,MotherPlant in pairs(PlayerFarm:WaitForChild("Important"):WaitForChild("Plants_Physical"):GetChildren()) do
		if compareCleanedNames(MotherPlant.Name, WantedPlant) then
			log("Found a good plant")
			if MotherPlant:FindFirstChild("Fruits") then
				for i, plant:Instance in pairs(MotherPlant.Fruits:GetChildren()) do
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
			else
				if MotherPlant:GetAttribute("Tranquil") then
					for i,part in pairs(MotherPlant:GetChildren()) do
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
function ScanBackpack()
	for i, item in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
		if matchesCriteria(parseBackpackItemInfo(item.Name), WantedPlant, "0.01", "Tranquil") then
			warn("FOUND IN BACKPACK")
		end

	end
end
task.spawn(function()
	while true do
		WantedPlant,WantedWeight = parseItemInfo(game.Workspace:WaitForChild("Interaction").UpdateItems["Corrupted Zen"]["Zen Platform"].BillboardPart.BillboardGui.ShecklesAmountFrame.ShecklesAmountLabel.Text)
		wait(1)
	end
end)
ScanBackpack()
