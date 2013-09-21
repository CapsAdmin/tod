AddCSLuaFile()
AddCSLuaFile("autorun/client/materials.lua")

tod = {}

tod.Params = {}
tod.CurrentParams = {}

local P = tod.Params
local C = tod.CurrentParams

-- sky paint	
local function GetSky()
	local ent = ents.FindByClass("env_skypaint")[1] or NULL
	
	if not ent:IsValid() then
		ent = ents.Create("env_skypaint")
		ent:Spawn()
		ent:Activate()
							
		ent:SetKeyValue("sunposmethod", "0")
		ent:SetKeyValue("drawstars", "1")
		ent:SetKeyValue("startexture", "skybox/starfield")
	
		RunConsoleCommand("sv_skyname", "painted")
	end		
	return ent
end
	
local function ADD_SKY_KEYVALUE(name, default)
	if CLIENT then
		P["sky_" .. name] = default
	end
	if SERVER then
		local type = type(default)
		if type == "Vector" then
			P["sky_" .. name] = function(val) GetSky():SetKeyValue(name, val.x .. " " .. val.y .. " " .. val.z) end
		elseif type == "number" then
			P["sky_" .. name] = function(val) GetSky():SetKeyValue(name, val) end
		end
	end
end

ADD_SKY_KEYVALUE("topcolor", Vector(0.2, 0.5, 1))--
ADD_SKY_KEYVALUE("bottomcolor", Vector(0.8, 1, 1))
ADD_SKY_KEYVALUE("fadebias", 1)
ADD_SKY_KEYVALUE("sunsize", 2)
ADD_SKY_KEYVALUE("suncolor", Vector(0.2, 0.1, 0))
ADD_SKY_KEYVALUE("duskscale", 1)
ADD_SKY_KEYVALUE("duskintensity", 1)
ADD_SKY_KEYVALUE("duskcolor", Vector(1, 0.2, 0))
ADD_SKY_KEYVALUE("starscale", 0.2)
ADD_SKY_KEYVALUE("starfade", 1)
ADD_SKY_KEYVALUE("starspeed", 0.01)
ADD_SKY_KEYVALUE("hdrscale", 0.66)

RunConsoleCommand("sv_skyname", "painted")

if SERVER then
	hook.Add("InitPostEntity","tod",function()
		GetSky()
		hook.Remove("InitPostEntity", "tod")
	end)
end

if CLIENT then
	P.bloom_darken = 0
	P.bloom_multiply = 0
	P.bloom_width = 1
	P.bloom_height = 1
	P.bloom_passes = 1
	P.bloom_saturation = 1
	P.bloom_color = Vector(1, 1, 1)

	P.color_add = Vector(0, 0, 0)
	P.color_multiply = Vector(0, 0, 0)
	P.color_brightness = 0
	P.color_contrast = 1
	P.color_saturation = 1
	
	P.sharpen_contrast = 0
	P.sharpen_distance = 0
	
	P.star_intensity = 0
	P.moon_size = 1
	P.moon_angles = Angle(0,0,0)
	
	P.fog_color = Vector(1,1,1)
	P.fog_start = 0
	P.fog_end = 32000
	P.fog_max_density = 1
	
	P.sun_angles = Angle(0,0,0)
	
	P.shadow_color = Vector(0,0,0)
	P.shadow_angles = Angle(0,0,0)
	
	P.world_light_multiplier = 0.5
end

if SERVER then
	
	P.sun_angles = function(val)	
		local ent = ents.FindByClass("env_sun")[1] or NULL
		
		local n = -val:Forward()
		GetSky():SetKeyValue("sunnormal", n.x .. " " .. n.y .. " " .. n.z)
		
		do 
			local ent = ents.FindByClass("shadow_control")[1] or NULL
			
			if ent:IsValid() then	
				ent:Fire("SetAngles", math.Round(val.p).." "..math.Round(val.y).." "..math.Round(val.r))
				
				local fade = (val.p/180)
				ent:Fire("SetDistance", fade * 70)
				if fade > 0 then
					ent:Fire("SetShadowsDisabled", "0")
				else
					ent:Fire("SetShadowsDisabled", "1")
				end
			end		
		end
		
		if ent:IsValid() then
			timer.Create("tod_sun_angles_hack", 0, 2, function()
				ent:SetAngles(val)
				ent:Fire("addoutput", "pitch " .. -val.p)
				ent:Activate()
			end)
		end
	end

	P.shadow_color = function(val)
		local ent = ents.FindByClass("shadow_control")[1] or NULL
		
		if ent:IsValid() then
			ent:Fire("color", math.Round(val.x).." "..math.Round(val.y).." "..math.Round(val.z))
		end
	end

	P.world_light_multiplier = function(val)
		local ent = ents.FindByClass("light_environment")[1] or NULL
		
		if ent:IsValid() then
			ent:Fire("SetPattern", string.char(math.Round(math.Clamp(64+(val * 64), 64, 127))))
		end
	end
