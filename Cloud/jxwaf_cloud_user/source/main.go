package main

import (
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"jxwaf-user-console/internal"
)

func main() {
	cfg := internal.LoadConfig()

	configPath := "/opt/jxwaf_user_console/conf/waf_config.json"
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		os.MkdirAll(filepath.Dir(configPath), 0755)
		cfg.SaveToFile(configPath)
	}

	cloudClient := internal.NewCloudClient(cfg.CloudAPIURL, cfg.CloudAPIKey, cfg.DefaultWebsiteAccessConf)
	sessionStore := internal.NewSessionStore(cfg.SessionSecret)

	var db *internal.DB
	var err error
	if cfg.MySQLHost != "" && cfg.MySQLUser != "" {
		db, err = internal.NewDB(cfg.MySQLDSN())
		if err != nil {
			log.Printf("警告: 数据库连接失败，将不使用数据库模式: %v", err)
			db = nil
		} else {
			defer db.Close()
		}
	} else {
		log.Printf("未配置 MySQL 数据库，将使用无数据库模式（依赖 Cloud API 返回 sub_waf_auth）")
	}

	mux := http.NewServeMux()

	handler := internal.NewHandler(cloudClient, sessionStore, db)
	handler.RegisterRoutes(mux)

	staticDir := getStaticDir()
	spaHandler := setupStaticFiles(mux, staticDir)

	// /user/ 路由：POST 请求走 API 代理，其他方法走 SPA
	userProxy := handler.UserProxy()
	mux.HandleFunc("/user/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			userProxy(w, r)
		} else {
			spaHandler(w, r)
		}
	})

	// 根路由：所有未匹配的请求，POST /api/ 返回404，其他返回SPA
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost && strings.HasPrefix(r.URL.Path, "/api/") {
			internal.FailResponse(w, "API not found: "+r.URL.Path)
			return
		}
		spaHandler(w, r)
	})

	port := getEnv("HTTP_PORT", "8080")
	addr := ":" + port
	log.Printf("JXWAF User Console 启动中，监听 %s", addr)

	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("服务启动失败: %v", err)
	}
}

func getStaticDir() string {
	if dir := os.Getenv("STATIC_DIR"); dir != "" {
		return dir
	}
	if _, err := os.Stat("/opt/jxwaf_user_console/html"); err == nil {
		return "/opt/jxwaf_user_console/html"
	}
	return "./static"
}

func setupStaticFiles(mux *http.ServeMux, staticDir string) http.HandlerFunc {
	assetsDir := filepath.Join(staticDir, "assets")
	assetsHandler := http.StripPrefix("/assets/", http.FileServer(http.Dir(assetsDir)))
	mux.Handle("/assets/", assetsHandler)

	mux.HandleFunc("/favicons.ico", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, filepath.Join(staticDir, "favicons.ico"))
	})

	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.NotFound(w, r)
			return
		}

		filePath := filepath.Join(staticDir, strings.TrimPrefix(r.URL.Path, "/"))
		if info, err := os.Stat(filePath); err == nil && !info.IsDir() {
			http.ServeFile(w, r, filePath)
			return
		}

		http.ServeFile(w, r, filepath.Join(staticDir, "index.html"))
	}
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
