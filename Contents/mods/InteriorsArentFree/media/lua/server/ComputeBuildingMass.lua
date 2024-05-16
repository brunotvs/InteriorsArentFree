local M = {}

local function tileObjectsMass(tileObjects)
	local mass = 0
	for _, object in ipairs(tileObjects) do
		local item = object:getContainer()
		local spriteProps = object:getSprite():getProperties()
		local name = object:getObjectName()
		local objectWeight = 0
		if spriteProps:Is("IsMoveAble") and spriteProps:Is("PickUpWeight") then
			local pickUpWeight = tonumber(spriteProps:Val("PickUpWeight"))
			objectWeight = pickUpWeight / 10 -- stored x10 by pz
			mass = mass + objectWeight
		end

		local container = object:getContainer()
		local containerWeight = 0
		if container then
			containerWeight = container:getContentsWeight()
			mass = mass + containerWeight
		end

		print("Tile object " .. name .. " weights: " .. objectWeight .. " and carries: " .. containerWeight)
	end
	return mass
end

local function worldObjectsMass(worldObjects)
	local mass = 0
	for i = 0, worldObjects:size() - 1 do
		local object = worldObjects:get(i)
		local item = object:getItem()
		local name = item:getName()
		local weight = item:getWeight()
		local contentsWeight = item:getContentsWeight()
		mass = mass + weight + contentsWeight
		print("World object " .. name .. " weights: " .. weight .. " and carries: " .. contentsWeight)
	end
	return mass
end

function M.getBuildingTotalMass(building)
	local mass = 0

	if not building then
		return
	end
	local roomsDef = building:getDef():getRooms()
	if not roomsDef then
		return
	end

	for i = 0, roomsDef:size() - 1 do
		local roomDef = roomsDef:get(i)
		local isoRoom = roomDef:getIsoRoom()
		local isoSquares = isoRoom:getSquares()
		local isoSquaresSize = isoSquares:size()
		for index = 0, isoSquaresSize - 1 do
			local square = isoSquares:get(index)
			local tileObjects = square:getLuaTileObjectList()
			local tileObjectsMassVal = tileObjectsMass(tileObjects)

			local worldObjects = square:getWorldObjects()
			local worldObjectsMassVal = worldObjectsMass(worldObjects)
			mass = mass + tileObjectsMassVal + worldObjectsMassVal
		end
		print("Total mass: " .. mass)
	end

	return mass
end

function M.getBuildingFromCoordinates(coordinates)
	local gridSquare = getSquare(coordinates.x, coordinates.y, coordinates.z)
	local building = gridSquare:getBuilding()
	return building
end

function BuildingTotalMass()
	local player = getPlayer()
	local currentCell = player:getCell()
	local x, y, z = player:getX(), player:getY(), player:getZ()
	local currentGridSquare = currentCell:getGridSquare(x, y, z)
	local building = currentGridSquare:getBuilding()
	return M.getBuildingTotalMass(building)
end
return M
