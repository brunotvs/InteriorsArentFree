local modDataName = "rvInteriorMod"

local function preventTrunkBedAccess(vehicle, part, chr)
	local vehicleName = vehicle:getScriptName()
	if RVInterior.canEnterFromBackList[vehicleName] then
		return false
	end

	if chr:getVehicle() then
		return false
	end
	if not vehicle:isInArea(part:getArea(), chr) then
		return false
	end
	local trunkDoor = vehicle:getPartById("TrunkDoor") or vehicle:getPartById("DoorRear")
	if trunkDoor and trunkDoor:getDoor() then
		if not trunkDoor:getInventoryItem() then
			return true
		end
		if not trunkDoor:getDoor():isOpen() then
			return false
		end
	end
	return true
end

Vehicles.ContainerAccess.TruckBed = preventTrunkBedAccess

local function onFillContainer(roomName, containerType, itemContainer)
	print(roomName)
	print(containerType)
	print(itemContainer)

	local object = itemContainer:getParent()

	local scriptName = object:getScriptName()
	if RVInterior.canEnterFromBackList[scriptName] then
		itemContainer:emptyIt()
	end
end

Events.OnFillContainer.Add(onFillContainer)
