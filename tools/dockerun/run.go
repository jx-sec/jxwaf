package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"syscall"

	"github.com/google/uuid"
)

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func loadConfig(path string) (map[string]string, bool, error) {
	content, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, false, err
	}

	conf := make(map[string]string)
	err = json.Unmarshal(content, &conf)
	if err != nil {
		return nil, false, err
	}

	return conf, conf["waf_auth"] == "", nil
}

func saveConfig(path string, data map[string]string) error {
	confJSON, err := json.Marshal(data)
	if err != nil {
		return err
	}
	return ioutil.WriteFile(path, confJSON, 0644)
}


func generateConfig(existingMap map[string]string) map[string]string {
	evData := map[string]string{
		"waf_update_website":                   getEnv("JXWAF_SERVER", "") + "/waf_update",
		"waf_monitor_website":                  getEnv("JXWAF_SERVER", "") + "/waf_monitor",
		"waf_name_list_item_update_website":    getEnv("JXWAF_SERVER", "") + "/waf_name_list_item_update",
		"waf_add_name_list_item_website":       getEnv("JXWAF_SERVER", "") + "/api/add_name_list_item",
		"waf_auth":                             getEnv("WAF_AUTH", ""),
		"bot_check_ip_bind":                    getEnv("BOT_CHECK_IP_BIND", "true"),
		"waf_cc_js_website":                    getEnv("WAF_CC_JS_WEBSITE", "https://cc.jxwaf.top/"),
	}

	if existingMap != nil {
		if v, ok := existingMap["waf_node_uuid"]; ok {
			evData["waf_node_uuid"] = v
		} else {
			evData["waf_node_uuid"] = uuid.New().String()
		}
	} else {
		evData["waf_node_uuid"] = uuid.New().String()
	}

	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown"
	}
	evData["waf_node_hostname"] = "docker_" + hostname

	return evData
}

func writeNginxConfig() error {
    wafDnsResolver := getEnv("WAF_DNS_RESOLVER", "114.114.114.114")
	httpPort := getEnv("HTTP_PORT", "80")
	httpsPort := getEnv("HTTPS_PORT", "443")
	nginxConfigTemplate := fmt.Sprintf(`#user  nobody;
worker_processes  auto;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


worker_rlimit_nofile 102400;
events {
    #multi_accept on;
    worker_connections  10240;
    #use epoll;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;
    client_body_buffer_size  10m;
    client_max_body_size 100m;
    sendfile        on;
    #tcp_nopush     on;
	resolver  %s ipv6=off;
  resolver_timeout 5s;
    #keepalive_timeout  0;
    keepalive_timeout  65;
    lua_ssl_trusted_certificate  /etc/pki/tls/certs/ca-bundle.crt;
    lua_ssl_verify_depth 3;
lua_shared_dict waf_conf_data 100m;
lua_shared_dict jxwaf_sys 100m;
lua_shared_dict jxwaf_limit_req 100m;
lua_shared_dict jxwaf_limit_count 100m;
lua_shared_dict jxwaf_limit_domain 100m;
lua_shared_dict jxwaf_limit_ip_count 100m;
lua_shared_dict jxwaf_limit_ip 100m;
lua_shared_dict jxwaf_limit_bot 100m;
lua_shared_dict jxwaf_public 500m;
lua_shared_dict jxwaf_inner 100m;
lua_shared_dict jxwaf_suppression 100m;
init_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/init.lua;
init_worker_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/init_worker.lua;
rewrite_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/rewrite.lua;
access_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/access.lua;
body_filter_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/body_filter.lua;
log_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/log.lua;
rewrite_by_lua_no_postpone on;
    #gzip  on;
	upstream jxwaf {
	server www.jxwaf.com;
  balancer_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/balancer.lua;
}
lua_code_cache on;
    server {
        listen       %s;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;
        set $proxy_pass_https_flag "false";
        location / {
            #root   html;
           # index  index.html index.htm;
            proxy_http_version 1.1;
          if ($proxy_pass_https_flag = "true"){
            proxy_pass https://jxwaf;
          }
          if ($proxy_pass_https_flag = "false"){
            proxy_pass http://jxwaf;
          }

           proxy_set_header Host  $http_host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
	 #proxy_pass http://www.jxwaf.com;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}
    server {
        listen       %s ssl;
        server_name  localhost;

        ssl_certificate      full_chain.pem;
        ssl_certificate_key  private.key;

        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;
        ssl_session_tickets off;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH:ECDHE-RSA-AES128-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA128:DHE-RSA-AES128-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA128:ECDHE-RSA-AES128-SHA384:ECDHE-RSA-AES128-SHA128:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA384:AES128-GCM-SHA128:AES128-SHA128:AES128-SHA128:AES128-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
        ssl_prefer_server_ciphers  on;
        ssl_certificate_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/ssl.lua;
        set $proxy_pass_https_flag "false";
        location / {
            root   html;
            index  index.html index.htm;
          if ($proxy_pass_https_flag = "true"){
            proxy_pass https://jxwaf;
          }
          if ($proxy_pass_https_flag = "false"){
            proxy_pass http://jxwaf;
          }
	    proxy_ssl_server_name on;
	    proxy_ssl_name $http_host;
	    proxy_ssl_session_reuse off;
            proxy_set_header Host  $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	   proxy_http_version 1.1;
	   proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
        }
    }


}`, wafDnsResolver, httpPort, httpsPort)

	return ioutil.WriteFile("/opt/jxwaf/nginx/conf/nginx.conf", []byte(nginxConfigTemplate), 0644)
}

func initializeWAF() {
	filePath := "/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json"

	// Write nginx configuration template
	if err := writeNginxConfig(); err != nil {
		log.Fatalf("failed writing nginx config: %v", err)
	}

	confMap, isNew, err := loadConfig(filePath)
	if err != nil {
		log.Fatalf("failed to load json config: %v", err)
	}

	finalConfig := generateConfig(confMap)
	if err := saveConfig(filePath, finalConfig); err != nil {
		log.Fatalf("failed to save waf config: %v", err)
	}

	if isNew {
		log.Printf("new configuration: %v", finalConfig)
	} else {
		log.Printf("existing configuration updated: %v", finalConfig)
	}

	cmd := "/opt/jxwaf/nginx/sbin/nginx"
	args := []string{
	    "jxwaf",
		"-g",
		"daemon off;",
	}
	if err := syscall.Exec(cmd, args, os.Environ()); err != nil {
		log.Fatalf("failed to execute nginx: %v", err)
	}
}

func main() {
	initializeWAF()
}
