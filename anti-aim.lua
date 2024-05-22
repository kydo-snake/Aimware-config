
--- GUI stuff
local POS = gui.Reference("Visuals", "Local", "Helper")
local MULTI = gui.Multibox(POS, "Antiaim lines")
local NETWORKED = gui.Checkbox(MULTI, "vis.local.aalines.networked", "Networked Angle", true)
local LOCALANG = gui.Checkbox(MULTI, "vis.local.aalines.local", "Local Angle", true)
local CAMERAANG = gui.Checkbox(MULTI, "vis.local.aalines.camera", "Camera Angle", true)
local LENGTH = gui.Slider(POS, "vis.local.aalines.length", "Length", 50, 10, 100, 1)

local screenX, screenY = draw.GetScreenSize()

local X_OFFSET = gui.Slider(POS, "vis.local.aalines.xoffset", "X Offset", 0, -screenX/2, screenX/2, 1)
local Y_OFFSET = gui.Slider(POS, "vis.local.aalines.yoffset", "Y Offset", 0, -screenY/2, screenY/2, 1)

local ONSCEREN = gui.Checkbox(POS, "vis.local.aalines.onscreen", "Onscreen", true)

local dragging = false
local dragXOffset = 0
local dragYOffset = 0

--- Variables
local fake = nil;
local localAngle = nil;
local pLocal = entities.GetLocalPlayer();
local choking;
local lastChoke;

--- The maths
local function AngleVectors(angles)

    local sp, sy, cp, cy;
    local forward = { }

    sy = math.sin(math.rad(angles[2]));
	cy = math.cos(math.rad(angles[2]));

	sp = math.sin(math.rad(angles[1]));
	cp = math.cos(math.rad(angles[1]));

	forward[1] = cp*cy;
	forward[2] = cp*sy;
    forward[3] = -sp;
    return forward;
end

local function doShit(t1, t2, m)
    local t3 ={};
    for i,v in ipairs(t1) do
        t3[i] = v + (t2[i] * m);
    end
    return t3;
end

local function iHateMyself(value, color, text)
    local forward = {};
    local origin = pLocal:GetAbsOrigin();
    forward = AngleVectors({0, value, 0});
    local end3D = doShit({origin.x, origin.y, origin.z}, forward, 25);
    local w2sX1, w2sY1 = client.WorldToScreen(origin);
    local w2sX2, w2sY2 = client.WorldToScreen(Vector3(end3D[1], end3D[2], end3D[3]));
    draw.Color(color[1], color[2], color[3], color[4])

    if w2sX1 and w2sY1 and w2sX2 and w2sY2 then
        draw.Line(w2sX1, w2sY1, w2sX2, w2sY2)
        local textW, textH = draw.GetTextSize(text);
        draw.TextShadow( w2sX2-(textW/2), w2sY2-(textH/2), text)
    end
end

local function drawAnglesOnScreen(angle, color, text)
    if not ONSCEREN:GetValue() then return end
    local radius = LENGTH:GetValue()
    local centerX, centerY = draw.GetScreenSize()
    centerX = centerX / 2 + X_OFFSET:GetValue()
    centerY = centerY / 2 + Y_OFFSET:GetValue()

    local angleRad = math.rad((cameraAngle.y - angle + 270) % 360)
    local posX = centerX + radius * math.cos(angleRad)
    local posY = centerY + radius * math.sin(angleRad)

    draw.Color(color[1], color[2], color[3], color[4])
    draw.Line(centerX, centerY, posX, posY)

    -- Berechnen Sie die Position der Beschriftungen basierend auf dem Winkel der Linie
    local textW, textH = draw.GetTextSize(text)
    local textOffset = 0
    draw.TextShadow(posX - textW / 2, posY - textH / 2 + textOffset, text)
end

callbacks.Register("Draw", function()
    pLocal = entities.GetLocalPlayer()
    fake = pLocal:GetPropVector("m_angEyeAngles")
    cameraAngle = engine.GetViewAngles()

    if lastChoke and lastChoke <= globals.CurTime() - 1 then
        choking = false
    end

    -- Get the current mouse position
    local mouseX, mouseY = input.GetMousePos()

    -- Calculate the center of the screen based on the current position of the indicator
    local screenX, screenY = draw.GetScreenSize()
    local centerX = screenX / 2 + X_OFFSET:GetValue()
    local centerY = screenY / 2 + Y_OFFSET:GetValue()

    -- Calculate the distance between the mouse position and the center of the screen
    local distanceX = math.abs(mouseX - centerX)
    local distanceY = math.abs(mouseY - centerY)

    -- Check if the left mouse button is down and the mouse is within the square area surrounding the indicator
    local draggingWithinArea = distanceX <= 50 and distanceY <= 50
    if input.IsButtonDown(1) and draggingWithinArea then
        if not dragging then
            -- Start dragging
            dragging = true

            -- Store the offset between the mouse position and the center of the screen
            dragXOffset = mouseX - X_OFFSET:GetValue()
            dragYOffset = mouseY - Y_OFFSET:GetValue()
        else
            -- Update the offset values while dragging
            X_OFFSET:SetValue(mouseX - dragXOffset)
            Y_OFFSET:SetValue(mouseY - dragYOffset)
        end
    elseif dragging and input.IsButtonDown(1) then
        -- Update the offset values while dragging even if mouse goes out of the area
        X_OFFSET:SetValue(mouseX - dragXOffset)
        Y_OFFSET:SetValue(mouseY - dragYOffset)
    else
        -- Stop dragging
        dragging = false
    end

    if pLocal and pLocal:IsAlive() then
        if ONSCEREN:GetValue() then
            local lineLength = LENGTH:GetValue()

            -- Calculate the size of the rectangle
            local rectSize = lineLength + lineLength * 0.4 + 75 -- Adding 10 pixels to each side to ensure lines are contained within the rectangle
        
            -- Draw the rectangle
            draw.Color(255, 255, 255, 255)
            draw.OutlinedRect(centerX - rectSize / 2, centerY - rectSize / 2, centerX + rectSize / 2, centerY + rectSize / 2)    
        end
        if fake and NETWORKED:GetValue() then 
            iHateMyself(fake.y, {255, 25, 25, 255}, "Networked") 
            drawAnglesOnScreen(fake.y, {255, 25, 25, 255}, "Networked")
        end
        if localAngle and LOCALANG:GetValue() then 
            iHateMyself(localAngle.y, {25, 25, 255, 255}, "Local Angle") 
            drawAnglesOnScreen(localAngle.y, {25, 25, 255, 255}, "Local Angle")
        end
        if cameraAngle and CAMERAANG:GetValue() then 
            iHateMyself(cameraAngle.y, {255, 255, 25, 255}, "Camera Angle") 
            drawAnglesOnScreen(cameraAngle.y, {255, 255, 25, 255}, "Camera Angle")
        end
    end
end)

callbacks.Register("CreateMove", function(pCmd)
    if pLocal and pLocal:IsAlive() then
        localAngle = pCmd:GetViewAngles()
    end
end)
