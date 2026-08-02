package internal

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"time"
)

// CloudClient Cloud 主控台 API 客户端
type CloudClient struct {
	baseURL                  string
	apiKey                   string // 主账号的 waf_auth，用于第一层鉴权
	defaultWebsiteAccessConf string // 默认接入配置名称，注册子账号时自动注入
	client                   *http.Client
}

// NewCloudClient 创建 Cloud API 客户端
func NewCloudClient(baseURL, apiKey, defaultWebsiteAccessConf string) *CloudClient {
	return &CloudClient{
		baseURL:                  baseURL,
		apiKey:                   apiKey,
		defaultWebsiteAccessConf: defaultWebsiteAccessConf,
		client: &http.Client{
			Timeout: 30 * time.Second,
			Transport: &http.Transport{
				MaxIdleConns:        100,
				MaxIdleConnsPerHost: 20,
				IdleConnTimeout:     90 * time.Second,
			},
		},
	}
}

// Post 发送 POST 请求到 Cloud API
// path: Cloud API 路径，如 /user/sub_account_login 或 /user/get_domain_list
// body: 请求体参数（会被序列化为 JSON）
// session: 用户会话（用于携带子账号身份），可为 nil
// 返回: HTTP 状态码, 响应体, 错误
func (c *CloudClient) Post(path string, body interface{}, session *Session) (int, []byte, error) {
	return c.doRequest("POST", path, body, session)
}

// Get 发送 GET 请求到 Cloud API
func (c *CloudClient) Get(path string, params map[string]string, session *Session) (int, []byte, error) {
	return c.doRequest("GET", path, params, session)
}

func (c *CloudClient) doRequest(method, path string, body interface{}, session *Session) (int, []byte, error) {
	if c.baseURL == "" {
		return 0, nil, fmt.Errorf("cloud_api_url 未配置")
	}

	reqURL := c.baseURL + path

	var reqBody io.Reader
	if body != nil {
		jsonData, err := json.Marshal(body)
		if err != nil {
			return 0, nil, fmt.Errorf("序列化请求体失败: %w", err)
		}
		reqBody = bytes.NewReader(jsonData)
	}

	req, err := http.NewRequest(method, reqURL, reqBody)
	if err != nil {
		return 0, nil, fmt.Errorf("创建请求失败: %w", err)
	}

	// 通用请求头
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	if session != nil {
		req.Header.Set("jxwaf-waf-auth", c.apiKey)
		req.Header.Set("jxwaf-sub-waf-auth", session.SubWafAuth)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		log.Printf("cloud_api 请求失败: %s %s err: %v", method, reqURL, err)
		return 0, nil, fmt.Errorf("请求 Cloud API 失败: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return resp.StatusCode, nil, fmt.Errorf("读取响应体失败: %w", err)
	}

	return resp.StatusCode, respBody, nil
}

// PostWithMainAuth 仅使用主账号 waf_auth 鉴权（用于登录等不需要子账号认证的场景）
func (c *CloudClient) PostWithMainAuth(path string, body interface{}) (int, []byte, error) {
	if c.baseURL == "" {
		return 0, nil, fmt.Errorf("cloud_api_url 未配置")
	}

	reqURL := c.baseURL + path

	var reqBody io.Reader
	if body != nil {
		jsonData, err := json.Marshal(body)
		if err != nil {
			return 0, nil, fmt.Errorf("序列化请求体失败: %w", err)
		}
		reqBody = bytes.NewReader(jsonData)
	}

	req, err := http.NewRequest("POST", reqURL, reqBody)
	if err != nil {
		return 0, nil, fmt.Errorf("创建请求失败: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("jxwaf-waf-auth", c.apiKey)

	resp, err := c.client.Do(req)
	if err != nil {
		log.Printf("cloud_api 请求失败: POST %s err: %v", reqURL, err)
		return 0, nil, fmt.Errorf("请求 Cloud API 失败: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return resp.StatusCode, nil, fmt.Errorf("读取响应体失败: %w", err)
	}

	return resp.StatusCode, respBody, nil
}

// encodeParams 将参数编码为 URL query string
func encodeParams(params map[string]string) string {
	values := url.Values{}
	for k, v := range params {
		values.Set(k, v)
	}
	return values.Encode()
}
