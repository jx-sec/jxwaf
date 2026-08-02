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
            <template v-if="!registerSuccess">
              <div class="card-header">
                <h2>创建账号</h2>
                <p>请填写账号信息完成注册</p>
              </div>
              <el-form ref="registerForm" :model="registerForm" :rules="rules" class="login-form" @submit.prevent>
                <div class="form-group">
                  <div class="input-wrapper">
                    <span class="input-icon">👤</span>
                    <el-form-item prop="sub_user_name">
                      <el-input
                        v-model="registerForm.sub_user_name"
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
                        v-model="registerForm.user_password"
                        type="password"
                        placeholder="请输入密码（至少6位）"
                        class="custom-input"
                        show-password
                      />
                    </el-form-item>
                  </div>
                </div>
                <div class="form-group">
                  <div class="input-wrapper">
                    <span class="input-icon">🔐</span>
                    <el-form-item prop="user_password2">
                      <el-input
                        v-model="registerForm.user_password2"
                        type="password"
                        placeholder="请再次输入密码"
                        class="custom-input"
                        show-password
                        @keyup.enter="onClickRegister('registerForm')"
                      />
                    </el-form-item>
                  </div>
                </div>
                <div class="form-group otp-switch-group">
                  <div class="otp-switch-wrapper">
                    <span class="otp-label">OTP双因素认证</span>
                    <el-switch
                      v-model="registerForm.otp_auth"
                      active-value="true"
                      inactive-value="false"
                      class="otp-switch"
                      @change="onOtpSwitchChange"
                    />
                  </div>
                </div>
                <div v-if="registerForm.otp_auth == 'true'" class="form-group">
                  <div class="otp-qrcode-wrapper">
                    <div class="otp-qrcode-title">请使用身份验证器（如Google Authenticator）扫描二维码</div>
                    <div class="otp-qrcode-box" @click="onClickGetOtp">
                      <span v-if="otpLoading" class="refresh-icon">⟳</span>
                      <img v-else-if="imgOtp" :src="imgOtp" alt="OTP二维码" class="otp-img" />
                      <span v-else class="otp-placeholder">点击获取二维码</span>
                    </div>
                    <div v-if="otpSecretKey" class="secret-key-row">
                      <span class="secret-key-label">密钥：</span>
                      <span class="secret-key-value" @click="copySecretKey">{{ otpSecretKey }}</span>
                      <span class="secret-key-copy" @click="copySecretKey">复制</span>
                    </div>
                    <div class="otp-manual-tip">若无法扫描，请手动输入密钥添加账号</div>
                  </div>
                </div>
                <div v-if="registerForm.otp_auth == 'true'" class="form-group">
                  <div class="input-wrapper">
                    <span class="input-icon">🔑</span>
                    <el-form-item prop="otp_auth_code">
                      <el-input
                        v-model="registerForm.otp_auth_code"
                        placeholder="请输入OTP验证码"
                        class="custom-input"
                        @keyup.enter="onClickRegister('registerForm')"
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
                    @click="onClickRegister('registerForm')"
                  >
                    <span v-if="loading" class="loading-spinner"></span>
                    <span v-else>注 册</span>
                  </button>
                </div>
              </el-form>
              <div class="card-footer">
                <el-button type="primary" link @click="$router.push('/user/login')">
                  已有账号？立即登录
                </el-button>
              </div>
            </template>
            <template v-else>
              <div class="success-section">
                <div class="success-icon">✓</div>
                <h2>注册成功</h2>
                <p class="success-desc">您的账号已创建成功</p>
                <button type="button" class="login-btn" @click="goToLogin">立即登录</button>
              </div>
            </template>
          </div>
        </div>
      </div>
    </div>
    <div class="copyright">© 2024 JXWAF. All rights reserved.</div>
  </div>
</template>

<script>
import { JXAjax } from '../assets/scripts/common'
import QRCode from 'qrcode'

