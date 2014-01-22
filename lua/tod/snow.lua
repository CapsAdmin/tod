local snow_density = 0.05
local texture_replacements = 
{
	"metastruct_2/grass",
	"gm_construct/grass",
	"nature/grassfloor002a",
	"nature/blendgrassgravel001a",
	"metastruct_2/blendgrass",
	"nature/blenddirtgrass008b_lowfriction",
	"metastruct_2/blend_mud_rock",
	"nature/blenddirtgrass005a",
	"nature/blendsandgrass008a",
	"nature/red_grass",
	"metastruct_2/blendg",
	"gm_construct/grass-sand",
	"nature/grassfloor002a_replacement",
	"nature/blendgrassgrass001a",
	"nature/blendsandgr",
	"gm_construct/flatgrass",
	"gm_construct/grass",
	"gm_construct/grass-sand_13",
	"gm_construct/flatgrass_2",
	"gm_construct/grass_13",
	"custom/grasssandblend08",
	"custom/grasssandblend09",
	"METASTRUCT_2/GRASS",
	"GM_CONSTRUCT/GRASS",
	"nature/grassfloor002a",
	"nature/blendgrassgravel001a",
	"metastruct_2/blendgrass",
	"shadertest/seamless7",
	"nature/blenddirtgrass008b_lowfriction",
	"metastruct_2/blend_mud_rock",
	"nature/blenddirtgrass005a",
	"nature/blendsandgrass008a",
	"nature/red_grass",
	"nature/red_grass",
	"metastruct_2/blendg",
	"gm_construct/grass-sand",
	"nature/grassfloor002a_replacement",
	"nature/blendgrassgrass001a",
	"nature/blendsandgr",
	"nature/blendgroundtograss008",
	"custom/grasstexture4",
	"custom/grasssandblend08",
	"custom/grasssandblend09",
	"maps/gm_bluehills/custom/grasssandblend08_wvt_patch",
	"maps/gm_bluehills/custom/grasssandblend09_wvt_patch",
	"de_cbble/grassfloor01",
}

local snow_config = 
{				
	["fog_start"] = 0,
	["fog_end"] = 7000,
	["fog_max_density"] = 0.25,
	["fog_color"] = Vector(255,255,255)*0.8, 
	["start_intensity"] = 0,
	["sky_topcolor"] = Vector(1,1,1)*0.5,
	["sky_bottomcolor"] = Vector(1,1,1)*0.5,
}

if SERVER then
	hook.Add("PlayerFootstep", "snow", function(ply, pos, foot, sound, volume, rf)
		sound = sound:lower()
		if sound:find("grass", nil, true) or sound:find("dirt", nil, true) then
			ply:EmitSound(("player/footsteps/snow%s.wav"):format(math.random(6)), 60, math.random(95,105))
			return true
		end
	end)
	
	local lerp = 0
	
	hook.Add("Think", "snow", function()
		math.randomseed(math.floor(CurTime()/100))
		if _G.LET_IT_SNOW then 
			math.randomseed(SysTime())
			
			lerp = math.min(lerp + FrameTime(), 1)
			
			tod.SetOverrideConfig(snow_config, lerp)
		else
			math.randomseed(SysTime())
			
			lerp = math.max(lerp - FrameTime(), -1)
			
			if lerp == -1 then
				tod.SetOverrideConfig()
			else							
				tod.SetOverrideConfig(snow_config, lerp)					
			end
		end
	end)
end

