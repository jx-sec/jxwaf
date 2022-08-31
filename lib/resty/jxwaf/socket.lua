-- Copyright (C) 2013-2014 Jiale Zhi (calio), CloudFlare Inc.
--require "luacov"

local concat                = table.concat
local tcp                   = ngx.socket.tcp
local udp                   = ngx.socket.udp
local timer_at              = ngx.timer.at
local ngx_log               = ngx.log
local ngx_sleep             = ngx.sleep
local type                  = type
local pairs                 = pairs
local tostring              = tostring
local debug                 = ngx.config.debug

local DEBUG                 = ngx.DEBUG
local CRIT                  = ngx.CRIT

local MAX_PORT              = 65535


-- table.new(narr, nrec)
local succ, new_tab = pcall(require, "table.new")
if not succ then
    new_tab = function () return {} end
end

local _M = new_tab(0, 5)
local _mt = { __index = _M }

local is_exiting

if not ngx.config or not ngx.config.ngx_lua_version
    or (ngx.config.subsystem ~= "stream" and ngx.config.ngx_lua_version < 9003) then

    is_exiting = function() return false end

    ngx_log(CRIT, "We strongly recommend you to update your ngx_lua module to "
            .. "0.9.3 or above. lua-resty-logger-socket will lose some log "
            .. "messages when Nginx reloads if it works with ngx_lua module "
            .. "below 0.9.3")
else
    is_exiting = ngx.worker.exiting
end


_M._VERSION = '0.03'

local logger_socket


local function _write_error(self, msg)
    self.last_error = msg
end

local function _do_connect(self)
    local ok, err, sock

    if not self.connected then
        if (self.sock_type == 'udp') then
            sock, err = udp()
        else
            sock, err = tcp()
        end

        if not sock then
            _write_error(self, err)
            return nil, err
        end

        sock:settimeout(self.timeout)
    end

    -- "host"/"port" and "path" have already been checked in init()
    if self.host and self.port then
        if (self.sock_type == 'udp') then
            ok, err = sock:setpeername(self.host, self.port)
        else
            ok, err = sock:connect(self.host, self.port)
        end
    elseif self.path then
        ok, err = sock:connect("unix:" .. self.path)
    end

    if not ok then
        return nil, err
    end

    return sock
end

local function _do_handshake(self, sock)
    if not self.ssl then
        return sock
    end

    local session, err = sock:sslhandshake(self.ssl_session, self.sni_host or self.host,
                                           self.ssl_verify)
    if not session then
        return nil, err
    end

    self.ssl_session = session
    return sock
end

local function _connect(self)
    local err, sock

    if self.connecting then
        if debug then
            ngx_log(DEBUG, "previous connection not finished")
        end
        return nil, "previous connection not finished"
    end

    self.connected = false
    self.connecting = true

    self.retry_connect = 0

    while self.retry_connect <= self.max_retry_times do
        sock, err = _do_connect(self)

        if sock then
            sock, err = _do_handshake(self, sock)
            if sock then
                self.connected = true
                break
            end
        end

        if debug then
            ngx_log(DEBUG, "reconnect to the log server: ", err)
        end

        -- ngx.sleep time is in seconds
        if not self.exiting then
            ngx_sleep(self.retry_interval / 1000)
        end

        self.retry_connect = self.retry_connect + 1
    end

    self.connecting = false
    if not self.connected then
        return nil, "try to connect to the log server failed after "
                    .. self.max_retry_times .. " retries: " .. err
    end

    return sock
end

local function _prepare_stream_buffer(self)
    local packet = concat(self.log_buffer_data, "", 1, self.log_buffer_index)
    self.send_buffer = self.send_buffer .. packet

    self.log_buffer_index = 0
    self.counter = self.counter + 1
    if self.counter > self.max_buffer_reuse then
        self.log_buffer_data = new_tab(20000, 0)
        self.counter = 0
        if debug then
            ngx_log(DEBUG, "log buffer reuse limit (" .. self.max_buffer_reuse
                    .. ") reached, create a new \"log_buffer_data\"")
        end
    end
end

local function _do_flush(self)
    local ok, err, sock, bytes
    local packet = self.send_buffer

    sock, err = _connect(self)
    if not sock then
        return nil, err
    end

    bytes, err = sock:send(packet)
    if not bytes then
        -- "sock:send" always closes current connection on error
        return nil, err
    end

    if debug then
        ngx.update_time()
        ngx_log(DEBUG, ngx.now(), ":log flush:" .. bytes .. ":" .. packet)
    end

    if (self.sock_type ~= 'udp') then
        ok, err = sock:setkeepalive(0, self.pool_size)
        if not ok then
            return nil, err
        end
    end

    return bytes
end

local function _need_flush(self)
    if self.buffer_size > 0 then
        return true
    end

    return false
end

