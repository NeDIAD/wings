local commit = 'f18c872e10da9c764ebd191051801b7c3b3bc4e9'
--[[

        /ᐠ. ｡.ᐟ\ᵐᵉᵒʷˎˊ˗ 
        Made by NeDIAD a.k.a NotDIAD
        https://github.com/NeDIAD , @nediad , @notdiad

]]

local ffi = require 'ffi'

local luna = {
    api = setmetatable( { }, { __index = _G } ),
    commit = commit or '?',
}

luna.export = function(name)
    return luna.api[name] or false -- for scripts that use old version
end

local table = setmetatable( { } , { __index = _G.table } )

-- Unlink values
---@param value table|any Value to unlink
---@param deep number Deep of unlink
---@return any
table.unlink = function(value, deep)
    deep = deep or math.huge

    if type(value) ~= 'table' or deep < 1 then return value end
    local unlink = { }
    
    for k, v in pairs(value) do
        unlink[k] = table.unlink(v, deep - 1)
    end

    return unlink
end

-- Find value in table
---@param origin table Table to recurse
---@param value any Value to find
---@param method? function Function to check
---@return number | nil
table.find = function(origin, value, method)
    method = method or function(this) return this == value end

    for k, v in ipairs(origin) do
        local found = method(v)
        if found then return k end
    end
end

-- Make array from dictionary
---@param origin table Table to recurse
---@param method string How to convert table
---@return table
table.flat = function(origin, method)
    local array = { }

    for key, value in pairs(origin) do
        local data = { key = key, value = value }
        table.insert(array, data[method]) 
    end

    return array
end

luna.api.table = table
local math = setmetatable( { } , { __index = _G.math } )

-- Round values
---@param ... number Values to round
---@return number
math.round = function(...)
    local pack, data = { }, { ... }
    for _, v in ipairs(data) do
        pack[_] = math.floor(v + .5)
    end
    return unpack(pack)
end

-- Rainbow color
---@param speed number Speed of rainbow
---@return number, number, number
math.rainbow = function(speed)
    speed = speed or 1
    
    local time = globals.realtime() * speed

    return math.floor(math.sin(time) * 127 + 128), math.floor(math.sin(time + 2 * math.pi / 3) * 127 + 128), math.floor(math.sin(time + 4 * math.pi / 3) * 127 + 128)
end

-- Clamp number
---@param value number Value to clamp
---@param min number Minimal value
---@param max number Maximum value
---@return number
math.clamp = function(value, min, max)
    return math.max(min, math.min(value, max))
end

-- Lerp number
---@param a number Start value
---@param b number End value
---@param t number Speed
---@param force boolean Disable forcing
---@return number
math.lerp = function(a, b, t, force)
    if not a or not b or not t then return 0 end

    if math.abs(a - b) < .01 and not force then return b end
    local lerp = a + (b - a) * t
    return lerp
end

-- Pulsing value
---@param min number Minimal value
---@param max number Maximum value
---@param speed number Speed
---@param time number Custom time
---@return number
math.pulse = function(min, max, speed, time)
    time = time or globals.realtime()

    return (max + min) / 2 + math.sin(time * speed) * (max - min) / 2
end

luna.api.math = math