end

if CLIENT then
	do -- stars	and moon
		tod.moon_ent = NULL
		
		do		
			local earth = Material("models/props_wasteland/rockcliff02c")
			local atmosphere = Material("models/props/de_tides/clouds")
			local atmosphere_outter = Material("models/debug/debugwhite")

			local render = render
			local SetMaterialOverride = function(m) 
				if _G.net then 
					render.MaterialOverride(m == 0 and nil or m) 
				else 
					SetMaterialOverride(m) 
				end
			end
			
			local render_SetColorModulation = render.SetColorModulation
			local render_SetBlend = render.SetBlend
			local render_MaterialOverride = render.MaterialOverride
			local math_Rand = math.Rand
			
			function tod.MoonRender(self)
				local normal_scale = C.moon_size * 40
				
				local fraction = 1
				local ply = LocalPlayer()
				
				if ply:GetAimVector():DotProduct((self:GetPos() - ply:EyePos()):GetNormalized()) > 0.999 then
					fraction = ply:GetFOV() / 5
					fraction = fraction ^ 20
				end
			
				--render.SuppressEngineLighting( true )
					--render.SetAmbientLight( 1, 1, 1)
					
						local rand = math_Rand(1, 100)
						render_SetColorModulation(rand, rand, rand)
						render_SetBlend(1)
						render_MaterialOverride(0)
						self:SetModelScale(normal_scale, 0)
						self:DrawModel()
						
						render_SetColorModulation(0.7, 0.8, 0.9)
						render_SetBlend(fraction)
						render_MaterialOverride(earth) 
						self:SetModelScale(normal_scale, 0) 
						self:DrawModel()
					
						render_SetColorModulation( 1,1,1 )
						render_SetBlend(0.5)
						render_MaterialOverride(atmosphere)
						self:SetModelScale(normal_scale, 0)
						self:DrawModel()
												
						render_SetColorModulation( 3.5,3.6,3.9 )
						render_SetBlend(fraction)
						render_MaterialOverride(atmosphere) 
						self:SetModelScale(normal_scale * 1.1, 0) 
						self:DrawModel()
												
						render_SetColorModulation(1, 1, 1)
						render_SetBlend(1)
						render_MaterialOverride(0)
					--render.SetAmbientLight( 1, 1, 1)
				--render.SuppressEngineLighting( false )
			
				if fraction < 0.2 then
					LocalPlayer():SetDSP(23)
					for i=1, 4 do
						LocalPlayer():EmitSound("weapons/explode"..math.random(3, 5)..".wav", 0, math.random(4))
					end
					timer.Create("tod_moon_sound", 0.25, 1, function()
						LocalPlayer():SetDSP(0)
						if _G.net then 
							LocalPlayer():ConCommand("stopsound")
						else
							LocalPlayer():ConCommand("stopsounds")
						end
					end)
				end
			end
			
			function tod.InitializeSky()				
				local origin = vector_origin
				local angles = vector_origin
				
				hook.Add("RenderScene", "tod_moon", function(pos, ang) origin = pos angles = ang end)
				
				local render_DrawSprite = render.DrawSprite
				local render_SetMaterial = render.SetMaterial
				local cam_Start3D = cam.Start3D
				local cam_End3D = cam.End3D
				
				hook.Add("PostDrawSkyBox", "tod_moon", function()
					if tod.moon_ent:IsValid() then
						local pos = origin + C.moon_angles:Forward() * -8000
						tod.moon_ent:SetPos(pos)
						tod.moon_ent:SetAngles((pos - origin):Angle() + Angle(-90,0,180))
						tod.MoonRender(tod.moon_ent)
					else
						timer.Simple(0.1, function() 
							local ent = ents.CreateClientProp()

							ent:SetModel("models/dav0r/hoverball.mdl")
							ent:SetMaterial("models/gman/gman_face_map3")
							ent:SetPos(origin)
							ent:SetColor(170,190,255,255)
							ent:SetNoDraw(true)

							tod.moon_ent = ent
						end)
					end
				end)
			end
			
			if LocalPlayer():IsValid() then
				tod.InitializeSky()	
			end
				
			hook.Add("InitPostEntity", "tod_moon", function()
				tod.InitializeSky()	
				hook.Remove("InitPostEntity", "tod_moon")
			end)
		end
	end

	local enable = CreateClientConVar("tod_pp", "0")
	local DrawColorModify = DrawColorModify
	
	hook.Add("RenderScreenspaceEffects", "tod_pp", function()	
				
		if not enable:GetBool() then return end
		
		-- hack
		-- DrawColorModify may exist after this script is ran
		DrawColorModify = DrawColorModify or _G.DrawColorModify 
		
		if 
			C.sharpen_contrast ~= 0 or
			C.sharpen_distance ~= 0
		then
			DrawSharpen(
				C.sharpen_contrast,
				C.sharpen_distance		
			)
		end
		
		if 
			C.color_add ~= vector_origin or
			C.color_multiply ~= vector_origin or
			C.color_brightness ~= 0 or
			C.color_contrast ~= 1 or
			C.color_saturation ~= 1 
		then			
			local params = {}
				params["$pp_colour_addr"] = C.color_multiply.r
				params["$pp_colour_addg"] = C.color_multiply.g
				params["$pp_colour_addb"] = C.color_multiply.b
				params["$pp_colour_brightness"] = C.color_brightness
				params["$pp_colour_contrast"] = C.color_contrast
				params["$pp_colour_colour"] = C.color_saturation
				params["$pp_colour_mulr"] = C.color_add.r
				params["$pp_colour_mulg"] = C.color_add.g
				params["$pp_colour_mulb"] = C.color_add.b
			DrawColorModify(params)
		end
		
		if 
			C.bloom_darken ~= 1 or
			C.bloom_multiply ~= 0
		then			
			DrawBloom(
				C.bloom_darken,
				C.bloom_multiply,
				C.bloom_width,
				C.bloom_height,
				C.bloom_passes,
				C.bloom_saturation,
				C.bloom_color.r,
				C.bloom_color.g,
				C.bloom_color.b
			)
		end
	end)
	
	local function SetupFog()
		render.FogMode(1)
		render.FogStart(C.fog_start)
		render.FogEnd(C.fog_end)
		render.FogColor(C.fog_color.r, C.fog_color.g, C.fog_color.b)
		render.FogMaxDensity(C.fog_max_density)
				
		return true
	end
	
	hook.Add("SetupWorldFog", "tod", SetupFog)
	hook.Add("SetupSkyboxFog", "tod", SetupFog)
	
	-- todo!
	-- have an inside and outside config
	--[[
	local smooth_outside = 0
	
	function tod.IsOutside()
		return smooth_outside > 0.5
	end		
	local cache = {}
	timer.Create("tod_outside", 0.2, 0, function()
		local outside = 0
		local ply = LocalPlayer()
		local a = ply:EyePos()
		a.x = math.Round(a.x/32)*32
		a.y = math.Round(a.y/32)*32
		a.z = math.Round(a.z/32)*32
		
		if cache[a.x..a.y..a.z] then 
			outside = 1
		else
			local b = a + VectorRand() * 32000
						
			if util.TraceLine(
				{
					start = a, 
					endpos = b,
					mask = MASK_OPAQUE,
				}
			).HitSky then
				outside = 4
				cache[a.x..a.y..a.z] = true
			end
		end
		
		smooth_outside = smooth_outside + ((outside - smooth_outside) * FrameTime() * 10)
		
		epoe.Print(tod.IsOutside())
	end)
	]]
