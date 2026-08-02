package internal

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"
)

// ServerConfig 运行时配置
type ServerConfig struct {
	CloudAPIURL              string `json:"cloud_api_url"`
	CloudAPIKey              string `json:"cloud_api_key"`              // 主账号的 waf_auth，用于调用 Cloud 的 /user/ 接口
	SessionSecret            string `json:"session_secret"`
	DefaultWebsiteAccessConf string `json:"default_website_access_conf"` // 默认接入配置名称，注册子账号时自动绑定
	MySQLHost                string `json:"mysql_host"`
	MySQLPort                string `json:"mysql_port"`
	MySQLUser                string `json:"mysql_user"`
	MySQLPassword            string `json:"mysql_password"`
	MySQLDatabase            string `json:"mysql_database"`
}

// LoadConfig 从环境变量加载配置并校验
func LoadConfig() *ServerConfig {
	cfg := &ServerConfig{
		CloudAPIURL:              getEnv("CLOUD_API_URL", ""),
		CloudAPIKey:              getEnv("CLOUD_API_KEY", ""),
		SessionSecret:            getEnv("SESSION_SECRET", ""),
		DefaultWebsiteAccessConf: getEnv("DEFAULT_WEBSITE_ACCESS_CONF", ""),
		MySQLHost:                getEnv("MYSQL_HOST", ""),
		MySQLPort:                getEnv("MYSQL_PORT", "3306"),
		MySQLUser:                getEnv("MYSQL_USER", ""),
		MySQLPassword:            getEnv("MYSQL_PASSWORD", ""),
		MySQLDatabase:            getEnv("MYSQL_DATABASE", "jxwaf"),
	}

	// SESSION_SECRET 未配置时自动生成随机密钥
	// 会话 ID 本身由 crypto/rand 生成，此值仅作为额外熵输入，无需用户配置
	if cfg.SessionSecret == "" {
		cfg.SessionSecret = generateRandomSecret()
		log.Printf("SESSION_SECRET 未配置，已自动生成随机密钥")
	}

	if err := cfg.Validate(); err != nil {
		log.Fatalf("配置校验失败: %v", err)
	}

	log.Printf("JXWAF User Console 配置加载完成:")
	log.Printf("  CLOUD_API_URL: %s", cfg.CloudAPIURL)
	log.Printf("  CLOUD_API_KEY: %s", maskSecret(cfg.CloudAPIKey))
	log.Printf("  SESSION_SECRET: %s", maskSecret(cfg.SessionSecret))
	log.Printf("  DEFAULT_WEBSITE_ACCESS_CONF: %s", cfg.DefaultWebsiteAccessConf)
	log.Printf("  MYSQL_HOST: %s:%s", cfg.MySQLHost, cfg.MySQLPort)
	log.Printf("  MYSQL_USER: %s", cfg.MySQLUser)
	log.Printf("  MYSQL_DATABASE: %s", cfg.MySQLDatabase)
	log.Printf("  HTTP_PORT: %s", getEnv("HTTP_PORT", "8080"))

	return cfg
}

// MySQLDSN 构建 MySQL DSN 连接字符串
func (c *ServerConfig) MySQLDSN() string {
	return fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=true&timeout=10s&readTimeout=10s&writeTimeout=10s",
		c.MySQLUser, c.MySQLPassword, c.MySQLHost, c.MySQLPort, c.MySQLDatabase)
}

// Validate 校验配置完整性
func (c *ServerConfig) Validate() error {
	var errs []string
	if c.CloudAPIURL == "" {
		errs = append(errs, "CLOUD_API_URL 是必填项")
	}
	if c.CloudAPIKey == "" {
		errs = append(errs, "CLOUD_API_KEY 是必填项")
	}
	if c.DefaultWebsiteAccessConf == "" {
		errs = append(errs, "DEFAULT_WEBSITE_ACCESS_CONF 是必填项")
	}
	// MySQL 配置为可选（如果 Cloud API 登录返回 sub_waf_auth 则不需要数据库）
	if len(errs) > 0 {
		return fmt.Errorf("配置校验失败: %v", errs)
	}
	return nil
}

// SaveToFile 将配置写入 JSON 文件（保留以兼容旧脚本）
func (c *ServerConfig) SaveToFile(path string) error {
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()
	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "    ")
	return encoder.Encode(c)
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

// generateRandomSecret 生成随机会话密钥
// 使用 crypto/rand 生成 32 字节随机数，失败时回退到时间戳保证进程可启动
func generateRandomSecret() string {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		log.Printf("警告: rand.Read 失败，使用时间戳生成密钥: %v", err)
		return fmt.Sprintf("%x", time.Now().UnixNano())
	}
	return hex.EncodeToString(b)
}

func maskSecret(s string) string {
	if len(s) == 0 {
		return ""
	}
	return "******"
}
