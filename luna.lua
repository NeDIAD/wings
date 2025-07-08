--[[

        /ᐠ. ｡.ᐟ\ᵐᵉᵒʷˎˊ˗ 
        Made by NeDIAD a.k.a NotDIAD
        https://github.com/NeDIAD , @nediad , @notdiad

]]

local ffi = require 'ffi'

--#region color
local color = {} do
    -- metatable based
    color.mt = {}
    color.mt.__index = color.mt 

    function color.mt:rgb()
        return self.r or 255, self.g or 255, self.b or 255
    end

    function color.mt:rgba()
        return self.r or 255, self.g or 255, self.b or 255, self.a or 255
    end

    function color.mt:hex()
        return color.toHex(self:rgb())
    end

    function color.mt:hexa()
        return color.toHex(self:rgba())
    end

    color.toHex = function(r, g, b, a)
        local pattern = '\a%02X%02X%02X' .. (a and '%02X' or '')
        return string.format(pattern, r, g, b, a)
    end

    color.alpha = function(str, a) -- turn HEX in string to HEXA
        local hex = string.format('%02X', a or 255)

        return string.gsub(str, '\a(%x%x%x%x%x%x)', function(col) return '\a' .. col .. hex end)
    end

    color.new = function(r, g, b, a)
        return setmetatable({ r = r , g = g , b = b , a = a }, color.mt)
    end
       
    -- ffi based
    ffi.cdef[[
        typedef struct {
            uint8_t r, g, b, a;
        } luna_color_struct_t; 
    ]]

    local function rgba_hex(hex)
        hex = string.gsub(hex, '^#', '') -- remove #
        return tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16), tonumber(string.sub(hex, 5, 6), 16), tonumber(string.sub(hex, 7, 8), 16) or 255
    end
        
    color.ffirgb = function(r, g, b, a)
        local mt = ffi.new('luna_color_struct_t')

        mt.r = r
        mt.g = g
        mt.b = b
        mt.a = a

        return mt 
    end

    color.ffihex = function(hex) return color.ffirgb(rgba_hex(hex)) end

    function color.mt:toFfi()
        return color.ffirgb(self:rgba())
    end
end

--#endregion

--#region throw
local throw = {} do
    throw.reset = color.new():hex()

    throw.natives = {
        print = vtable_bind('vstdlib.dll', 'VEngineCvar007', 25, 'void(__cdecl*)(void*, const void*, const char*, ...)')
    }

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
--#endregion

--#region table
local cTable = table
local table = setmetatable({}, { __index = cTable })

table.find = function(where, what, fn)
    fn = fn or function(v, need) return v == need end

    for i, v in ipairs(where) do
        if fn(v, what) then return i end
    end

    return nil
end

table.toArray = function(what, debug)
    local array = {}
    debug = debug or 2
    
    for _, v in pairs(what) do
        local data = {_, v}
        if debug == 1 then data = _ end
        if debug == 2 then data = v end

        table.insert(array, data)
    end
    
    return array
end

table.copy = function(what)
    if type(what) ~= 'table' then return what end
    local copy = {}

    for i, v in ipairs(what) do
        copy[i] = table.copy(v)
    end

    for i, v in pairs(what) do
        copy[i] = table.copy(v)
    end

    return copy
end
--#endregion


--#region math
local cMath = math
local math = setmetatable({}, { __index = cMath })

math.round = function(...)
    local pack, data = {}, { ... }
    for _, v in ipairs(data) do
        pack[_] = math.floor(v + .5)
    end
    return unpack(pack)
end

math.rainbow = function(speed)
    speed = speed or 1
    
    local time = globals.realtime() * speed

    return math.floor(math.sin(time) * 127 + 128), math.floor(math.sin(time + 2 * math.pi / 3) * 127 + 128), math.floor(math.sin(time + 4 * math.pi / 3) * 127 + 128)
end

math.clamp = function(value, min, max)
    return math.max(min, math.min(value, max))
end

math.lerp = function(a, b, t, force)
    if not a or not b or not t then return 0 end

    if math.abs(a - b) < .01 and not force then return b end
    local lerp = a + (b - a) * t
    return lerp
end

math.pulse = function(min, max, speed, time)
    time = time or globals.realtime()

    return (max + min) / 2 + math.sin(time * speed) * (max - min) / 2
end
--#endregion


local luna = { mods = { } }

luna.register = function(name, module)
    if luna.mods[name] then error('That module already registered') return false end
    luna.mods[name] = module
    
    return true
end

luna.export = function(name)
    return luna.mods[name] or false
end

--#region mods
luna.register('color', color)
luna.register('throw', throw)
luna.register('table', table)
luna.register('math', math)

-- tweaks
local tweaks = {}

