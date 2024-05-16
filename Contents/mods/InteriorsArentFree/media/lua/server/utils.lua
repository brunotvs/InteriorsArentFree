local function getBuildingRooms(building)
	local rooms
	for i = 0, getNumClassFields(building) - 1 do
		local field = getClassField(building, i)
		local fieldName = string.match(tostring(field), "([^%.]+)$")
		if fieldName == "Rooms" then
			rooms = getClassFieldVal(building, field)
			return rooms
		end
	end
	return rooms
end

local function VectorMethod(building, method)
	local rooms
	for i = 0, getNumClassFunctions(building) - 1 do
		local field = getClassFunction(building, i)
		local fieldName = field:getName()
		if fieldName == method then
			rooms = field
			return rooms
		end
	end
	return rooms
end
