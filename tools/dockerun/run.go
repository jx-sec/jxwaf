package main

import (
	"os"
	"syscall"
	"log"
	"github.com/google/uuid"
	"io/ioutil"
	"encoding/json"
)


func getEnv(key, fallback string) string {
    if value, ok := os.LookupEnv(key); ok {
        return value
    }
    return fallback
}

var (
	file_path = "/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json"
	server = getEnv("JXWAF_SERVER","")
	wafapikey = getEnv("WAF_API_KEY","")
	wafapipassword = getEnv("WAF_API_PASSWORD","")

	cmd = "/opt/jxwaf/nginx/sbin/nginx"
	args = []string{
		"jxwaf",
		"-g",
		"daemon off;",
	}
)

func evndata()  map[string]string{
	evndata := map[string]string{
		"waf_update_website": server + "/waf_update",
		"waf_monitor_website": server + "/waf_monitor",
		"waf_name_list_item_update_website": server + "/waf_name_list_item_update",
		"waf_add_name_list_item_website": server + "/api/add_name_list_item",
		"waf_node_hostname":"docker_" + uuid.New().String(),
		"waf_api_key": wafapikey,
		"waf_api_password": wafapipassword,

	}
	return evndata 
}

func waf_init(){
	// confmap := evndata()
	var confmap map[string]string
	file, err := os.Open(file_path)
    if err != nil {
       log.Panic("config open err: ",err)
    }
    defer file.Close()
    content, _ := ioutil.ReadAll(file)
	err = json.Unmarshal(content, &confmap)
	if err != nil {
		log.Panic("json marshal err: ",err)
	}
	if confmap["waf_api_key"] == "" {
		confmap := evndata()
		confjson, err := json.Marshal(&confmap)
		if err != nil {
			log.Print(err)
		}
		ioutil.WriteFile(file_path, confjson, 0644)
		log.Print(string(confjson))
	}else{
		hostname := confmap["waf_node_hostname"]
		node_uuid := confmap["waf_node_uuid"]
		confmap := evndata()
		confmap["waf_node_hostname"] = hostname
		confmap["waf_node_uuid"] = node_uuid
		confjson, err := json.Marshal(&confmap)
		if err != nil {
			log.Print(err)
		}
		ioutil.WriteFile(file_path, confjson, 0644)
		log.Print(string(confjson))
	}

	if err := syscall.Exec(cmd, args,os.Environ()); err != nil {
		log.Fatal(err)
	}

}


func main() {
	
	waf_init()
}