end

-- keep hidden entities
-- light_environment won't update properly if the map didn't compile with it properly.
-- the light refreshes on full update (reconnecting for instance) 
-- or when you spawn a light somewhere on the map it will update that sector of the map

-- so if you're using a realtime tod it shouldn't be that noticable
do 
	tod.hidden_entities = {}

	hook.Add("EntityKeyValue", "hidden_entities", function(ent, key, val)
		local T = ent:GetClass():lower()
		
		if 
			T == "shadow_control" or
			T == "light_environment" or
			T == "sky_camera" or
			T == "env_sun" or
			T == "env_fog_controller"
		then
			ent:SetKeyValue("targetname", T)
			tod.hidden_entities[T] = ent
		end
	end)
end

for key, val in pairs(tod.Params) do
	if type(val) ~= "function" then
		tod.CurrentParams[key] = val
	end
end

-- lerping
do
	function tod.Lerp(mult, a, b)	
		local params = {}
		for key, val in pairs(a) do
			if type(val) == "number" then
				params[key] =  Lerp(mult, val, b[key] or val)
			elseif type(val) == "Vector" then
				if not params[key] then
					params[key] = Vector(0,0,0)
				end
				params[key] = LerpVector(mult, val, b[key] or val)
			elseif type(val) == "Angle" then
				if not params[key] then
					params[key] = Angle(0,0,0)
				end
				params[key] = LerpAngle(mult, val, b[key] or val)
			end
		end
		return params
	end

	local function lerp(mult, tbl)
		local out = {}

		for i = 1, #tbl - 1 do
			out[i] = tod.Lerp(mult, tbl[i], tbl[i + 1])
		end

		if #out > 1 then
			return lerp(mult, out) 
		else 
			return out[1] 
		end
	end 

	function tod.LerpConfigs(mult, ...)
		return lerp(mult, {...})
	end 
