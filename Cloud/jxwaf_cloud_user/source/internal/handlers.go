package internal

import (
	"crypto/rand"
	"encoding/base32"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
)

type Handler struct {
	cloud    *CloudClient
	sessions *SessionStore
	db       *DB
}

func NewHandler(cloud *CloudClient, sessions *SessionStore, db *DB) *Handler {
	return &Handler{
		cloud:    cloud,
		sessions: sessions,
		db:       db,
	}
}

func (h *Handler) genericUserProxy(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.NotFound(w, r)
		return
	}
	session := h.sessions.GetFromRequest(r)
	if session == nil {
		FailResponse(w, "未登录或会话已过期，请重新登录")
		return
	}

	cloudPath := r.URL.Path
	body := readRequestBody(r)
	status, respBody, err := h.cloud.Post(cloudPath, body, session)
	if err != nil {
		log.Printf("通用代理请求失败: %s err: %v", cloudPath, err)
		FailResponse(w, "请求后端服务失败")
		return
	}
	if status != 200 {
		log.Printf("Cloud API 返回异常状态: %d path: %s", status, cloudPath)
		FailResponse(w, "后端服务异常")
		return
	}
	RawResponse(w, respBody)
}

func (h *Handler) UserProxy() http.HandlerFunc {
	return h.genericUserProxy
}

