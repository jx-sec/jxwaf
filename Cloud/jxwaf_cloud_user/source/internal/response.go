package internal

import (
	"encoding/json"
	"net/http"
)

// APIResponse Cloud API 统一响应格式
type APIResponse struct {
	Result  bool        `json:"result"`
	Message interface{} `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}

// FailResponse 返回失败响应
func FailResponse(w http.ResponseWriter, message string) {
	writeJSON(w, APIResponse{
		Result:  false,
		Message: message,
	})
}

// SuccessResponse 返回成功响应（带消息）
func SuccessResponse(w http.ResponseWriter, message interface{}) {
	writeJSON(w, APIResponse{
		Result:  true,
		Message: message,
	})
}

// RawResponse 直接返回原始 JSON 数据（透传 Cloud API 响应）
func RawResponse(w http.ResponseWriter, body []byte) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(body)
}

// writeJSON 写入 JSON 响应
func writeJSON(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(data)
}