end

function tod.SetParameter(key, val)
	if type(tod.Params[key]) == "function" then
		tod.Params[key](val)
	end
	tod.CurrentParams[key] = val
end

function tod.GetParameter(key)
	return tod.CurrentParams[key]
end

function tod.SetConfig(data)
	for key, val in pairs(data) do
		tod.SetParameter(key, val)
	end
end

local last_time = 0

function tod.GetCycle(scale)
	if SERVER and tod.current_cycle and tod.current_cycle >= 0 then 
		return tod.current_cycle 
	end
	
	scale = scale or 1
	
	local time = tod.time or 0
		
	if CLIENT and time and time >= 0 then 
		time = time / 100 
	else
		time = (UnPredictedCurTime() / scale)
	end
		
	return time
end

if CLIENT then
	net.Receive("tod", function()
		tod.time = net.ReadFloat()
	end)
end

if SERVER then
	util.AddNetworkString("tod")
	
	function tod.SetCycle(time)
		tod.current_cycle = time and (time%1) or -1
		net.Start("tod")
			net.WriteFloat(time and (time * 100) or -1)
		net.Send()
	end
end

if CLIENT then
	function tod.SetNWParameter(key, val)
		tod.SetParameter(key, val)
		RunConsoleCommand("set_tod_param", glon.encode({key, val})) -- lol
	end
	
	usermessage.Hook("set_tod_param", function(umr)
		local key, val = unpack(glon.decode(umr:ReadString())) -- lol
		if key and val then
			tod.SetParameter(key, val)
		end
	end)
end

if SERVER then
	function tod.SetNWParameter(key, val)
		tod.SetParameter(key, val)
		umsg.Start("set_tod_param")
			umsg.String(glon.encode{key, val}) -- lol
		umsg.End()
	end
	
	concommand.Add("set_tod_param", function(ply, _, args)
		if ply:IsAdmin() then
			local key, val = unpack(glon.decode(args[1])) -- lol
			
			if key and val then
				tod.SetNWParameter(key, val)
			end
		end
	end)
end
	
if SERVER then
	local enable = CreateConVar("sv_tod", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_GAMEDLL})

	local function cmd(val)
		if val == "demo" then
			game.ConsoleCommand("sv_tod 0\n")
			tod.SetCycle()
		else
			local daytime = tonumber(val)
			
			if daytime then
				game.ConsoleCommand("sv_tod 0\n")
				tod.SetCycle((daytime / 24)%1)
			else
				game.ConsoleCommand("sv_tod 1\n")
				tod.SetCycle()
			end
		end
	end
	
	if aowl then
		aowl.AddCommand("settod", function(player, line, val)
			cmd(val)
		end, "moderators")
	else
		concommand.Add("settod", function(ply, _, args)
			if ply:IsAdmin() then
				cmd(args[1])
			end			
		end)
	end
	
	timer.Create("real_time_tod", 1, 0, function()
		if not enable:GetBool() then return end
		
		local H, M, S = os.date("%H"), os.date("%M"), os.date("%S")
		local fraction = (H*3600 + M*60 + S) / 86400

		tod.SetCycle(fraction%1)
	end)