local color = { } do
    ---@class Color
    local mt = { }
    mt.__index = mt
    mt.__tostring = function(self)
        return string.format('Color(%s, %s, %s, %s)', self:rgba())
    end

    -- Export RGB from Color
    ---@param self Color
    ---@return number, number, number
    function mt:rgb()
        return self.r or 255, self.g or 255, self.b or 255
    end

    -- Export RGBA from Color
    ---@param self Color
    ---@return number, number, number, number
    function mt:rgba()
        return self.r or 255, self.g or 255, self.b or 255, self.a or 255
    end

    -- Export HEX from Color
    ---@param self Color
    ---@return string
    function mt:hex()
        return color.toHex(self:rgb())
    end

    -- Export HEX with Alpha from Color
    ---@param self Color
    ---@return string
    function mt:hexa()
        return color.toHex(self:rgba())
    end

    -- Turn RGB\A to HEX\A
    ---@param r number Red channel
    ---@param g number Green channel
    ---@param b number Blue channel
    ---@param a? number Alpha channel
    ---@return string
    color.toHex = function(r, g, b, a)
        local pattern = '\a%02X%02X%02X' .. (a and '%02X' or '')
        return string.format(pattern, r, g, b, a)
    end

    -- Create new color
    ---@param r number Red channel
    ---@param g number Green channel
    ---@param b number Blue channel
    ---@param a? number Alpha channel
    ---@return Color
    color.new = function(r, g, b, a)
        return setmetatable({ r = r , g = g , b = b , a = a }, mt)
    end

    ffi.cdef[[
        typedef struct {
            uint8_t r, g, b, a;
        } luna_color_struct_t; 
    ]]

    local function rgba_hex(hex)
        hex = string.gsub(hex, '^#', '') -- remove #
        return tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16), tonumber(string.sub(hex, 5, 6), 16), tonumber(string.sub(hex, 7, 8), 16) or 255
    end

    -- Create new ffi struct
    ---@param r number Red channel
    ---@param g number Green channel
    ---@param b number Blue channel
    ---@param a number Alpha channel
    ---@return table
    color.ffirgb = function(r, g, b, a)
        local mt = ffi.new('luna_color_struct_t')

        mt.r = r
        mt.g = g
        mt.b = b
        mt.a = a

        return mt 
    end

    -- Create new ffi struct
    ---@param hex string HEX string
    ---@return table
    color.ffihex = function(hex) return color.ffirgb(rgba_hex(hex)) end

    -- Export FFi from Color
    ---@param self Color
    ---@return table
    function mt:toFfi()
        return color.ffirgb(self:rgba())
    end
end

luna.api.color = color

local throw = { } do
    throw.reset = color.new():hex()

    throw.natives = {
        print = vtable_bind('vstdlib.dll', 'VEngineCvar007', 25, 'void(__cdecl*)(void*, const void*, const char*, ...)')
    }

    -- Throw text in console
    ---@param ... string|any Text to throw
    throw.out = function(...)
        local direct = throw.natives.print
        local args = {...}  

        for _, v in ipairs(args) do
            local str = tostring(v) 
            local format = string.gsub('\r' .. str, '\r', throw.reset)

            for col, text in format:gmatch('\a(%x%x%x%x%x%x)([^\a]*)') do -- split by color, and print
                direct(color.ffihex(col), text)
            end
        end
        
        direct(throw.reset, '\n') -- clear color & go to a new line

        return true
    end
end

luna.api.throw = throw

local hook = { } do
    hook.unique = { }
    hook.list = { }

    -- Get hook bound
    ---@param mt Hook
    ---@return string?, number?
    function hook.get(mt)
        for event, hooks in pairs(hook.list) do
            local index = table.find(hooks, mt)
            if index then return event, index end
        end
    end

    -- Process event
    ---@param event string Event to process
    ---@param ... any Arguments
    ---@return any
    function hook.process(event, ...)
        if not hook.list[event] then return false end

        for k, mt in ipairs(hook.list[event]) do
            local status, err = pcall(mt.call, mt, ...)
            if not status then print(err) end
        end
    end

    -- Cast event
    ---@param event string Event to cast
    ---@return boolean
    function hook.cast(event)
        if hook.list[event] then return false end

        hook.list[event] = { }
        hook.unique[event] = function( ... ) return hook.process(event, ...) end
        pcall(client.set_event_callback, event, hook.unique[event])

        return true
    end

    -- Uncast event
    ---@param event string Event to uncast
    ---@return boolean
    function hook.uncast(event)
        if not hook.list[event] then return false end

        for k, mt in ipairs(hook.list[event]) do mt:unbind() end
        pcall(client.unset_event_callback, event, hook.unique[event])
        hook.unique[event] = nil
        hook.list[event] = nil

        collectgarbage('collect')

        return true
    end

    function hook.new(event, fn)
        local mt = setmetatable( { fn = fn } , hook.mt )
        mt:bind(event)

        return mt
    end

    ---@class Hook
    ---@field fn function Function to call
    ---@field bound string Bound event
    local mt = { }
    mt.__index = mt
    mt.__tostring = function(self) return 'Hook' end
    hook.mt = mt

    -- Return event and index
    ---@param self Hook
    ---@return string?, number?
    function mt:whoami()
        return hook.get(self)
    end

    -- Unbind hook
    ---@param self Hook
    ---@return boolean
    function mt:unbind()
        local event, index = self:whoami()
        if not event or not index then return false end
        self.bound = event

        table.remove(hook.list[event], index)

        return true
    end

    -- Bind hook
    ---@param self Hook
    ---@param event? string New event to bind
    ---@return boolean
    function mt:bind(event)
        if self:whoami() ~= nil then return false end
        event = event or self.bound

        if not event then return false end
        
        hook.cast(event)
        table.insert(hook.list[event], self)
        self.bound = nil

        return true
    end

    -- Execute hook
    ---@param self Hook
    ---@param ... any Arguments
    ---@return any
    function mt:call( ... )
        if type(self.fn) ~= 'function' then return false end
        if type(self.pass_condition) == 'function' then
            local try = self:pass_condition()

            if not try then return false end
        end

        return self.fn( ... )
    end

    -- Add condition to hook call
    ---@param fn function Condition
    ---@return boolean
    function mt:condition(fn)
        self.pass_condition = fn
        
        return true
    end
