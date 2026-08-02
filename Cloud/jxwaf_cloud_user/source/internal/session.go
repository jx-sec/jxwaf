package internal

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"
)

const (
	SessionCookieName    = "jxwaf_user_session"
	SessionExpireSeconds = 86400 // 24 小时
)

// Session 用户会话
// 新版鉴权: 存储主账号 user_name + 子账号 sub_user_name + 子账号 waf_auth(sub_waf_auth)
// 调用 Cloud /user/ 接口时通过 jxwaf_waf_auth + jxwaf_sub_waf_auth 双层 Header 鉴权
type Session struct {
	UserName    string `json:"user_name"`
	SubUserName string `json:"sub_user_name"`
	SubWafAuth  string `json:"sub_waf_auth"` // 子账号的 waf_auth，用于双层鉴权
	CreatedAt   int64  `json:"created_at"`
	ExpireAt    int64  `json:"expire_at"`
}

// SessionStore 内存会话存储，带 TTL 自动过期
type SessionStore struct {
	mu       sync.RWMutex
	sessions map[string]*Session
	secret   string
}

// NewSessionStore 创建会话存储并启动后台清理协程
func NewSessionStore(secret string) *SessionStore {
	s := &SessionStore{
		sessions: make(map[string]*Session),
		secret:   secret,
	}
	go s.cleanupLoop()
	return s
}

// Create 创建新会话，返回 session_id
func (s *SessionStore) Create(userName, subUserName, subWafAuth string) string {
	s.mu.Lock()
	defer s.mu.Unlock()

	sessionID := generateSessionID(s.secret)
	now := time.Now().Unix()
	s.sessions[sessionID] = &Session{
		UserName:    userName,
		SubUserName: subUserName,
		SubWafAuth:  subWafAuth,
		CreatedAt:   now,
		ExpireAt:    now + SessionExpireSeconds,
	}
	return sessionID
}

// Get 获取会话，自动续期
func (s *SessionStore) Get(sessionID string) *Session {
	s.mu.RLock()
	sess, ok := s.sessions[sessionID]
	s.mu.RUnlock()

	if !ok {
		return nil
	}

	// 检查是否过期
	if sess.ExpireAt < time.Now().Unix() {
		s.mu.Lock()
		delete(s.sessions, sessionID)
		s.mu.Unlock()
		return nil
	}

	// 续期
	s.mu.Lock()
	sess.ExpireAt = time.Now().Unix() + SessionExpireSeconds
	s.mu.Unlock()

	// 返回副本避免外部修改
	return &Session{
		UserName:    sess.UserName,
		SubUserName: sess.SubUserName,
		SubWafAuth:  sess.SubWafAuth,
		CreatedAt:   sess.CreatedAt,
		ExpireAt:    sess.ExpireAt,
	}
}

// Destroy 销毁会话
func (s *SessionStore) Destroy(sessionID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.sessions, sessionID)
}

// GetFromRequest 从 HTTP 请求 Cookie 中提取并返回会话
func (s *SessionStore) GetFromRequest(r *http.Request) *Session {
	cookie, err := r.Cookie(SessionCookieName)
	if err != nil {
		return nil
	}
	return s.Get(cookie.Value)
}

// SetCookie 设置会话 Cookie 到响应
func SetCookie(w http.ResponseWriter, sessionID string) {
	http.SetCookie(w, &http.Cookie{
		Name:     SessionCookieName,
		Value:    sessionID,
		Path:     "/",
		HttpOnly: true,
		MaxAge:   SessionExpireSeconds,
	})
}

// ClearCookie 清除会话 Cookie
func ClearCookie(w http.ResponseWriter) {
	http.SetCookie(w, &http.Cookie{
		Name:     SessionCookieName,
		Value:    "",
		Path:     "/",
		HttpOnly: true,
		MaxAge:   0,
	})
}

// cleanupLoop 后台定时清理过期会话
func (s *SessionStore) cleanupLoop() {
	ticker := time.NewTicker(60 * time.Second)
	defer ticker.Stop()
	for range ticker.C {
		s.mu.Lock()
		now := time.Now().Unix()
		expired := 0
		for id, sess := range s.sessions {
			if sess.ExpireAt < now {
				delete(s.sessions, id)
				expired++
			}
		}
		s.mu.Unlock()
		if expired > 0 {
			log.Printf("已清理 %d 个过期会话", expired)
		}
	}
}

// generateSessionID 生成安全的随机 session ID
func generateSessionID(secret string) string {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		log.Printf("警告: rand.Read 失败，使用时间戳回退: %v", err)
		return hex.EncodeToString([]byte(time.Now().Format("20060102150405"))) + secret
	}
	return hex.EncodeToString(buf)
}

// JSON 序列化辅助
func (s *Session) ToJSON() string {
	data, _ := json.Marshal(s)
	return string(data)
}
