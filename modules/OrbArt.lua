





local ThugUI = _G.ThugUI
local OA = {}
ThugUI.OrbArt = OA


OA.MODEL_CLIP = "clip"

local ORB_SIZE = 224

local function ApplyFillDirection(bar, dir)
    if bar.SetRenderMode and Enum.StatusBarRenderMode then
        pcall(bar.SetRenderMode, bar, Enum.StatusBarRenderMode.Linear)
    end
    local standard = Enum.StatusBarFillStyle and Enum.StatusBarFillStyle.Standard or 0
    local center = Enum.StatusBarFillStyle and Enum.StatusBarFillStyle.Center or 2
    dir = dir or "up"
    local orient, reverse, style = "VERTICAL", false, standard
    if dir == "down" then reverse = true
    elseif dir == "right" then orient = "HORIZONTAL"
    elseif dir == "left" then orient, reverse = "HORIZONTAL", true
    elseif dir == "center" then style = center
    end
    bar:SetOrientation(orient)
    if bar.SetReverseFill then pcall(bar.SetReverseFill, bar, reverse) end
    if bar.SetFillStyle then pcall(bar.SetFillStyle, bar, style) end
end

local function SetBarTexture(bar, file, mask)
    bar:SetStatusBarTexture(file)
    local tex = bar:GetStatusBarTexture()
    if tex and mask and tex.AddMaskTexture then
        if tex.RemoveMaskTexture then pcall(tex.RemoveMaskTexture, tex, mask) end
        tex:AddMaskTexture(mask)
    end
    return tex
end

local function Unpack3(t, r, g, b)
    if type(t) == "table" then return t[1] or r, t[2] or g, t[3] or b end
    return r, g, b
end

function OA.Copy(t)
    if type(t) ~= "table" then return t end
    local res = {}
    for k, v in pairs(t) do
        res[k] = OA.Copy(v)
    end
    return res
end

local function Clamp(val, min, max)
    if type(val) ~= "number" then return min end
    if val < min then return min end
    if val > max then return max end
    return val
end

function OA.Sanitize(stack, kind)
    local clean = {}
    local dropped = 0
    local isPip = (kind == "pip")

    if not isPip then
        if stack.background then
            clean.background = {
                file = stack.background.file or "",
                color = OA.Copy(stack.background.color) or {1, 1, 1},
                alpha = Clamp(stack.background.alpha, 0, 1),
                blend = stack.background.blend or "normal",
            }
        end
        if stack.fill then
            clean.fill = {
                file = stack.fill.file or "",
                color = OA.Copy(stack.fill.color) or {1, 1, 1},
                alpha = Clamp(stack.fill.alpha, 0, 1),
                blend = stack.fill.blend or "normal",
            }
        end
    end

    clean.layers = {}
    local seenNames = {}
    local rawLayers = stack.layers or {}
    
    for _, l in ipairs(rawLayers) do
        if #clean.layers >= 6 then
            dropped = dropped + 1
        else
            local lkind = l.kind
            if isPip and lkind == "model" then
                dropped = dropped + 1
            elseif lkind ~= "texture" and lkind ~= "model" then
                dropped = dropped + 1
            else
                local name = l.name or "Layer"
                local baseName = name
                local suffix = 2
                while seenNames[name] do
                    name = baseName .. " " .. suffix
                    suffix = suffix + 1
                end
                seenNames[name] = true

                local cl = {
                    name = name,
                    kind = lkind,
                    file = l.file or "",
                    path = l.path or "",
                    blend = l.blend or "normal",
                    color = OA.Copy(l.color) or {1, 1, 1},
                    alpha = Clamp(l.alpha, 0, 1),
                    desat = l.desat and true or false,
                    scale = Clamp(l.scale, 0.05, 5),
                    x = Clamp(l.x, -400, 400),
                    y = Clamp(l.y, -400, 400),
                    drain = l.drain and true or false,
                }
                
                if lkind == "model" then
                    cl.camDist = l.camDist or 1
                    cl.camX = l.camX or 0
                    cl.camY = l.camY or 0
                    cl.camZ = l.camZ or 0
                    cl.facing = l.facing or 0
                elseif lkind == "texture" then
                    cl.spin = type(l.spin) == "number" and l.spin or 0
                    if l.pulseScale then
                        cl.pulseScale = {
                            from = Clamp(l.pulseScale.from, 0.05, 5),
                            to = Clamp(l.pulseScale.to, 0.05, 5),
                            period = math.max(0.1, tonumber(l.pulseScale.period) or 1)
                        }
                    end
                    if l.pulseAlpha then
                        cl.pulseAlpha = {
                            from = Clamp(l.pulseAlpha.from, 0, 1),
                            to = Clamp(l.pulseAlpha.to, 0, 1),
                            period = math.max(0.1, tonumber(l.pulseAlpha.period) or 1)
                        }
                    end
                end
                
                table.insert(clean.layers, cl)
            end
        end
    end

    return clean, dropped