end

luna.api.hook = hook

local render = { } do

    render.temp = {
        blurReady = false, -- is blur ready
    }

    hook.new('paint_ui', function()
        local map, lp = globals.mapname(), entity.get_local_player()
        local team = entity.get_prop(lp, 'm_iTeamNum')
        local isLoaded = true

        if not map then isLoaded = false end
        if not lp then 
            isLoaded = false 
        elseif not team or team == 0 then
            isLoaded = false
        end

        render.temp.blurReady = isLoaded
    end)

    -- Render blur
    ---@param x number X position
    ---@param y number Y position
    ---@param w number W size
    ---@param h number H size
    function render.blur(x, y, w, h) -- make blur available only in-game to prevent possible crash
        x, y, w, h = math.round(x, y, w, h)

        if not render.temp.blurReady then return false end
        renderer.blur(x, y, w, h)
    end

    -- Render glow effect
    ---@param x number X position
    ---@param y number Y position
    ---@param w number W size
    ---@param h number H size
    ---@param r number Red channel
    ---@param g number Green channel
    ---@param b number Blue channel
    ---@param a number Alpha channel
    ---@param radius number Radius
    ---@param size number Size of glow
    ---@param quality number Quality of glow
    function render.glow(x, y, w, h, r, g, b, a, radius, size, quality)
        quality = quality or 3
        size = size or 5

        x, y, w, h, r, g, b, a, radius, size, quality = math.round(x, y, w, h, r, g, b, a, radius, size, quality)

        for i = size, 1, -1 do
            local distance = (i - 1) / (size - 1)
            render.rectangle_outline(x - i, y - i, w + i * 2, h + i * 2, r, g, b, a * math.exp(-distance * quality), radius + i, 1)
        end
    end

    ---@param x number X position
    ---@param y number Y position
    ---@param w number W size
    ---@param h number H size
    ---@param r number Red channel
    ---@param g number Green channel
    ---@param b number Blue channel
    ---@param a number Alpha channel
    ---@param radius number Radius
    function render.rectangle(x, y, w, h, r, g, b, a, radius)
        radius = radius or 4
        x, y, w, h, r, g, b, a, radius = math.round(x, y, w, h, r, g, b, a, radius)

        local limit = math.min(w, h) / 2 -- limit radius to dont break render
        radius = math.clamp(radius, 0, limit)

        -- rectangles
        renderer.rectangle(x + radius, y, w - 2 * radius, h, r, g, b, a)
        renderer.rectangle(x, y + radius, radius, h - 2 * radius, r, g, b, a)
        renderer.rectangle(x + w - radius, y + radius, radius, h - 2 * radius, r, g, b, a)

        -- corners
        renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
        renderer.circle(x + w - radius, y + radius, r, g, b, a, radius, 90, 0.25)
        renderer.circle(x + radius, y + h - radius, r, g, b, a, radius, -90, 0.25)
        renderer.circle(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25)
    end

    ---@param x number X position
    ---@param y number Y position
    ---@param w number W size
    ---@param h number H size
    ---@param r number Red channel
    ---@param g number Green channel
    ---@param b number Blue channel
    ---@param a number Alpha channel
    ---@param radius number Radius
    function render.rectangle_outline(x, y, w, h, r, g, b, a, radius, thickness)
        x, y, w, h, r, g, b, a, radius, thickness = math.round(x, y, w, h, r, g, b, a, radius, thickness)

        local limit = math.min(w, h) / 2 -- limit radius to dont break render
        radius = math.clamp(radius, 0, limit)

        -- rectangles / lines
        renderer.rectangle(x + radius, y, w - 2 * radius, thickness, r, g, b, a)
        renderer.rectangle(x + radius, y + h - thickness, w - 2 * radius, thickness, r, g, b, a)
        renderer.rectangle(x, y + radius, thickness, h - 2 * radius, r, g, b, a)
        renderer.rectangle(x + w - thickness, y + radius, thickness, h - 2 * radius, r, g, b, a)

        -- corners
        renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, thickness)
        renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, 270, 0.25, thickness)
        renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, thickness)
        renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, thickness)

        return true
    end

    ---@param x number X position
    ---@param y number Y position
    ---@param w number W size
    ---@param h number H size
    ---@param r number Red channel
    ---@param g number Green channel
    ---@param b number Blue channel
    ---@param a number Alpha channel
    ---@param radius number Radius
    function render.selection(x, y, w, h, r, g, b, a, radius)
        radius = radius or 4

        x = math.round(x); y = math.round(y); w = math.round(w); h = math.round(h)
        radius = math.min(radius, math.floor(w / 2), math.floor(h / 2))

        renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, 1)
        renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, 270, 0.25, 1)
        renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, 1)
        renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, 1)
    end
