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
function compareCleanedNames(str1, str2)
	-- Remove all spaces and convert to lowercase
	local clean1 = string.lower(string.gsub(str1, "%s+", ""))
	local clean2 = string.lower(string.gsub(str2, "%s+", ""))

	return clean1 == clean2
end
function printdata(a)
	print(a.Weight.Value)
	print("")

end
function FindBestPlant()
	if PlayerFarm == nil then
		log("Player farm not found")
	end
	for i,MotherPlant in pairs(PlayerFarm:WaitForChild("Important"):WaitForChild("Plants_Physical"):GetChildren()) do
		print(MotherPlant.Name)
		if compareCleanedNames(MotherPlant.Name, WantedPlant) then
			log("Found a good plant")
			if MotherPlant:FindFirstChild("Fruits") then
				log("Plant is a multiHarvest plant")
				for i, plant in pairs(MotherPlant.Fruits:GetChildren()) do
					if plant.Weight.Value >= tonumber(WantedWeight) then
						warn("FOUND")
					end
				end
			end
		end
	end
end
task.spawn(function()
	while true do
		WantedPlant,WantedWeight = parseItemInfo(game.Workspace:WaitForChild("Interaction").UpdateItems["Corrupted Zen"]["Zen Platform"].BillboardPart.BillboardGui.ShecklesAmountFrame.ShecklesAmountLabel.Text)
		wait(1)
	end
end)
FindBestPlant()
