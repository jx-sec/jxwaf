<template>
  <div v-if="isLoginOrRegister">
    <router-view />
  </div>
  <div v-else class="common-layout" v-loading="pageLoading" :element-loading-text="pageLoadingText">
    <el-container class="container-height">
      <el-aside :width="isCollapse ? '64px' : '200px'" class="el-aside">
        <div class="title" :class="{ 'title-collapse': isCollapse }">
          <div class="title-box">
            <p v-if="isCollapse">
              <span><img :src="imgLogoSmall" class="logo-small" /></span>
            </p>
            <p v-else>
              <span><img :src="imgLogo" class="logo-img" /></span>
              <span class="title-text">JXWAF用户控制台</span>
            </p>
          </div>
        </div>
        <el-scrollbar>
          <el-menu
            :default-active="activeMenu"
            :collapse="isCollapse"
            :collapse-transition="false"
            class="el-menu-vertical"
            router
            background-color="#545c64"
            text-color="#fff"
            active-text-color="#409eff"
          >
            <el-menu-item index="/user/usage-stat">
              <el-icon><DataAnalysis /></el-icon>
              <template #title>数据统计</template>
            </el-menu-item>
            <el-menu-item index="/user/soc-attack-event">
              <el-icon><Warning /></el-icon>
              <template #title>攻击事件</template>
            </el-menu-item>
            <el-menu-item index="/user/domain">
              <el-icon><Link /></el-icon>
              <template #title>网站接入</template>
            </el-menu-item>
            <el-menu-item index="/user/dns-config">
              <el-icon><Connection /></el-icon>
              <template #title>CNAME 自动接入配置</template>
            </el-menu-item>
            <el-menu-item index="/user/ssl-manage">
              <el-icon><Lock /></el-icon>
              <template #title>证书管理</template>
            </el-menu-item>

            <el-sub-menu index="protection-config">
              <template #title>
                <el-icon><Setting /></el-icon>
                <span>防护配置</span>
              </template>
              <el-menu-item index="/user/web-engine-protection">Web引擎配置</el-menu-item>
              <el-menu-item index="/user/web-rule-protection">Web规则配置</el-menu-item>
              <el-menu-item index="/user/page-tamper-proof">网页防篡改</el-menu-item>
              <el-menu-item index="/user/web-white-rule">Web白名单规则</el-menu-item>
              <el-menu-item index="/user/flow-engine-protection">流量防护引擎</el-menu-item>
              <el-menu-item index="/user/flow-rule-protection">流量防护规则</el-menu-item>
              <el-menu-item index="/user/flow-ip-region-block">IP区域封禁</el-menu-item>
              <el-menu-item index="/user/flow-white-rule">流量白名单规则</el-menu-item>
            </el-sub-menu>

            <el-sub-menu index="cdn-config">
              <template #title>
                <el-icon><Promotion /></el-icon>
                <span>CDN功能配置</span>
              </template>
              <el-menu-item index="/user/cache-policy">静态资源缓存</el-menu-item>
              <el-menu-item index="/user/cache-warmup">资源预热</el-menu-item>
              <el-menu-item index="/user/cache-refresh">资源刷新</el-menu-item>
            </el-sub-menu>

            <el-menu-item index="/user/soc-query-log">
              <el-icon><Document /></el-icon>
              <template #title>日志查询</template>
            </el-menu-item>
          </el-menu>
        </el-scrollbar>
      </el-aside>
      <el-container>
        <el-header class="el-header">
          <div class="left" @click="toggleCollapse">
            <el-icon :size="20"><Fold v-if="!isCollapse" /><Expand v-else /></el-icon>
          </div>
          <div class="right">
            <span style="margin-right: 10px">{{ userName }}</span>
            <a href="javascript:void(0)" class="link" @click="handleLogout">退出</a>
          </div>
        </el-header>
        <el-main>
          <router-view />
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  Fold,
  Expand,
  DataAnalysis,
  Warning,
  Link,
  Lock,
  Setting,
  Promotion,
  Document,
  Connection
} from '@element-plus/icons-vue'
import { JXAjax, getUserName, clearSession } from './assets/scripts/common'
import imgLogo from './assets/images/logo1800.png'