end

luna.api.render = render

local mouse = { } do 
    mouse.held = function() return client.key_state(0x01) end

    mouse.inbounds = function(x, y, w, h)
        local mX, mY = ui.mouse_position()

        return mX >= x and mY >= y and mX <= (x + w) and mY <= (y + h)
    end
end

luna.api.mouse = mouse

-- drag
local drag = { temp = { } } do
    local object = { }
    object.__index = object

    object.update = function(self, x, y, w, h)
        self.x = x or self.x
        self.y = y or self.y
        self.w = w or self.w
        self.h = h or self.h

        return self
    end

    object.setDraggable = function(self, state) self.draggable = state return self end

    object.isDraggable = function(self)
        if not self.draggable then return false end
        if not ui.is_menu_open() then return false end
        if not mouse.held() then return false end
        if not mouse.inbounds(self.x, self.y, self.w, self.h) then return false end
        local x, y = ui.menu_position()
        local w, h = ui.menu_size()
        
        if mouse.inbounds(x, y, w, h) then return false end -- uff ja block if mouse in menu 
        if drag.feed then return false end
        
        return true
    end

    object.dragStart = function(self, isForced)
        if self.dragHook then return self end

        local isDraggable = self:isDraggable()
        if not isDraggable and not isForced then return false end
        drag.publish(self)

        local sW, sH = client.screen_size()
        drag.snap = { -- adapt snap to new screensize
            {
                -- pos1: { x , y }
                -- pos2: { x , y }

                { 0 , sH / 2 },
                { sW, sH / 2 },
            },

            {
                { sW / 2 , 0 },
                { sW / 2, sH },
            }
        }

        self.dragHook = hook.new('paint_ui', function()
            self:dragUpdate()
        end)

        return self
    end

    object.dragStop = function(self)
        if not self.dragHook then return false end
        self.dragHook:unbind()
        self.dragHook = nil
        drag.publish(nil)

        self.dragOffsetX = nil
        self.dragOffsetY = nil

        return self
    end

    object.snapToLines = function(self, x, y)
        if not drag.snap or #drag.snap == 0 then return x, y end

        local threshold = 45
        local snapX, snapY = x, y

        local centerX = x + self.w / 2
        local centerY = y + self.h / 2

        for _, line in ipairs(drag.snap) do
            local pos1, pos2 = line[1], line[2]

            if pos1[1] == pos2[1] then
                local lineX = pos1[1]
                if math.abs(centerX - lineX) <= threshold then
                    snapX = lineX - self.w / 2
                end
            end

            if pos1[2] == pos2[2] then
                local lineY = pos1[2]
                if math.abs(centerY - lineY) <= threshold then
                    snapY = lineY - self.h / 2
                end
            end
        end

        return snapX, snapY
    end

    object.dragUpdate = function(self)
        if not mouse.held() then
            self:dragStop()
            return false
        end

        local mX, mY = ui.mouse_position()

        if not self.dragOffsetX or not self.dragOffsetY then
            self.dragOffsetX = mX - self.x
            self.dragOffsetY = mY - self.y
        end

        local targetX = mX - self.dragOffsetX
        local targetY = mY - self.dragOffsetY

        targetX, targetY = self:snapToLines(targetX, targetY)

        if not self.blocked.x then self.x = math.lerp(self.x, targetX, .15) end
        if not self.blocked.y then self.y = math.lerp(self.y, targetY, .15) end

        local sW, sH = client.screen_size()

        if self.x < 0 then self.x = 0 end
        if self.y < 0 then self.y = 0 end

        if self.x + self.w > sW then self.x = sW - self.w end
        if self.y + self.h > sH then self.y = sH - self.h end

        if type(self.onUpdate) == 'function' then self:onUpdate() end

        return true
    end

    drag.object = function(x, y, w, h)
        return setmetatable({ x = x , y = y , w = w , h = h , draggable = true , id = '' , blocked = { } }, object)
    end
    
    drag.publish = function(what) drag.feed = what end
    drag.snap = { }

    drag.snapHook = hook.new('paint_ui', function()
        local dragging = type(drag.feed) == 'table'
        drag.temp.alpha = math.lerp(drag.temp.alpha, dragging and 1 or 0, .05)

        for _, snap in ipairs(drag.snap) do
            renderer.line(
                snap[1][1], snap[1][2],
                snap[2][1], snap[2][2],

                255, 255, 255, 150 * drag.temp.alpha
            )
        end
    end, 1)