func readRequestBody(r *http.Request) interface{} {
	if r.Body == nil {
		return nil
	}
	body, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("读取请求体失败: %v", err)
		return nil
	}
	if len(body) == 0 {
		return nil
	}

	var data interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		return string(body)
	}
	return data
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var params struct {
		SubUserName  string `json:"sub_user_name"`
		UserPassword string `json:"user_password"`
		OtpAuthCode  string `json:"otp_auth_code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&params); err != nil {
		FailResponse(w, "请求参数格式错误")
		return
	}

	if params.SubUserName == "" {
		FailResponse(w, "账号名不能为空")
		return
	}
	if params.UserPassword == "" {
		FailResponse(w, "密码不能为空")
		return
	}

	reqBody := map[string]interface{}{
		"sub_user_name": params.SubUserName,
		"user_password": params.UserPassword,
		"otp_auth_code": params.OtpAuthCode,
	}

	status, respBody, err := h.cloud.PostWithMainAuth("/user/sub_account_login", reqBody)
	if err != nil {
		log.Printf("登录验证失败: %v", err)
		FailResponse(w, "认证服务暂时不可用，请稍后重试")
		return
	}
	if status != 200 {
		log.Printf("Cloud API 登录返回异常状态: %d", status)
		FailResponse(w, "认证服务异常")
		return
	}

	var result struct {
		Result  bool   `json:"result"`
		Message string `json:"message"`
		WafAuth string `json:"waf_auth"`
	}
	if err := json.Unmarshal(respBody, &result); err != nil {
		FailResponse(w, "解析认证响应失败")
		return
	}
	if !result.Result {
		FailResponse(w, result.Message)
		return
	}

	subWafAuth := result.WafAuth
	if subWafAuth == "" {
		if h.db == nil {
			FailResponse(w, "Cloud API 未返回账号认证信息，且未配置数据库，无法登录")
			return
		}
		userName, err := h.db.GetUserNameByWafAuth(h.cloud.apiKey)
		if err != nil {
			log.Printf("查询主账号 user_name 失败: %v", err)
			FailResponse(w, "获取账号信息失败")
			return
		}
		subWafAuth, err = h.db.GetSubWafAuth(userName, params.SubUserName)
		if err != nil {
			log.Printf("查询子账号 waf_auth 失败: %v", err)
			FailResponse(w, "获取账号认证信息失败")
			return
		}
	}

	sessionID := h.sessions.Create("", params.SubUserName, subWafAuth)
	if sessionID == "" {
		FailResponse(w, "创建会话失败，请重试")
		return
	}

	SetCookie(w, sessionID)
	writeJSON(w, map[string]interface{}{
		"result":   true,
		"message":  params.SubUserName,
		"waf_auth": subWafAuth,
	})
}

func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	if cookie, err := r.Cookie(SessionCookieName); err == nil {
		h.sessions.Destroy(cookie.Value)
	}
	ClearCookie(w)
	SuccessResponse(w, "已退出登录")
}

func (h *Handler) CheckSession(w http.ResponseWriter, r *http.Request) {
	session := h.sessions.GetFromRequest(r)
	if session == nil {
		FailResponse(w, "未登录或会话已过期")
		return
	}
	writeJSON(w, map[string]interface{}{
		"result": true,
		"data": map[string]string{
			"sub_user_name": session.SubUserName,
		},
	})
}

func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var dataMap map[string]interface{}
	if r.Body != nil {
		bodyBytes, err := io.ReadAll(r.Body)
		if err != nil {
			FailResponse(w, "读取请求体失败")
			return
		}
		if len(bodyBytes) > 0 {
			if err := json.Unmarshal(bodyBytes, &dataMap); err != nil {
				FailResponse(w, "请求参数格式错误")
				return
			}
		}
	}
	if dataMap == nil {
		dataMap = map[string]interface{}{}
	}
	// 注入默认接入配置（对终端用户透明，由 Cloud_user 启动配置决定）
	dataMap["website_access_conf"] = h.cloud.defaultWebsiteAccessConf
	log.Printf("注册请求转发至 Cloud, 已注入 website_access_conf=%s, sub_user_name=%s", dataMap["website_access_conf"], dataMap["sub_user_name"])
	status, respBody, err := h.cloud.PostWithMainAuth("/user/sub_account_register", dataMap)
	if err != nil {
		log.Printf("注册请求失败: %v", err)
		FailResponse(w, "注册服务暂时不可用，请稍后重试")
		return
	}
	if status != 200 {
		FailResponse(w, "注册服务异常")
		return
	}
	RawResponse(w, respBody)
}

func generateOTPSecret() string {
	b := make([]byte, 10)
	rand.Read(b)
	return base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(b)
}

func (h *Handler) GetOtpQrUrl(w http.ResponseWriter, r *http.Request) {
	secretKey := generateOTPSecret()
	otpUrl := fmt.Sprintf("otpauth://totp/jxwaf-user?secret=%s&issuer=jxwaf", secretKey)
	returnData := map[string]interface{}{
		"result":         true,
		"message":        otpUrl,
		"otp_secret_key": secretKey,
	}
	writeJSON(w, returnData)
}

func (h *Handler) cdnWarmupRoute(w http.ResponseWriter, r *http.Request) {
	session := h.sessions.GetFromRequest(r)
	if session == nil {
		FailResponse(w, "未登录或会话已过期，请重新登录")
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/cdn_warmup/")
	var cloudPath string
	switch path {
	case "list":
		cloudPath = "/user/get_cache_warmup_list"
	case "create":
		cloudPath = "/user/create_cache_warmup_task"
	case "detail":
		cloudPath = "/user/get_cache_warmup_detail"
	case "delete":
		cloudPath = "/user/delete_cache_warmup_task"
	}

	if cloudPath == "" {
		FailResponse(w, "不支持的预热操作")
		return
	}

	body := readRequestBody(r)
	status, respBody, err := h.cloud.Post(cloudPath, body, session)
	if err != nil {
		log.Printf("CDN预热代理请求失败: %s err: %v", cloudPath, err)
		FailResponse(w, "请求后端服务失败")
		return
	}
	if status != 200 {
		FailResponse(w, "后端服务异常")
		return
	}
	RawResponse(w, respBody)
}

func (h *Handler) cdnRefreshRoute(w http.ResponseWriter, r *http.Request) {
	session := h.sessions.GetFromRequest(r)
	if session == nil {
		FailResponse(w, "未登录或会话已过期，请重新登录")
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/cdn_refresh/")
	var cloudPath string
	switch path {
	case "list":
		cloudPath = "/user/get_cache_refresh_list"
	case "create":
		cloudPath = "/user/create_cache_refresh_task"
	case "detail":
		cloudPath = "/user/get_cache_refresh_detail"
	case "delete":
		cloudPath = "/user/delete_cache_refresh_task"
	}

	if cloudPath == "" {
		FailResponse(w, "不支持的刷新操作")
		return
	}

	body := readRequestBody(r)
	status, respBody, err := h.cloud.Post(cloudPath, body, session)
	if err != nil {
		log.Printf("CDN刷新代理请求失败: %s err: %v", cloudPath, err)
		FailResponse(w, "请求后端服务失败")
		return
	}
	if status != 200 {
		FailResponse(w, "后端服务异常")
		return
	}
	RawResponse(w, respBody)
}

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/login", h.Login)
	mux.HandleFunc("/api/register", h.Register)
	mux.HandleFunc("/api/get_otp_qr_url", h.GetOtpQrUrl)
	mux.HandleFunc("/api/logout", h.Logout)
	mux.HandleFunc("/api/check_session", h.CheckSession)

	mux.HandleFunc("/api/cdn_warmup/", h.cdnWarmupRoute)
	mux.HandleFunc("/api/cdn_refresh/", h.cdnRefreshRoute)
}
