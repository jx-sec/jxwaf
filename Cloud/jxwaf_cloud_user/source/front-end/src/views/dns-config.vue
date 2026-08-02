<template>
  <div>
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>网站接入</el-breadcrumb-item>
        <el-breadcrumb-item>CNAME 自动接入配置</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>
    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <el-alert
          title="配置 DNS 服务商后，新增网站时将自动在您的 DNS 上添加 CNAME 记录，实现一键接入。支持配置多个 DNS 服务商，系统将按域名后缀自动匹配。"
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 16px;"
        />
        <div class="container-header">
          <div></div>
          <el-button @click="onClickCreate()" type="primary">
            <el-icon><DocumentAdd /></el-icon>
            <span>添加 DNS 配置</span>
          </el-button>
        </div>
        <div class="demo-block">
          <el-table :data="tableData" style="width: 100%">
            <el-table-column prop="dns_provider" label="DNS 服务商">
              <template #default="scope">
                <el-tag v-if="scope.row.dns_provider == 'Aliyun'" size="small" type="primary">阿里云 DNS</el-tag>
                <el-tag v-else-if="scope.row.dns_provider == 'Tencent'" size="small" type="success">腾讯云 DNSPod</el-tag>
                <el-tag v-else-if="scope.row.dns_provider == 'Cloudflare'" size="small" type="warning">Cloudflare</el-tag>
                <el-tag v-else size="small">{{ scope.row.dns_provider }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="dns_domain" label="DNS 域名"></el-table-column>
            <el-table-column label="自动接入" align="center" width="90">
              <template #default="scope">
                <el-tag v-if="scope.row.auto_access == 'true'" size="small" type="success">已启用</el-tag>
                <el-tag v-else size="small" type="info">未启用</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="create_time" label="创建时间" width="180"></el-table-column>
            <el-table-column label="操作" align="right" width="240">
              <template #default="scope">
                <el-button
                  size="small"
                  type="text"
                  @click="onClickEdit(scope.row)"
                >编辑</el-button>
                <el-button
                  size="small"
                  type="text"
                  :loading="scope.row.testLoading"
                  @click="onClickTest(scope.row)"
                >测试连接</el-button>
                <el-popover
                  placement="top"
                  :width="160"
                  trigger="click"
                  :visible="scope.row.isVisiblePopover"
                >
                  <p>确定删除吗？</p>
                  <div style="text-align: right; margin: 0">
                    <el-button size="small" type="text" @click="scope.row.isVisiblePopover = false">取消</el-button>
                    <el-button
                      type="primary"
                      size="small"
                      @click="handleDelete(scope.row)"
                      :loading="loading"
                    >确定</el-button>
                  </div>
                  <template #reference>
                    <el-button type="text" size="small" @click="scope.row.isVisiblePopover = true">删除</el-button>
                  </template>
                </el-popover>
              </template>
            </el-table-column>
          </el-table>

          <el-pagination
            background
            layout="prev, pager, next"
            :page-count="tableTotal"
            v-model:current-page="currentPage"
            :page-size="50"
            small
            @current-change="onCurrentChange"
          />
        </div>
      </el-col>

      <el-dialog
        :title="dialogTitle"
        v-model="dialogFormVisible"
        width="580px"
        :close-on-click-modal="false"
        @closed="dialogClose"
        align-center
      >
        <el-form
          class="form-tag-dialog"
          :model="form"
          label-position="right"
          label-width="140px"
          :rules="rules"
          ref="form"
        >
          <el-form-item label="DNS 服务商" prop="dns_provider">
            <el-select v-model="form.dns_provider" placeholder="请选择 DNS 服务商" style="width: 100%">
              <el-option label="阿里云 DNS" value="Aliyun"></el-option>
              <el-option label="腾讯云 DNSPod" value="Tencent"></el-option>
              <el-option label="Cloudflare" value="Cloudflare"></el-option>
            </el-select>
          </el-form-item>
          <el-form-item label="API Key / SecretId" prop="dns_api_key">
            <el-input v-model="form.dns_api_key" placeholder="请输入 API Key 或 SecretId"></el-input>
          </el-form-item>
          <el-form-item label="API Secret / Key" prop="dns_api_secret">
            <el-input
              v-model="form.dns_api_secret"
              placeholder="请输入 API Secret 或 SecretKey"
              type="password"
              show-password
            ></el-input>
          </el-form-item>
          <el-form-item label="DNS 域名" prop="dns_domain">
            <el-input v-model="form.dns_domain" placeholder="请输入托管的根域名，如 example.com"></el-input>
          </el-form-item>
          <el-form-item label="自动接入">
            <el-switch
              v-model="form.auto_access"
              active-value="true"
              inactive-value="false"
            />
          </el-form-item>
          <el-form-item v-if="isEdit">
            <el-button
              type="success"
              :loading="testLoading"
              @click="onClickTestInDialog"
            >测试连接</el-button>
          </el-form-item>
        </el-form>
        <template #footer>
          <span class="dialog-footer">
            <el-button @click="dialogFormVisible = false">取消</el-button>
            <el-button type="primary" @click="onSubmitForm" :loading="submitLoading">确定</el-button>
          </span>
        </template>
      </el-dialog>
    </el-row>
  </div>
</template>

<script>
import { mixin, JXAjax } from '../assets/scripts/common'
import { ElMessage } from 'element-plus'

export default {
  mixins: [mixin],
  data() {
    return {
      loadingPage: false,
      tableData: [],
      currentPage: 1,
      tableTotal: 0,
      dialogFormVisible: false,
      dialogTitle: '',
      isEdit: false,
      editId: null,
      testLoading: false,
      submitLoading: false,
      loading: false,
      form: {
        dns_provider: '',
        dns_api_key: '',
        dns_api_secret: '',
        dns_domain: '',
        auto_access: 'false'
      },
      rules: {
        dns_provider: [
          { required: true, message: '请选择 DNS 服务商', trigger: 'change' }
        ],
        dns_api_key: [
          { required: true, message: '请输入 API Key / SecretId', trigger: 'blur' }
        ],
        dns_api_secret: [
          { required: true, message: '请输入 API Secret / SecretKey', trigger: 'blur' }
        ],
        dns_domain: [
          { required: true, message: '请输入 DNS 域名', trigger: 'blur' },
          { pattern: /^(?!\d+\.\d+\.\d+\.\d+$).+$/, message: 'DNS 域名不能是 IP 地址', trigger: 'blur' }
        ]
      }
    }
  },
  mounted() {
    this.onCurrentChange(1)
  },
  methods: {
    onCurrentChange(currentPage) {
      var t = this
      t.loadingPage = true
      JXAjax(
        'post',
        '/user/get_dns_config_list',
        { page: currentPage },
        function (response) {
          t.loadingPage = false
          t.tableData = response.data.records
          t.currentPage = response.data.page
          t.tableTotal = response.data.total_pages
          for (var i = 0; i < t.tableData.length; i++) {
            t.tableData[i].isVisiblePopover = false
            t.tableData[i].testLoading = false
          }
        },
        function () {
          t.loadingPage = false
        }
      )
    },
    onClickCreate() {
      this.isEdit = false
      this.editId = null
      this.dialogTitle = '添加 DNS 配置'
      this.form = {
        dns_provider: '',
        dns_api_key: '',
        dns_api_secret: '',
        dns_domain: '',
        auto_access: 'false'
      }
      this.dialogFormVisible = true
    },
    onClickEdit(row) {
      var t = this
      this.isEdit = true
      this.editId = row.id
      this.dialogTitle = '编辑 DNS 配置'
      // 列表接口不返回密钥，先用列表字段填充，再异步拉取详情补全 key/secret
      this.form = {
        dns_provider: row.dns_provider,
        dns_api_key: '',
        dns_api_secret: '',
        dns_domain: row.dns_domain,
        auto_access: row.auto_access
      }
      this.dialogFormVisible = true
      JXAjax(
        'post',
        '/user/get_dns_config',
        { id: row.id },
        function (response) {
          var detail = response.data.message
          if (detail) {
            t.form.dns_provider = detail.dns_provider
            t.form.dns_api_key = detail.dns_api_key || ''
            t.form.dns_api_secret = detail.dns_api_secret || ''
            t.form.dns_domain = detail.dns_domain
            t.form.auto_access = detail.auto_access
          }
        },
        function () {
          t.dialogFormVisible = false
        },
        'no-message'
      )
    },
    dialogClose() {
      if (this.$refs.form) {
        this.$refs.form.resetFields()
      }
    },
    onSubmitForm() {
      var t = this
      this.$refs.form.validate((valid) => {
        if (valid) {
          t.submitLoading = true
          var url = t.isEdit ? '/user/edit_dns_config' : '/user/create_dns_config'
          var params = {
            dns_provider: t.form.dns_provider,
            dns_api_key: t.form.dns_api_key,
            dns_api_secret: t.form.dns_api_secret,
            dns_domain: t.form.dns_domain,
            auto_access: t.form.auto_access
          }
          if (t.isEdit) {
            params.id = t.editId
          }
          JXAjax(
            'post',
            url,
            params,
            function (response) {
              t.submitLoading = false
              t.dialogFormVisible = false
              ElMessage.success(response.data.message)
              t.onCurrentChange(t.currentPage)
            },
            function () {
              t.submitLoading = false
            }
          )
        }
      })
    },
    handleDelete(row) {
      var t = this
      t.loading = true
      JXAjax(
        'post',
        '/user/delete_dns_config',
        { id: row.id },
        function (response) {
          t.loading = false
          row.isVisiblePopover = false
          ElMessage.success(response.data.message)
          t.onCurrentChange(t.currentPage)
        },
        function () {
          t.loading = false
          row.isVisiblePopover = false
        }
      )
    },
    onClickTest(row) {
      var t = this
      row.testLoading = true
      JXAjax(
        'post',
        '/user/test_dns_config_connectivity',
        { id: row.id },
        function (response) {
          row.testLoading = false
          ElMessage.success(response.data.message)
        },
        function () {
          row.testLoading = false
        }
      )
    },
    onClickTestInDialog() {
      var t = this
      t.testLoading = true
      JXAjax(
        'post',
        '/user/test_dns_config_connectivity',
        { id: t.editId },
        function (response) {
          t.testLoading = false
          ElMessage.success(response.data.message)
        },
        function () {
          t.testLoading = false
        }
      )
    }
  }
}
</script>

<style scoped>
</style>