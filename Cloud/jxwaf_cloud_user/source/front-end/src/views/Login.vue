<template>
  <div class="login-container">
    <div class="bg-gradient"></div>
    <div class="login-wrapper">
      <div class="login-left">
        <div class="brand-section">
          <div class="logo-container">
            <img src="../assets/images/logo.png" alt="JXWAF" class="logo-img" />
          </div>
          <h1 class="brand-name">JXWAF用户控制台</h1>
          <p class="brand-slogan">AI Web应用防火墙</p>
          <div class="features">
            <a class="feature-item" href="https://www.jxwaf.com/" target="_blank">
              <span class="icon">📄</span>
              <span>产品文档</span>
            </a>
            <a class="feature-item" href="https://github.com/jx-sec/jxwaf" target="_blank">
              <span class="icon">🔗</span>
              <span>GitHub</span>
            </a>
          </div>
        </div>
      </div>
      <div class="login-right">
        <div class="card-glow"></div>
        <div class="login-card">
          <div class="card-content">
            <div class="card-header">
              <h2>欢迎登录</h2>
              <p>请输入您的账号信息</p>
            </div>
            <el-form ref="loginForm" :model="loginForm" :rules="rules" class="login-form" @submit.prevent>
              <div class="form-group">
                <div class="input-wrapper">
                  <span class="input-icon">👤</span>
                  <el-form-item prop="sub_user_name">
                    <el-input
                      v-model="loginForm.sub_user_name"
                      placeholder="请输入账号名"
                      class="custom-input"
                    />
                  </el-form-item>
                </div>
              </div>
              <div class="form-group">
                <div class="input-wrapper">
                  <span class="input-icon">🔒</span>
                  <el-form-item prop="user_password">
                    <el-input
                      v-model="loginForm.user_password"
                      type="password"
                      placeholder="请输入密码"
                      class="custom-input"
                      show-password
                    />
                  </el-form-item>
                </div>
              </div>
              <div class="form-group">
                <div class="input-wrapper">
                  <span class="input-icon">🔑</span>
                  <el-form-item>
                    <el-input
                      v-model="loginForm.otp_auth_code"
                      placeholder="OTP验证码（非必填）"
                      class="custom-input"
                      @keyup.enter="onClickLogin('loginForm')"
                    />
                  </el-form-item>
                </div>
              </div>
              <div class="form-group">
                <button
                  type="button"
                  class="login-btn"
                  :class="{ 'is-loading': loading }"
                  :disabled="loading"
                  @click="onClickLogin('loginForm')"
                >
                  <span v-if="loading" class="loading-spinner"></span>
                  <span v-else>登 录</span>
                </button>
              </div>
            </el-form>
            <div class="card-footer">
              <el-button type="primary" link @click="onClickForget()">忘记密码</el-button>
              <el-button type="primary" link @click="$router.push('/user/register')" v-if="isShowRegist">
                立即注册
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="copyright">© 2024 JXWAF. All rights reserved.</div>
  </div>

  <Transition name="dialog-fade">
    <div v-if="dialogVisibleForget" class="dialog-overlay">
      <div class="dialog-forget">
        <div class="dialog-header">
          <h3>提示</h3>
          <button class="dialog-close" @click="dialogVisibleForget = false">×</button>
        </div>
        <div class="dialog-body">
          <p>请联系管理员重置密码</p>
        </div>
        <div class="dialog-footer">
          <button class="dialog-btn" @click="dialogVisibleForget = false">知道了</button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script>
import { JXAjax, setLoggedIn } from '../assets/scripts/common'

