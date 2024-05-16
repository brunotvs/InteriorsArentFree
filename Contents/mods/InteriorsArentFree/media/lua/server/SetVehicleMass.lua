local rvInteriorModDataName = "rvInteriorMod"
local modDataName = "InteriorsArenFree"
local buildingMass = require("ComputeBuildingMass")

-- ModData access functions

local function checkInteriorsArentFreeModData(vehicleName)
	if not ModData.exists(modDataName) then
		ModData.add(modDataName, {
			interiors = {},
		})
	end
	if vehicleName and ModData.get(modDataName).interiors[vehicleName] == nil then
		ModData.get(modDataName).interiors[vehicleName] = {
			interiorData = {},
		}
	end
end

local function getInteriorsArentFreeModData(vehicleName, interiorInstance, create)
	checkInteriorsArentFreeModData(vehicleName)
	if not interiorInstance then
		return ModData.get(modDataName).interiors[vehicleName]
	else
		local interiorData = ModData.get(modDataName).interiors[vehicleName].interiorData[interiorInstance]
		if interiorData or not create then
			return interiorData
		else
			return {}
		end
	end
end

local function coordinatesInsideInterior(coordinates)
	local x = coordinates.x
	local y = coordinates.y
	local margin = RVInterior.interiorStride / 3
	local max = (RVInterior.interiorSquare - 1) * RVInterior.interiorStride + margin
	for vehicleName, params in pairs(RVInterior.interior) do
		if
			params.entryPoint
			and x > params.entryPoint[1] - margin
			and x < params.entryPoint[1] + max
			and y > params.entryPoint[2] - margin
			and y < params.entryPoint[2] + max
		then
			return vehicleName
		end
	end
	return nil
end

--- Calculate a player's interiorInstance and vehicleName (if not provided) based on their coordinates.
local function calculateCoordinatesInteriorInstance(coordinates, vehicleName)
	if not vehicleName then
		vehicleName = coordinatesInsideInterior(coordinates)
		if not vehicleName then
			return nil
		end
	else
		vehicleName = RVInterior.getVehicleName(vehicleName)
	end
	local interiorParams = RVInterior.getInteriorParameters(vehicleName)
	local instanceX = math.floor(0.5 + (coordinates.x - interiorParams.entryPoint[1]) / RVInterior.interiorStride)
	local instanceY = math.floor(0.5 + (coordinates.y - interiorParams.entryPoint[2]) / RVInterior.interiorStride)
	if
		instanceX < 0
		or instanceX >= RVInterior.interiorSquare
		or instanceY < 0
		or instanceY >= RVInterior.interiorSquare
	then
		return nil
	end
	local interiorInstance = 1 + instanceX + instanceY * RVInterior.interiorSquare
	return { vehicleName = vehicleName, interiorInstance = interiorInstance }
end

local function getRVInteriorModData(vehicleName, interiorInstance)
	if not interiorInstance then
		local interior = ModData.get(rvInteriorModDataName).interiors[vehicleName]
		return interior
	else
		local interiorData = ModData.get(rvInteriorModDataName).interiors[vehicleName].interiorData[interiorInstance]
		if interiorData then
			return interiorData
		else
			return {}
		end
	end
end

-- Test if a vehicle matches the expected name and interior instance.
local function doesVehicleMatch(vehicle, vehicleName, interiorInstance)
	local canonicalVehicleName = RVInterior.getVehicleName(vehicle:getScript():getFullName(), true)
	if canonicalVehicleName ~= vehicleName then
		return false
	end
	local modData = RVInterior.getVehicleModData(vehicle, RVInterior.getInteriorParameters(canonicalVehicleName))
	return modData and interiorInstance == modData.interiorInstance
end

-- Generic handler for client commands
local clientCommandHandlers = {}
local adminClientCommandHandlers = {}
local clientVehicleCommandHandlers = {}

local allCommandHandlers = {
	RVInterior = clientCommandHandlers,
	RVInteriorAdmin = adminClientCommandHandlers,
	vehicle = clientVehicleCommandHandlers,
}

local function onClientCommand(module, command, player, arguments)
	local handers = allCommandHandlers[module]
	if handers and handers[command] then
		handers[command](player, arguments)
	end
end

Events.OnClientCommand.Add(onClientCommand)

function clientCommandHandlers.clientFinishEnterInterior(player)
	local interior = RVInterior.calculatePlayerInteriorInstance(player)
	if not interior then
		return
	end
	local interiorCoordinates = RVInterior.getInteriorCoordinates(interior.vehicleName, interior.interiorInstance)
	local building = buildingMass.getBuildingFromCoordinates(interiorCoordinates)
	local interiorMass = buildingMass.getBuildingTotalMass(building)

	local data = getInteriorsArentFreeModData(interior.vehicleName, interior.interiorInstance)
	data.mass = interiorMass
	print(interiorMass)
end

function clientCommandHandlers.clientFinishExitInterior(player, arguments)
	local vehicle = getVehicleById(arguments.vehicleId)
	if vehicle == nil then
		print(
			"RVInterior WARNING: player ",
			player:getFullName(),
			" tried to update battery of ",
			arguments.vehicleName,
			" with unknown vehicleId: ",
			arguments.vehicleId
		)
		return
	end
	local modData = vehicle:getModData()
	local vehicleName = RVInterior.getVehicleName(vehicle:getScript():getFullName())
	local vehicleModData = RVInterior.getVehicleModData(vehicle, RVInterior.getInteriorParameters(vehicleName))
	local interiorInstance = vehicleModData.interiorInstance
end

local M = {}

-- Iterate over all added interiors and return the vehicleName of the map region the player's X & Y coords are inside.

function M.getVehicle(coordinates, vehicleName, interiorInstance)
	local retries = 500
	local vehicleIndex = 0
	local playerLeftInteriorClosure

	-- Wait until at least the tile they're now on has loaded before trying to find the vehicle.
	local square = getSquare(coordinates.x, coordinates.y, coordinates.z)

	-- Try to locate the correct vehicle as they're loaded into memory.
	local cell = square:getCell()
	local allVehicles = cell:getVehicles()

	if allVehicles:size() == 0 then
		return
	elseif vehicleIndex >= allVehicles:size() then
		vehicleIndex = 0
	end

	local vehicle = allVehicles:get(vehicleIndex)
	vehicleIndex = vehicleIndex + 1

	if not doesVehicleMatch(vehicle, vehicleName, interiorInstance) then
		return
	end
end

function TestModData()
	local interiorData = ModData.get(rvInteriorModDataName).interiors["Base.TrailerTSMega"].interiorData
end

function GetVehicleData()
	local player = getPlayer()
	local currentCell = player:getCell()
	local x, y, z = player:getX(), player:getY(), player:getZ()
	local currentGridSquare = currentCell:getGridSquare(x, y, z)
	loadGridSquare(currentGridSquare)
end
