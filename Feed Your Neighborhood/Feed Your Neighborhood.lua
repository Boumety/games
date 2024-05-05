Config = {
    Items = {
		"aduermael.avatar",

		"kooow.cardboard_box_long",

		"voxels.raw_patty",
		"voxels.medium_patty",
		"voxels.cooked_patty",
		"voxels.burnt_patty",
		"voxels.burger",

		"voxels.pizza",

		"voxels.beef_pile",
		"voxels.chicken_pile",

		"voxels.burger_bun",
		"voxels.hotdog_bun",
		"voxels.hotdog_bbq",

		"voxels.beef_skewer_burnt",
		"voxels.beef_skewer_cooked",
		"voxels.beef_skewer_medium",
		"voxels.beef_skewer_raw",

		"voxels.chicken_skewer_burnt",
		"voxels.chicken_skewer_cook",
		"voxels.chicken_skewer_med",
		"voxels.chicken_skewer_raw",

		"voxels.sausage_burnt",
		"voxels.sausage_cooked",
		"voxels.sausage_medium",
		"voxels.sausage_raw",

		"voxels.skewer",
		"voxels.skewer_pile",
    }
}

Modules = {
    data = "github.com/Boumety/module/data",
	ui_blocks = "github.com/caillef/cubzh-library/ui_blocks:09941d5",
    device_orientation = "github.com/BucheGithub/modzh/device_orientation:dac0a99",
    --leaderboard = "github.com/BucheGithub/modzh/leaderboard:33eda6f",
    --leaderboard_ui = "github.com/BucheGithub/modzh/leaderboard_ui:ff47e5a",
}