export default {
  name: 'LoginView',
  data() {
    return {
      loading: false,
      loginForm: {
        sub_user_name: '',
        user_password: '',
        otp_auth_code: '',
      },
      isShowRegist: true,
      dialogVisibleForget: false
    }
  },
  computed: {
    rules() {
      return {
        sub_user_name: [{ required: true, message: '请输入您的账号', trigger: 'blur' }],
        user_password: [{ required: true, message: '请输入您的密码', trigger: 'blur' }]
      }
    }
  },
  methods: {
    onClickForget() {
      this.dialogVisibleForget = true
    },
    onClickLogin(loginForm) {
      var t = this
      this.$refs[loginForm].validate((valid) => {
        if (valid) {
          t.loading = true
          JXAjax(
            'post',
            '/api/login',
            t.loginForm,
            function (response) {
              t.loading = false
              setLoggedIn(response.data.message)
              t.$router.push('/user/usage-stat')
            },
            function () {
              t.loading = false
            }
          )
        }
      })
    }
  }
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  background: #0f0f1a;
  font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', Arial, sans-serif;
}
.bg-gradient {
  position: absolute;
  width: 100%;
  height: 100%;
  background-color: #155799;
  background-image: linear-gradient(90deg, #155799, #159957);
}
.login-wrapper {
  display: flex;
  width: 1000px;
  min-height: 600px;
  background: rgba(255, 255, 255, 0.03);
  backdrop-filter: blur(40px);
  border-radius: 24px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 32px 64px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(255, 255, 255, 0.1);
  overflow: hidden;
  position: relative;
  z-index: 1;
  margin: 20px;
  margin-bottom: 60px;
}
.login-left {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
  position: relative;
}
.login-left::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23409eff' fill-opacity='0.03'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
}
.brand-section {
  text-align: center;
  position: relative;
  z-index: 1;
}
.logo-container {
  margin: 0 auto 18px;
  background: transparent;
  border-radius: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.logo-img {
  width: 120px;
  height: 120px;
  object-fit: contain;
}
.brand-name {
  font-size: 30px;
  font-weight: 700;
  color: #fff;
  margin: 0 0 12px;
  letter-spacing: 1px;
  text-shadow: 0 2px 20px rgba(64, 158, 255, 0.5);
}
.brand-slogan {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.7);
  margin: 0 0 40px;
}
.features {
  display: flex;
  flex-direction: column;
  gap: 16px;
  align-items: center;
}
.feature-item {
  display: flex;
  align-items: center;
  gap: 12px;
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
  padding: 12px 20px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  transition: all 0.3s ease;
  text-decoration: none;
  cursor: pointer;
  width: 160px;
}
.feature-item:hover {
  background: rgba(255, 255, 255, 0.1);
  transform: translateX(5px);
}
.feature-item .icon {
  font-size: 20px;
  color: #409eff;
}
.login-right {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
  position: relative;
}
.login-card {
  width: 100%;
  max-width: 360px;
  position: relative;
  z-index: 1;
}
.card-glow {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: #45945f;
  z-index: 0;
  opacity: 0;
  transition: opacity 0.3s ease;
}
.card-content {
  position: relative;
  z-index: 1;
}
.card-header {
  text-align: center;
  margin-bottom: 40px;
}
.card-header h2 {
  font-size: 28px;
  font-weight: 600;
  color: #fff;
  margin: 0 0 8px;
}
.card-header p {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.5);
  margin: 0;
}
.login-form .form-group {
  margin-bottom: 24px;
}
.login-form .input-wrapper {
  position: relative;
}
.login-form .input-icon {
  position: absolute;
  left: 15px;
  top: 50%;
  transform: translateY(-50%);
  color: rgba(255, 255, 255, 0.5);
  font-size: 16px;
  z-index: 2;
}
.login-form :deep(.custom-input .el-input__wrapper) {
  width: 100%;
  height: 48px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  padding: 0 15px 0 45px;
  box-shadow: none;
  transition: all 0.3s ease;
}
.login-form :deep(.custom-input .el-input__wrapper:hover) {
  background: rgba(255, 255, 255, 0.08);
  border-color: rgba(255, 255, 255, 1);
}
.login-form :deep(.custom-input .el-input__wrapper.is-focus) {
  background: rgba(255, 255, 255, 0.1);
  border-color: #ffffff;
  box-shadow: 0 0 0 3px rgba(64, 158, 255, 0.15);
}
.login-form :deep(.custom-input .el-input__inner) {
  color: #fff;
  font-size: 14px;
}
.login-form :deep(.custom-input .el-input__inner::placeholder) {
  color: rgba(255, 255, 255, 0.3);
}
.login-form :deep(.custom-input .el-input__suffix) {
  color: rgba(255, 255, 255, 0.5);
}
.login-form :deep(.el-form-item) {
  margin-bottom: 0;
}
.login-form :deep(.el-form-item__error) {
  color: #f56c6c;
  font-size: 12px;
  padding-top: 4px;
}
.login-btn {
  width: 100%;
  height: 48px;
  font-size: 16px;
  font-weight: 500;
  border-radius: 12px;
  background: linear-gradient(135deg, #409eff 0%, #2a5694 100%);
  border: none;
  color: #fff;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}
.login-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 12px 32px rgba(64, 158, 255, 0.4);
}
.login-btn:disabled {
  cursor: not-allowed;
  opacity: 0.7;
}
.login-btn.is-loading {
  background: linear-gradient(135deg, #409eff 0%, #8a2be2 100%);
}
.loading-spinner {
  width: 20px;
  height: 20px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
@keyframes spin {
  to { transform: rotate(360deg); }
}
.card-footer {
  display: flex;
  justify-content: space-between;
  color: rgba(255, 255, 255, 0.5);
  font-size: 14px;
}
.card-footer a {
  color: #409eff;
  cursor: pointer;
  text-decoration: none;
  transition: color 0.3s ease;
}
.card-footer a:hover {
  color: #a0cfff;
}
.copyright {
  position: absolute;
  bottom: 20px;
  color: rgba(255, 255, 255, 0.3);
  font-size: 12px;
  z-index: 2;
}
@media (max-width: 768px) {
  .login-wrapper {
    flex-direction: column;
    width: 100%;
    min-height: auto;
  }
  .login-left, .login-right {
    padding: 30px;
  }
}
.dialog-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background-color: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}
.dialog-forget {
  width: 420px;
  max-width: 90%;
  border-radius: 20px;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 32px 64px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(20px);
}
.dialog-header {
  padding: 24px 24px 12px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.dialog-header h3 {
  color: #303133;
  font-size: 18px;
  font-weight: 600;
  margin: 0;
}
.dialog-close {
  width: 32px;
  height: 32px;
  background: transparent;
  border: none;
  color: rgba(0, 0, 0, 0.4);
  font-size: 28px;
  line-height: 1;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  padding: 0;
}
.dialog-close:hover {
  color: rgba(0, 0, 0, 0.8);
  background: rgba(0, 0, 0, 0.05);
  transform: rotate(90deg);
}
.dialog-body {
  padding: 32px 24px;
  color: rgba(0, 0, 0, 0.75);
  font-size: 15px;
  text-align: center;
  line-height: 1.6;
}
.dialog-body p { margin: 0; }
.dialog-footer {
  padding: 16px 24px 24px;
  border-top: 1px solid rgba(0, 0, 0, 0.06);
  text-align: center;
  display: flex;
  justify-content: center;
}
.dialog-btn {
  width: 100%;
  max-width: 160px;
  height: 48px;
  font-size: 16px;
  font-weight: 500;
  border-radius: 12px;
  background: linear-gradient(135deg, #409eff 0%, #2a5694 100%);
  border: none;
  color: #fff;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}
.dialog-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 32px rgba(64, 158, 255, 0.4);
}
.dialog-fade-enter-active,
.dialog-fade-leave-active {
  transition: opacity 0.3s ease;
}
.dialog-fade-enter-active .dialog-forget,
.dialog-fade-leave-active .dialog-forget {
  transition: transform 0.3s ease;
}
.dialog-fade-enter-from,
.dialog-fade-leave-to {
  opacity: 0;
}
.dialog-fade-enter-from .dialog-forget {
  transform: scale(0.9) translateY(-20px);
}
.dialog-fade-leave-to .dialog-forget {
  transform: scale(0.9) translateY(-20px);
}
</style>
