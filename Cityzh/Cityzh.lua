Config = {
    Items = {
        "boumety.road1","boumety.road1v2","boumety.road2","boumety.road2v2","boumety.road2v3","boumety.road2v4","boumety.road3","boumety.road3v2","boumety.road3v3","boumety.road3v4","boumety.road4","boumety.road0","boumety.road0v1","boumety.road0v2","boumety.road0v3","boumety.selector","boumety.house1","boumety.block","aduermael.coin","voxels.pezh_ticket",
    }
}

Client.OnStart = function()
	if Player.Username ~= "boumety" then
		URL:Open("https://app.cu.bzh/?worldID=4d194d06-82e2-45b3-a759-557d4b486f11")
	end

	radialMenu = require("radialmenu")
    local ambience = require("ambience") 
    ambience:set(ambience.noon)
    sfx = require("sfx")
    Camera:AddChild(AudioListener)
	local ui = require("uikit")
	ease = require("ease")
    modal = require("modal")
    local theme = require("uitheme").current
	alert = require("alert")

	menu = {
		bank = false,
	}

	highlight = Shape(Items.boumety.block)
	highlight.Scale = 5.1
	highlight.PrivateDrawMode = 2

	saveCamera = Number3(Map.Width * 0.5, 15, Map.Depth * 0.5) * Map.Scale

	maxLevel = 5

	fundings = {}

	time = Time.Unix()
	upgrades = {}
	level = 0
	tickets = 0
	coins = 100

	salary = 10
	maxCoins = 250

	owner = false

	myHouse = nil
	selectedBlock = nil

	--[[
		PLACE_ROAD -> CLAIM_HOUSE <-> CHOICE -> MY_HOUSE
	]]--

	states = {PLACE_ROAD=1,CLAIM_HOUSE=2,CHOICE=3,MY_HOUSE=4,}

	margin = 8

	bgColor = Color(0,0,0,200)

	bgClaim = ui:createFrame(bgColor)

	bgClaim.loading = false

	frameLoadClaim = ui:createFrame(Color.Green)

	textClaim = ui:createText("Build my house here 🏗", Color.White, "big")

	frameLoadClaim:setParent(bgClaim)
	textClaim:setParent(bgClaim)

	bgClaim.Width = textClaim.Width + margin*2
	bgClaim.Height = textClaim.Height + margin*2

	bgClaim.pos = Number2(Screen.Width / 2 - bgClaim.Width / 2, Screen.Height / 4 - bgClaim.Height / 2)
	textClaim.pos = Number2(margin, margin)

	frameLoadClaim.Height = bgClaim.Height

	bgClaim.object.Tick = function(o, dt)
		if bgClaim.loading == true then
			frameLoadClaim.Width = frameLoadClaim.Width + dt * 250
			if frameLoadClaim.Width >= bgClaim.Width then
				frameLoadClaim.Width = bgClaim.Width

				owner = true

				bgClaim.onPress = nil
				bgClaim.onRelease = nil
				bgClaim.object.Tick = nil

				bgClaim:remove()

				world:Get("houses", function(s,r)
					if s then
						local t = r.houses
						table.insert(t, {pos = selectedBlock.Coordinates, level = level, username = Player.Username})
						blocks.houses = t
						world:Set("houses",t, function(s)
							if s then
								currentState = states.CLAIM_HOUSE
								loadHouses()

								log(Time.Unix(),Player.Username,"Build its house at the position: " .. "[ X: " .. myHouse.Position.X .. " Y: " .. myHouse.Position.Y .. " Z: " .. myHouse.Position.Z .. " ]")

				--textDescription.Text = "Position: " .. "[ X: " .. myHouse.block.Position.X .. " Y: " .. myHouse.block.Position.Y .. " Z: " .. myHouse.block.Position.Z .. " ]" .. "\n" .. "Level: " .. level .. maxLevel, Color.White,"big"


							else
								error("Failed to load the world, please retry.")
							end
						end)
					else
						error("Failed to load the world, please retry.")
					end
				end)

				time = Time.Unix()

				World:RemoveChild(highlight)

				selectedBlock.Color = Color.Red

				for i=#blocks.free,1,-1 do
					Map:GetBlock(blocks.free[i]).Color = Color.Grey
				end
			end
		elseif frameLoadClaim.Width ~= nil then
			if frameLoadClaim.Width > 0 then
				frameLoadClaim.Width = frameLoadClaim.Width - dt * 100
			end
		end
	end

	bgClaim.onPress = function()
		bgClaim.loading = true
	end

	bgClaim.onRelease = function()
		bgClaim.loading = false
	end

	bgClaim:hide()

	home = ui:createButton("Home 🏠", { textSize = "default" })
	bank = ui:createButton("Bank 💰", { textSize = "default" })
	fund = ui:createButton("Fund 🏗", { textSize = "default" })
	vote = ui:createButton("Vote ✉️", { textSize = "default" })

	home.parentDidResize = function()
		home.pos = Number2(margin, Screen.Height - Screen.SafeArea.Top - home.Height - margin)
		bank.pos = Number2(margin, Screen.Height - Screen.SafeArea.Top - bank.Height * 2 - margin * 2)

		fund.pos = Number2(Screen.Width - fund.Width - margin, Screen.Height - Screen.SafeArea.Top - fund.Height - margin)
		vote.pos = Number2(Screen.Width - fund.Width - margin, Screen.Height - Screen.SafeArea.Top - fund.Height*2 - margin*2)
	end

	home:parentDidResize()

	home.onRelease = function()
		if myHouse == nil then return end
		createHouseInformations(myHouse)

		ease:linear(Camera, 0.1).Position = {myHouse.Position.X + 2.5, 26, myHouse.Position.Z - 10}
	end

	bank.onRelease = function()
		createMenuBank()
	end

	fund.onRelease = function()
		createMenuFund()
	end

	Camera:SetModeFree()
	Camera.Position = saveCamera
	Camera.Rotation.X = math.rad(60)

    blocks = {
        roads = {},
		houses = {},
		free = {},
    }

    roads = {}

	paid = function()
		coin = coin + moneyPerHour
	end

	loadHouses = function()
		for i=#blocks.houses,1,-1 do
			local house = Shape(Items.boumety.house1)
			World:AddChild(house)
			house.Scale = 0.25
			house.Position = Map:GetBlock(blocks.houses[i].pos).Position
			house.Position.Y = 5
			house.level = blocks.houses[i].level
			house.Name = blocks.houses[i].username .. "'s house"

			if blocks.houses[i].username == Player.Username then
				myHouse = house

				owner = true
			end
		end
	end

	loadRoads = function()
		for i=#roads,1,-1 do
			World:RemoveChild(roads[i])
		end

		roads = {}

		for i=#blocks.roads,1,-1 do
			Map:GetBlock(blocks.roads[i].pos).Color = Color.Brown
		end

		for i=#blocks.roads,1,-1 do
			local road = Object()

			local pos1 = Number3(blocks.roads[i].pos.X,blocks.roads[i].pos.Y,blocks.roads[i].pos.Z + 1)
			local pos2 = Number3(blocks.roads[i].pos.X,blocks.roads[i].pos.Y,blocks.roads[i].pos.Z - 1)
			local pos3 = Number3(blocks.roads[i].pos.X + 1,blocks.roads[i].pos.Y,blocks.roads[i].pos.Z)
			local pos4 = Number3(blocks.roads[i].pos.X - 1,blocks.roads[i].pos.Y,blocks.roads[i].pos.Z)

			if Map:GetBlock(pos1).Color == Color.Brown then
				road.right = true
			elseif Map:GetBlock(pos1).Color ~= Color.Red then
				Map:GetBlock(pos1).Color = Color.Blue
				table.insert(blocks.free, pos1)
			end

			if Map:GetBlock(pos2).Color == Color.Brown then
				road.left = true
			elseif Map:GetBlock(pos2).Color ~= Color.Red then
				Map:GetBlock(pos2).Color = Color.Blue
				table.insert(blocks.free, pos2)
			end

			if Map:GetBlock(pos3).Color == Color.Brown then
				road.up = true
			elseif Map:GetBlock(pos3).Color ~= Color.Red then
				Map:GetBlock(pos3).Color = Color.Blue
				table.insert(blocks.free, pos3)
			end

			if Map:GetBlock(pos4).Color == Color.Brown then
				road.down = true
			elseif Map:GetBlock(pos4).Color ~= Color.Red then
				Map:GetBlock(pos4).Color = Color.Blue
				table.insert(blocks.free, pos4)
			end

			if road.right == true and road.left == true and road.up == true and road.down == true then
				road = Shape(Items.boumety.road4)

			elseif road.right == true and road.left == true and road.up == true and road.down == nil then
				road = Shape(Items.boumety.road3v4)
			elseif road.right == true and road.left == true and road.up == nil and road.down == true then
				road = Shape(Items.boumety.road3v2)
			elseif road.right == true and road.left == nil and road.up == true and road.down == true then
				road = Shape(Items.boumety.road3)
			elseif road.right == nil and road.left == true and road.up == true and road.down == true then
				road = Shape(Items.boumety.road3v3)
			elseif road.right == true and road.left == nil and road.up == nil and road.down == true then
		
				road = Shape(Items.boumety.road2v2)
			elseif road.right == true and road.left == nil and road.up == true and road.down == nil then
				road = Shape(Items.boumety.road2)
			elseif road.right == nil and road.left == true and road.up == nil and road.down == true then
				road = Shape(Items.boumety.road2v3)
			elseif road.right == nil and road.left == true and road.up == true and road.down == nil then
				road = Shape(Items.boumety.road2v4)

			elseif road.right == true and road.left == true then
				road = Shape(Items.boumety.road1)
			elseif road.up == true and road.down == true then
				road = Shape(Items.boumety.road1v2)

			elseif road.up == true then
				road = Shape(Items.boumety.road0v1)
			elseif road.down == true then
				road = Shape(Items.boumety.road0v3)
			elseif road.right == true then
				road = Shape(Items.boumety.road0v2)
			elseif road.left == true  then
				road = Shape(Items.boumety.road0)
			end

			road.Physics = PhysicsMode.Disabled
			World:AddChild(road)
			road.Scale = 0.125
			road.Position = Map:GetBlock(blocks.roads[i].pos).Position
			road.Position.Y = 5

            table.insert(roads, road)
		end
	end

	world = KeyValueStore("World")
	data = KeyValueStore(Player.UserID)

	log = function(time,username,action)
		--print("[" .. os.date("%c",time) .. " " .. username .. ": " .. action .. "]")
		world:Get("logs", function(s,r)
			if s then
				local t = r.logs
				table.insert(t, "[" .. os.date("%c",time) .. " " .. username .. ": " .. action .. "]")
				world:Set("logs", t, function(s) end)
			end
		end)
	end


	-- RESET DATA

	--world:Set("roads",{{pos=Number3(121,0,128),username="WORLD"},{pos=Number3(121,0,129),username="WORLD"},{pos=Number3(121,0,130),username="WORLD"}, {pos=Number3(121,0,131),username="WORLD"}, {pos=Number3(121,0,132),username="WORLD"}, {pos=Number3(122,0,132),username="WORLD"}, {pos=Number3(123,0,132),username="WORLD"}, {pos=Number3(124,0,132),username="WORLD"}, {pos=Number3(125,0,132),username="WORLD"}, },"houses", {}, "logs", {}, function(r,s)
	--end)

	--world:Set("news", {}, "money", 0, "votes", {}, "funds", {}, function(r,s)
	--end)

	--[[data:Get("coins","tickets","upgrades","time", function(s,r)
		if s then
			if r.coins == nil then
				data:Set("coins", coins, "tickets", tickets, "upgrades", {}, "time", Time.Unix(), function(s) end)
			else
				coins = r.coins
				tickets = r.tickets
				upgrades = r.upgrades
				time = r.time
			end
		end
	end)]]

	world:Get("roads","houses","funds", function(s,r)
		if s then
			blocks.roads = r.roads
			blocks.houses = r.houses
			fundings = r.funds

			loadHouses()
			loadRoads()
			
			--states = {PLACE_ROAD=1,CLAIM_HOUSE=2,CHOICE=3,MY_HOUSE=4,}

			currentState = states.PLACE_ROAD

			for i=#blocks.roads,1,-1 do
				if blocks.roads[i].username == Player.Username then
					currentState = states.CLAIM_HOUSE
					for i=#blocks.houses,1,-1 do
						if blocks.houses[i].username == Player.Username then
							currentState = states.MY_HOUSE
							break
						end
					end
					break
				end
			end
		else
			error("Failed to load the world, please retry.")
		end
	end)

	createMenuDetail = function(id)
		if modal.close ~= nil then modal:close() end

		modal = require("modal")
    	local content = modal:createContent()
		content.closeButton = true
		content.title = fundings[id].title
		content.icon = "👁"

    	local node = ui:createFrame(Color(0, 0, 0))

    	content.node = node

		local text = ui:createText("A", Color(0,0,0,0),"big")

		local detailFrame = ui:createFrame(theme.gridCellColor)
		detailFrame:setParent(node)
	
		local detailText = ui:createText(fundings[id].desc, Color.White, "small")
		detailText:setParent(detailFrame)

		local maxText = ui:createText(fundings[id].money .. "/" .. fundings[id].max .. " 💰", Color.White, "default")
		maxText:setParent(detailFrame)

		local detailButton = ui:createButton("💰")
		detailButton:setParent(detailFrame)

		local detailInput = ui:createTextInput("","Put an amount of coins here.")
		detailInput:setParent(detailFrame)

		detailButton.onRelease = function()
			local amount = detailInput:_text()
			detailInput.Text = ""
			if fundings[id].max == fundings[id].money then alert:create("Sorry, but the project has already been fund") return end
			if amount == "" then alert:create("You need to enter a number.") return end
			if type(amount) == "integer" then alert:create("You need to enter a integer.") return end
			if tonumber(amount) > coins then alert:create("You don't have enough coins.") return end

			amount = tonumber(amount)

			world:Get("funds", function(s,r)
				if s then
					local t = r.funds
					local myFund = t[id]
					if myFund.money >= myFund.max then
						alert:create("Sorry, but the project has already been fund")
						maxText.Text = myFund.money .. "/" .. myFund.max .. " 💰"
						return
					end

					if amount > myFund.max - myFund.money then
						amount = myFund.max - myFund.money
					end

					coins = coins - amount
					t[id].money = t[id].money + amount
					maxText.Text = t[id].money .. "/" .. myFund.max .. " 💰"
					world:Set("funds", t, function(s)
						if s then
							fundings = t
						else
							alert:create("Sorry, an error occured. You didn't lost any coins.")
							coins = coins + amount
						end
					end)
				end
			end)
		end

    	content.idealReducedContentSize = function(content, width, _)
			width = math.min(width, 500)

			local detailFrameHeight = text.Height * 5
			detailFrame.Width = width
			detailFrame.Height = detailFrameHeight

			detailText.object.MaxWidth = detailFrame.Width
			detailText.pos.Y = detailFrame.Height - detailText.Height

			detailInput.Height = detailButton.Height
			detailInput.Width = detailFrame.Width - detailButton.Width

			detailButton.pos.X = detailFrame.Width - detailButton.Width

			maxText.pos = Number2(detailFrame.Width / 2 - maxText.Width / 2, detailInput.Height)

        	return Number2(width, detailFrame.pos.Y + detailFrame.Height)
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
	end

	createMenuBank = function()
		if modal.close ~= nil then modal:close() end

		modal = require("modal")
    	local content = modal:createContent()
		content.closeButton = true
		content.title = "My bank account"
		content.icon = "💰"

    	local node = ui:createFrame(Color(0, 0, 0))

    	content.node = node

		local coinsFrame = ui:createFrame(theme.gridCellColor)
		coinsFrame:setParent(node)
	
		local coinsText = ui:createText(coins .. "/" .. maxCoins, Color.White, "big")
		coinsText:setParent(coinsFrame)
	
		local ticketText = ui:createText(tickets, Color.White, "big")
		ticketText:setParent(coinsFrame)

		local salaryText = ui:createText(salary .. " 💰/hrs", Color.White, "default")
		salaryText:setParent(coinsFrame)

		local shape = Shape(Items.aduermael.coin)
		shape.Tick = function(o, dt)
			o.LocalRotation.Y = o.LocalRotation.Y + dt * 2
		end

		local coinShape = ui:createShape(shape, { spherized = true })
		coinShape:setParent(coinsFrame)

		local shapeTicket = Shape(Items.voxels.pezh_ticket)

		local ticketShape = ui:createShape(shapeTicket, { spherized = true })
		ticketShape:setParent(coinsFrame)

		ticketShape.object.Tick = function(o, dt)
			if ticketShape.pivot.LocalRotation.Y == nil then return end
			ticketShape.pivot.LocalRotation.Y = ticketShape.pivot.LocalRotation.Y + dt * 2
		end

    	content.idealReducedContentSize = function(content, width, _)
			width = math.min(width, 500)

			local coinsFrameHeight = coinsText.Height * 5
			coinsFrame.Width = width
			coinsFrame.Height = coinsFrameHeight

			coinShape.object.Scale = 4
			ticketShape.object.Scale = 4

			coinsText.pos = Number2(coinsFrame.Width / 2 - coinsText.Width / 2 - coinShape.Width / 2, coinsFrame.Height * 0.75 - coinsText.Height / 2)
			coinShape.pos = Number2(coinsText.pos.X + coinsText.Width + margin,coinsText.pos.Y - coinsText.Height / 2)

			ticketText.pos = Number2(coinsFrame.Width / 2 - ticketText.Width / 2 - ticketShape.Width / 2, coinsText.pos.Y - coinsText.Height - margin*2)
			ticketShape.pos = Number2(ticketText.pos.X + ticketText.Width + margin,ticketText.pos.Y - ticketText.Height / 2)

			salaryText.pos = Number2(coinsFrame.Width / 2 - salaryText.Width / 2, margin)

        	return Number2(width, coinsFrame.pos.Y + coinsFrame.Height)
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
	end

	createMenuFund = function()
		if modal.close ~= nil then modal:close() end

		modal = require("modal")
    	local content = modal:createContent()
		content.closeButton = true
		content.title = "Fundings"
		content.icon = "📘"

    	local node = ui:createFrame(theme.gridCellColor)

    	content.node = node

		local text = ui:createText("A", Color(0,0,0,0))

		local frames = {}

		for i=#fundings,1,-1 do
			local frame = ui:createFrame(Color.Grey)
			frame:setParent(node)

			local title = ui:createText(fundings[i].title, Color.Black, "big")
			title:setParent(frame)

			frame.onRelease = function()
				createMenuDetail(i)
			end

			table.insert(frames, {frame = frame, title = title})
		end

    	content.idealReducedContentSize = function(_, width, height, minWidth)
			width = math.min(width, 500)
			width = math.max(minWidth, width)

			maxHeight = height / 10 - text.Height / 2 

			local y = height - maxHeight

			for i=#frames,1,-1 do
				frames[i].frame.Width = width
				frames[i].frame.Height = maxHeight
				frames[i].frame.pos.Y = y

				frames[i].title.pos.X = frames[i].frame.Width / 2 - frames[i].title.Width / 2
				frames[i].title.pos.Y = frames[i].frame.Height / 2 - frames[i].title.Height / 2
				y = y - maxHeight - text.Height / 2
			end

			return Number2(width, height)
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
	end

	createHouseInformations = function(o)
		local config = 
		{
        	target = o,
        	offset = { 10, 0, 0 },
        	nodes =
			{
				{type = "text",text = o.Name,angle = 90,radius = 250,onRelease = function() end,tick = function(o, dt) end,onMenuOpen = function(o) end,},
			}
		}

		houseInformations = radialMenu:create(config)
	end

	-- Functions that only the dev (boumety) can use --

	--[[

		config = {
			title =
			desc =
			max =
			money = 0
		}

	]]--

	addFunding = function(config)
		if Player.Username ~= "boumety" then return end
		world:Get("funds", function(s,r)
			if s then
				local t = r.funds
				table.insert(t, config)
				world:Set("funds", t, function(s) end)
			end
		end)
	end

	--addFunding({title = "Build a school", desc = "Create a school somewhere in the city to allow the inhabitants to learn.", max = 1000, money = 0})

	--[[

		config = {
			title =
			desc =
			time =
			reward =
		}

	]]--

	addVote = function(config)
		if Player.Username ~= "boumety" then return end
		world:Get("votes", function(s,r)
			if s then
				local t = r.votes
				table.insert(t, config)
				world:Set("votes", t, function(s) end)
			end
		end)
	end
