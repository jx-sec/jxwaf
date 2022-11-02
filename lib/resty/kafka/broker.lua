-- Copyright (C) Dejiang Zhu(doujiang24)


local response = require "resty.kafka.response"
local request = require "resty.kafka.request"

local to_int32 = response.to_int32
local setmetatable = setmetatable
local tcp = ngx.socket.tcp
local pid = ngx.worker.pid
local tostring = tostring

local sasl = require "resty.kafka.sasl"

local _M = {}
local mt = { __index = _M }


local function _sock_send_recieve(sock, request)
    local bytes, err = sock:send(request:package())
    if not bytes then
        return nil, err, true
    end

    local len, err = sock:receive(4)
    if not len then
        if err == "timeout" then
            sock:close()
            return nil, err
        end
        return nil, err, true
    end

    local data, err = sock:receive(to_int32(len))
    if not data then
        if err == "timeout" then
            sock:close()
            return nil, err
        end
        return nil, err, true
    end

    return response:new(data, request.api_version), nil, true
end


local function _sasl_handshake(sock, brk)
    local cli_id = "worker" .. pid()
    local req = request:new(request.SaslHandshakeRequest, 0, cli_id,
                            request.API_VERSION_V1)

    req:string(brk.auth.mechanism)

    local resp, err = _sock_send_recieve(sock, req, brk.config)
    if not resp  then
        return nil, err
    end

    local err_code = resp:int16()
    if err_code ~= 0 then
        local error_msg = resp:string()

        return nil, error_msg
    end

    return true
end


local function _sasl_auth(sock, brk)
    local cli_id = "worker" .. pid()
    local req = request:new(request.SaslAuthenticateRequest, 0, cli_id,
                            request.API_VERSION_V1)

    local msg = sasl.encode(brk.auth.mechanism, nil, brk.auth.user,
                            brk.auth.password)

    req:bytes(msg)

    local resp, err = _sock_send_recieve(sock, req, brk.config)
    if not resp  then
        return nil, err
    end

    local err_code = resp:int16()
    local error_msg = resp:string()
    local auth_bytes = resp:bytes()

    if err_code ~= 0 then
        return nil, error_msg
    end

    return true
end


local function sasl_auth(sock, broker)
    local ok, err = _sasl_handshake(sock, broker)
    if  not ok then
        return nil, err
    end

    local ok, err = _sasl_auth(sock, broker)
    if not ok then
        return nil, err
    end

    return true
end


function _M.new(self, host, port, socket_config, sasl_config)
    return setmetatable({
        host = host,
        port = port,
        config = socket_config,
        auth = sasl_config,
    }, mt)
end


function _M.send_receive(self, request)
    local sock, err = tcp()
    if not sock then
        return nil, err, true
    end

    sock:settimeout(self.config.socket_timeout)

    local ok, err = sock:connect(self.host, self.port)
    if not ok then
        return nil, err, true
    end

    local times, err = sock:getreusedtimes()
    if not times then
        return nil, "failed to get reused time: " .. tostring(err), true
    end

    if self.config.ssl and times == 0 then
        -- first connectted connnection
        local ok, err = sock:sslhandshake(false, self.host,
                                          self.config.ssl_verify)
        if not ok then
            return nil, "failed to do SSL handshake with "
                        ..  self.host .. ":" .. tostring(self.port) .. ": "
                        .. err, true
        end
    end

    if self.auth and times == 0 then -- SASL AUTH
        local ok, err = sasl_auth(sock, self)
        if  not ok then
            return nil, "failed to do " .. self.auth.mechanism .." auth with "
                        ..  self.host .. ":" .. tostring(self.port) .. ": "
                        .. err, true

        end
    end

    local data, err, retryable = _sock_send_recieve(sock, request)

    sock:setkeepalive(self.config.keepalive_timeout, self.config.keepalive_size)

    return data, err, retryable
end


return _M