tweaks.steam32 = function(steam3)
    -- [U:1:XXXXXXXXX]
    local id = tonumber(steam3)
    if not id then return nil end

    local id = ffi.new('uint64_t', tonumber(steam3))
    local offset = ffi.new('uint64_t', 76561197960265728)
    -- ^ lua + big numbers = inaccuracy

    -- steam64 = steam3 + 76561197960265728
    return tostring(id + offset):gsub('ULL', '')
end

tweaks.time = function(ts)
    ts = ts or client.unix_time()

    return panorama.loadstring(string.format([[
        var date = new Date(%d * 1000);
        var year = date.getFullYear();
        var month = String(date.getMonth() + 1).padStart(2, '0');
        var day = String(date.getDate()).padStart(2, '0');
        var hours = String(date.getHours()).padStart(2, '0');
        var minutes = String(date.getMinutes()).padStart(2, '0');
        var seconds = String(date.getSeconds()).padStart(2, '0');
        return year + '-' + month + '-' + day + ' ' + hours + ':' + minutes + ':' + seconds;
    ]], ts))()
end

luna.register('tweaks', tweaks)

-- hook
local hook = { list = { } , casted = { } }
hook.mt = {}
hook.mt.__index = hook.mt

function hook.mt:remove()
    local id = table.find(hook.list, self, function(this) return this.fn == self.fn end)
    if id then table.remove(hook.list, id) end
    
    return id
end

hook.new = function(what, fn)
    local mt = setmetatable({
        hook = what,
        fn = fn,
    }, hook.mt)

    table.insert(hook.list, mt)
    if not hook.casted[what] then
        pcall(hook.cast, what)
    end

    return mt
end

hook.call = function(what, ...)
    for _, mt in ipairs(hook.list) do
        if mt.hook == what then
            mt.fn = type(mt.fn) == 'function' and mt.fn or function() return end
            local status, reason = pcall(mt.fn, ...)
            if not status then error(what .. ': ' .. reason) end
        end
    end

    return true
end

hook.cast = function(what)
    local cast = function(...)
        hook.call(what, ...)
    end

    pcall(client.set_event_callback, what, cast)
    hook.casted[what] = cast

    return true
end

hook.uncast = function(what)
    local cast = hook.casted[what]
    if not cast then return false end
    pcall(client.unset_event_callback, what, cast)
    hook.casted[what] = nil

    return true
end

luna.register('hook', hook)

-- render
local render = { }

render.temp = {
    blurReady = false, -- is blur ready
}

client.set_event_callback('paint_ui', function()
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

-- render functions
function render.blur(x, y, w, h) -- make blur available only in-game to prevent possible crash
    x, y, w, h = math.round(x, y, w, h)

    if not render.temp.blurReady then return false end
    renderer.blur(x, y, w, h)
end

function render.glow(x, y, w, h, r, g, b, a, radius, size, quality)
    quality = quality or 3
    size = size or 5

    x, y, w, h, r, g, b, a, radius, size, quality = math.round(x, y, w, h, r, g, b, a, radius, size, quality)
    
    for i = size, 1, -1 do
        local distance = (i - 1) / (size - 1)
        render.rectangle_outline(x - i, y - i, w + i * 2, h + i * 2, r, g, b, a * math.exp(-distance * quality), radius + i, 1)
    end
end

---@param x number Position X
---@param y number Position Y
---@param w number Size W
---@param h number Size H
---@param r number Red Color
---@param g number Green Color
---@param b number Blue Color
---@param a number Alpha Color
---@param radius number Corner radius
---@return boolean
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

    return true
end

---@param x number Position X
---@param y number Position Y
---@param w number Size W
---@param h number Size H
---@param r number Red Color
---@param g number Green Color
---@param b number Blue Color
---@param a number Alpha Color
---@param radius number Corner radius
---@return boolean
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

function render.selection(x, y, w, h, r, g, b, a, radius)
    radius = radius or 4

    x = math.round(x); y = math.round(y); w = math.round(w); h = math.round(h)
    radius = math.min(radius, math.floor(w / 2), math.floor(h / 2))

    renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, 1)
    renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, 270, 0.25, 1)
    renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, 1)
    renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, 1)
end

luna.register('render', render)

-- mouse
local mouse = {} do 
    mouse.held = function() return client.key_state(0x01) end

    mouse.inbounds = function(x, y, w, h)
        local mX, mY = ui.mouse_position()

        return mX >= x and mY >= y and mX <= (x + w) and mY <= (y + h)
    end
end

luna.register('mouse', mouse)

-- drag
local drag = { temp = {} } do
    local object = {}
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
        self.dragHook:remove()
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
        return setmetatable({ x = x , y = y , w = w , h = h , draggable = true , id = '' , blocked = {} }, object)
    end
    
    drag.publish = function(what) drag.feed = what end
    drag.snap = {}

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

luna.register('drag', drag)

-- widget
local widget = {} do
    local object = {}
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
        self.temp = {}

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

luna.register('widget', widget)

--#endregion

luna.commit = commit or '?'

return luna