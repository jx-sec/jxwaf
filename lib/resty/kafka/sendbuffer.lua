-- Copyright (C) Dejiang Zhu(doujiang24)


local setmetatable = setmetatable
local pairs = pairs
local next = next


local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local MAX_REUSE = 10000


local _M = {}
local mt = { __index = _M }

function _M.new(self, batch_num, batch_size)
    local sendbuffer = {
        topics = {},
        queue_num = 0,
        batch_num = batch_num * 2,
        batch_size = batch_size,
    }
    return setmetatable(sendbuffer, mt)
end


function _M.add(self, topic, partition_id, key, msg)
    local topics = self.topics

    if not topics[topic] then
        topics[topic] = {}
    end

    if not topics[topic][partition_id] then
        topics[topic][partition_id] = {
            queue = new_tab(self.batch_num, 0),
            index = 0,
            used = 0,
            size = 0,
            offset = 0,
            retryable = true,
            err = "",
        }
    end

    local buffer = topics[topic][partition_id]
    local index = buffer.index
    local queue = buffer.queue

    if index == 0 then
        self.queue_num = self.queue_num + 1
        buffer.retryable = true
    end

    queue[index + 1] = key
    queue[index + 2] = msg

    buffer.index = index + 2
    buffer.size = buffer.size + #msg + (key and #key or 0)

    if (buffer.size >= self.batch_size) or (buffer.index >= self.batch_num) then
        return true
    end
end


function _M.offset(self, topic, partition_id, offset)
    local buffer = self.topics[topic][partition_id]

    if not offset then
        return buffer.offset
    end

    buffer.offset = offset + (buffer.index / 2)
end


function _M.clear(self, topic, partition_id)
    local buffer = self.topics[topic][partition_id]
    buffer.index = 0
    buffer.size = 0
    buffer.used = buffer.used + 1

    if buffer.used >= MAX_REUSE then
        buffer.queue = new_tab(self.batch_num, 0)
        buffer.used = 0
    end

    self.queue_num = self.queue_num - 1
end


function _M.done(self)
    return self.queue_num == 0
end


function _M.err(self, topic, partition_id, err, retryable)
    local buffer = self.topics[topic][partition_id]

    if err then
        buffer.err = err
        buffer.retryable = retryable
        return buffer.index
    else
        return buffer.err, buffer.retryable
    end
end


function _M.loop(self)
    local topics, t, p = self.topics

    return function ()
        if t then
            for partition_id, queue in next, topics[t], p do
                p = partition_id
                if queue.index > 0 then
                    return t, partition_id, queue
                end
            end
        end


        for topic, partitions in next, topics, t do
            t = topic
            p = nil
            for partition_id, queue in next, partitions, p do
                p = partition_id
                if queue.index > 0 then
                    return topic, partition_id, queue
                end
            end
        end

        return
    end
end


function _M.aggregator(self, client)
    local num = 0
    local sendbroker = {}
    local brokers = {}

    local i = 1
    for topic, partition_id, queue in self:loop() do
        if queue.retryable then
            local broker_conf, err = client:choose_broker(topic, partition_id)
            if not broker_conf then
                self:err(topic, partition_id, err, true)

            else
                if not brokers[broker_conf] then
                    brokers[broker_conf] = {
                        topics = {},
                        topic_num = 0,
                        size = 0,
                    }
                end

                local broker = brokers[broker_conf]
                if not broker.topics[topic] then
                    brokers[broker_conf].topics[topic] = {
                        partitions = {},
                        partition_num = 0,
                    }

                    broker.topic_num = broker.topic_num + 1
                end

                local broker_topic = broker.topics[topic]

                broker_topic.partitions[partition_id] = queue
                broker_topic.partition_num = broker_topic.partition_num + 1

                broker.size = broker.size + queue.size

                if broker.size >= self.batch_size then
                    sendbroker[num + 1] = broker_conf
                    sendbroker[num + 2] = brokers[broker_conf]

                    num = num + 2
                    brokers[broker_conf] = nil
                end
            end
        end
    end

    for broker_conf, topic_partitions in pairs(brokers) do
        sendbroker[num + 1] = broker_conf
        sendbroker[num + 2] = brokers[broker_conf]
        num = num + 2
    end

    return num, sendbroker
end


return _M
