local client = require("resty.kafka.client")
local broker = require("resty.kafka.broker")
local protocol_consumer = require("resty.kafka.protocol.consumer")
local Errors = require("resty.kafka.errors")

local ngx_log = ngx.log
local INFO = ngx.INFO


local _M = { _VERSION = "0.20" }
local mt = { __index = _M }

function _M.new(self, broker_list, client_config)
    local opts = client_config or {}

    local cli = client:new(broker_list, client_config)
    local p = setmetatable({
        client = cli,
        correlation_id = 1,
        isolation_level = opts.isolation_level or 0,
        client_rack = opts.client_rack or "default",
        socket_config = cli.socket_config,
    }, mt)

    return p
end


--- Get the available offsets of the partition of the specified topic
-- When the error in request, offset will be nil and err will be the error message.
-- @author bzp2010 <bzp2010@apache.org>
-- @param self
-- @param topic      The name of topic
-- @param partition  The partition of topic
-- @param timestamp  The starting timestamp of the obtained message offset
-- @return offset    The obtained offset value, may be nil
-- @return err       The error of request, may be nil
function _M.list_offset(self, topic, partition, timestamp)
    timestamp = timestamp or protocol_consumer.LIST_OFFSET_TIMESTAMP_FIRST

    local cli = self.client
    local broker_conf, err = cli:choose_broker(topic, partition)
    if not broker_conf then
        return nil, err
    end

    local bk, err = broker:new(broker_conf.host, broker_conf.port, self.socket_config, broker_conf.sasl_config)
    if not bk then
        return nil, err
    end

    local req, err = protocol_consumer.list_offset_encode(self, {
        topic_num = 1,
        topics = {
            [topic] = {
                partition_num = 1,
                partitions = {
                    [partition] = {
                        timestamp = timestamp
                    }
                },
            }
        },
    })
    if not req then
        return nil, err
    end

    local resp, err = bk:send_receive(req)
    if not resp then
        return nil, err
    end

    local result = protocol_consumer.list_offset_decode(resp)
    local data = result.topics[topic].partitions[partition]

    local errcode = data.errcode
    if errcode ~= 0 then
        err = Errors[errcode].msg

        ngx_log(INFO, "list offset err: ", err, ", topic: ", topic,
            ", partition_id: ", partition)

        return nil, err
    end

    return data.offset, nil
end


--- Fetch message
-- The maximum waiting time is 100 ms, and the maximum message response is 100 MiB.
-- @author bzp2010 <bzp2010@apache.org>
-- @param self
-- @param topic      The name of topic
-- @param partition  The partition of topic
-- @param offset     The starting offset of the message to get
-- @return messages  The obtained offset messages, which is in a table, may be nil
-- @return err       The error of request, may be nil
function _M.fetch(self, topic, partition, offset)
    local cli = self.client
    local broker_conf, err = cli:choose_broker(topic, partition)
    if not broker_conf then
        return nil, err
    end

    local bk, err = broker:new(broker_conf.host, broker_conf.port, self.socket_config, broker_conf.sasl_config)
    if not bk then
        return nil, err
    end

    local req = protocol_consumer.fetch_encode(self, {
        topic_num = 1,
        topics = {
            [topic] = {
                partition_num = 1,
                partitions = {
                    [partition] = {
                        offset = offset
                    }
                },
            }
        },
    })
    if not req then
        return nil, err
    end

    local resp, err = bk:send_receive(req)
    if not resp then
        return nil, err
    end

    local result = protocol_consumer.fetch_decode(resp, offset)
    local data = result.topics[topic].partitions[partition]

    local errcode = data.errcode
    if errcode ~= 0 then
        err = Errors[errcode].msg

        ngx_log(INFO, "fetch message err: ", err, ", topic: ", topic,
            ", partition_id: ", partition)

        return nil, err
    end

    return data, nil
end


return _M