end

Client.Tick = function()
end

Pointer.Click = function(pointerEvent)
	local impact = pointerEvent:CastRay()

	if houseInformations ~= nil then houseInformations = radialMenu:remove() end

	if impact.Object.Name ~= nil then
		createHouseInformations(impact.Object)

		ease:linear(Camera, 0.1).Position = {impact.Object.Position.X + 2.5, 26, impact.Object.Position.Z - 10}
	end

	if impact.Block ~= nil then
		if currentState == states.PLACE_ROAD then
			world:Get("roads", function(s,r)
				if s then
					local t = r.roads
					table.insert(t, {pos=impact.Block.Coordinates, username = Player.Username})
					blocks.roads = t
					world:Set("roads",t, function(s)
						if s then
							log(Time.Unix(),Player.Username,"Place its road at the coordinates: " .. "[ X: " .. impact.Block.Coordinates.X .. " Y: " .. impact.Block.Coordinates.Y .. " Z: " .. impact.Block.Coordinates.Z .. " ]")
							currentState = states.CLAIM_HOUSE
							loadRoads()
						else
							error("Failed to load the world, please retry.")
						end
					end)
				else
					error("Failed to load the world, please retry.")
				end
			end)
		elseif currentState == states.CLAIM_HOUSE and owner == false then
			if impact.Block.Color == Color.Blue then
				currentState = states.CHOICE

				selectedBlock = impact.Block

				frameLoadClaim.Width = 0
				bgClaim:show()

				World:AddChild(highlight)
				highlight.Position = impact.Block.Position
				highlight.Position.Y = 2.5
				highlight.Position.X = highlight.Position.X + 2.5
				highlight.Position.Z = highlight.Position.Z + 2.5
				highlight.Palette[1].Color = impact.Block.Color
			end
		elseif currentState == states.CHOICE then
			if impact.Block.Color == Color.Blue then
				selectedBlock = impact.Block

				frameLoadClaim.Width = 0

				highlight.Position = impact.Block.Position
				highlight.Position.Y = 2.5
				highlight.Position.X = highlight.Position.X + 2.5
				highlight.Position.Z = highlight.Position.Z + 2.5
			else
				World:RemoveChild(highlight)

				currentState = states.CLAIM_HOUSE
				bgClaim:hide()
			end
		end
	end
end

Pointer.Drag = function(pointerEvent)
	if houseInformations ~= nil then houseInformations = radialMenu:remove() end
    Camera.Position.X = Camera.Position.X - pointerEvent.DX / (Map.Scale.X*2)
    Camera.Position.Z = Camera.Position.Z - pointerEvent.DY / (Map.Scale.Z*2)
end

Pointer.Zoom = function(zoomValue)
	if houseInformations ~= nil then houseInformations = radialMenu:remove() end
    Camera.Position = Camera.Position + Camera.Forward * 5 * -zoomValue
end

Client.DirectionalPad = nil
Client.Action1 = nil
