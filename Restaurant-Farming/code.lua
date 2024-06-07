-- Comments are things to do
Config = {
    Map = "aduermael.hills",
	Items = {
		"voxels.wheat_chunk",
		"drouethug.cz_food_bread",
		"fax.windmill",
		"drouethug.cz_item_plate",
		"pratamacam.furnace",
		"pratamacam.bag_of_flour",
		"voxels.wheat",

		"avatoon.egg",
		"wrden.fried_egg",
		"voxels.chicken",

		"uevoxel.beekeeping",
		"uevoxel.honey02",

		"voxels.corn_stage_4",
		"voxels.corn",
		"voxels.corn_cooked",

		"claire.cow",
		"pratamacam.milk_carton",
		"pratamacam.building01c",
		"wrden.yellow_cheese",

		"voxels.corn_stage_4",
		"voxels.corn",
		"voxels.corn_cooked",
		"pratamacam.building01a",
		"sequoia.popcorn",

		"pratamacam.building01b",
		"voxels.potato",
		"voxels.potato_cut",
		"voxels.chips_bag",
		"voxels.fries",

		"boumety.endturn",

		"wrden.red_cheese",
	},
}

Client.OnStart = function()
	if Player.Username ~= "boumety" then
		if Player.Username ~= "notilos" then
			URL:Open("https://app.cu.bzh/?worldID=4d194d06-82e2-45b3-a759-557d4b486f11")
		end
	end

	Map.PrivateDrawMode = 8

	Camera:SetModeFree()
	Camera.Position = Number3(600, Map.Height*3, 600)
	Camera.Rotation.X = math.rad(50)

	uiCollisionGroup = 8

    uiCamera = Camera()
    uiCamera:SetParent(World)
    uiCamera.On = true
    uiCamera.Far = 500
	uiCamera.Near = 0

    uiCamera.Layers = 2

    uiCamera.Projection = ProjectionMode.Orthographic
    uiCamera.Width = Screen.Width
    uiCamera.Height = Screen.Height

    uiOrigin = Object()
    uiOrigin:SetParent(uiCamera)

	oldWidth = Screen.Width
	oldHeight = Screen.Height

	cards = {}

	Screen.DidResize = function(width, height)
   	 uiCamera.Width = Screen.Width
   	 uiCamera.Height = Screen.Height

   	 uiOrigin.LocalPosition = { -Screen.Width / 2, -Screen.Height / 2, 0 }

		for k, v in pairs(cards) do
			v.Scale = Screen.Width / 15 / v.longest
			v.LocalPosition = Number3(Screen.Width / 5 * v.nb + Screen.Width / 5 / 2, (margin * 2 + uiOffsetY[v.name]) * v.Scale.X, v.Depth * v.Scale.Z)
		end

		endTurnBtn.Scale = Screen.Width / 4 / endTurnBtn.longest
		endTurnBtn.LocalPosition = Number3(Screen.Width / 4 + endTurnBtn.Width * endTurnBtn.Scale.X, Screen.Height / 2 - endTurnBtn.Height * endTurnBtn.Scale.Y, endTurnBtn.Depth * endTurnBtn.Scale.Z * 1.2)
	end

	createUiShape = function(shape, ratio)
		local s = Shape(shape, {includeChildren = true})
		s.Pivot = {s.Width/2, s.Height/2, s.Depth/2}

		local box = Box()
		box:Fit(s, false)

		local localBox = Box()
		localBox.Min = box.Min - s.Position
		localBox.Max = box.Max - s.Position

		local longest = math.max(localBox.Max.X - localBox.Min.X, math.max(localBox.Max.Y - localBox.Min.Y, localBox.Max.Z - localBox.Min.Z))

		s.ratio = ratio
		s.longest = longest
		s.Scale = Screen.Width / ratio / longest

		s.IsUnlit = true
		s.CollisionGroups = uiCollisionGroup
		s.Layers = 2

		for i=1, s.ChildrenCount do			
			local sha = s:GetChild(i)
			sha.Layers = 2
			sha.IsUnlit = true
			for i=1, sha.ChildrenCount do
				sha:GetChild(i).Layers = 2
				sha:GetChild(i).IsUnlit = true
			end
		end

		uiOrigin:AddChild(s)

		return s
	end

	endTurnBtn = createUiShape(Shape(Items.boumety.endturn), 2)

    local ambience = require("ambience") 
    ambience:set(ambience.noon)
    sfx = require("sfx")
    Camera:AddChild(AudioListener)
	ease = require("ease")
	particles = require("particles")

	coin = 0

	margin = 8
	time = 0.03
	animationDelay = 0.5
	canPlace = true
	canPlay = true

	types = {
		CROP = 1,
		ANIMAL = 2,
		BUILDING = 3,
	}

	informations = {
		PRODUCERS = {
			["Wheat Chunk"] = {name = "Wheat Chunk",shape = Shape(Items.voxels.wheat_chunk), require = {}, produce = {{product="Wheat"}, }, type = types.CROP},
			["Beehive"] = {name = "Beehive",shape = Shape(Items.uevoxel.beekeeping), rot = math.rad(180), require = {}, produce = {{product="Honey"},}, type = types.CROP},
			["Chicken"] = {name = "Chicken",shape = Shape(Items.voxels.chicken), require = {}, produce = {{product="Egg"},}, type = types.ANIMAL},
			["Cow"] = {name = "Cow",shape = Shape(Items.claire.cow), rot = math.rad(180), require = {}, produce = {{product="Milk", quan=1},}, type = types.ANIMAL},

			["Furnace"] = {name = "Furnace",shape = Shape(Items.pratamacam.furnace), rot = math.rad(180), require = {{require="Wheat"}, {require="Egg"}}, produce = {{product="Bread"}, {product="Fried egg"},}, type = types.BUILDING},
			["Windmill"] = {name = "Windmill",shape = Shape(Items.fax.windmill), require = {{require="Wheat"}}, produce = {{product="Flour", quan=1},}, type = types.BUILDING},
			["Dairy"] = {name = "Dairy",shape = Shape(Items.pratamacam.building01c), rot = math.rad(180), require = {{require="Milk"},}, produce = {{product="Cheese"},}, type = types.BUILDING},
		},

		RESOURCES = {
			["Wheat"] = {name = "Wheat",shape = Shape(Items.voxels.wheat), rot = math.rad(180), offset = Number3(5,3,5), price = 1,},
			["Honey"] = {name = "Honey",shape = Shape(Items.uevoxel.honey02), rot = math.rad(180), offset = Number3(5,8,5), price = 1,},
			["Egg"] = {name = "Egg",shape = Shape(Items.avatoon.egg), offset = Number3(5,5,5), price = 1,},
			["Milk"] = {name = "Milk",shape = Shape(Items.pratamacam.milk_carton), rot = math.rad(180), offset = Number3(5,3,5), price = 1,},
			["Flour"] = {name = "Flour",shape = Shape(Items.pratamacam.bag_of_flour), rot = math.rad(180), offset = Number3(5,5,5), price = 1,},
			["Cheese"] = {name = "Cheese",shape = Shape(Items.wrden.yellow_cheese), rot = math.rad(180), offset = Number3(5,7,5), price = 1,},
			["Bread"] = {name = "Bread",shape = Shape(Items.drouethug.cz_food_bread), offset = Number3(5,2,5), price = 1,},
			["Fried egg"] = {name = "Fried egg",shape = Shape(Items.wrden.fried_egg), offset = Number3(5,8,5), price = 1,},
			["Red Cheese"] = {name = "Red Cheese",shape = Shape(Items.wrden.red_cheese), offset = Number3(5,8,5), price = 2,},
		},

		UPGRADES = {
			["Red Cheese"] = {name = "Red Cheese", shape = Shape(Items.wrden.red_cheese), desc = "Turn all cheese into red cheese, multipluing its value by 1.5."},
			["Hungry Cow"] = {name = "Hungry Cow", shape = Shape(Items.claire.cow),  desc = "Cow can eat 1 [Wheat] to produce 2 [Milk]. Don't produce [Milk] if not feeden."},
			["Honied"] = {name = "Honied", shape = Shape(Items.uevoxel.honey02),  desc = "Multiply the total value at the end of the turn depending on the number of [Honey] produced on that said turn. (5 [Honey]: 1.05x, 10 [Honey]: 1.10x, 15 [Honey]: 1.15x)"},
			["Flourier"] = {name = "Flourier", shape = Shape(Items.pratamacam.bag_of_flour),  desc = "Produce 2 [Flour] per [Wheat]"}
		},
	}

	storage = {}

	for i, v in pairs(informations.RESOURCES) do
		storage[i] = 0
	end

	field = {}

	uiOffsetY = {
		["Wheat Chunk"] = 0,
		["Chicken"] = 1,
		["Beehive"] = 6,
		["Windmill"] = 30,
		["Furnace"] = 50,
		["Cow"] = 10,
		["Dairy"] = 30,
	}

	upgrades = {}

	for z=71, 69, -1 do
		for x=50, 70, 1 do
			local block = Map:GetBlock(x,0,z)
			block.Color = Color.Brown
			table.insert(field, {block=block})
		end
	end

	current = informations.PRODUCERS.MISC["Wheat Chunk"]

	plant = function(info, block)
		local plant = Shape(info.card.shape, {includeChildren = true})
		plant:SetParent(World)

		plant.Name = info.card.name
		plant.Pivot = Number3(plant.Width / 2, 0, plant.Depth / 2)
		plant.Position = block.Position + Number3(5,9,5)

		plant.Scale = 1
		local box = Box()
		box:Fit(plant, false)

		local localBox = Box()
		localBox.Min = box.Min - plant.Position
		localBox.Max = box.Max - plant.Position

		local longest = math.max(localBox.Max.X - localBox.Min.X, math.max(localBox.Max.Y - localBox.Min.Y, localBox.Max.Z - localBox.Min.Z))

		plant.Scale = Map.Scale.X / longest

		plant.Rotation.Y = info.card.rot or 0
		plant.Physics = PhysicsMode.Disabled

		local config = spawnParticules(plant.Position, 40, 1.0 + math.random(), Color.Brown)
		local emitter = particles:newEmitter(config)

		emitter:spawn(30)

		plant.Scale = plant.Scale / 1.1

		ease:inQuad(plant, 0.25).Scale = {plant.Scale.X*1.1,plant.Scale.Y*1.1,plant.Scale.Z*1.1}

		for i=1, #field do
			if field[i].block.Coordinates == block.Coordinates then
				field[i].obj = plant
				field[i].data = info.card
			end
		end
	end

	collect = function(require, produce, block, obj)
		if #require == 0 then
			for i=1, #produce do
				storage[produce[i].product] = storage[produce[i].product] + (produce[i].quan or 1)

				Timer((i-1)/2, function() spawnResource(produce[i].product, block, obj) end)
			end
		else
			for i=1, #require do
				local quan = storage[require[i].require]
				if quan >= (require[i].quan or 1) then
					local res = produce[i].product
					for k=1, #produce do
						storage[produce[i].product] = storage[produce[i].product] + (produce[i].quan or 1) * quan
						storage[require[i].require] = storage[require[i].require] - quan
					end

					if quan > 0 then
						Timer((i-1)/2, function() spawnResource(res, block, obj) end)
					end
				end
			end
		end
	end

	resetStorage = function()
		for k, v in pairs(storage) do
			storage[k] = 0
		end
	end

	spawnResource = function(resource, block, obj)
		local shape = informations.RESOURCES[resource].shape

		local res = Shape(shape, {includeChildren = true})
		res.Pivot = Number3(res.Width / 2, 0, res.Depth / 2)
		res.Position = block.Position + informations.RESOURCES[resource].offset

		local box = Box()
		box:Fit(res, false)

		local localBox = Box()
		localBox.Min = box.Min - res.Position
		localBox.Max = box.Max - res.Position

		local longest = math.max(localBox.Max.X - localBox.Min.X, math.max(localBox.Max.Y - localBox.Min.Y, localBox.Max.Z - localBox.Min.Z))

		res.Scale = Map.Scale.X / 2 / longest

		res.Position.Y = res.Position.Y + obj.Height * obj.Scale.Y + res.Height * res.Scale.Y
		res.Rotation.Y = shape.rot or 0
		res.Physics = PhysicsMode.Disabled
		World:AddChild(res)

		local config = spawnParticules(res.Position, 25, 0.5 + math.random(), Color.White)
		local emitter = particles:newEmitter(config)

		ease:inQuad(res, animationDelay, { onDone = function() emitter:spawn(30) World:RemoveChild(res) end }).Position = {res.Position.X,res.Position.Y + 5,res.Position.Z}
	end

	sellDishes = function()
		local total = 0
		for k, v in pairs(informations.RESOURCES) do
			local gain = storage[k] * informations.RESOURCES[k].price
			if gain > 0 then
				coin = coin + gain
				total = total + gain
				print(k, "x" .. storage[k] .. ": " .. gain)
			end
		end
		print("Total earned: " .. total)
		print("Bank account: " .. coin)
	end

	spawnParticules = function(pos, speed, sca, col)
		local pi2 = math.pi * 2

		local config = {
			velocity = function()
				local v = Number3(0, 0, 1)
				v:Rotate(math.random() * pi2, math.random() * pi2, 0)
				return v * speed
			end,
			position = function()
				return pos
			end,
			scale = function()
				return sca
			end,
			color = function()
				return col
			end,
			life = function()
				return 0.3
			end,
			collidesWithGroups = function()
				return nil
			end,
		}

		return config
	end

	endTurn = function()
		canPlace = false
		canPlay = false
		current = nil

		for i=#field, 1, -1 do
			local block = field[i].block
			local obj = field[i].obj
			local data = field[i].data
			local scale

			-- Improve ease code side

			Timer((i-1)*time, function()
				block.Color = Color.White

				if obj then
					sfx("walk_concrete_1", {Position = Camera.Position, Volume = 0.5, Pitch = 2})

					scale = obj.Scale
					ease:inSine(obj, time, { onDone = function()
						ease:inSine(obj, time).Scale = {obj.Scale.X/1.25,obj.Scale.Y/1.25,obj.Scale.Z/1.25}
					end }).Scale = {obj.Scale.X*1.25,obj.Scale.Y*1.25,obj.Scale.Z*1.25}

					collect(data.require, data.produce, block, obj)
				end

			end)

			Timer(i*time, function()
				block.Color = Color.Brown
			end)
		end

		Timer(#field*time, function()
			sellDishes()

			resetStorage()

			drawCard()

			canPlace = true
			canPlay = true

			sfx("twang_1", {Position = Camera.Position, Volume = 1, Pitch = 1 + math.random() * 0.5})
		end)
	end

	drawCard = function()
		-- Better card
		-- Animation
		-- Better draw

		for k, v in pairs(cards) do
			if v then
				v:SetParent(nil)
			end
		end

		cards = {}

		local building = {}
		local misc = {}

		for k, v in pairs(informations.PRODUCERS) do
			if v.type == types.BUILDING then
				table.insert(building, v)
			else
				table.insert(misc, v)
			end
		end


		for i=1, 5 do
			local info

			if i==5 then
				info = building[math.random(#building)]
			else
				info = misc[math.random(#misc)]
			end

			local shape = createUiShape(info.shape, 15)

			shape.nb = i-1
			shape.name = info.name

			shape.info = info

			table.insert(cards, shape)

			shape.LocalRotation = {math.rad(-30), 0, math.rad(-30)}

			shape.Tick = function(_, dt)
				shape.LocalRotation.Y = shape.LocalRotation.Y + math.rad(1)
			end

			Screen:DidResize()
		end
	end

	drawUpgrade = function()
		local list = {}

		for k, v in pairs(informations.UPGRADES) do
			table.insert(list, informations.UPGRADES[k])
		end

		local choices = {}

		for i=1, 3 do
			local r = math.random(#list)
			local choice = list[r]

			local upgrade = createUiShape(choice.shape, 10)

			upgrade.LocalRotation = {math.rad(-30), 0, math.rad(-30)}

			upgrade.Tick = function(_, dt)
				upgrade.LocalRotation.Y = upgrade.LocalRotation.Y + math.rad(1)
			end

			local size = upgrade.Depth
			if upgrade.Width > upgrade.Depth then
				size = upgrade.Width
			end

			upgrade.LocalPosition = Number3((Screen.Width / 3) * (i-1) + (upgrade.Width * upgrade.Scale.X) * 2, Screen.Height / 2, size * upgrade.Scale.Z)

			table.insert(choices, list[r])
			table.remove(list, r)
		end

		--endTurnBtn.IsHidden = true
	end

	drawCard()
	drawUpgrade()
end

Client.Action1 = nil
Client.DirectionalPad = nil
Client.Tick = nil

Client.OnChat = function(payload)
	return true
end

Pointer.Down = function(pointerEvent)
	local origin = Number3((pointerEvent.X - 0.5) * Screen.Width, (pointerEvent.Y - 0.5) * Screen.Height, 0)
	local direction = { 0, 0, 1 }

    local impact = Ray(origin, direction):Cast({ uiCollisionGroup })
	if impact then
		if not canPlay then return end

		if current.shape == impact.Shape then
			sfx("hitmarker_2", {Position = Camera.Position, Volume = 1, Pitch = 1 + math.random() * 0.5})

			ease:inSine(current.shape, 0.1).Scale = {current.shape.Scale.X  * 1.5, current.shape.Scale.Y  * 1.5, current.shape.Scale.Z  * 1.5}
			current = nil
			return
		end
			
		if current then
			ease:inSine(current.shape, 0.1).Scale = {current.shape.Scale.X  * 1.5, current.shape.Scale.Y  * 1.5, current.shape.Scale.Z  * 1.5}
		end

		for i=1, #cards do
			if impact.Shape == cards[i] then
				sfx("hitmarker_1", {Position = Camera.Position, Volume = 1, Pitch = 1 + math.random() * 0.5})

				local shape = impact.Shape
				current = {card=shape.info, shape=shape, pos=shape.Position}
				ease:inSine(current.shape, 0.1).Scale = {current.shape.Scale.X  / 1.5, current.shape.Scale.Y  / 1.5, current.shape.Scale.Z  / 1.5}
				return
			end
		end

		if impact.Shape == endTurnBtn then
			sfx("victory_1", {Position = Camera.Position, Volume = 1, Pitch = 1 + math.random() * 0.5})

			ease:inSine(endTurnBtn, 0.25).Scale = {endTurnBtn.Scale.X  / 1.5, endTurnBtn.Scale.Y  / 1.5, endTurnBtn.Scale.Z  / 1.5}
			endTurn()
		end
	else
   	 local impact = pointerEvent:CastRay()
		local block = impact.Block

		for i=1, #field do
			if field[i].block.Coordinates == block.Coordinates and field[i].obj then
				return
			end
		end

    	if block and current and canPlace and block.Color == Color.Brown then
			sfx("walk_grass_1", {Position = Camera.Position, Volume = 1, Pitch = 1 + math.random() * 0.5})

			plant(current, block)
			current.shape.IsHidden = true
			current = nil
   	 end
	end
end