export default {
  name: 'RegisterView',
  data() {
    return {
      active: 0,
      loading: false,
      otpLoading: false,
      registerForm: {
        sub_user_name: '',
        user_password: '',
        user_password2: '',
        otp_auth_code: '',
        otp_auth: 'false'
      },
      imgOtp: '',
      otpSecretKey: '',
      registerSuccess: false
    }
  },
  computed: {
    rules() {
      var t = this
      var validatePass2 = function(rule, value, callback) {
        if (value === '') {
          callback(new Error('请再次输入密码'))
        } else if (value !== t.registerForm.user_password) {
          callback(new Error('两次输入密码不一致'))
        } else {
          callback()
        }
      }
      var baseRules = {
        sub_user_name: [
          { required: true, message: '请输入账号名', trigger: 'blur' },
          { min: 3, max: 32, message: '账号名长度为3-32个字符', trigger: 'blur' }
        ],
        user_password: [
          { required: true, message: '请输入密码', trigger: 'blur' },
          { min: 6, message: '密码长度至少6位', trigger: 'blur' }
        ],
        user_password2: [
          { required: true, validator: validatePass2, trigger: 'blur' }
        ]
      }
      if (this.registerForm.otp_auth === 'true') {
        baseRules.otp_auth_code = [
          { required: true, message: '请输入OTP验证码', trigger: 'blur' }
        ]
      }
      return baseRules
    }
  },
  methods: {
    onOtpSwitchChange(val) {
      if (val === 'true') {
        this.onClickGetOtp()
      } else {
        this.imgOtp = ''
        this.otpSecretKey = ''
        this.registerForm.otp_auth_code = ''
      }
    },
    onClickGetOtp() {
      var t = this
      t.otpLoading = true
      JXAjax(
        'post',
        '/api/get_otp_qr_url',
        {},
        function (response) {
          t.otpLoading = false
          if (response.data.result) {
            var otpUrl = response.data.message
            t.otpSecretKey = response.data.otp_secret_key
            QRCode.toDataURL(otpUrl, { width: 160, margin: 1 })
              .then(function (dataUrl) {
                t.imgOtp = dataUrl
              })
              .catch(function (err) {
                t.$message({
                  showClose: true,
                  message: '二维码生成失败: ' + err,
                  type: 'error'
                })
              })
          } else {
            t.$message({
              showClose: true,
              message: response.data.message || '获取OTP二维码失败',
              type: 'error'
            })
          }
        },
        function () {
          t.otpLoading = false
        },
        'no-massage'
      )
    },
    onClickRegister(formName) {
      var t = this
      this.$refs[formName].validate((valid) => {
        if (valid) {
          t.loading = true
          var postData = {
            sub_user_name: t.registerForm.sub_user_name,
            user_password: t.registerForm.user_password,
            sub_otp_auth: t.registerForm.otp_auth
          }
          if (t.registerForm.otp_auth === 'true') {
            postData.otp_auth_code = t.registerForm.otp_auth_code
            postData.otp_secret_key = t.otpSecretKey
          }
          JXAjax(
            'post',
            '/api/register',
            postData,
            function (response) {
              t.loading = false
              if (response.data.result) {
                t.registerSuccess = true
              } else {
                t.$message({
                  showClose: true,
                  message: response.data.message || '注册失败',
                  type: 'error'
                })
              }
            },
            function () {
              t.loading = false
            }
          )
        }
      })
    },
    copySecretKey() {
      if (this.otpSecretKey && navigator.clipboard) {
        navigator.clipboard.writeText(this.otpSecretKey)
        this.$message({
          message: '密钥已复制',
          type: 'success',
          duration: 1500
        })
      }
    },
    goToLogin() {
      this.$router.push('/user/login')
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
  overflow-y: auto;
  max-height: calc(100vh - 120px);
}
.login-card {
  width: 100%;
  max-width: 400px;
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
  margin-bottom: 30px;
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
  margin-bottom: 20px;
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
.otp-switch-group {
  margin-bottom: 16px !important;
}
.otp-switch-wrapper {
  display: flex;
  align-items: center;
  gap: 12px;
}
.otp-label {
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
}
.otp-switch {
  --el-switch-on-color: #409eff;
}
.otp-qrcode-wrapper {
  text-align: center;
}
.otp-qrcode-title {
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
  margin-bottom: 12px;
  text-align: left;
}
.otp-qrcode-box {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 180px;
  border: 1px dashed rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  background: rgba(255, 255, 255, 0.02);
}
.otp-qrcode-box:hover {
  border-color: rgba(255, 255, 255, 1);
  background: rgba(255, 255, 255, 0.05);
}
.otp-placeholder {
  color: rgba(255, 255, 255, 0.4);
  font-size: 14px;
}
.refresh-icon {
  color: rgba(255, 255, 255, 0.5);
  font-size: 26px;
  animation: rotation 2s linear infinite;
  display: inline-block;
}
@keyframes rotation {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
.otp-img {
  max-width: 160px;
  max-height: 160px;
  border-radius: 8px;
}
.secret-key-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 12px;
  padding: 8px 12px;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 8px;
  font-size: 12px;
  flex-wrap: wrap;
}
.secret-key-label {
  color: rgba(255, 255, 255, 0.5);
  font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Microsoft YaHei', Arial, sans-serif;
}
.secret-key-value {
  color: #409eff;
  font-weight: 600;
  font-family: 'Courier New', monospace;
  letter-spacing: 1px;
  word-break: break-all;
  cursor: pointer;
  flex: 1;
}
.secret-key-copy {
  color: #67c23a;
  cursor: pointer;
  padding: 2px 8px;
  border-radius: 4px;
  background: rgba(103, 194, 58, 0.15);
  font-size: 12px;
  font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Microsoft YaHei', Arial, sans-serif;
  transition: background 0.2s;
  flex-shrink: 0;
}
.secret-key-copy:hover {
  background: rgba(103, 194, 58, 0.3);
}
.otp-manual-tip {
  color: rgba(255, 255, 255, 0.4);
  font-size: 12px;
  margin-top: 8px;
  text-align: left;
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
  display: inline-block;
}
@keyframes spin {
  to { transform: rotate(360deg); }
}
.card-footer {
  display: flex;
  justify-content: center;
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
.success-section {
  text-align: center;
  padding: 40px 20px;
}
.success-icon {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #00ced1, #409eff);
  color: #fff;
  font-size: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 24px;
}
.success-section h2 {
  font-size: 24px;
  font-weight: 600;
  color: #fff;
  margin: 0 0 12px;
}
.success-desc {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.5);
  margin: 0 0 32px;
}
@media (max-width: 768px) {
  .login-wrapper {
    flex-direction: column;
    width: 90%;
    min-height: auto;
    max-height: none;
  }
  .login-left, .login-right {
    padding: 30px;
  }
  .login-right {
    max-height: none;
    overflow-y: visible;
  }
}
</style>
