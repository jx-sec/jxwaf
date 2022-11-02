-- Copyright (C) Dejiang Zhu(doujiang24)


local setmetatable = setmetatable
local ngx_null = ngx.null

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end


local _M = {}
local mt = { __index = _M }

function _M.new(self, batch_num, max_buffering)
    local sendbuffer = {
        queue = new_tab(max_buffering * 3, 0),
        batch_num = batch_num,
        size = max_buffering * 3,
        start = 1,
        num = 0,
    }
    return setmetatable(sendbuffer, mt)
end


function _M.add(self, topic, key, message)
    local num = self.num
    local size = self.size

    if num >= size then
        return nil, "buffer overflow"
    end

    local index = (self.start + num) % size
    local queue = self.queue

    queue[index] = topic
    queue[index + 1] = key
    queue[index + 2] = message

    self.num = num + 3

    return true
end


function _M.pop(self)
    local num = self.num
    if num <= 0 then
        return nil, "empty buffer"
    end

    self.num = num - 3

    local start = self.start
    local queue = self.queue

    self.start = (start + 3) % self.size

    local key, topic, message = queue[start], queue[start + 1], queue[start + 2]

    queue[start], queue[start + 1], queue[start + 2] = ngx_null, ngx_null, ngx_null

    return key, topic, message
end


function _M.left_num(self)
    return self.num / 3
end


function _M.need_send(self)
    return self.num / 3 >= self.batch_num
end


return _M