end

-- finally, the actual config

local night = 
{	
	["sun_angles"] = Angle(-90, 45, 0),
	["moon_angles"] = -Angle(-90, 45, 0),
	["world_light_multiplier"] = 0.53,
	
	["color_brightness"] = 0,
	["color_contrast"] = 1,
	["color_saturation"] = 0.75,
	["color_multiply"] = Vector(-0.017, -0.005, 0.02),
	["color_add"] = Vector(0, 0, 0),
	
	["fog_start"] = 0,
	["fog_end"] = 14000,
	["fog_max_density"] = 0.25,
	["fog_color"] = Vector(0.25, 0.20, 0.30),
	
	["shadow_angles"] = Angle(-90, 45, 0),
	["shadow_color"] = Vector(0, 0, 0),
	
	["star_intensity"] = 1,
	
	["bloom_passes"] = 1,
	["bloom_color"] = Vector(1, 1, 1),
	["bloom_width"] = 1,
	["bloom_saturation"] = 1,
	["bloom_height"] = 1,
	["bloom_darken"] = 0,
	["bloom_multiply"] = 0,
	
	["sharpen_contrast"] = 0,
	["sharpen_distance"] = 0,
	
	["sky_topcolor"] = Vector(0, 0, 0),
	["sky_bottomcolor"] = Vector(0, 0, 0),
	["sky_fadebias"] = 1,
	["sky_sunsize"] = 0,
	["sky_sunnormal"] = Vector(0.4, 0, 0.01),
	["sky_suncolor"] = Vector(0.2, 0.1, 0),
	["sky_duskscale"] = 1,
	["sky_duskintensity"] = 1,
	["sky_duskcolor"] = Vector(0, 0, 0),
	["sky_starscale"] = 0.5,
	["sky_starfade"] = 10,
	["sky_starspeed"] = 0.01,
	["sky_hdrscale"] = 0.66,
}

local dusk = 
{
	["sun_angles"] = Angle(0, 45, 0),
	["moon_angles"] = -Angle(0, 45, 0),
	["world_light_multiplier"] = 0.53,
	
	["color_brightness"] = 0,
	["color_contrast"] = 1,
	["color_saturation"] = 1.1,
	["color_multiply"] = Vector(0.017, 0.005, -0.02),
	["color_add"] = Vector(0, 0, 0),
	
	["fog_start"] = 0,
	["fog_end"] = 10000,
	["fog_max_density"] = 1,
	["fog_color"] = Vector(1, 0.85, 0.6), 
	
	["shadow_angles"] = Angle(0, 45, 0),
	["shadow_color"] = Vector(0, 0, 0),
	
	["star_intensity"] = 0,
	
	["bloom_passes"] = 3,
	["bloom_color"] = Vector(1, 1, 1),
	["bloom_width"] = 5,
	["bloom_height"] = 5,
	["bloom_saturation"] = 0.25,
	["bloom_darken"] = 1,
	["bloom_multiply"] = 0,
	
	["sharpen_contrast"] = 0,
	["sharpen_distance"] = 0,
	
	["sky_topcolor"] = Vector(1, 1, 1),
	["sky_bottomcolor"] = Vector(1, 1, 1)*0,
	["sky_fadebias"] = 1,
	["sky_sunsize"] = 2,
	["sky_sunnormal"] = Vector(0, 0, 0),
	["sky_suncolor"] = Vector(0.5, 0.1, 0),
	["sky_duskscale"] = 7,
	["sky_duskintensity"] = 5,
	["sky_duskcolor"] = Vector(1, 0.2, 0),
	["sky_starscale"] = 0.5,
	["sky_starfade"] = 1,
	["sky_starspeed"] = 0.01,
	["sky_hdrscale"] = 0.66,
}

