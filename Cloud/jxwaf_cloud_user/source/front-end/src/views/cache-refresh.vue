<template>
  <div class="custom-wrap">
    <el-breadcrumb class="breadcrumb-style" separator="/">
      <el-breadcrumb-item>CDN功能配置</el-breadcrumb-item>
      <el-breadcrumb-item>资源刷新</el-breadcrumb-item>
    </el-breadcrumb>
    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <div class="container-header only-btn">
          <div>
            <el-button type="primary" @click="dialogCreateFormVisible = true">添加刷新规则</el-button>
          </div>
        </div>
        <div class="demo-block">
          <el-alert
            title="资源刷新说明"
            type="info"
            :closable="false"
            style="margin-bottom: 15px;"
          >
            <template #default>
              添加刷新规则后，系统将在有效期内对匹配的URL强制回源刷新缓存，规则到期后自动失效。
            </template>
          </el-alert>
          <el-table :data="tableData" style="width: 100%">
            <el-table-column prop="rule_name" label="规则名称" min-width="150"></el-table-column>
            <el-table-column prop="match_value" label="匹配内容" min-width="250" show-overflow-tooltip></el-table-column>
            <el-table-column prop="match_type" label="匹配类型" width="100">
              <template #default="scope">
                <el-tag v-if="scope.row.match_type == 'prefix'" type="warning">前缀匹配</el-tag>
                <el-tag v-else-if="scope.row.match_type == 'regex'" type="danger">正则匹配</el-tag>
                <el-tag v-else type="primary">精确匹配</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="create_time" label="创建时间" width="170">
              <template #default="scope">
                {{ formatTime(scope.row.create_time) }}
              </template>
            </el-table-column>
            <el-table-column prop="expire_time" label="过期时间" width="170">
              <template #default="scope">
                {{ formatTime(scope.row.expire_time) }}
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="100">
              <template #default="scope">
                <el-tag v-if="scope.row.status == 'active'" type="success">生效中</el-tag>
                <el-tag v-else type="info">已过期</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" align="right" width="100">
              <template #default="scope">
                <el-popover placement="top" :width="160" trigger="click" :visible="scope.row.isVisiblePopover">
                  <p>确定删除吗？</p>
                  <div style="text-align: right; margin: 0">
                    <el-button size="small" type="text" @click="scope.row.isVisiblePopover = false">取消</el-button>
                    <el-button type="primary" size="small" @click="handleDelete(scope.row)" :loading="loading">确定</el-button>
                  </div>
                  <template #reference>
                    <el-button type="text" size="small" @click="scope.row.isVisiblePopover = true">删除</el-button>
                  </template>
                </el-popover>
              </template>
            </el-table-column>
          </el-table>
          <el-pagination
            small
            background
            layout="prev, pager, next"
            :page-count="tableTotal"
            v-model:current-page="currentPage"
            :page-size="20"
            @current-change="onCurrentChange"
          />
        </div>
      </el-col>
    </el-row>

    <el-dialog title="添加刷新规则" v-model="dialogCreateFormVisible" width="680px" :close-on-click-modal="false" @closed="dialogCloseCreate" align-center>
      <el-form :model="createForm" :rules="createRules" ref="createFormRef" label-position="top">
        <el-form-item label="匹配类型" prop="match_type">
          <el-radio-group v-model="createForm.match_type">
            <el-radio label="exact">精确匹配（刷新单个URL）</el-radio>
            <el-radio label="prefix">前缀匹配（刷新目录下所有资源）</el-radio>
            <el-radio label="regex">正则匹配（按正则表达式刷新）</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item :label="createForm.match_type == 'regex' ? '正则表达式列表' : 'URL列表'" prop="urls">
          <el-input v-model="createForm.urls" type="textarea" :autosize="{ minRows: 6 }" :placeholder="createForm.match_type == 'regex' ? '每行一个正则表达式，如 ^/api/.*' : '每行一个URL，或用逗号/分号分隔'"></el-input>
          <div style="color: #909399; font-size: 12px; margin-top: 5px;">
            <span v-if="createForm.match_type == 'exact'">精确匹配：每行一个完整URL，如 https://example.com/index.html，每行将生成一条独立刷新规则，最多100个URL</span>
            <span v-else-if="createForm.match_type == 'prefix'">前缀匹配：每行一个URL前缀，如 https://example.com/images/，将刷新该目录下所有资源</span>
            <span v-else>正则匹配：每行一个正则表达式（针对路径部分），如 ^/api/.*\.json$，将匹配所有符合正则的路径，每行生成一条独立规则</span>
          </div>
        </el-form-item>
        <el-form-item label="有效期（小时）">
          <el-input-number v-model="createForm.expire_hours" :min="1" :max="168" :step="1"></el-input-number>
          <span style="margin-left: 10px; color: #909399; font-size: 12px;">规则到期后自动失效，默认24小时</span>
        </el-form-item>
      </el-form>
      <template #footer class="dialog-footer">
        <el-button @click="dialogCreateFormVisible = false">取消</el-button>
        <el-button type="primary" @click="onClickCreateSubmit" :loading="loading">提交刷新</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { mixin, JXAjax, formatterTime } from '../assets/scripts/common'

export default {
  mixins: [mixin],
  data() {
    return {
      loading: false,
      loadingPage: false,
      tableData: [],
      currentPage: 1,
      tableTotal: 1,
      dialogCreateFormVisible: false,
      createForm: {
        match_type: 'exact',
        urls: '',
        expire_hours: 24
      },
      createRules: {
        urls: [{ required: true, message: '请输入URL列表', trigger: 'blur' }]
      }
    }
  },
  mounted() {
    this.onCurrentChange()
  },
  methods: {
    formatTime(timestamp) {
      if (!timestamp) return '-'
      return formatterTime(timestamp)
    },
    getData(page) {
      var t = this
      t.loadingPage = true
      JXAjax(
        'post',
        '/api/cdn_refresh/list',
        { page: page, page_size: 20 },
        function (response) {
          t.loadingPage = false
          t.tableData = response.data.records || []
          t.tableData.forEach((item) => {
            item.isVisiblePopover = false
          })
          if (response.data.total_pages == 0) {
            t.tableTotal = 1
          } else {
            t.tableTotal = response.data.total_pages
          }
          t.currentPage = response.data.page || 1
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    onCurrentChange() {
      this.getData(this.currentPage)
      this.$nextTick(() => {
        window.scroll(0, 0)
      })
    },
    dialogCloseCreate() {
      this.createForm.match_type = 'exact'
      this.createForm.urls = ''
      this.createForm.expire_hours = 24
      this.$refs['createFormRef'] && this.$refs['createFormRef'].resetFields()
    },
    onClickCreateSubmit() {
      var t = this
      this.$refs['createFormRef'].validate((valid) => {
        if (!valid) return
        t.loading = true
        JXAjax(
          'post',
          '/api/cdn_refresh/create',
          {
            match_type: t.createForm.match_type,
            urls: t.createForm.urls,
            expire_seconds: t.createForm.expire_hours * 3600
          },
          function (response) {
            t.dialogCreateFormVisible = false
            t.loading = false
            t.onCurrentChange()
          },
          function () {
            t.loading = false
          }
        )
      })
    },
    handleDelete(row) {
      var t = this
      t.loading = true
      JXAjax(
        'post',
        '/api/cdn_refresh/delete',
        { _id: row._id },
        function (response) {
          row.isVisiblePopover = false
          t.loading = false
          t.onCurrentChange()
        },
        function () {
          t.loading = false
        }
      )
    }
  }
}
</script>

<style scoped>
</style>
