local protocol = require("resty.kafka.protocol.common")
local bit = require("bit")
local math = require("math")

local crc32c = protocol.crc32c
local ngx_log = ngx.log
local ngx_crc32 = ngx.crc32_long
local ERR = ngx.ERR
local INFO = ngx.INFO
local table_insert = table.insert
local band = bit.band
local math_abs = math.abs


local _M = {}


--- Decode MessageSet v0 and v1 (the old format) data.
-- Tip: The return value message contains the int64 value, which is of
-- type cdata and cannot be used directly in some scenarios.
-- @author bzp2010 <bzp2010@apache.org>
local function _message_set_v0_1_decode(resp, ret)
    local message = {}

    message.offset = resp:int64()

    -- Sometimes in low version protocols many useless empty data are
    -- returned, they are characterized by a -1 offset at the beginning
    -- and 0 for each offset after that, we will discard the data after that.
    -- The response will be closed (offset is set to the end),
    -- i.e. it cannot continue reading any data.
    -- Tip: offset uses int64 storage, and it is almost impossible for us
    -- to write so many messages, so the case where offset does have a
    -- negative value is not considered here.
    if message.offset < 0 then
        resp:close()
        return "empty message" -- return error
    end

    local message_size = resp:int32()
    local crc = resp:int32()
    local crc_content = resp:peek_bytes(resp.offset, message_size - 4)
    local calc_crc = ngx_crc32(crc_content)
    if crc ~= calc_crc and math_abs(crc) + math_abs(calc_crc) ~= 4294967296 then
        return "crc checksum error"
    end

    local magic_byte = resp:int8()

    -- TODO: support compressed Message Set
    local attributes = resp:int8()

    -- message version 1 added timestamp
    if magic_byte == protocol.API_VERSION_V1 then
        message.timestamp = resp:int64()
    else
        message.timestamp = 0
    end

    message.key = resp:bytes()
    message.value = resp:bytes()

    table_insert(ret, message)

    return nil -- error
end


--- Decode MessageSet v2 (aka RecordBatch) data.
-- Tip: The return value message contains the int64 value, which is of
-- type cdata and cannot be used directly in some scenarios.
-- @author bzp2010 <bzp2010@apache.org>
local function _message_set_v2_decode(resp, ret, fetch_offset)
    ret = ret or {}

    -- RecordBatch decoder, refer to this documents
    -- https://kafka.apache.org/documentation/#recordbatch
    local base_offset = resp:int64() -- baseOffset
    local batch_length = resp:int32() -- batchLength
    local partition_leader_epoch = resp:int32() -- partitionLeaderEpoch
    local magic_byte = resp:int8() -- magic
    local crc = resp:int32() -- crc

    -- Get all remaining message bodies by length for crc. The crc content
    -- starts with attributes, so here we need to reduce its middle
    -- three fields' length, include partition_leader_epoch (4 byte),
    -- magic_byte (1 byte) and crc (4 byte).
    local crc_content = resp:peek_bytes(resp.offset, batch_length - 4 - 1 - 4)
    local calc_crc = crc32c(crc_content)
    if crc ~= calc_crc then
        return "crc checksum error"
    end

    -- TODO: support compressed Message Set
    local attributes = resp:int16() -- attributes

    local last_offset_delta = resp:int32() -- lastOffsetDelta
    local last_offset = base_offset + last_offset_delta

    -- If the last record's offset is also less than fetch's offset,
    -- all outdated records are discarded.
    if last_offset < fetch_offset then
        resp:close()
        return "all records outdated"
    end

    -- RecordBatch contains the timestamp starting value and the
    -- maximum value of these records.
    local first_timestamp = resp:int64() -- firstTimestamp
    local max_timestamp = resp:int64() -- maxTimestamp

    -- These fields are intended to support idempotent messages.
    -- The features are NYI
    local producer_id = resp:int64() -- producerId
    local producer_epoch = resp:int16() -- producerEpoch
    local base_sequence = resp:int32() -- baseSequence

    local record_num = resp:int32() -- [records] array length

    for i = 1, record_num do
        local message = {}

        -- Record decoder, refer to this documents
        -- https://kafka.apache.org/documentation/#record
        local len = resp:varint()
        local message_end = resp.offset + len

        -- According to the protocol, only reserved.
        local record_attributes = resp:int8()

        -- Offset of this Record from RecordBatch's base value.
        local timestamp_delta = resp:varlong()
        local offset_delta = resp:varint()

        -- The sixth bit of isControlBatch (bit 5) in attributes has a value of 1,
        -- i.e. the current MessageSet (RecordBatch) is a ControlBatch.
        -- !! Not process Conrtol Batch for now, they will be skipped !!
        if band(attributes, 0x20) > 0 then
            resp:varint() -- keyLength skipped
            resp:int16() -- ControlBatch version skipped
            resp:int16() -- ControlBatch type skipped

            ngx_log(INFO, "A Control Batch was skipped during the parsing of the message v2")

            goto continue
        end

        message.offset = base_offset + offset_delta
        message.timestamp = first_timestamp + timestamp_delta
        message.key = resp:varint_bytes()
        message.value = resp:varint_bytes()

        table_insert(ret, message)

        -- Calculates the length of the header field by the expected end position
        -- of the message and skips the specified number of bytes.
        -- !! Not parse message headers for now, they will be skipped !!
        local header_len = message_end - resp.offset
        resp.offset = resp.offset + header_len
        ::continue::
    end

    return nil
end


---------
-- Decode the message set, a different version of decoder will be selected
-- automatically according to the MagicByte inside the message
-- @author bzp2010 <bzp2010@apache.org>
function _M.message_set_decode(resp, fetch_offset)
    local ret = {}
    local message_set_size = resp:int32()

    -- Keep parsing the message until all the data in the
    -- current response is exhausted
    while resp:remain() > 0 do
        -- Get 1 byte integer after 2 byte offset
        -- [MessageSet] message magic_byte, it contains Message version
        local message_version = resp:peek_int(16, 1)

        local messages, messages_set_info, err
        if message_version == 0 or message_version == 1 then
            -- old MessageSet v0 or v1
            err = _message_set_v0_1_decode(resp, ret)
        else
            -- MessageSet v2 aka RecordBatch
            err = _message_set_v2_decode(resp, ret, fetch_offset)
        end

        if err then
            ngx_log(ERR, "failed to decode message set, err: ", err)
        end
    end

    return ret
end


return _M
