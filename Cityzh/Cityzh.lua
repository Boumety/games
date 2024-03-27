Config = {
    Items = {
        "boumety.road1","boumety.road1v2","boumety.road2","boumety.road2v2","boumety.road2v3","boumety.road2v4","boumety.road3","boumety.road3v2","boumety.road3v3","boumety.road3v4","boumety.road4","boumety.road0","boumety.road0v1","boumety.road0v2","boumety.road0v3","boumety.selector","boumety.house1","boumety.block",
    }
}

Client.OnStart = function()
	if Player.Username == "boumety" then Dev:SetGameThumbnail() end
    local ambience = require("ambience") 
    ambience:set(ambience.noon)
    sfx = require("sfx")
    Camera:AddChild(AudioListener)
	ui = require("uikit")
	ease = require("ease")
    modal = require("modal")
    theme = require("uitheme").current

	highlight = Shape(Items.boumety.block)
	highlight.Scale = 5.1
	highlight.PrivateDrawMode = 2

	coinPerHour = 10

	saveCamera = Number3(Map.Width * 0.5, 15, Map.Depth * 0.5) * Map.Scale

	level = 1
	maxLevel = 5

	coin = 0
	maxCoin = 100

	owner = false
	myHouse = nil
	time = nil

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

	bgHouse = ui:createFrame(bgColor)

	inputHouse = ui:createTextInput(Player.Username .. "'s house", "Give a name to your house!")

	textMoney = ui:createText("My money:", Color.White, "big")
	textTotalMoney = ui:createText(coin .. "/" .. maxCoin .. " 💰", Color.White,"big")
	textDescription = ui:createText("")

	inputHouse:setParent(bgHouse)
	textMoney:setParent(bgHouse)
	textTotalMoney:setParent(bgHouse)
	textDescription:setParent(bgHouse)

	bgHouse.Height = Screen.Height - Screen.SafeArea.Top - margin *2
	bgHouse.Width = Screen.Width / 4

	inputHouse.Width = bgHouse.Width - margin*2

	inputHouse.Position = Number2(margin, bgHouse.Height - inputHouse.Height - margin)
	bgHouse.Position = Number2(Screen.Width - bgHouse.Width - margin, margin)

	bgHouse:hide()

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
		ease:linear(Camera, 0.1).Position = {myHouse.Position.X + 2.5, 26, myHouse.Position.Z - 10}
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

	log = function(time,username,action)
		print("[" .. os.date("%c",time) .. " " .. username .. ": " .. action .. "]")
		-- Other stuff later
	end

	-- Can't use because of Cuzbh :(((
	--data = KeyValueStore(Player.UserID)

	world = KeyValueStore("World")

	--world:Set("roads",{{pos=Number3(121,0,128),username="WORLD"},{pos=Number3(121,0,129),username="WORLD"},{pos=Number3(121,0,130),username="WORLD"}, {pos=Number3(121,0,131),username="WORLD"}, {pos=Number3(121,0,132),username="WORLD"}, {pos=Number3(122,0,132),username="WORLD"}, {pos=Number3(123,0,132),username="WORLD"}, {pos=Number3(124,0,132),username="WORLD"}, {pos=Number3(125,0,132),username="WORLD"}, },"houses", {}, function(r,s)
	--end)

	world:Get("roads","houses", function(s,r)
		if s then
			blocks.roads = r.roads
			blocks.houses = r.houses

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
end

Client.Tick = function()
	if time ~= nil then
		if time + 3600 == Time.Unix() then
			time = Time.Unix()
			paid()
		end
	end
end

Pointer.Click = function(pointerEvent)
	local impact = pointerEvent:CastRay()
	if impact.Object.Name ~= nil then
		print(impact.Object.Name)
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
    Camera.Position.X = Camera.Position.X - pointerEvent.DX / (Map.Scale.X*2)
    Camera.Position.Z = Camera.Position.Z - pointerEvent.DY / (Map.Scale.Z*2)
end

Pointer.Zoom = function(zoomValue)
    Camera.Position = Camera.Position + Camera.Forward * 5 * -zoomValue
end

Client.DirectionalPad = nil
Client.Action1 = nil