end

luna.api.drag = drag

hook.new('setup_command', function(list)
    if drag.feed then
        list.in_attack = false
        list.in_attack2 = false
    end
end)

hook.new('paint_ui', function()
    if mouse.held() and ui.is_menu_open() and not drag.feed then
        client.delay_call(.1, function()
            if mouse.held() and ui.is_menu_open() and not drag.feed then
                drag.publish('')
            end
        end)
    elseif drag.feed and not mouse.held() then
        drag.publish()
    end
end)

-- widget
local widget = { } do
    local object = { }
    object.__index = object
    
    object.drawFn = holder

    object.update = function(self)
        self.drag.x = self.x
        self.drag.y = self.y
        self.drag.w = self.w
        self.drag.h = self.h
    end

    object.init = function(self)
        self.drag = drag.object(self.x, self.y, self.w, self.h)
        self.drag:setDraggable(false)
        self.temp = { }

        local _x, _y = client.screen_size()
        local x, y = ui.new_slider('LUA', 'B', self.id .. ':x', 0, _x, self.x), ui.new_slider('LUA', 'B', self.id .. ':y', 0, _y, self.y)

        self.ui = { x = x , y = y }

        ui.set_callback(x, function()
            self.x = ui.get(x)
            self.drag.x = ui.get(x)
        end)

        ui.set_callback(y, function()
            self.y = ui.get(y)
            self.drag.y = ui.get(y)
        end)

        ui.set_visible(x, false)
        ui.set_visible(y, false)

        self.drag.x = self.x
        self.drag.y = self.h

        self.drag.onUpdate = function(drag)
            self.x = drag.x ; self.y = drag.y ; self.w = drag.w ; self.h = drag.h
        
            ui.set(x, drag.x)
            ui.set(y, drag.y)
        end

        hook.new('paint_ui', function()
            self.drag:dragStart() -- if can then start dragging

            local shown = ui.is_menu_open() and self.shown
            local dragging = drag.feed == self.drag
            
            local alpha = shown and ( dragging and .9 or .6 ) or 0
            local offset = shown and ( dragging and 6 or 4 ) or 0
            local widget = self.shown and 1 or 0
            local modify = shown and 1 or 0

            self.temp.alpha = math.lerp(self.temp.alpha, alpha, .1)
            self.temp.offset = math.lerp(self.temp.offset, offset, .2)

            self.modify = math.lerp(self.modify, modify, .05)
            self.alpha = math.lerp(self.alpha, widget, .05)
            
            local offset = self.temp.offset
            local x, y, w, h = math.round(self.x), math.round(self.y), math.round(self.w), math.round(self.h)

            render.selection(x - offset, y - offset, w + offset * 2, h + offset * 2, 255, 255, 255, 255 * self.temp.alpha, 5)

            if type(self.drawFn) == 'function' then
                self:drawFn()
            end
        end)

        self.init = nil
        return self 
    end

    object.center = function(self, x, y)
        if x then self.x = x - self.w / 2 end
        if y then self.y = y - self.h / 2 end
    end

    object.visible = function(self, state)
        self.drag:setDraggable(state)
        self.shown = state
    end

    object.disallow = function(self, what)
        self.drag.blocked[what] = true
    end

    object.allow = function(self, what)
        self.drag.blocked[what] = false
    end

    widget.new = function(id, x, y, w, h)
        return setmetatable({ id = id, x = x , y = y , w = w , h = h , shown = false }, object):init()
    end
