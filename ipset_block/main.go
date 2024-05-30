package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
)

// IPBanRequest 代表接收的JSON格式请求
type IPBanRequest struct {
	NetworkBlockIP string `json:"network_block_ip"`
	Auth           string `json:"auth"`
}

// ResponseMessage 用于响应消息
type ResponseMessage struct {
	Result  bool   `json:"result"`
	Message string `json:"message"`
}

// 全局变量，存储启动服务时从环境变量中获取的认证密钥
var authKey string

func main() {
	// 创建日志文件
	logFile, err := os.OpenFile("ip_ban.log", os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0666)
	if err != nil {
		log.Fatalf("Error opening log file: %v", err)
	}
	defer logFile.Close()

	// 设置日志的输出到文件
	log.SetOutput(logFile)

	// 从环境变量中获取认证密钥
	authKey = os.Getenv("IP_BAN_AUTH")
	if authKey == "" {
		log.Println("Auth key must be set in environment variable IP_BAN_AUTH.")
		os.Exit(1)
	}

	http.HandleFunc("/banip", ipHandler)
	log.Println("Server is listening on port 6677...")
	if err := http.ListenAndServe(":6677", nil); err != nil {
		log.Panicf("Error starting server: %v", err)
	}
}

func ipHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeResponse(w, ResponseMessage{false, "Only POST method is allowed"}, http.StatusMethodNotAllowed, "Only POST method is allowed")
		return
	}
	var req IPBanRequest
	body, err := io.ReadAll(r.Body)
	if err != nil {
		writeResponse(w, ResponseMessage{false, "Error reading request body"}, http.StatusBadRequest, "Error reading request body")
		return
	}
	if err := json.Unmarshal(body, &req); err != nil {
		writeResponse(w, ResponseMessage{false, "Invalid JSON"}, http.StatusBadRequest, "Invalid JSON")
		return
	}
	if req.Auth != authKey {
		writeResponse(w, ResponseMessage{false, "Unauthorized"}, http.StatusUnauthorized, "Unauthorized access attempt")
		return
	}
	if net.ParseIP(req.NetworkBlockIP) == nil {
		writeResponse(w, ResponseMessage{false, "Invalid IP address"}, http.StatusBadRequest, "Invalid IP address")
		return
	}
	out, err := exec.Command("sh", "-c", fmt.Sprintf("ipset add blacklist %s", req.NetworkBlockIP)).CombinedOutput()
	if err != nil {
		writeResponse(
			w,
			ResponseMessage{false, fmt.Sprintf("Error banning IP: %v, output: %s", err, out)},
			http.StatusInternalServerError,
			fmt.Sprintf("Error banning IP: %v, output: %s\n", err, out),
		)
		return
	}
	writeResponse(w, ResponseMessage{true, "IP banned successfully"}, http.StatusOK, fmt.Sprintf("IP %s banned successfully\n", req.NetworkBlockIP))
}

func writeResponse(w http.ResponseWriter, response ResponseMessage, httpCode int, logMessage string) {
	jsonResponse, _ := json.Marshal(response)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(httpCode)
	w.Write(jsonResponse)
	log.Print(logMessage)
}
