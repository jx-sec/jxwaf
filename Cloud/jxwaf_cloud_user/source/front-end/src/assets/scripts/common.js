import axios from 'axios'
import { ElMessage } from 'element-plus'
import errMsg from './errMsg.json'

axios.defaults.withCredentials = true

var SESSION_KEY = 'jxwaf_session'
var SESSION_USER = 'jxwaf_username'

export var nameMap = {
  'cn': '国内',
  'abroad': '国外',
  'black': '黑名单',
  'white': '白名单',
  'redirect': '重定向',
  'monitor': '监控',
  'high': '高危',
  'medium': '中危',
  'low': '低危',
  'normal': '正常',
  'true': '是',
  'false': '否'
}

export function isLoggedIn() {
  return sessionStorage.getItem(SESSION_KEY) === '1'
}

export function getUserName() {
  return sessionStorage.getItem(SESSION_USER) || ''
}

export function setLoggedIn(username) {
  sessionStorage.setItem(SESSION_KEY, '1')
  localStorage.setItem('isLogin', '1')
  if (username) {
    sessionStorage.setItem(SESSION_USER, username)
    localStorage.setItem('userName', username)
  }
}

export function clearSession() {
  sessionStorage.removeItem(SESSION_KEY)
  sessionStorage.removeItem(SESSION_USER)
  localStorage.removeItem('isLogin')
  localStorage.removeItem('userName')
}

export function formatterTime(row, column, cellValue) {
  if (!cellValue) return ''
  var d = new Date(cellValue * 1000)
  var year = d.getFullYear()
  var month = (d.getMonth() + 1) < 10 ? '0' + (d.getMonth() + 1) : (d.getMonth() + 1)
  var day = d.getDate() < 10 ? '0' + d.getDate() : d.getDate()
  var hour = d.getHours() < 10 ? '0' + d.getHours() : d.getHours()
  var minute = d.getMinutes() < 10 ? '0' + d.getMinutes() : d.getMinutes()
  var second = d.getSeconds() < 10 ? '0' + d.getSeconds() : d.getSeconds()
  return year + '-' + month + '-' + day + ' ' + hour + ':' + minute + ':' + second
}

export function formatterDateTime(time) {
  if (!time) return ''
  var d = new Date(time)
  var year = d.getFullYear()
  var month = (d.getMonth() + 1) < 10 ? '0' + (d.getMonth() + 1) : (d.getMonth() + 1)
  var day = d.getDate() < 10 ? '0' + d.getDate() : d.getDate()
  var hour = d.getHours() < 10 ? '0' + d.getHours() : d.getHours()
  var minute = d.getMinutes() < 10 ? '0' + d.getMinutes() : d.getMinutes()
  var second = d.getSeconds() < 10 ? '0' + d.getSeconds() : d.getSeconds()
  return year + '-' + month + '-' + day + ' ' + hour + ':' + minute + ':' + second
}

export function validateRuleName(rule, value, callback) {
  let r = /^[a-zA-Z][a-zA-Z0-9_-]*$/
  let flag = r.test(value)
  if (!flag) {
    callback(new Error('请输入字母开头，只包含字母、数字、下划线"_"、中横线"-"'))
  } else {
    callback()
  }
}

export function validatePositiveInt(rule, value, callback) {
  let r = /^\+?[1-9][0-9]*$/
  let flag = r.test(value)
  if (!flag) {
    callback(new Error('请输入大于0的整数'))
  } else {
    callback()
  }
}

export function validatePort(rule, value, callback) {
  if (value < 1 || value > 65534) {
    callback(new Error('后端服务器端口需1~65534之间'))
  } else {
    callback()
  }
}

export function validateDomainPort(rule, value, callback) {
  if (value.indexOf('\\') > -1 || value.indexOf('?') > -1 || value.indexOf('/') > -1) {
    callback(new Error('域名/IP输入错误'))
  } else {
    callback()
  }
}

function isSuccessResponse(data) {
  if (data && typeof data === 'object') {
    if (data.result === true) return true
    if (data.code === 200) return true
  }
  return false
}

function getErrorMessage(data) {
  if (data && typeof data === 'object') {
    if (data.message) return data.message
    if (data.msg) return data.msg
  }
  return '请求失败'
}

function isAuthError(msg) {
  const authErrors = [
    'redirect_to_login',
    '未登录或会话已过期，请重新登录',
    'missing jxwaf_waf_auth',
    'invalid jxwaf_waf_auth',
    'missing jxwaf_sub_waf_auth',
    'invalid jxwaf_sub_waf_auth',
    'sub account not belong to this user'
  ]
  return authErrors.indexOf(msg) !== -1
}

function redirectToLogin() {
  clearSession()
  ElMessage.closeAll()
  ElMessage({
    duration: 0,
    showClose: true,
    message: '认证失效，请重新登录',
    type: 'error'
  })
  setTimeout(function () {
    window.location.href = '/user/login'
  }, 1500)
}

export function JXAjax(method, url, params, success, fail, messageStatus) {
  let strMsg = errMsg[500]
  let detail = strMsg
  let msgStatus = messageStatus || 'has-massage'

  return axios({
    method: method,
    url: url,
    data: params
  })
    .then(function (response) {
      const data = response.data
      if (isSuccessResponse(data)) {
        if (url === '/api/login' && data.message) {
          setLoggedIn(params.sub_user_name)
        }
        if (method === 'post' && msgStatus === 'has-massage' && url !== '/api/logout' && url !== '/api/check_session') {
          ElMessage({
            message: errMsg[200] || '操作成功',
            type: 'success'
          })
        }
        success(response)
      } else {
        if (data.errCode) {
          strMsg = errMsg[data.errCode]
        }
        detail = getErrorMessage(data)
        if (detail === 'name is exist') {
          ElMessage({
            duration: 0,
            showClose: true,
            message:
              '错误原因：' +
              "<a href='javascript:;' class='error-message-btn' onclick='this.nextElementSibling.style.display=\"block\"'> " +
              '名称已存在' +
              " </a> <p class='error-message-detail' style= 'display: none;'>" +
              detail +
              '</p>',
            type: 'error',
            dangerouslyUseHTMLString: true
          })
        } else if (isAuthError(detail)) {
          redirectToLogin()
        } else {
          ElMessage({
            duration: 0,
            showClose: true,
            message: detail || strMsg,
            type: 'error'
          })
        }
        if (fail) fail()
      }
    })
    .catch(function (error) {
      var msg = error.message || '网络请求失败'
      if (error.response && error.response.data) {
        msg = getErrorMessage(error.response.data)
      }
      if (isAuthError(msg)) {
        redirectToLogin()
        if (fail) fail()
        return
      }
      ElMessage({
        duration: 0,
        showClose: true,
        message: msg || strMsg,
        type: 'error'
      })
      if (fail) fail()
    })
}

export const mixin = {
  data() {
    return {
      timeout: null
    }
  },
  mounted() {
    this.checkLogin()
  },
  methods: {
    checkLogin() {
      var t = this
      if (isLoggedIn()) return
      JXAjax(
        'post',
        '/api/check_session',
        {},
        function (response) {
          if (response.data.result && response.data.data) {
            setLoggedIn(response.data.data.sub_user_name)
          }
        },
        function () {
          var path = window.location.pathname
          if (path !== '/user/login' && path !== '/user/register') {
            clearSession()
            window.location.href = '/user/login'
          }
        },
        'no-message'
      )
    }
  }
}

export default mixin
