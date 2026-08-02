<template>
  <div class="custom-wrap">
    <el-breadcrumb class="breadcrumb-style" separator="/">
      <el-breadcrumb-item>CDN功能配置</el-breadcrumb-item>
      <el-breadcrumb-item>静态资源缓存</el-breadcrumb-item>
    </el-breadcrumb>

    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <el-alert
          title="静态资源缓存说明"
          type="info"
          :closable="false"
          style="margin-bottom: 15px;"
        >
          <template #default>
            开启静态资源缓存后，js/css/png 等静态资源文件将缓存到 CDN 节点，用户请求命中缓存时直接返回、无需回源，可有效降低源站压力并加速页面加载。
          </template>
        </el-alert>

        <div class="cache-policy-card">
          <div class="cache-switch-row">
            <div class="cache-switch-info">
              <div class="cache-switch-title">
                <span class="cache-switch-name">静态资源缓存</span>
                <el-tag
                  v-if="switchData.static_resource_cache == 'true'"
                  type="success"
                  size="small"
                  effect="light"
                  >已开启</el-tag
                >
                <el-tag v-else type="info" size="small" effect="plain">未开启</el-tag>
              </div>
              <p class="cache-switch-desc">缓存 js/css/png/jpg 等静态资源文件，命中缓存后直接返回，无需回源</p>
            </div>
            <el-switch
              v-model="switchData.static_resource_cache"
              active-value="true"
              inactive-value="false"
              @change="onSwitchChange('static_resource_cache', $event)"
              :loading="switchLoading"
            ></el-switch>
          </div>

          <div v-if="switchData.static_resource_cache == 'true'" class="cache-types-block">
            <span class="cache-types-label">缓存资源类型</span>
            <div class="cache-types-list">
              <el-tag
                v-for="ext in cacheFileTypes"
                :key="ext"
                size="small"
                type="info"
                effect="plain"
                >.{{ ext }}</el-tag
              >
            </div>
          </div>

          <div v-if="switchData.static_resource_cache == 'true'" class="cache-secondary-box">
            <div class="cache-switch-row">
              <div class="cache-switch-info">
                <div class="cache-switch-title">
                  <span class="cache-switch-name">带参请求缓存</span>
                </div>
                <p class="cache-switch-desc">
                  开启：以「路径 + 查询参数」作为缓存键，相同路径不同参数的请求分别缓存；关闭：仅以路径作为缓存键（默认）
                </p>
              </div>
              <el-switch
                v-model="switchData.query_param_cache"
                active-value="true"
                inactive-value="false"
                @change="onSwitchChange('query_param_cache', $event)"
                :loading="switchLoading"
              ></el-switch>
            </div>
          </div>
        </div>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import { mixin, JXAjax } from '../assets/scripts/common'

export default {
  mixins: [mixin],
  data() {
    return {
      loadingPage: false,
      switchLoading: false,
      switchData: {
        static_resource_cache: 'false',
        query_param_cache: 'false'
      },
      cacheFileTypes: [
        'js', 'css', 'png', 'jpg', 'jpeg', 'gif', 'ico', 'svg',
        'woff', 'woff2', 'ttf', 'eot', 'mp4', 'mp3', 'webp',
        'bmp', 'pdf', 'zip', 'rar', 'gz'
      ]
    }
  },
  mounted() {
    this.getData()
  },
  methods: {
    getData() {
      var t = this
      var url = '/user/get_cache_switch'
      t.loadingPage = true
      JXAjax(
        'post',
        url,
        {},
        function (response) {
          t.loadingPage = false
          if (response.data.message) {
            t.switchData = {
              static_resource_cache: response.data.message.static_resource_cache || 'false',
              query_param_cache: response.data.message.query_param_cache || 'false'
            }
          }
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    onSwitchChange(switchName, switchStatus) {
      var t = this
      if (switchName === 'static_resource_cache' && switchStatus === 'false') {
        t.switchData.query_param_cache = 'false'
      }
      t.switchLoading = true
      var url = '/user/edit_cache_switch'
      var postData = {
        switch_name: switchName,
        switch_status: switchStatus
      }
      JXAjax(
        'post',
        url,
        postData,
        function () {
          t.switchLoading = false
        },
        function () {
          t.switchLoading = false
          t.getData()
        }
      )
    }
  }
}
</script>
<style scoped>
.cache-policy-card {
  padding: 6px 20px 20px;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  background: #fff;
}

.cache-switch-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 18px 0;
}

.cache-switch-info {
  flex: 1;
  margin-right: 20px;
}

.cache-switch-title {
  display: flex;
  align-items: center;
  gap: 8px;
}

.cache-switch-name {
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

.cache-switch-desc {
  margin: 6px 0 0;
  color: #909399;
  font-size: 12px;
  line-height: 18px;
}

.cache-types-block {
  display: flex;
  align-items: flex-start;
  padding: 14px 16px;
  margin-bottom: 18px;
  background: #fafafa;
  border: 1px solid #ebeef5;
  border-radius: 4px;
}

.cache-types-label {
  flex-shrink: 0;
  margin-right: 14px;
  font-size: 12px;
  line-height: 24px;
  color: #606266;
}

.cache-types-list {
  flex: 1;
}

.cache-types-list .el-tag {
  margin: 0 8px 8px 0;
}

.cache-secondary-box {
  padding: 0 16px;
  background: #fafafa;
  border: 1px solid #ebeef5;
  border-radius: 4px;
}
</style>
