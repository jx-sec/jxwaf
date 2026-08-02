<template>
  <div class="custom-wrap">
    <el-breadcrumb class="breadcrumb-style" separator="/">
      <el-breadcrumb-item>CDN功能配置</el-breadcrumb-item>
      <el-breadcrumb-item>资源预热</el-breadcrumb-item>
    </el-breadcrumb>
    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <div class="container-header only-btn">
          <div>
            <el-button type="primary" @click="dialogCreateFormVisible = true">新建预热任务</el-button>
          </div>
        </div>
        <div class="demo-block">
          <el-table :data="tableData" style="width: 100%">
            <el-table-column prop="task_name" label="任务名称" min-width="150"></el-table-column>
            <el-table-column label="URL数量" width="100">
              <template #default="scope">
                {{ scope.row.url_list ? scope.row.url_list.length : 0 }}
              </template>
            </el-table-column>
            <el-table-column prop="create_time" label="创建时间" width="180">
              <template #default="scope">
                {{ formatTime(scope.row.create_time) }}
              </template>
            </el-table-column>
            <el-table-column label="成功/失败" width="120">
              <template #default="scope">
                <span style="color: #67c23a">{{ scope.row.success_count || 0 }}</span>
                <span style="margin: 0 4px">/</span>
                <span style="color: #f56c6c">{{ scope.row.failed_count || 0 }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="100">
              <template #default="scope">
                <el-tag v-if="scope.row.status == 'success'" type="success">成功</el-tag>
                <el-tag v-else-if="scope.row.status == 'failed'" type="danger">失败</el-tag>
                <el-tag v-else-if="scope.row.status == 'partial'" type="warning">部分成功</el-tag>
                <el-tag v-else type="info">进行中</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" align="right" width="150">
              <template #default="scope">
                <el-button size="small" @click="handleDetail(scope.row)" class="button-block" type="text">详情</el-button>
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

    <el-dialog title="新建预热任务" v-model="dialogCreateFormVisible" width="680px" :close-on-click-modal="false" @closed="dialogCloseCreate" align-center>
      <el-form :model="createForm" :rules="createRules" ref="createFormRef" label-position="top">
        <el-form-item label="任务名称" prop="task_name">
          <el-input v-model="createForm.task_name" placeholder="请输入任务名称"></el-input>
        </el-form-item>
        <el-form-item label="URL列表" prop="urls">
          <el-input v-model="createForm.urls" type="textarea" :autosize="{ minRows: 6 }" placeholder="每行一个URL，或用逗号/分号分隔"></el-input>
          <div style="color: #909399; font-size: 12px; margin-top: 5px;">支持填写多个URL，每行一个，最多100个URL</div>
        </el-form-item>
      </el-form>
      <template #footer class="dialog-footer">
        <el-button @click="dialogCreateFormVisible = false">取消</el-button>
        <el-button type="primary" @click="onClickCreateSubmit" :loading="loading">提交预热</el-button>
      </template>
    </el-dialog>

    <el-dialog title="任务详情" v-model="dialogDetailVisible" width="780px" :close-on-click-modal="false" align-center>
      <el-descriptions :column="1" border v-if="detailData">
        <el-descriptions-item label="任务名称">{{ detailData.task_name }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ formatTime(detailData.create_time) }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag v-if="detailData.status == 'success'" type="success">成功</el-tag>
          <el-tag v-else-if="detailData.status == 'failed'" type="danger">失败</el-tag>
          <el-tag v-else-if="detailData.status == 'partial'" type="warning">部分成功</el-tag>
          <el-tag v-else type="info">进行中</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="URL列表">
          <div v-if="detailData.url_list">
            <div v-for="(url, idx) in detailData.url_list" :key="idx" style="margin-bottom: 4px; word-break: break-all;">
              {{ idx + 1 }}. {{ url }}
            </div>
          </div>
        </el-descriptions-item>
      </el-descriptions>
      <template #footer class="dialog-footer">
        <el-button type="primary" @click="dialogDetailVisible = false">关闭</el-button>
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
      dialogDetailVisible: false,
      detailData: null,
      createForm: {
        task_name: '',
        urls: ''
      },
      createRules: {
        task_name: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
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
        '/api/cdn_warmup/list',
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
      this.createForm.task_name = ''
      this.createForm.urls = ''
      this.$refs['createFormRef'] && this.$refs['createFormRef'].resetFields()
    },
    onClickCreateSubmit() {
      var t = this
      this.$refs['createFormRef'].validate((valid) => {
        if (!valid) return
        t.loading = true
        JXAjax(
          'post',
          '/api/cdn_warmup/create',
          {
            task_name: t.createForm.task_name,
            urls: t.createForm.urls
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
    handleDetail(row) {
      var t = this
      JXAjax(
        'post',
        '/api/cdn_warmup/detail',
        { _id: row._id },
        function (response) {
          t.detailData = response.data.message
          t.dialogDetailVisible = true
        },
        function () {},
        'no-message'
      )
    },
    handleDelete(row) {
      var t = this
      t.loading = true
      JXAjax(
        'post',
        '/api/cdn_warmup/delete',
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