Client.OnStart = function()
	--Dev.DisplayColliders = true

	data:setPlayerData()

	read = function(d)
		if Player.Username == "boumety" then print(#d) end
	end

	save = function()
		data:setPlayerData()
	end

	Menu:AddDidBecomeActiveCallback(save)

	save()

	data:getAllData(read)

	device_orientation:init({ forcedOrientation = "landscape" })

	load = function(url)
		HTTP:Get(url, function(res)
			if res.StatusCode ~= 200 then
				print("Error on " .. fileName .." loading. Code: " .. res.StatusCode)
				return
			end
			local texture = res.Body
			createQuad(texture)
		end)
	end
--https://raw.githubusercontent.com/Boumety/module/main/action4/img/Action4.png
--https://github.com/Boumety/module/blob/main/action4/img/Action4.png
	createQuad = function(texture, config)
		local defaultConfig = {
			position = Number3(0, 0, 0),
			rotation = Rotation(0, 0, 0),
			scale = Number3(1, 1, 1)
		}
		local q = Quad()
		q.Image = texture
		q.Position = config.position or defaultConfig.position
		q.Rotation = config.rotation or defaultConfig.rotation
		q.Scale = config.scale or defaultConfig.scale

		q:SetParent(World)

		table.insert(tutorials, q)
	end

    local ambience = require("ambience") 
    ambience:set(ambience.noon)
    sfx = require("sfx")
    Player.Head:AddChild(AudioListener)
    local theme = require("uitheme").current
    ease = require("ease")
    local ui = require("uikit")

	Camera:SetModeFree()
	Camera.Position = Number3(-14,84,-22)
	Camera.Rotation = Number3(0.63,0.77,0)

	margin = 8

	defaultNeighbors = {"voxels","notilos","claire","aduermael","caillef","xavier","buche","gaetan","nanskip","fab3kleuuu","uevoxel","pratamacam",}
	neighbors = defaultNeighbors

	LocalEvent:Listen(LocalEvent.Name.AvatarLoaded, function(p)
   	 if p ~= Player then return end
    	if Player.EyeLidRight then
    	    Player.EyeLidRight:RemoveFromParent()
    	    Player.EyeLidLeft:RemoveFromParent()
   	 end

		Player.IsHiddenSelf = true

		local equipments = require("equipments")
		equipments.unloadAll(Player)
	end)

    require("api"):getFriends(function(err, list)
		if err == true then
			neighbors = {}
			for i=1, #list do
				table.insert(neighbors, list[i].username)
			end

			while #neighbors < 12 do
				table.insert(neighbors, defaultNeighbors[1])
				table.remove(defaultNeighbors, 1)
			end
		end
    end)

	queue = {}
	positions = {Number3(7, 45.5, -23.71), Number3(18, 45.5, -23.71), Number3(28, 45.5, -23.71), Number3(38, 45.5, -23.71),Number3(48, 45.5, -23.71),Number3(58, 45.5, -23.71), }
	endPos = Number3(-23.35, 45.5, -23.71)

	disabled = false
	started = false
	rotated = true

	LocalEvent:Listen(device_orientation.LocalEvent.OnOrientationChange, function(isCorrect)
   	 if isCorrect then
			rotated = true
    	else
			rotated = false
    	end
	end)

	zoomInOut = 0

	clickFrame = ui:createFrame(Color.Black)
	click = ui:createText("Click anywhere to launch", Color.White, "big")

	clickFrame.Width = click.Width + margin*2
	clickFrame.Height = click.Height + margin*2

	click:setParent(clickFrame)

	ui_blocks:anchorNode(click, "center", "center", 0)
	ui_blocks:anchorNode(clickFrame, "center", "center", 0)

	holding = nil

	pizzas = 0
	pizzaTable = {}

	delayNeighborMax = 25
	delayNeighborMin = 20
	currentNeighbor = 1.5

	delaySlow = 0.75
	delayFast = 2

	reduceDelayNeighbor = delaySlow

	waves = 0.1

	coins = 0
	reputation = 100

	heat = 0
	heatOn = false

	local modalFrameShape = {{text="Burger", shape=Shape(Items.voxels.burger)}, {text="Hotdog", shape=Shape(Items.voxels.hotdog_bbq)}, {text="Chicken Skewer", shape=Shape(Items.voxels.chicken_skewer_cook)}, {text="Beef Skewer", shape=Shape(Items.voxels.beef_skewer_cooked)}}
	local recipes = {"-Take a patty\n-Put on the grill\n-Wait until it is cooked and take it\n-Click on the burger bun", "-Take sausage\n-Put on the grill\n-Wait until it is cooked and take it\n-Click on the sausage bun", "-Click on the pile of skewers to take one\n-Click on the pile of chicken\n-Put on the grill\n-Wait until it is cooked and take it", "-Click on the pile of skewer to take one\n-Click on the pile of patty\n-Put on the grill\n-Wait until it is cooked and take it"}

	rawPatty = Shape(Items.voxels.raw_patty)
	rawPatty.Name = "rawPatty1"
	mediumPatty = Shape(Items.voxels.medium_patty)
	mediumPatty.Name = "mediumPatty1"
	cookedPatty = Shape(Items.voxels.cooked_patty)
	cookedPatty.Name = "cookedPatty1"
	burntPatty = Shape(Items.voxels.burnt_patty)
	burntPatty.Name = "burntPatty1"

	burger = Shape(Items.voxels.burger)
	burger.Name = "burger"

	skewer = Shape(Items.voxels.skewer)
	skewer.Name = "skewer"

	hotdog = Shape(Items.voxels.hotdog_bbq)
	hotdog.Name = "hotdog"

	pizza = Shape(Items.voxels.pizza)
	pizza.Name = "pizza"

	rawSausage = Shape(Items.voxels.sausage_raw)
	rawSausage.Name = "rawSausage2"
	mediumSausage = Shape(Items.voxels.sausage_medium)
	mediumSausage.Name = "mediumSausage2"
	cookedSausage = Shape(Items.voxels.sausage_cooked)
	cookedSausage.Name = "cookedSausage2"
	burntSausage = Shape(Items.voxels.sausage_burnt)
	burntSausage.Name = "burntSausage2"

	rawChicken = Shape(Items.voxels.chicken_skewer_raw)
	rawChicken.Name = "rawChicken3"
	mediumChicken = Shape(Items.voxels.chicken_skewer_med)
	mediumChicken.Name = "mediumChicken3"
	cookedChicken = Shape(Items.voxels.chicken_skewer_cook)
	cookedChicken.Name = "cookedChicken3"
	burntChicken = Shape(Items.voxels.chicken_skewer_burnt)
	burntChicken.Name = "burntChicken3"

	rawBeef = Shape(Items.voxels.beef_skewer_raw)
	rawBeef.Name = "rawBeef4"
	mediumBeef = Shape(Items.voxels.beef_skewer_medium)
	mediumBeef.Name = "mediumBeef4"
	cookedBeef = Shape(Items.voxels.beef_skewer_cooked)
	cookedBeef.Name = "cookedBeef4"
	burntBeef = Shape(Items.voxels.beef_skewer_burnt)
	burntBeef.Name = "burntBeef4"

	orders = {
		{name="burger", sell=10,},
		{name="hotdog", sell=5,},
		{name="cookedChicken3", sell=7,},
		{name="cookedBeef4", sell=8,},
	}

	states = {
		["1"] = {
			{obj=Shape(rawPatty), name="rawPatty1", state=0},
			{obj=Shape(mediumPatty), name="mediumPatty1", state=50},
			{obj=Shape(cookedPatty), name="cookedPatty1", state=150},
			{obj=Shape(burntPatty), name="burntPatty1", state=200},
		},
		["2"] = {
			{obj=Shape(rawSausage), name="rawSausage2", state=0},
			{obj=Shape(mediumSausage), name="mediumSausage2", state=20},
			{obj=Shape(cookedSausage), name="cookedSausage2", state=70},
			{obj=Shape(burntSausage), name="burntSausage2", state=100},
		},
		["3"] = {
			{obj=Shape(rawChicken), name="rawChicken3", state=0},
			{obj=Shape(mediumChicken), name="mediumChicken3", state=20},
			{obj=Shape(cookedChicken), name="cookedChicken3", state=120},
			{obj=Shape(burntChicken), name="burntChicken3", state=170},
		},
		["4"] = {
			{obj=Shape(rawBeef), name="rawBeef4", state=0},
			{obj=Shape(mediumBeef), name="mediumBeef4", state=20},
			{obj=Shape(cookedBeef), name="cookedBeef4", state=130},
			{obj=Shape(burntBeef), name="burntBeef4", state=180},
		},
	}

	holdItem = function(o)
		holding = Shape(o)
		Player:AddChild(holding)

		holding.Physics = PhysicsMode.Disabled

		if o.Name == "pizza" then
			holding.LocalPosition = Number3(-3.5, 17, 7)
			holding.Scale = 0.3
		elseif o.Name == "rawChicken3" or o.Name == "cookedChicken3" or o.Name == "burntChicken3" or o.Name == "rawBeef4" or o.Name == "cookedBeef4" or o.Name == "burntBeef4" or o.Name == "skewer" or o.Name == "rawSausage2" or o.Name == "cookedSausage2" or o.Name == "burntSausage2" then
			holding.LocalPosition = Number3(-0.5, 17, 7)
			holding.Scale = 0.4
		else
			holding.LocalPosition = Number3(-1.5, 17, 7)
			holding.Scale = 0.5
		end

		holding.Name = o.Name
	end

	unhold = function()
		holding:SetParent(nil)
		holding = nil
	end

	spawnClient = function()
		if #queue == #positions then return end
		local order = {orders[math.random(#orders)], orders[math.random(#orders, 8)], orders[math.random(#orders, 8)]}
		local happiness = 100
		local time = 1
		local total = 0
		local placed = false
		local gone = false

		local player = Object()
		local skin = require("avatar"):get(neighbors[math.random(#neighbors)])
		skin:SetParent(player)
		player.Scale = 0.5
		World:AddChild(player)
		player.Position = Number3(60, 45.5, -23.71)

		local box = Object()
		player:AddChild(box)
		box.CollisionBox = Box({0,0,0},{10,30,10})
		box.LocalPosition = Number3(-5,0,-5)
		box.Physics = PhysicsMode.Disabled
		box.Name = "avatar"

		table.insert(queue, {client=player, order=order})

		player.pos = #queue

		local t = Text()

		t.Text = happiness .. "/100 😛"
		t.Type = TextType.World
		t.IsUnlit = true

		t.FontSize = 2

		t:SetParent(player)

		local cancelOrder = function()
			order = nil
			t:SetParent(nil)
			local config = { onDone = function() World:RemoveChild(player) end }
			ease:inSine(player, 0.5).Rotation = {0, math.rad(270), 0}
			ease:inSine(player, 2, config).Position = endPos

			table.remove(queue, 1)
			for i=1, #queue do
				queue[i].client:updatePosition()
			end
		end

		local updatePos = function()
			placed = false
			player.Rotation.Y = math.rad(270)
			local config = {onDone = function()
				placed = true
				if player.Position == positions[1] then
					t.LocalPosition = { 0, 30, 10 }
					t.LocalRotation.Y = math.rad(180)

					ease:inSine(player, 0.5).Rotation = {0, 0, 0}
					box.Physics = PhysicsMode.Trigger
					time = 2
				else
					t.LocalPosition = {10, 30, 0 }
					t.LocalRotation.Y = math.rad(270)
					time = 1
				end

				player.Tick = function(o, dt)
					happiness = happiness - ((time + waves + reduceDelayNeighbor/2) * 0.2) * dt
					t.Text = math.floor(happiness) .. "/100 😛"

					if happiness < 0 then
						t.Text = "0/100 😛"
						if player.pos == 1 and placed == true and gone == false then
							reputation = reputation - 10
							cancelOrder()
							player.Tick = nil
						end
					end
				end
				--disabled = false
			end}
			ease:inSine(player, 2, config).Position = positions[player.pos]
		end

		updatePos()
		--disabled = true

		player.updatePosition = function()
			player.pos = player.pos - 1
			--disabled = true

			updatePos()
		end

		player.updateOrder = function(o, f)
			for i=1, #order do
				if order[i].name == f then
					total = total + order[i].sell
					table.remove(order, i)

					local child = player:GetChild(i + 3)
					child:SetParent(nil)
					child = nil
					
					--player:GetChild(child).IsHidden = true

					for u=i + 3, player.ChildrenCount do
						player:GetChild(u).LocalPosition.Y = player:GetChild(u).LocalPosition.Y - 8
					end

					if #order == 0 then
						waves = waves + 0.005
						order = nil
						gone = true

						local tip = math.floor(happiness)/10 + math.floor(total/4)
						local money = total + tip

						local v = Text()

						v.Text = "+" .. money .. " 💰"
						v.Type = TextType.World
						v.IsUnlit = true
						v.BackgroundColor = Color(0,0,0,0)

						v.FontSize = 2

						v:SetParent(World)
						v.Position = t.Position
						v.Rotation.Y = math.rad(180)

						v.Tick = function(o, dt)
							v.Position.Y = v.Position.Y + 4 * dt
						end

						Timer(2, function() World:RemoveChild(v) end)

						coins = coins + money
						reputation = reputation + math.floor((happiness - 50)/10)

						t:SetParent(nil)
						local config = { onDone = function() World:RemoveChild(player) player = nil end }
						ease:inSine(player, 0.5).Rotation = {0, math.rad(270), 0}
						ease:inSine(player, 2, config).Position = endPos

						table.remove(queue, 1)
						for i=1, #queue do
							queue[i].client:updatePosition()
						end
					end
					break
					return
				elseif f == "pizza" then
					happiness = happiness + 50 <= 100 and happiness + 50 or 100+1
					return
				end
			end
		end

		local spawnBurger = function()
			local o = Shape(burger)
			o.LocalPosition = Number3(-3, 35 + (player.ChildrenCount - 3) * 8, -3)
			player:AddChild(o)
			o.Physics = PhysicsMode.Disabled
		end

		local spawnHotdog = function()
			local o = Shape(hotdog)
			o.LocalPosition = Number3(-1, 35 + (player.ChildrenCount - 3) * 8, -5)
			player:AddChild(o)
			o.Physics = PhysicsMode.Disabled
		end

		local spawnChicken = function()
			local o = Shape(cookedChicken)
			o.LocalPosition = Number3(-1, 35 + (player.ChildrenCount - 3) * 8, -5)
			player:AddChild(o)
			o.Physics = PhysicsMode.Disabled
		end

		local spawnBeef = function()
			local o = Shape(cookedBeef)
			o.LocalPosition = Number3(-1, 35 + (player.ChildrenCount - 3) * 8, -5)
			player:AddChild(o)
			o.Physics = PhysicsMode.Disabled
		end

		for i=1, #order do
			if order[i].name == "burger" then
				spawnBurger()
			elseif order[i].name == "hotdog" then
				spawnHotdog()
			elseif order[i].name == "cookedChicken3" then
				spawnChicken()
			elseif order[i].name == "cookedBeef4" then
				spawnBeef()
			end
		end
	end

	updatePizzas = function(nb)
		for i=1, nb do
			local p = Shape(pizza)
			World:AddChild(p)
			p.Scale = 0.15
			p.Physics = PhysicsMode.Static
			p.Position = Number3(25,53.2 + pizzas * 0.45,19)
			p.Pivot = p.Center
			p.Rotation.Y = math.rad(math.random(0, 360))
			pizzas = pizzas + 1
			table.insert(pizzaTable, p)
		end
	end

	updatePizzas(15)

	removePizza = function()
		pizzas = pizzas - 1
		World:RemoveChild(pizzaTable[#pizzaTable])
		table.remove(pizzaTable, #pizzaTable)
	end

	wave = function()
		heat = 0
		waves = waves + 0.2
	end

	openModal = function()
		Pointer:Show()
		UI.Crosshair = false

		if modal.close ~= nil then modal:close() end

		local modalFrame = {}

	    local modal = require("modal")

    	local content = modal:createContent()
		content.closeButton = true
		content.title = "Recipes"
		content.icon = "🔎"

    	local node = ui:createFrame(Color(0, 0, 0, 100))

    	content.node = node

		local frame = ui:createFrame(Color(0, 0, 0,200))
		frame:setParent(node)

		local txt = ui:createText("A", Color.Black)
		txt:setParent(frame)
		txt:hide()

		for i=1, #modalFrameShape do
			local frameRecipe = ui:createFrame(Color(255, 255, 255,255))
			frameRecipe:setParent(frame)

			local shape = ui:createShape(modalFrameShape[i].shape, { spherized = true })
			shape:setParent(frameRecipe)
			shape.object.LocalRotation.X = math.rad(-45)
			shape.object.LocalRotation.Y = math.rad(45)

			local text = ui:createText(modalFrameShape[i].text, Color.Black)
			text.object.Scale = 1.35
			text:setParent(frameRecipe)

			table.insert(modalFrame, {frame=frameRecipe, shape=shape, text=text})

			frameRecipe.onRelease = function()
				modal:close()
				openModalRecipe(i)
			end
		end

    	content.idealReducedContentSize = function(content, width, _)
			width = math.min(width, 500)

			local frameHeight = txt.Height * 5
			frame.Width = width
			frame.Height = width

			for i=1, #modalFrame do
				modalFrame[i].frame.Width = width/2 - margin*2
				modalFrame[i].frame.Height = width/2 - margin*2

				modalFrame[i].text.pos = Number2(modalFrame[i].frame.Width / 2 - modalFrame[i].text.Width / 2,4)

				modalFrame[i].shape.Width = 200
				modalFrame[i].shape.Height = 200

				modalFrame[i].shape.pos = Number2(modalFrame[i].shape.Width/4,0)
			end

			modalFrame[1].frame.pos = Number2(margin, width/2 + margin)
			modalFrame[2].frame.pos = Number2(modalFrame[1].frame.Width + margin*3, width/2 + margin)
			modalFrame[3].frame.pos = Number2(margin, margin)
			modalFrame[4].frame.pos = Number2(modalFrame[1].frame.Width + margin*3, margin)

        	return Number2(width, frame.pos.Y + frame.Height)
    	end

    	local maxWidth = function()
    	    return Screen.Width - theme.modalMargin * 2
    	end

    	local maxHeight = function()
    	    return Screen.Height - 100
    	end

    	local position = function(modal, forceBounce)
    	    local p = Number3(Screen.Width * 0.5 - modal.Width * 0.5, Screen.Height * 0.5 - modal.Height * 0.5, 0)

       	 if not modal.updatedPosition or forceBounce then
        	    modal.LocalPosition = p - { 0, 100, 0 }
        	    modal.updatedPosition = true
      	      ease:outElastic(modal, 0.3).LocalPosition = p
       	 else
         	   ease:cancel(modal)
     	       modal.LocalPosition = p
        	end
    	end

    	modal = modal:create(content, maxWidth, maxHeight, position, ui)

		modal.didClose = function()
			Pointer:Hide()
			UI.Crosshair = true

			modalFrame = nil
		end
	end

	openModalRecipe = function(nb)
		Pointer:Show()
		UI.Crosshair = false

		if modal.close ~= nil then modal:close() end

	    local modal = require("modal")

    	local content = modal:createContent()
		content.closeButton = true
		content.title = modalFrameShape[nb].text
		content.icon = "👁"

    	local node = ui:createFrame(Color(0, 0, 0, 100))

    	content.node = node

		local frame = ui:createFrame(Color(0, 0, 0,200))
		frame:setParent(node)

		local txt = ui:createText("A", Color.Black)
		txt:setParent(frame)
		txt:hide()

		local desc = ui:createText(recipes[nb], Color.White, "big")
		--desc.object.Scale = 1.35
		desc:setParent(frame)

		--local shape = ui:createShape(modalFrameShape[nb].shape, { spherized = true })
		--shape:setParent(frame)
		--shape.Width = 100
		--shape.Height = 100
		--shape.object.LocalRotation.X = math.rad(-45)
		--shape.object.LocalRotation.Y = math.rad(45)

		--local text = ui:createText(modalFrameShape[nb].text, Color.White)
		--text:setParent(frame)

    	content.idealReducedContentSize = function(content, width, _)
			width = math.min(width, 500)

			local frameHeight = txt.Height * 15
			frame.Width = width
			frame.Height = frameHeight

			desc.object.MaxWidth = frame.Width

			desc.pos = Number2(frame.Width/2-desc.Width/2,frame.Height/2-desc.Height/2)

			--shape.pos = Number2(shape.Width/4,shape.Height)

			--text.pos = Number2(margin,frame.Height/2-text.Height/2)

        	return Number2(width, frame.pos.Y + frame.Height)
    	end

    	local maxWidth = function()
    	    return Screen.Width - theme.modalMargin * 2
    	end

    	local maxHeight = function()
    	    return Screen.Height - 100
    	end

    	local position = function(modal, forceBounce)
    	    local p = Number3(Screen.Width * 0.5 - modal.Width * 0.5, Screen.Height * 0.5 - modal.Height * 0.5, 0)

       	 if not modal.updatedPosition or forceBounce then
        	    modal.LocalPosition = p - { 0, 100, 0 }
        	    modal.updatedPosition = true
      	      ease:outElastic(modal, 0.3).LocalPosition = p
       	 else
         	   ease:cancel(modal)
     	       modal.LocalPosition = p
        	end
    	end

    	modal = modal:create(content, maxWidth, maxHeight, position, ui)

		modal.didClose = function()
			Pointer:Hide()
			UI.Crosshair = true
		end
	end
end

Client.OnWorldObjectLoad = function(obj)
	if grills == nil then
		grills = {}
		prices = {0, 20, 250, 1000, 2500}
  	  sfx = require("sfx")
		cardbox = Shape(Items.kooow.cardboard_box_long)
		coins = 0
		heat = 0
	end

	local name = obj.Name

	if string.sub(name, 1, 3) == "bbq" then
		local nb = tonumber(string.sub(name, 5, -1))
		if tonumber(string.sub(name, 5, -1)) == 0 then
			local c = Shape(cardbox)
			World:AddChild(c)
			c.Position = obj.Position
			c.Position.X = c.Position.X - 5.5
			c.Scale = 0.4
			c.price = prices[nb]
			c.Name = "cardbox"
			c.buy = function()
				print(coins, c.price)
				if coins >= c.price then
					coins = coins - c.price
					obj.IsHidden = false
					obj.Physics = PhysicsMode.Static

					World:RemoveChild(c)
				end
			end
			obj.IsHidden = true
			obj.Physics = PhysicsMode.Disabled

			local t = Text()

			t.Text = c.price .. " 💰"
			t.Type = TextType.World
			t.IsUnlit = true

			t.FontSize = 4

			t:SetParent(c)
			t.LocalPosition = { 14, 20, 10 }
		end

		grills[nb] = obj
		obj.Name = "grill"
		obj.cooking = 0
		obj.time = 2.5
		obj:GetChild(1).state = false

		local p = obj:GetChild(1)
		p:GetChild(1).Physics = PhysicsMode.Disabled

		local b1 = Object()
		b1.CollisionBox = Box({0,0,0},{7,0.5,5})
		obj:AddChild(b1)
		b1.LocalPosition = Number3(-7,10,-2.5)
		b1.Name = "box_1"
		b1.pos = Number3(0,0,0)

		local b2 = Object()
		b2.CollisionBox = Box({0,0,0},{7,0.5,5})
		obj:AddChild(b2)
		b2.LocalPosition = Number3(0,10,-2.5)
		b2.Name = "box_2"
		b2.pos = Number3(0,0,0)

		local changeMeat = function(start, finish, name, cook)
			local g = start:GetParent()
			start:SetParent(nil)

			local m = Shape(finish)
			g:AddChild(m)
			m.LocalScale = 0.6
			m.LocalScale.Y = 0.5
			m.LocalPosition = start.LocalPosition
			m.Name = name
			m.cook = cook
		end

		local cook = function(p, dt, n)
			if p.cook == nil then p.cook = 0 end

			p.cook = p.cook + obj.time * dt

			if p.cook >= n[2].state and p.Name == n[1].name then
				changeMeat(p, n[2].obj, n[2].name, n[2].state)
			elseif p.cook >= n[3].state and p.Name == n[2].name then
				changeMeat(p, n[3].obj, n[3].name, n[3].state)
			elseif p.cook >= n[4].state and p.Name == n[3].name then
				changeMeat(p, n[4].obj, n[4].name, n[4].state)
			end
		end

		obj.Tick = function(o, dt)
			if b1:GetChild(1) ~= nil then
				cook(b1:GetChild(1), dt, states[string.sub(b1:GetChild(1).Name, #b1:GetChild(1).Name, -1)])
			else
				b1.Physics = PhysicsMode.Trigger
			end

			if b2:GetChild(1) ~= nil then
				cook(b2:GetChild(1), dt, states[string.sub(b2:GetChild(1).Name, #b2:GetChild(1).Name, -1)])
			else
				b2.Physics = PhysicsMode.Trigger
			end
		end
	elseif name == "fridge" then
		local drawer = obj:GetChild(1)
		drawer.LocalScale = 0.9
		drawer.LocalPosition.Z = drawer.LocalPosition.Z + 3

		local door = obj:GetChild(2)
		door.LocalRotation.Y = 0
		door.state = true

		local box1 = Object()
		box1.CollisionBox = Box({0,0,0},{15,4,20})
		obj:AddChild(box1)
		box1.LocalPosition = Number3(-8,22,-9)
		box1.Name = "takePatty"
		box1.Physics = PhysicsMode.Trigger

		local box2 = Object()
		box2.CollisionBox = Box({0,0,0},{15,4,20})
		obj:AddChild(box2)
		box2.LocalPosition = Number3(-8,27,-9)
		box2.Name = "takeSausage"
		box2.Physics = PhysicsMode.Trigger

		local box3 = Object()
		box3.CollisionBox = Box({0,0,0},{15,4,20})
		obj:AddChild(box3)
		box3.LocalPosition = Number3(-8,17,-9)
		box3.Name = "takeChicken"
		box3.Physics = PhysicsMode.Trigger

		obj.Physics = PhysicsMode.StaticPerBlock

		local t = Text()

		t.Type = TextType.World
		t.IsUnlit = true

		t.FontSize = 4

		t:SetParent(obj)
		t.LocalPosition = { -1, 50, 0 }

		--t.Tick = function(o, dt)
		--	t.Text = "Patties: " .. patties .. "/20"
		--end
	elseif name == "coins" then
		local t = Text()

		t.Type = TextType.World
		t.IsUnlit = true

		t.FontSize = 5

		t:SetParent(obj)
		t.LocalPosition.Y = 30
		obj.Tick = function()
			t.Text = coins .. " 💰"
		end
	elseif name == "computer" then
		local t = Text()

		t.Type = TextType.World
		t.IsUnlit = true

		t.FontSize = 4

		t:SetParent(obj)
		t.LocalPosition.Y = 40
		obj.Tick = function()
			t.Text = "Reputation:\n" .. reputation .. "/100 😬"
		end
	elseif name == "voxels.hotdog" then
		obj.IsHidden = true
	elseif name == "hotdog_bun" then
		for i=1, obj.ChildrenCount do
			obj:GetChild(i).Name = name
		end
	elseif name == "skewers" then
		for i=1, obj.ChildrenCount do
			obj:GetChild(i).Name = name
		end
	elseif name == "hide" then
		obj.IsHidden = true
	elseif name == "first" then
		obj.IsHidden = true
		local dialog = require("dialog")
		local player = Object()
		local skin = require("avatar"):get("boumety")
		skin:SetParent(player)
		player.Scale = 0.5

		local currentDialog = 1
		local tree = {"Welcome to Feed Your Neighborhood!\nYou can click Action1 (spacebar) to skip to the next dialog.",  "Your neighbors will come to ask for food and you need to fulfill their orders.", "Above my head, you can see my happiness bar.", "Once it hits 0, I'm just leaving this place.", "If it's high enough I'll leave a tip.","BuT if it is too low I'll remove reputation points", "Your reputation is on the computer near the dumpster, once it is at 0 you lose.", }
	elseif name == "book" then
		local t = Text()

		t.Type = TextType.World
		t.IsUnlit = true

		t.Text = "Click on the book\nto check the recipes!"
		t.FontSize = 2

		t:SetParent(obj)
		t.LocalRotation.Y = math.rad(180)
		t.LocalPosition = { -1, 10, 0 }
	end
end

Client.Action1 = function()
	Player.Velocity.Y = 100
	print(Camera.Position, Camera.Rotation)
end

Client.Action2 = function()
    local ray = Ray(Camera.Position, Camera.Forward)
    local impact = ray:Cast(nil, Player)

	if impact.Object == nil then return end
	if impact.Distance >= 40 then return end

	local obj = impact.Object
	local name = impact.Object.Name

	if name == "box_1" or name == "box_2" then
		if holding == nil then return end
		if string.sub(holding.Name, 1, 3) ~= "raw" then return end
		local g = obj:GetParent()

		Player:RemoveChild(holding)
		obj:AddChild(holding)
		holding.LocalScale = 0.6
		holding.LocalScale.Y = 0.5

		obj.Physics = PhysicsMode.Disabled

		holding.LocalPosition = obj.pos
		if holding.Name ~= "rawPatty1" then
			holding.LocalPosition.Z = holding.LocalPosition.Z - 1
		end

		holding = nil
	elseif name == "cardbox" then
		obj:buy()
	elseif name == "Lid" then
		local g = obj:GetParent()
		if obj.state == false then
			ease:inSine(obj, 0.2).LocalRotation = { -math.rad(90), obj.LocalRotation.Y, obj.LocalRotation.Z }
			g.time = 5
		else
			ease:outSine(obj, 0.2).LocalRotation = { 0.33, obj.LocalRotation.Y, obj.LocalRotation.Z }
			g.time = 2.5
		end
		obj.state = not obj.state
	elseif name == "Door" then
		if obj.state == false then
			ease:inSine(obj, 0.2).LocalRotation = { obj.LocalRotation.X, 0, obj.LocalRotation.Z }
		else
			ease:outSine(obj, 0.2).LocalRotation = { obj.LocalRotation.X, math.rad(-90), obj.LocalRotation.Z }
		end
		obj.state = not obj.state
	elseif name == "pizza" then
		if holding ~= nil then return end
		removePizza()
		holdItem(pizza)
	elseif name == "skewers" then
		if holding ~= nil then return end

		holdItem(skewer)
	elseif name == "takePatty" then
		if holding == nil then
			holdItem(rawPatty)
		elseif holding.Name == "skewer" then
			unhold()
			holdItem(rawBeef)
		end
	elseif name == "takeSausage" then
		if holding ~= nil then return end

		holdItem(rawSausage)
	elseif name == "takeChicken" then
		if holding.Name ~= "skewer" then return end

		unhold()
		holdItem(rawChicken)
	elseif name == "cookedPatty1" then
		if holding ~= nil then return end
		holdItem(cookedPatty)

		obj:SetParent(nil)
	elseif name == "burntPatty1" then
		if holding ~= nil then return end
		holdItem(burntPatty)

		obj:SetParent(nil)
	elseif name == "cookedSausage2" then
		if holding ~= nil then return end
		holdItem(cookedSausage)

		obj:SetParent(nil)
	elseif name == "burntSausage2" then
		if holding ~= nil then return end
		holdItem(burntSausage)

		obj:SetParent(nil)
	elseif name == "cookedChicken3" then
		if holding ~= nil then return end
		holdItem(cookedChicken)

		obj:SetParent(nil)
	elseif name == "burntChicken3" then
		if holding ~= nil then return end
		holdItem(burntChicken)

		obj:SetParent(nil)
	elseif name == "cookedBeef4" then
		if holding ~= nil then return end
		holdItem(cookedBeef)

		obj:SetParent(nil)
	elseif name == "burntBeef4" then
		if holding ~= nil then return end
		holdItem(burntBeef)

		obj:SetParent(nil)
	elseif name == "burger_bun" then
		if holding.Name ~= "cookedPatty1" then return end

		unhold()
		holdItem(burger)
	elseif name == "hotdog_bun" then
		if holding.Name ~= "cookedSausage2" then return end

		unhold()
		holdItem(hotdog)
	elseif name == "dumpster" then
		if holding == nil then return end
		unhold()
	elseif name == "avatar" then
		if holding == nil then return end
		local a = obj:GetParent()
		a:updateOrder(holding.Name)

		unhold()
	elseif name == "book" then
		openModal()
	end
end

Client.Tick = function(dt)
	if started == false then
		zoomInOut = zoomInOut + dt * 3
		Camera.FOV = 60 + math.sin(zoomInOut) * 2

		Camera.Position.X = -14 + math.sin(zoomInOut) * 1
		Camera.Position.Z = -22 + math.sin(zoomInOut) * 1
		return
	end

	if disabled == true then return end

	reputation = reputation <= 100 and reputation or 100

	if reputation <= 0 then
		reputation = 0
		Dev:CopyToClipboard("My score: " .. coins .. " 💰")
		URL:Open("https://app.cu.bzh/?worldID=d34da963-a4d8-448a-8dd1-db6e363123f0")
	end

	currentNeighbor = currentNeighbor - (reduceDelayNeighbor + waves) * dt

	if currentNeighbor <= 0 then
		currentNeighbor = math.random(delayNeighborMin, delayNeighborMax)
		spawnClient()
	end

	heat = heat + 1.5 * dt
	if heat > 100 then
		wave()
	end
end

Pointer.Click = function(pointerEvent)
	if started == false and rotated == true then
		clickFrame:remove()

		Camera:SetModeFirstPerson(Player, 3.0)
		Pointer:Hide()
		--UI.Crosshair = true

		Camera.LocalPosition.Y = Camera.LocalPosition.Y + 5
    	World:AddChild(Player)
		Player.Position = Number3(12,45,-9)

		started = true
	end
end

Client.OnChat = function(payload) return true end