if CLIENT then
	do	
		-- initialize points
		local snow_data = {}
		local max = 16000
		local grid_size = 768
		local range = max / grid_size

		local pos

		for x = -range, range do
			x = x * grid_size
			for y = -range, range do
				y = y * grid_size
				for z = -range, range do
					z = z * grid_size
					
					pos = Vector(x,y,z)
					local conents = util.PointContents(pos)
					
					if conents == CONTENTS_EMPTY or conents == CONTENTS_TESTFOGVOLUME then
						local up = util.QuickTrace(pos, vector_up * max * 2)
						up.HitTexture = up.HitTexture:lower()
						if up.HitTexture == "tools/toolsskybox" or up.HitTexture == "**empty**" then
							table.insert(snow_data, pos)
						end
					end
				end
			end
		end

		-- emit the particles from points
		local draw_these = {}
		local emt = ParticleEmitter(EyePos(), false)
		
		local lerp = 0

		hook.Add("Think", "snow", function()
			math.randomseed(math.floor(CurTime()/100))
			if math.random() < 0.5 then 
				math.randomseed(SysTime())
				
				lerp = math.min(lerp + FrameTime(), 1)
			
				for _, point in pairs(draw_these) do
					if math.random() > snow_density then continue end
					
					local prt = emt:Add("particle/snow", point)
					prt:SetVelocity(VectorRand() * 100 * Vector(1,1,0))
					prt:SetAngles(Angle(math.random(360), math.random(360), math.random(360)))
					prt:SetLifeTime(0)
					prt:SetDieTime(10)
					prt:SetStartAlpha(255)
					prt:SetEndAlpha(0)
					prt:SetStartSize(0)
					prt:SetEndSize(5)
					prt:SetGravity(Vector(0,0,math.Rand(-30, -200)))
					prt:SetCollide(true)
					--prt:SetCollideCallback(SnowCallback)
				end
				
				tod.SetOverrideConfig(snow_config, lerp)
			else
				math.randomseed(SysTime())
				
				lerp = math.max(lerp - FrameTime(), -1)
				
				if lerp == -1 then
					tod.SetOverrideConfig()
				else					
					tod.SetOverrideConfig(snow_config, lerp)					
				end
			end			
		end)

		-- show or hide points
		local function fastlen(point)
			return point.x * point.x + point.y * point.y + point.z * point.z
		end
		
		local iterations = math.min(math.ceil(#snow_data/(1/0.1)), #snow_data)
		local lastkey = 1
		local lastpos = nil
		local len = 3000 ^ 2
		local movelen = 100 ^ 2
		local ply = LocalPlayer()
		
		local eyepos = Vector()
		hook.Add("RenderScene", "snow", function(pos, ang) eyepos = pos end)

		timer.Create("snow_sector_think", 0.1, 0, function()
			math.randomseed(math.floor(CurTime()/100))
			if math.random() > 0.5 then math.randomseed(SysTime()) return end
			math.randomseed(SysTime())
			
			if not ply:IsValid() then
				ply = LocalPlayer()
				return
			end
			
			local pos = eyepos + ply:GetVelocity() -- todo: render scene eyepos velocity
			if lastpos == nil or fastlen(lastpos - pos) > movelen then
				local c = #snow_data
				local r = math.min(iterations, c)
				local completed = false
				
				for i = 1, r do				
					local key = lastkey + 1
					if key > c then
						completed = true
						lastkey = 1
						break
					end
					
					local point = snow_data[key]
					local dc = fastlen(point - pos) < len
					
					if dc and draw_these[key] == nil then
						draw_these[key] = point
					elseif not dc and draw_these[key] ~= nil then
						draw_these[key] = nil
					end
					
					lastkey = key
				end
				
				if completed then 
					lastpos = pos 
				end
			end
		end)
	end
	
	do -- texture replace
		hook.Add("Think", "snow_init", function()
			if not LocalPlayer():IsValid() then return end

			if materials then
				local sky = 
				{
					"up",
					"dn",
					"lf",
					"rt",
					"ft",
					"bk",
				}

				local sky_name = GetConVarString("sv_skyname")

				for _, path in pairs(sky) do	
					path = "skybox/" .. sky_name .. path
					materials.ReplaceTexture(path, "Decals/decal_paintsplatterpink001")
					materials.SetColor(path, Vector(0.9,1,0.9)*0.9)
				end

				for _, path in pairs(texture_replacements) do
					materials.ReplaceTexture(path, "NATURE/SNOWFLOOR001A")
					materials.SetColor(path, Vector(1, 1, 1) * 0.4)
				end
			end

			hook.Remove("Think", "snow_init")
		end)
	end
end