package internal

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

// DB 数据库连接
type DB struct {
	db *sql.DB
}

// NewDB 创建数据库连接并测试连通性
func NewDB(dsn string) (*DB, error) {
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, fmt.Errorf("打开数据库连接失败: %w", err)
	}

	db.SetMaxOpenConns(20)
	db.SetMaxIdleConns(5)

	if err := db.Ping(); err != nil {
		db.Close()
		return nil, fmt.Errorf("数据库连接测试失败: %w", err)
	}

	log.Printf("数据库连接成功")
	return &DB{db: db}, nil
}

// Close 关闭数据库连接
func (d *DB) Close() {
	if d.db != nil {
		d.db.Close()
	}
}

// GetSubWafAuth 登录成功后查询子账号的 waf_auth（sub_waf_auth）
// userName: 主账号名（由 Cloud API 的 jxwaf_waf_auth 反查得到）
// subUserName: 子账号名
// 返回子账号的 waf_auth，用于后续调用 Cloud /user/ 接口时的双层鉴权
func (d *DB) GetSubWafAuth(userName, subUserName string) (string, error) {
	var wafAuth string
	query := "SELECT waf_auth FROM jxwaf_waf_sub_account WHERE user_name = ? AND sub_user_name = ?;"
	err := d.db.QueryRow(query, userName, subUserName).Scan(&wafAuth)
	if err != nil {
		if err == sql.ErrNoRows {
			return "", fmt.Errorf("账号 %s 不存在", subUserName)
		}
		return "", fmt.Errorf("查询子账号 waf_auth 失败: %w", err)
	}
	return wafAuth, nil
}

// GetUserNameByWafAuth 通过主账号 waf_auth 反查 user_name
// 用于登录成功后从 Cloud API key 获取对应的 user_name
func (d *DB) GetUserNameByWafAuth(wafAuth string) (string, error) {
	var userName string
	query := "SELECT user_name FROM jxwaf_admin_account WHERE waf_auth = ?;"
	err := d.db.QueryRow(query, wafAuth).Scan(&userName)
	if err != nil {
		if err == sql.ErrNoRows {
			return "", fmt.Errorf("waf_auth 对应的主账号不存在")
		}
		return "", fmt.Errorf("查询主账号 user_name 失败: %w", err)
	}
	return userName, nil
}