export default {
  name: 'App',
  components: {
    Fold,
    Expand,
    DataAnalysis,
    Warning,
    Link,
    Lock,
    Setting,
    Promotion,
    Document,
    Connection
  },
  setup() {
    const route = useRoute()
    const router = useRouter()
    const isCollapse = ref(false)
    const userName = ref('')
    const pageLoading = ref(false)
    const pageLoadingText = ref('加载中...')

    const isLoginOrRegister = computed(() => {
      return route.path === '/user/login' || route.path === '/user/register'
    })

    const activeMenu = computed(() => route.path)

    const toggleCollapse = () => {
      isCollapse.value = !isCollapse.value
    }

    const handleLogout = () => {
      pageLoading.value = true
      pageLoadingText.value = '退出中...'
      JXAjax(
        'post',
        '/api/logout',
        {},
        function () {
          pageLoading.value = false
          clearSession()
          ElMessage.success('退出成功')
          router.push('/user/login')
        },
        function () {
          pageLoading.value = false
          ElMessage.error('退出失败,请稍后重试')
        }
      )
    }

    onMounted(() => {
      userName.value = getUserName() || ''
    })

    watch(
      () => route.path,
      () => {
        userName.value = getUserName() || ''
      }
    )

    return {
      isCollapse,
      userName,
      pageLoading,
      pageLoadingText,
      isLoginOrRegister,
      activeMenu,
      imgLogo,
      imgLogoSmall: imgLogo,
      toggleCollapse,
      handleLogout
    }
  }
}
</script>

<style scoped>
.common-layout {
  height: 100vh;
  font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', Arial, sans-serif;
}
.container-height {
  height: 100%;
}
.el-aside {
  background-color: #545c64;
  overflow-x: hidden;
}
.title {
  height: 60px;
  line-height: 60px;
  color: #fff;
  display: flex;
  justify-content: center;
  background-color: #545c64;
}
.title-box p {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100%;
  margin: 0;
}
.title-box p span {
  display: flex;
  align-items: center;
}
.logo-img {
  width: 30px;
  height: 30px;
  display: block;
  margin-right: 8px;
}
.logo-small {
  width: 30px;
  height: 30px;
  display: block;
}
.title-text {
  font-size: 14px;
  font-weight: 700;
  white-space: nowrap;
  overflow: hidden;
}
.el-menu-vertical {
  border-right: none;
  height: calc(100vh - 60px);
}
.el-menu-vertical:not(.el-menu--collapse) {
  width: 200px;
}
.el-header {
  background-color: #545c64;
  color: #333;
  text-align: center;
  line-height: 60px;
  height: 60px;
  padding: 0;
  font-size: 12px;
  text-align: left;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.left,
.right {
  padding: 0 20px;
  color: #66b1ff;
  display: flex;
  align-items: center;
}
.left {
  cursor: pointer;
}
.left .el-icon {
  height: 60px;
  line-height: 60px;
  display: block;
}
.right .link {
  cursor: pointer;
  color: #66b1ff;
  text-decoration: none;
}
:deep(.el-menu) {
  background-color: #545c64;
  border-right: none;
}
:deep(.el-menu-item),
:deep(.el-sub-menu__title) {
  color: #fff;
}
:deep(.el-menu-item:hover),
:deep(.el-sub-menu__title:hover) {
  background-color: #4b5259;
  color: #fff;
}
:deep(.el-menu-item.is-active) {
  background-color: #409eff;
  color: #fff;
}
:deep(.el-sub-menu .el-menu-item) {
  background-color: #434a50;
}
:deep(.el-sub-menu .el-menu-item:hover) {
  background-color: #3a4046;
  color: #fff;
}
:deep(.el-sub-menu .el-menu-item.is-active) {
  background-color: #409eff;
  color: #fff;
}
</style>