local function _flush_lock(self)
    if not self.flushing then
        if debug then
            ngx_log(DEBUG, "flush lock acquired")
        end
        self.flushing = true
        return true
    end
    return false
end

local function _flush_unlock(self)
    if debug then
        ngx_log(DEBUG, "flush lock released")
    end
    self.flushing = false
end

local function _flush(premature, self)
    local err

    -- pre check
    if not _flush_lock(self) then
        if debug then
            ngx_log(DEBUG, "previous flush not finished")
        end
        -- do this later
        return true
    end

    if not _need_flush(self) then
        if debug then
            ngx_log(DEBUG, "no need to flush:", self.log_buffer_index)
        end
        _flush_unlock(self)
        return true
    end

    -- start flushing
    self.retry_send = 0
    if debug then
        ngx_log(DEBUG, "start flushing")
    end

    local bytes
    while self.retry_send <= self.max_retry_times do
        if self.log_buffer_index > 0 then
            _prepare_stream_buffer(self)
        end

        bytes, err = _do_flush(self)

        if bytes then
            break
        end

        if debug then
            ngx_log(DEBUG, "resend log messages to the log server: ", err)
        end

        -- ngx.sleep time is in seconds
        if not self.exiting then
            ngx_sleep(self.retry_interval / 1000)
        end

        self.retry_send = self.retry_send + 1
    end

    _flush_unlock(self)

    if not bytes then
        local err_msg = "try to send log messages to the log server "
                        .. "failed after " .. self.max_retry_times .. " retries: "
                        .. err
        _write_error(self, err_msg)
        return nil, err_msg
    else
        if debug then
            ngx_log(DEBUG, "send " .. bytes .. " bytes")
        end
    end

    self.buffer_size = self.buffer_size - #self.send_buffer
    self.send_buffer = ""

    return bytes
end

local function _periodic_flush(premature, self)
    if premature then
        self.exiting = true
    end

    if self.need_periodic_flush or self.exiting then
        -- no regular flush happened after periodic flush timer had been set
        if debug then
            ngx_log(DEBUG, "performing periodic flush")
        end
        _flush(_, self)
    else
        if debug then
            ngx_log(DEBUG, "no need to perform periodic flush: regular flush "
                    .. "happened before")
        end
        self.need_periodic_flush = true
    end

    timer_at(self.periodic_flush, _periodic_flush, self)
end

local function _flush_buffer(self)
    local ok, err = timer_at(0, _flush, self)

    self.need_periodic_flush = false

    if not ok then
        _write_error(self, err)
        return nil, err
    end
end

local function _write_buffer(self, msg, len)
    self.log_buffer_index = self.log_buffer_index + 1
    self.log_buffer_data[self.log_buffer_index] = msg

    self.buffer_size = self.buffer_size + len


    return self.buffer_size
end

function _mt.new(self, user_config)

    -- user config
    local conf = {
        flush_limit           = 4096,         -- 4KB
        drop_limit            = 1048576,      -- 1MB
        timeout               = 1000,         -- 1 sec
        host                  = nil,
        port                  = nil,
        ssl                   = false,
        ssl_verify            = true,
        sni_host              = nil,
        path                  = nil,
        max_buffer_reuse      = 10000,        -- reuse buffer for at most 10000 times
        periodic_flush        = nil,
        need_periodic_flush   = nil,
        sock_type             = 'tcp',

        -- internal variables
        buffer_size           = 0,
        -- 2nd level buffer, it stores logs ready to be sent out
        send_buffer           = "",
        -- 1st level buffer, it stores incoming logs
        log_buffer_data       = new_tab(20000, 0),
        -- number of log lines in current 1st level buffer, starts from 0
        log_buffer_index      = 0,

        last_error            = nil,

        connecting            = nil,
        connected             = nil,
        exiting               = nil,
        retry_connect         = 0,
        retry_send            = 0,
        max_retry_times       = 3,
        retry_interval        = 100,         -- 0.1s
        pool_size             = 10,
        flushing              = nil,
        logger_initted        = nil,
        counter               = 0,
        ssl_session           = nil
    }

    local logger = setmetatable(conf, _mt)

    if user_config then
        local ok, err = logger:init(user_config)
        if not ok then
            return nil, err
        end
    end
    logger_socket = logger
    return logger
end


function _mt.init(user_config)
    logger_socket = _mt:new()
    return logger_socket:init(user_config)
end