local day = 
{
	["sun_angles"] = Angle(90, 45, 0),
	["moon_angles"] = -Angle(90, 45, 0),
	["world_light_multiplier"] = 1,
	
	["color_brightness"] = 0,
	["color_contrast"] = 1,
	["color_saturation"] = 1,
	["color_multiply"] = Vector(0,0,0),
	["color_add"] = Vector(0, 0, 0),
	
	["fog_start"] = 0,
	["fog_end"] = 30000,
	["fog_max_density"] = -1,
	["fog_color"] = Vector(1,1,1), 
	
	["shadow_angles"] = Angle(0, 45, 0),
	["shadow_color"] = Vector(0, 0, 0),
	
	["star_intensity"] = 0,
	
	["bloom_passes"] = 3,
	["bloom_color"] = Vector(1, 1, 1),
	["bloom_width"] = 5,
	["bloom_height"] = 5,
	["bloom_saturation"] = 0.25,
	["bloom_darken"] = 1,
	["bloom_multiply"] = 0,
	
	["sharpen_contrast"] = 0,
	["sharpen_distance"] = 0,
	
	["sky_topcolor"] = Vector(0.125, 0.5, 1),
	["sky_bottomcolor"] = Vector(0.8, 1, 1),
	["sky_fadebias"] = 0.25,
	["sky_sunsize"] = 1,
	["sky_sunnormal"] = Vector(0, 0, 0),
	["sky_suncolor"] = Vector(0.2, 0.1, 0),
	["sky_duskscale"] = 0,
	["sky_duskintensity"] = -1,
	["sky_duskcolor"] = Vector(1, 0.2, 0),
	["sky_starscale"] = 0.5,
	["sky_starfade"] = 1,
	["sky_starspeed"] = 0.01,
	["sky_hdrscale"] = 0.66,
}

local dawn = 
{
	["sun_angles"] = Angle(90*2, 45, 0),
	["moon_angles"] = -Angle(90*2, 45, 0),
	["world_light_multiplier"] = 0.53,
	
	["color_brightness"] = 0,
	["color_contrast"] = 1,
	["color_saturation"] = 0.9,
	["color_multiply"] = Vector(0.017, -0.075, 0.01),
	["color_add"] = Vector(0, 0, 0),
	
	["fog_start"] = 0,
	["fog_end"] = 10000,
	["fog_max_density"] = -1,
	["fog_color"] = Vector(1,1,1), 
	
	["shadow_angles"] = Angle(0, 45, 0),
	["shadow_color"] = Vector(0, 0, 0),
	
	["star_intensity"] = 0,
	
	["bloom_passes"] = 3,
	["bloom_color"] = Vector(1, 1, 1),
	["bloom_width"] = 5,
	["bloom_height"] = 5,
	["bloom_saturation"] = 0.25,
	["bloom_darken"] = 1,
	["bloom_multiply"] = 0,
	
	["sharpen_contrast"] = 0,
	["sharpen_distance"] = 0,
	
	["sky_topcolor"] = Vector(1, 0.25, 1) * 0.25,
	["sky_bottomcolor"] = Vector(1, 0.5, 0.25),
	["sky_fadebias"] = 0,
	["sky_sunsize"] = 1,
	["sky_sunnormal"] = Vector(0, 0, 0),
	["sky_suncolor"] = Vector(0.2, 0.1, 0),
	["sky_duskscale"] = 2,
	["sky_duskintensity"] = 5,
	["sky_duskcolor"] = Vector(1, 0.1, 0.5),
	["sky_starscale"] = 0.5,
	["sky_starfade"] = 100,
	["sky_starspeed"] = 0.01,
	["sky_hdrscale"] = 0.66,
}

local cache = {}
local last_time

timer.Create("tod", 0.1, 0, function()
	local time = math.Round(tod.GetCycle(20), 3)
	local cfg
	
	if cache[time] then
		cfg = cache[time]
	else
		cfg = tod.LerpConfigs(
			time, 
			
			night,night,night,night,night,night,night, -- hacky (or is it?) way to make the night last longer
			dusk, 
			day,day,day,day,day,day,day,day, 
			dawn
		)
		cache[time] = cfg
	end
	
	if CLIENT then
		if last_time ~= time then	
			render.RedownloadAllLightmaps()
			last_time = time
		end
	end
	
	tod.SetConfig(cfg)	
end)

do -- weather
	local month = tonumber(os.date("%m")) or -1

	if month >= 11 or month <= 2 then
		include("tod_weather/snow.lua")
		AddCSLuaFile("tod_weather/snow.lua")
	end
end