end

luna.api.widget = widget

local exploit = { } do
    -- Is DT / OSAA charged?
    ---@return boolean
    function exploit.is_ready()
        local lp = entity.get_local_player()
        if not lp then return false end

        return globals.tickcount() > entity.get_prop(lp, 'm_nTickBase')
    end

    -- For defensive
    exploit.tickbase = { command = 0, previous = 0, delta = 0 }

    exploit.tickbase.run_command = hook.new('run_command', function(cmd)
        exploit.tickbase.command = cmd.command_number
    end)

    exploit.tickbase.predict_command = hook.new('predict_command', function(cmd)
        if cmd.command_number == exploit.tickbase.command then
            local tickbase = entity.get_prop(entity.get_local_player(), 'm_nTickBase')

            exploit.tickbase.delta = math.clamp(math.abs(tickbase - exploit.tickbase.previous) - 1, 0, 14) -- -1 to get only ticks modified by exploit
            exploit.tickbase.previous = math.max(tickbase, exploit.tickbase.previous or 0)
            exploit.tickbase.command = 0
        end
    end)

	exploit.tickbase.level_init = hook.new('level_init', function()
		exploit.tickbase.previous = 0
        exploit.tickbase.delta = 0
	end)

    -- Get tickbase delta.
    ---@return number
    function exploit.get_delta()
        return exploit.tickbase.delta
    end

    -- Does player in defensive right now?
    ---@param cmd table Command CTX
    ---@return boolean
    function exploit.in_defensive(cmd)
        if not exploit.is_ready() then return false end

        return (cmd and cmd.force_defensive) or exploit.get_delta() > 8
    end

    -- Can defensive be forced?
    ---@param tick number Forced tick
    ---@return boolean
    function exploit.can_be_forced(tick)
        local lp = entity.get_local_player()
        if not lp or not exploit.is_ready() then return false end
        
        return globals.tickcount() % 14 < tick
    end
end

luna.api.exploit = exploit

local utils = { } do
    utils.native = { } do
        -- Interface's
        utils.native.vgui3 = client.create_interface('vguimatsurface.dll', 'VGUI_Surface031')

        -- Native's
        utils.native.playsound = ffi.cast('void(__thiscall*)(void*, const char*)', (ffi.cast('void***', utils.native.vgui3)[0])[82])
    end
        
    -- Play sound by path
    ---@param path string Path to file in "csgo/sound"
    ---@return nil
    function utils.playsound(path)
        local sound = ffi.cast('const char*', path)

        utils.native.playsound(utils.native.vgui3, sound)
    end

    -- Normalize value by limit
    ---@param value number Value to normalize
    ---@param limit number Limitation
    ---@return number
    function utils.normalize(value, limit)
        return ((value + limit) % (limit * 2)) - limit
    end

    -- Spin between two values
    ---@param v1 number Min / Start
    ---@param v2 number Max / End
    ---@return number
    function utils.spin(v1, v2)
        local t = 0.5 * (1 - math.cos(globals.realtime() * math.pi))
        return v1 + (v2 - v1) * t
    end
end

luna.api.utils = utils

return luna