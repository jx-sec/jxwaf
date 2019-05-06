local ffi = require "ffi"
ffi.cdef[[
typedef int log_producer_result;
typedef struct _log_producer_config_tag
{
    char * key;
    char * value;
}log_producer_config_tag;
typedef struct _log_producer_config
{
    char * endpoint;
    char * project;
    char * logstore;
    char * accessKeyId;
    char * accessKey;
    char * securityToken;
    char * topic;
    char * source;
//    CRITICALSECTION securityTokenLock;
    log_producer_config_tag * tags;
    int32_t tagAllocSize;
    int32_t tagCount;

    int32_t sendThreadCount;

    int32_t packageTimeoutInMS;
    int32_t logCountPerPackage;
    int32_t logBytesPerPackage;
    int32_t maxBufferBytes;

    char * netInterface;
    char * remote_address;
    int32_t connectTimeoutSec;
    int32_t sendTimeoutSec;
    int32_t destroyFlusherWaitTimeoutSec;
    int32_t destroySenderWaitTimeoutSec;

    int32_t compressType; 
    int32_t using_https; 

}log_producer_config;

log_producer_result log_producer_env_empty_init();
log_producer_config * create_log_producer_config();
void log_producer_config_set_endpoint(log_producer_config * config, const char * endpoint);
void log_producer_config_set_project(log_producer_config * config, const char * project);
void log_producer_config_set_logstore(log_producer_config * config, const char * logstore);
void log_producer_config_set_access_id(log_producer_config * config, const char * access_id);
void log_producer_config_set_access_key(log_producer_config * config, const char * access_id);
void log_producer_config_set_topic(log_producer_config * config, const char * topic);
void log_producer_config_set_source(log_producer_config * config, const char * source);
void log_producer_config_add_tag(log_producer_config * config, const char * key, const char * value);
void log_producer_config_set_packet_timeout(log_producer_config * config, int32_t time_out_ms);
void log_producer_config_set_packet_log_count(log_producer_config * config, int32_t log_count);
void log_producer_config_set_packet_log_bytes(log_producer_config * config, int32_t log_bytes);
void log_producer_config_set_max_buffer_limit(log_producer_config * config, int64_t max_buffer_bytes);
void log_producer_config_set_send_thread_count(log_producer_config * config, int32_t thread_count);
void log_producer_config_set_remote_address(log_producer_config * config, const char * remote_address);
void log_producer_config_set_net_interface(log_producer_config * config, const char * net_interface);
void log_producer_config_set_connect_timeout_sec(log_producer_config * config, int32_t connect_timeout_sec);
void log_producer_config_set_send_timeout_sec(log_producer_config * config, int32_t send_timeout_sec);
void log_producer_config_set_destroy_flusher_wait_sec(log_producer_config * config, int32_t destroy_flusher_wait_sec);
void log_producer_config_set_destroy_sender_wait_sec(log_producer_config * config, int32_t destroy_sender_wait_sec);
void log_producer_config_set_compress_type(log_producer_config * config, int32_t compress_type);
void log_producer_config_set_using_http(log_producer_config * config, int32_t using_https);
void destroy_log_producer_config(log_producer_config * config);
typedef struct _log_producer log_producer;
typedef void (*on_log_producer_send_done_function)(const char * config_name, log_producer_result result, size_t log_bytes, size_t compressed_bytes, const char * req_id, const char * error_message, const unsigned char * raw_buffer);
log_producer * create_log_producer(log_producer_config * config, on_log_producer_send_done_function send_done_function);
void log_producer_config_reset_security_token(log_producer_config * config, const char * access_id, const char * access_secret, const char * security_token);
typedef struct _log_producer_client
{
    volatile int32_t valid_flag;
    int32_t log_level;
    void * private_data;
}log_producer_client;
log_producer_result log_producer_env_init(int32_t log_global_flag);
typedef struct _log_producer log_producer;
log_producer_client * get_log_producer_client(log_producer * producer, const char * config_name);
log_producer_result log_producer_client_add_log(log_producer_client * client, int32_t kv_count, ...);
void destroy_log_producer(log_producer * producer);
void log_producer_env_destroy();
]]
local _M = {}
local aliyun_log
local config
--local client

function _M.init()
  ffi.load("/usr/local/lib/libcurl.so", true)
  aliyun_log = ffi.load("/opt/jxwaf/lualib/liblog_c_sdk.so")
  local result = aliyun_log.log_producer_env_init(3)
  if result ~= 0 then
       return nil
  end
  --local result = aliyun_log.log_producer_env_empty_init()
  --if result ~= 1 then
  --  return nil
  --end 
 return aliyun_log
end

function _M.init_config(endpoint,project,logstore,source,access_id,access_key,topic)
  local producer_config = aliyun_log.create_log_producer_config()
  aliyun_log.log_producer_config_set_endpoint(producer_config, endpoint)
  aliyun_log.log_producer_config_set_project(producer_config, project)
  aliyun_log.log_producer_config_set_logstore(producer_config, logstore)
  aliyun_log.log_producer_config_set_source(producer_config, source)
  aliyun_log.log_producer_config_set_access_id(producer_config, access_id)
  aliyun_log.log_producer_config_set_access_key(producer_config, access_key)
  aliyun_log.log_producer_config_set_topic(producer_config, topic)
  aliyun_log.log_producer_config_set_packet_log_bytes(producer_config, 3*1024*1024)
  aliyun_log.log_producer_config_set_packet_log_count(producer_config, 2048)
  aliyun_log.log_producer_config_set_packet_timeout(producer_config, 3000)
  aliyun_log.log_producer_config_set_max_buffer_limit(producer_config, 64*1024*1024)
  aliyun_log.log_producer_config_set_send_thread_count(producer_config, 1)
  aliyun_log.log_producer_config_set_compress_type(producer_config, 1)
  aliyun_log.log_producer_config_set_connect_timeout_sec(producer_config, 10)
  aliyun_log.log_producer_config_set_send_timeout_sec(producer_config, 10)
  aliyun_log.log_producer_config_set_destroy_flusher_wait_sec(producer_config, 1)
  aliyun_log.log_producer_config_set_destroy_sender_wait_sec(producer_config, 1)
  aliyun_log.log_producer_config_set_net_interface(producer_config, nil)
  config = aliyun_log.create_log_producer(producer_config,nil)
  if not config then
    ngx.log(ngx.ERR,"create log producer by config fail")
    return nil
  end
  local client = aliyun_log.get_log_producer_client(config,nil)
  if not client then
    ngx.log(ngx.ERR,"create log producer client by config fail")
    return nil 
  end
  return client,config
end

function _M.send_log(client,config,message,headers)
  local result =aliyun_log.log_producer_client_add_log(client,4,"jxwaf_log",message,"http_headers",headers)
  if result ~= 0 then
    ngx.log(ngx.ERR,"fail send message")
    return nil
  end 
  aliyun_log.destroy_log_producer(config)
  aliyun_log.log_producer_env_destroy()
  return result
end


return _M