function _M.init(self, user_config)
    if (type(user_config) ~= "table") then
        return nil, "user_config must be a table"
    end

    for k, v in pairs(user_config) do
        if k == "host" then
            if type(v) ~= "string" then
                return nil, '"host" must be a string'
            end
            self.host = v
        elseif k == "port" then
            if type(v) ~= "number" then
                return nil, '"port" must be a number'
            end
            if v < 0 or v > MAX_PORT then
                return nil, ('"port" out of range 0~%s'):format(MAX_PORT)
            end
            self.port = v
        elseif k == "path" then
            if type(v) ~= "string" then
                return nil, '"path" must be a string'
            end
            self.path = v
        elseif k == "sock_type" then
            if type(v) ~= "string" then
                return nil, '"sock_type" must be a string'
            end
            if v ~= "tcp" and v ~= "udp" then
                return nil, '"sock_type" must be "tcp" or "udp"'
            end
            self.sock_type = v
        elseif k == "flush_limit" then
            if type(v) ~= "number" or v < 0 then
                return nil, 'invalid "flush_limit"'
            end
            self.flush_limit = v
        elseif k == "drop_limit" then
            if type(v) ~= "number" or v < 0 then
                return nil, 'invalid "drop_limit"'
            end
            self.drop_limit = v
        elseif k == "timeout" then
            if type(v) ~= "number" or v < 0 then
                return nil, 'invalid "timeout"'
            end
            self.timeout = v
        elseif k == "max_retry_times" then
            if type(v) ~= "number" or v < 0 then
                return nil, 'invalid "max_retry_times"'
            end
            self.max_retry_times = v
        elseif k == "retry_interval" then
            if type(v) ~= "number" or v < 0 then
                return nil, 'invalid "retry_interval"'
            end
            -- ngx.sleep time is in seconds
            self.retry_interval = v
        elseif k == "pool_size" then
            if type(v) ~= "number" or v < 0 then
                return nil, 'invalid "pool_size"'
            end
            self.pool_size = v
        elseif k == "max_buffer_reuse" then
            if type(v) ~= "number" or v < 0 then
                return nil, 'invalid "max_buffer_reuse"'
            end
            self.max_buffer_reuse = v
        elseif k == "periodic_flush" then
            if type(v) ~= "number" or v < 0 then
                return nil, 'invalid "periodic_flush"'
            end
            self.periodic_flush = v
        elseif k == "ssl" then
            if type(v) ~= "boolean" then
                return nil, '"ssl" must be a boolean value'
            end
            self.ssl = v
        elseif k == "ssl_verify" then
            if type(v) ~= "boolean" then
                return nil, '"ssl_verify" must be a boolean value'
            end
            self.ssl_verify = v
        elseif k == "sni_host" then
            if type(v) ~= "string" then
                return nil, '"sni_host" must be a string'
            end
            self.sni_host = v
        end
    end

    if not (self.host and self.port) and not self.path then
        return nil, "no logging server configured. \"host\"/\"port\" or "
                .. "\"path\" is required."
    end


    if (self.flush_limit >= self.drop_limit) then
        return nil, "\"flush_limit\" should be < \"drop_limit\""
    end

    self.flushing = false
    self.exiting = false
    self.connecting = false

    self.connected = false
    self.retry_connect = 0
    self.retry_send = 0

    self.logger_initted = true

    if self.periodic_flush then
        if debug then
            ngx_log(DEBUG, "periodic flush enabled for every "
                    .. self.periodic_flush .. " seconds")
        end
        self.need_periodic_flush = true
        timer_at(self.periodic_flush, _periodic_flush, self)
    end

    return self.logger_initted
end

function _mt.log(msg)
    if not logger_socket then
        return nil, "not initialized"
    end

    return logger_socket:log(msg)
end

function _M.log(self, msg)
    if not self.logger_initted then
        return nil, "not initialized"
    end

    local bytes

    if type(msg) ~= "string" then
        msg = tostring(msg)
    end

    local msg_len = #msg

    if (debug) then
        ngx.update_time()
        ngx_log(DEBUG, ngx.now(), ":log message length: " .. msg_len)
    end

    -- response of "_flush_buffer" is not checked, because it writes
    -- error buffer
    if (is_exiting()) then
        self.exiting = true
        _write_buffer(self, msg, msg_len)
        _flush_buffer(self)
        if (debug) then
            ngx_log(DEBUG, "Nginx worker is exiting")
        end
        bytes = 0
    elseif (msg_len + self.buffer_size < self.flush_limit) then
        _write_buffer(self, msg, msg_len)
        bytes = msg_len
    elseif (msg_len + self.buffer_size <= self.drop_limit) then
        _write_buffer(self, msg, msg_len)
        _flush_buffer(self)
        bytes = msg_len
    else
        _flush_buffer(self)
        if (debug) then
            ngx_log(DEBUG, "logger buffer is full, this log message will be "
                    .. "dropped")
        end
        bytes = 0
        --- this log message doesn't fit in buffer, drop it
    end

    if self.last_error then
        local err = self.last_error
        self.last_error = nil
        return bytes, err
    end

    return bytes
end

function _mt.initted()
    if not logger_socket then
        logger_socket = _mt:new()
    end

    return logger_socket.logger_initted
end

function _M.initted(self)
    return self.logger_initted
end

function _mt.flush()
    if not logger_socket then
        logger_socket = _mt:new()
    end

    return _flush(_, logger_socket)
end

_M.flush = _flush

return _mt