end

function OA:NewCanvas(host, opts)
    local canvas = {
        host = host,
        opts = opts,
        layerFrames = {},
        activeLayers = 0,
        direction = "up"
    }
    local baseLevel = opts.baseLevel or 0
    local isPip = (opts.kind == "pip")

    if not isPip then
        canvas.bgFrame = CreateFrame("Frame", nil, host)
        canvas.bgFrame:SetAllPoints(host)
        canvas.bgFrame:SetFrameLevel(baseLevel + 1)
        canvas.bg = canvas.bgFrame:CreateTexture(nil, "BACKGROUND")
        canvas.bg:SetAllPoints(canvas.bgFrame)

        canvas.fill = CreateFrame("StatusBar", nil, host)
        canvas.fill:SetAllPoints(host)
        canvas.fill:SetFrameLevel(baseLevel + 2)
        SetBarTexture(canvas.fill, "Interface\\Buttons\\WHITE8X8", opts.mask)

        canvas.clipFrame = CreateFrame("Frame", nil, host)
        canvas.clipFrame:SetAllPoints(canvas.fill:GetStatusBarTexture())
        if canvas.clipFrame.SetClipsChildren then
            pcall(canvas.clipFrame.SetClipsChildren, canvas.clipFrame, true)
        end
        canvas.clipFrame:SetFrameLevel(baseLevel + 2)
    end

    function canvas:Hide()
        if self.bgFrame then self.bgFrame:Hide() end
        if self.fill then self.fill:Hide() end
        if self.clipFrame then self.clipFrame:Hide() end
        for i = 1, self.activeLayers do
            local lf = self.layerFrames[i]
            lf.frame:Hide()
            if lf.spinAg then lf.spinAg:Stop() end
            if lf.pulseAg then lf.pulseAg:Stop() end
        end
    end

    function canvas:Show()
        if self.bgFrame then self.bgFrame:Show() end
        if self.fill then self.fill:Show() end
        if self.clipFrame then self.clipFrame:Show() end
        for i = 1, self.activeLayers do
            local lf = self.layerFrames[i]
            lf.frame:Show()
            if lf.layerData then
                if lf.spinAg and lf.layerData.spin and lf.layerData.spin ~= 0 then lf.spinAg:Play() end
                if lf.pulseAg and (lf.layerData.pulseScale or lf.layerData.pulseAlpha) then lf.pulseAg:Play() end
            end
        end
    end

    function canvas:Layers()
        local res = {}
        for i = 1, self.activeLayers do
            table.insert(res, self.layerFrames[i].frame)
        end
        return res
    end

    function canvas:Apply(stack, adjust, direction)
        adjust = adjust or {}
        direction = direction or "up"
        self.direction = direction

        if not isPip then
            if stack.background then
                self.bgFrame:Show()
                self.bg:SetTexture(stack.background.file)
                if opts.mask and self.bg.AddMaskTexture then
                    if self.bg.RemoveMaskTexture then pcall(self.bg.RemoveMaskTexture, self.bg, opts.mask) end
                    self.bg:AddMaskTexture(opts.mask)
                end
                self.bg:SetVertexColor(Unpack3(stack.background.color, 1, 1, 1))
                self.bg:SetAlpha(stack.background.alpha or 1)
                if self.bg.SetBlendMode and ThugUI.OrbEffects then 
                    pcall(self.bg.SetBlendMode, self.bg, ThugUI.OrbEffects.BlendFor(stack.background.blend)) 
                end
            else
                self.bgFrame:Hide()
            end

            if stack.fill then
                self.fill:Show()
                local ftex = stack.fill.file
                if not ftex or ftex == "" then ftex = "Interface\\Buttons\\WHITE8X8" end
                SetBarTexture(self.fill, ftex, opts.mask)
                self.fill:SetStatusBarColor(Unpack3(stack.fill.color, 1, 1, 1))
                self.fill:SetAlpha(stack.fill.alpha or 1)
                local tex = self.fill:GetStatusBarTexture()
                if tex and tex.SetBlendMode and ThugUI.OrbEffects then 
                    pcall(tex.SetBlendMode, tex, ThugUI.OrbEffects.BlendFor(stack.fill.blend)) 
                end
            else
                
                
                
                self.fill:Show()
                SetBarTexture(self.fill, "Interface\\Buttons\\WHITE8X8", opts.mask)
                self.fill:SetAlpha(0)
            end
            ApplyFillDirection(self.fill, direction)
        end

        local layers = stack.layers or {}
        local oldLayers = self.activeLayers
        self.activeLayers = #layers

        for i = 1, self.activeLayers do
            local l = layers[i]
            local lf = self.layerFrames[i]
            if not lf then
                lf = {}
                self.layerFrames[i] = lf
            end
            lf.layerData = l
            local level = isPip and (baseLevel + i) or (baseLevel + 2 + i)
            
            local parent = host
            if not isPip and l.drain then
                parent = self.clipFrame
            end

            if l.kind == "model" and not isPip then
                if not lf.frame or lf.kind ~= "model" then
                    if lf.frame then lf.frame:Hide() end
                    if OA.MODEL_CLIP == "scroll" then
                        lf.frame = CreateFrame("ScrollFrame", nil, parent)
                        lf.scrollChild = CreateFrame("Frame", nil, lf.frame)
                        lf.frame:SetScrollChild(lf.scrollChild)
                        lf.model = CreateFrame("PlayerModel", nil, lf.scrollChild)
                        lf.model:SetAllPoints(lf.scrollChild)
                    else
                        lf.frame = CreateFrame("PlayerModel", nil, parent)
                        lf.model = lf.frame
                    end
                    if lf.model.SetKeepModelOnHide then pcall(lf.model.SetKeepModelOnHide, lf.model, true) end
                    lf.kind = "model"
                    lf.lastFile = nil  
                end
            else
                if not lf.frame or lf.kind ~= "texture" then
                    if lf.frame then
                        lf.frame:Hide()
                        if lf.spinAg then lf.spinAg:Stop() end
                        if lf.pulseAg then lf.pulseAg:Stop() end
                    end
                    lf.frame = CreateFrame("Frame", nil, parent)
                    lf.tex = lf.frame:CreateTexture(nil, "ARTWORK")
                    lf.tex:SetAllPoints(lf.frame)
                    lf.kind = "texture"
                    lf.spinAg, lf.pulseAg = nil, nil  
                end
            end

            local adj = adjust[l.name] or {}
            local x = (l.x or 0) + (adj.x or 0)
            local y = (l.y or 0) + (adj.y or 0)
            local scale = (l.scale or 1) * (adj.scale or 1)

            lf.frame:SetParent(parent)
            lf.frame:SetFrameLevel(level)
            
            if OA.MODEL_CLIP == "scroll" and lf.kind == "model" then
                lf.frame:ClearAllPoints()
                lf.frame:SetPoint("CENTER", host, "CENTER", x, y)
                local w, h = host:GetWidth() * scale, host:GetHeight() * scale
                lf.frame:SetSize(w, h)
                lf.scrollChild:SetSize(w, h)
            else
                lf.frame:ClearAllPoints()
                lf.frame:SetPoint("CENTER", host, "CENTER", x, y)
                lf.frame:SetSize(host:GetWidth() * scale, host:GetHeight() * scale)
            end

            if lf.kind == "model" then
                if lf.lastFile ~= l.file then
                    pcall(lf.model.SetModel, lf.model, l.file)
                    lf.lastFile = l.file
                end
                lf.model:SetAlpha(l.alpha or 1)
                if lf.model.SetCamDistanceScale then pcall(lf.model.SetCamDistanceScale, lf.model, l.camDist or 1) end
                if lf.model.SetPosition then pcall(lf.model.SetPosition, lf.model, l.camX or 0, l.camY or 0, l.camZ or 0) end
                if lf.model.SetFacing then pcall(lf.model.SetFacing, lf.model, l.facing or 0) end
            else
                lf.tex:SetTexture(l.file)
                if opts.mask and lf.tex.AddMaskTexture then
                    if lf.tex.RemoveMaskTexture then pcall(lf.tex.RemoveMaskTexture, lf.tex, opts.mask) end
                    lf.tex:AddMaskTexture(opts.mask)
                end
                if lf.tex.SetDesaturated then pcall(lf.tex.SetDesaturated, lf.tex, l.desat) end
                lf.tex:SetVertexColor(Unpack3(l.color, 1, 1, 1))
                lf.tex:SetAlpha(l.alpha or 1)
                if lf.tex.SetBlendMode and ThugUI.OrbEffects then pcall(lf.tex.SetBlendMode, lf.tex, ThugUI.OrbEffects.BlendFor(l.blend)) end

                local spinChanged = (lf.lastSpin ~= l.spin)
                local pScaleChanged = false
                if type(l.pulseScale) == "table" and type(lf.lastPulseScale) == "table" then
                    pScaleChanged = (l.pulseScale.from ~= lf.lastPulseScale.from or l.pulseScale.to ~= lf.lastPulseScale.to or l.pulseScale.period ~= lf.lastPulseScale.period)
                else
                    pScaleChanged = (l.pulseScale ~= lf.lastPulseScale)
                end
                local pAlphaChanged = false
                if type(l.pulseAlpha) == "table" and type(lf.lastPulseAlpha) == "table" then
                    pAlphaChanged = (l.pulseAlpha.from ~= lf.lastPulseAlpha.from or l.pulseAlpha.to ~= lf.lastPulseAlpha.to or l.pulseAlpha.period ~= lf.lastPulseAlpha.period)
                else
                    pAlphaChanged = (l.pulseAlpha ~= lf.lastPulseAlpha)
                end

                if spinChanged or not lf.spinAg then
                    if lf.spinAg then lf.spinAg:Stop() end
                    
                    
                    lf.spinAg = lf.tex:CreateAnimationGroup()
                    if lf.spinAg.SetLooping then pcall(lf.spinAg.SetLooping, lf.spinAg, "REPEAT") end
                    if l.spin and l.spin ~= 0 then
                        local rot = lf.spinAg:CreateAnimation("Rotation")
                        
                        
                        local deg = l.spin < 0 and 360 or -360
                        if rot.SetDegrees then pcall(rot.SetDegrees, rot, deg) end
                        if rot.SetDuration then pcall(rot.SetDuration, rot, math.abs(l.spin)) end
                    end
                end
                
                if pScaleChanged or pAlphaChanged or not lf.pulseAg then
                    if lf.pulseAg then lf.pulseAg:Stop() end
                    lf.pulseAg = lf.tex:CreateAnimationGroup()
                    if lf.pulseAg.SetLooping then pcall(lf.pulseAg.SetLooping, lf.pulseAg, "BOUNCE") end
                    if l.pulseScale then
                        local s = lf.pulseAg:CreateAnimation("Scale")
                        if s.SetScaleFrom then pcall(s.SetScaleFrom, s, l.pulseScale.from, l.pulseScale.from) end
                        if s.SetScaleTo then pcall(s.SetScaleTo, s, l.pulseScale.to, l.pulseScale.to) end
                        if s.SetDuration then pcall(s.SetDuration, s, l.pulseScale.period / 2) end
                    end
                    if l.pulseAlpha then
                        local a = lf.pulseAg:CreateAnimation("Alpha")
                        if a.SetFromAlpha then pcall(a.SetFromAlpha, a, l.pulseAlpha.from) end
                        if a.SetToAlpha then pcall(a.SetToAlpha, a, l.pulseAlpha.to) end
                        if a.SetDuration then pcall(a.SetDuration, a, l.pulseAlpha.period / 2) end
                    end
                end

                lf.lastSpin = l.spin
                lf.lastPulseScale = OA.Copy(l.pulseScale)
                lf.lastPulseAlpha = OA.Copy(l.pulseAlpha)
                
                if lf.frame:IsVisible() then
                    if l.spin and l.spin ~= 0 then lf.spinAg:Play() end
                    if l.pulseScale or l.pulseAlpha then lf.pulseAg:Play() end
                end
            end
            
            lf.frame:Show()
        end
        
        for i = self.activeLayers + 1, oldLayers do
            if self.layerFrames[i] and self.layerFrames[i].frame then
                self.layerFrames[i].frame:Hide()
                if self.layerFrames[i].spinAg then self.layerFrames[i].spinAg:Stop() end
                if self.layerFrames[i].pulseAg then self.layerFrames[i].pulseAg:Stop() end
            end
        end
    end

    function canvas:SetValue(cur, max)
        if not isPip and self.fill then
            self.fill:SetMinMaxValues(0, max)
            self.fill:SetValue(cur)
        end
        if not isPip and OA.MODEL_CLIP == "scroll" then
            local secret = issecretvalue and (issecretvalue(cur) or issecretvalue(max))
            if secret then
                if not OA.loggedSecretClip then
                    OA.loggedSecretClip = true
                    if ThugUI.Diagnostics then
                        ThugUI.Diagnostics:Log("ORBART", "secret value: model clip held")
                    end
                end
            else
                local frac = 0
                if max and max > 0 then frac = cur / max end
                if frac < 0 then frac = 0 end
                if frac > 1 then frac = 1 end
                
                local dir = self.direction or "up"
                for i = 1, self.activeLayers do
                    local lf = self.layerFrames[i]
                    if lf.kind == "model" and lf.layerData and lf.layerData.drain and lf.frame.SetVerticalScroll then
                        if dir ~= "up" then
                            lf.frame:SetHeight(ORB_SIZE)
                            if lf.frame.SetVerticalScroll then
                                pcall(lf.frame.SetVerticalScroll, lf.frame, 0)
                            end
                        else
                            local height = ORB_SIZE * frac
                            if height < 0.1 then height = 0.1 end
                            lf.frame:SetHeight(height)
                            if lf.frame.SetVerticalScroll then
                                pcall(lf.frame.SetVerticalScroll, lf.frame, ORB_SIZE - height)
                            end
                        end
                    end
                end
            end
        end
    end

    return canvas
end
