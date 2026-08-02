<template>
  <div>
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>证书管理</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>
    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <div class="container-header">
          <div class="data-search-input">
            <el-input
              placeholder="请输入关键词进行搜索"
              prefix-icon="Search"
              v-model="dataSearch"
              @input="onChangeSearch"
            >
            </el-input>
          </div>
          <div>
            <el-button type="primary" @click="onClickFreeSSL()">申请通配符证书</el-button>
            <el-button type="primary" @click="onClickCreateSSL()">上传SSL证书</el-button>
          </div>
        </div>
        <div class="demo-block">
          <el-table :data="tableData" style="width: 100%">
            <el-table-column prop="ssl_domain" label="SSL证书域名"></el-table-column>
            <el-table-column prop="detail" label="描述"></el-table-column>
            <el-table-column label="证书来源">
              <template #default="scope">
                <span v-if="scope.row.source == 'system'">系统自动申请</span>
                <span v-if="scope.row.source == 'custom'">用户上传</span>
              </template>
            </el-table-column>
            <el-table-column label="证书状态">
              <template #default="scope">
                <el-tag v-if="scope.row.cert_status == 'success'" size="small" type="success">已签发</el-tag>
                <el-tag v-else-if="scope.row.cert_status == 'pending'" size="small" type="primary">申请中</el-tag>
                <el-tooltip v-else-if="scope.row.cert_status == 'failed'" :content="scope.row.cert_error || '申请失败'" placement="top">
                  <el-tag size="small" type="danger">申请失败</el-tag>
                </el-tooltip>
                <el-tag v-else-if="scope.row.source == 'custom'" size="small" type="success">已上传</el-tag>
                <el-tag v-else size="small" type="info">未申请</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="自动更新">
              <template #default="scope">
                <el-tag v-if="scope.row.source == 'custom'" size="small" type="info">不支持</el-tag>
                <el-tag v-else-if="scope.row.auto_update == 'true'" size="small" type="success">开启</el-tag>
                <el-tag v-else size="small" type="info">关闭</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="更新时间" prop="update_time"> </el-table-column>
            <el-table-column label="操作" align="right">
              <template #default="scope">
                <el-button
                  size="small"
                  @click="handleEdit(scope.row)"
                  class="button-block"
                  type="text"
                  >配置</el-button
                >
                <el-button
                  v-if="scope.row.source == 'system' && scope.row.cert_status == 'failed'"
                  size="small"
                  @click="onClickRetryCert(scope.row)"
                  class="button-block"
                  type="text"
                  >重新申请</el-button
                >
                <el-popover
                  placement="top"
                  :width="160"
                  trigger="click"
                  :visible="scope.row.isVisiblePopover"
                >
                  <p>确定删除吗？</p>
                  <div style="text-align: right; margin: 0">
                    <el-button size="small" type="text" @click="scope.row.isVisiblePopover = false"
                      >取消</el-button
                    >
                    <el-button
                      type="primary"
                      size="small"
                      @click="handleDelete(scope.row)"
                      :loading="loading"
                      >确定
                    </el-button>
                  </div>
                  <template #reference>
                    <el-button type="text" size="small" @click="scope.row.isVisiblePopover = true"
                      >删除</el-button
                    >
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
            :page-size="50"
            @current-change="onCurrentChange"
          />
        </div>
      </el-col>
    </el-row>
    <el-dialog
      :title="sslTitle"
      v-model="dialogSslFormVisible"
      width="580px"
      :close-on-click-modal="false"
      @close="dialogClose"
    >
      <el-form
        class="form-tag-dialog"
        :model="sslForm"
        label-width="120px"
        :rules="rules"
        ref="sslForm"
      >
        <el-form-item label="SSL证书域名" prop="ssl_domain" key="1">
          <el-input
            v-model="sslForm.ssl_domain"
            v-if="sslType == 'new'"
            placeholder="支持通配符，且为小写，例如 www.jxwaf.com"
          >
          </el-input>
          <el-input
            v-model="sslForm.ssl_domain"
            v-if="sslType == 'edit'"
            disabled="disabled"
          ></el-input>
        </el-form-item>
        <el-form-item label="描述" key="2">
          <el-input v-model="sslForm.detail" placeholder="SSL证书详情描述"></el-input>
        </el-form-item>
        <el-form-item label="公钥" prop="public_key" key="3">
          <el-input
            v-model="sslForm.public_key"
            placeholder="需包含证书链"
            type="textarea"
            :rows="4"
          ></el-input>
          <el-upload
            ref="uploadCrt"
            action=""
            class="upload-ssl"
            :limit="1"
            :auto-upload="false"
            :on-exceed="handleExceedCrt"
            :on-change="changeCrt"
          >
            <template #trigger>
              <el-button type="primary" plain size="small">点击上传公钥文件</el-button>
            </template>
            <el-button class="ml-3" type="success" style="display: none"></el-button>
          </el-upload>
        </el-form-item>
        <el-form-item label="私钥" prop="private_key" key="4">
          <el-input v-model="sslForm.private_key" type="textarea" :rows="4"></el-input>
          <el-upload
            ref="uploadKey"
            action=""
            class="upload-ssl"
            :limit="1"
            :auto-upload="false"
            :on-exceed="handleExceedKey"
            :on-change="changeKey"
          >
            <template #trigger>
              <el-button type="primary" plain size="small">点击上传私钥文件</el-button>
            </template>
            <el-button class="ml-3" type="success" style="display: none"></el-button>
          </el-upload>
        </el-form-item>
      </el-form>
      <template #footer class="dialog-footer">
        <el-button @click="dialogSslFormVisible = false">取消</el-button>
        <el-button type="primary" @click="onClicksslSubmit('sslForm')" :loading="loading"
          >确定</el-button
        >
      </template>
    </el-dialog>
    <el-dialog
      :title="sslFreeTitle"
      v-model="dialogSslFreeVisible"
      width="580px"
      :close-on-click-modal="false"
      @closed="dialogCloseFree"
      :loading="loading"
      class="dialog-ssl-manage"
    >
      <el-form
        class="form-tag-dialog"
        :model="sslFreeForm"
        label-width="160px"
        :rules="rules"
        ref="sslFreeForm"
      >
        <el-form-item label="DNS服务提供商" key="3" class="is-required">
          <el-radio-group v-model="sslFreeForm.dns_type" @change="onChangeDnsType">
            <el-radio label="aliyun">阿里云</el-radio>
            <el-radio label="tencent">腾讯云</el-radio>
            <el-radio label="cloudflare">Cloudflare</el-radio>
          </el-radio-group>
          <div class="dns-type-tip">
            <span v-if="sslFreeForm.dns_type == 'aliyun'">阿里云DNS：需要 AccessKey ID 和 AccessKey Secret，可在阿里云控制台 RAM 访问控制中创建</span>
            <span v-if="sslFreeForm.dns_type == 'tencent'">腾讯云DNSPod：需要 SecretId 和 SecretKey，可在腾讯云控制台 API 密钥管理中创建</span>
            <span v-if="sslFreeForm.dns_type == 'cloudflare'">Cloudflare：仅需 API Token，可在 Cloudflare 控制台 My Profile - API Tokens 中创建（需 Zone.DNS 编辑权限）</span>
          </div>
        </el-form-item>
        <el-form-item
          label="API Token"
          key="4"
          prop="dns_api_key"
          v-if="sslFreeForm.dns_type == 'cloudflare'"
        >
          <el-input placeholder="请输入 API Token" v-model="sslFreeForm.dns_api_key" show-password></el-input>
        </el-form-item>
        <el-form-item
          label="AccessKey ID"
          key="5"
          prop="dns_api_key"
          v-if="sslFreeForm.dns_type == 'aliyun'"
        >
          <el-input placeholder="请输入 AccessKey ID" v-model="sslFreeForm.dns_api_key" show-password></el-input>
        </el-form-item>
        <el-form-item
          label="AccessKey Secret"
          key="6"
          prop="dns_api_secret"
          v-if="sslFreeForm.dns_type == 'aliyun'"
        >
          <el-input placeholder="请输入 AccessKey Secret" v-model="sslFreeForm.dns_api_secret" show-password></el-input>
        </el-form-item>
        <el-form-item
          label="SecretId"
          key="10"
          prop="dns_api_key"
          v-if="sslFreeForm.dns_type == 'tencent'"
        >
          <el-input placeholder="请输入 SecretId" v-model="sslFreeForm.dns_api_key" show-password></el-input>
        </el-form-item>
        <el-form-item
          label="SecretKey"
          key="11"
          prop="dns_api_secret"
          v-if="sslFreeForm.dns_type == 'tencent'"
        >
          <el-input placeholder="请输入 SecretKey" v-model="sslFreeForm.dns_api_secret" show-password></el-input>
        </el-form-item>
        <el-form-item label="证书申请域名" prop="ssl_domain" key="12">
          <el-input v-model="sslFreeForm.ssl_domain" placeholder="请输入域名">
            <template #prepend>*.</template>
          </el-input>
        </el-form-item>
        <el-form-item label="证书自动更新" key="13">
          <el-switch v-model="sslFreeForm.auto_update" active-value="true" inactive-value="false" />
        </el-form-item>
        <template v-if="sslFreeType == 'edit' && sslFreeForm.cert_status == 'success'">
          <el-form-item label="公钥" key="14">
            <el-input
              v-model="sslFreeForm.public_key"
              type="textarea"
              :rows="6"
              readonly
            ></el-input>
          </el-form-item>
          <el-form-item label="私钥" key="15">
            <el-input
              v-model="sslFreeForm.private_key"
              type="textarea"
              :rows="6"
              readonly
            ></el-input>
          </el-form-item>
        </template>
        <p class="form-info-color"><el-icon><Warning /></el-icon>提示：申请大概需要1分钟时间，请稍后查看</p>
      </el-form>
      <template #footer class="dialog-footer">
        <el-button @click="dialogSslFreeVisible = false">取消</el-button>
        <el-button type="primary" @click="onClickSslFreeSubmit('sslFreeForm')" :loading="loading"
          >确定</el-button
        >
      </template>
    </el-dialog>
  </div>
</template>
<script>
import { mixin, JXAjax, formatterTime } from '../assets/scripts/common'
import { useRoute } from 'vue-router'

export default {
  mixins: [mixin],
  data() {
    return {
      sslTitle: '添加证书',
      sslType: 'new',
      sslFreeTitle: '申请通配符证书',
      sslFreeType: 'new',
      dataSearch: '',
      loadingPage: false,
      dialogSslFormVisible: false,
      loading: false,
      sslForm: {
        detail: '',
        ssl_domain: '',
        private_key: '',
        public_key: ''
      },
      currentPage: 1,
      tableTotal: 1,
      tableData: [],
      dialogSslFreeVisible: false,
      sslFreeForm: {
        ssl_domain: '',
        dns_type: 'aliyun',
        dns_api_key: '',
        dns_api_secret: '',
        auto_update: 'true'
      }
    }
  },
  computed: {
    rules() {
      return {
        ssl_domain: [
          {
            required: true,
            message: '请输入通配符域名，例如*.jxwaf.com',
            trigger: ['blur', 'change']
          }
        ],
        dns_api_key: [{ required: true, message: '请输入', trigger: ['blur', 'change'] }],
        dns_api_secret: [{ required: true, message: '请输入', trigger: ['blur', 'change'] }],
        public_key: [{ required: true, message: '请输入公钥', trigger: 'blur' }],
        private_key: [{ required: true, message: '请输入私钥', trigger: 'blur' }],
        domain: [{ required: true, message: '请选择', trigger: 'change' }]
      }
    }
  },

  mounted() {
    this.onCurrentChange(this.currentPage)
  },
  methods: {
    getData(page) {
      var t = this
      JXAjax(
        'post',
        '/user/get_ssl_manage_list',
        { page: page },
        function (response) {
          t.tableData = response.data.records
          t.tableData.forEach((item) => {
            item.isVisiblePopover = false
            item.update_time = formatterTime(item.update_time)
          })
          if (response.data.total_pages == 0) {
            t.tableTotal = 1
          } else {
            t.tableTotal = response.data.total_pages
          }

          t.currentPage = response.data.page
        },
        function () {
        },
        'no-message'
      )
    },

    dialogClose() {
      this.sslForm = {
        detail: '',
        ssl_domain: '',
        public_key: '',
        private_key: ''
      }
      this.$refs['sslForm'].resetFields()
    },
    dialogCloseFree() {
      this.sslFreeForm = {
        ssl_domain: '',
        dns_type: 'aliyun',
        dns_api_key: '',
        dns_api_secret: '',
        auto_update: 'true'
      }
      this.$refs['sslFreeForm'].resetFields()
    },
    onClicksslSubmit(sslForm) {
      var t = this
      var postUrl = '/user/create_ssl_manage'
      if (t.sslType == 'edit') {
        postUrl = '/user/edit_ssl_manage'
      }
      this.$refs[sslForm].validate((valid) => {
        if (valid) {
          t.loading = true
          var postData = JSON.parse(JSON.stringify(t.sslForm))
          JXAjax(
            'post',
            postUrl,
            postData,
            function (response) {
              t.loading = false
              t.dialogSslFormVisible = false
              t.onCurrentChange(t.currentPage)
            },
            function () {
              t.loading = false
            }
          )
        }
      })
    },

    onClickCreateSSL() {
      var t = this
      t.sslTitle = '上传SSL证书'
      t.sslType = 'new'
      t.dialogSslFormVisible = true
    },
    onClickFreeSSL() {
      var t = this
      t.sslFreeTitle = '申请通配符证书'
      t.sslFreeType = 'new'
      this.dialogSslFreeVisible = true
    },
    onChangeDnsType() {
      this.sslFreeForm.dns_api_key = ''
      this.sslFreeForm.dns_api_secret = ''
      this.sslFreeForm.dns_api_secret=''
      this.$refs['sslFreeForm'].resetFields()
    },
    handleEdit(data) {
      var t = this
      t.loadingPage = true
      var postUrl = '/user/get_ssl_manage'
      var oData = { ssl_domain: data.ssl_domain }

      JXAjax(
        'post',
        postUrl,
        oData,
        function (response) {
          t.loadingPage = false

          if (response.data.message.source == 'system') {
            t.dialogSslFreeVisible = true
            t.sslFreeTitle = '编辑证书'
            t.sslFreeType = 'edit'
            var certData = response.data.message
            if (certData.ssl_domain && certData.ssl_domain.indexOf('*.') === 0) {
              certData.ssl_domain = certData.ssl_domain.substring(2)
            }
            t.sslFreeForm = certData
          } else {
            t.sslForm = response.data.message
            t.dialogSslFormVisible = true
            t.sslTitle = '编辑证书'
            t.sslType = 'edit'
          }
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },

    handleDelete(data) {
      var t = this
      t.loading = true
      JXAjax(
        'post',
        '/user/delete_ssl_manage',
        { ssl_domain: data.ssl_domain },
        function (response) {
          data.isVisiblePopover = false
          t.loading = false
          t.onCurrentChange(t.currentPage)
        },
        function () {
          t.loading = false
        }
      )
    },
    onClickRetryCert(data) {
      var t = this
      t.loading = true
      JXAjax(
        'post',
        '/user/retry_ssl_cert',
        { ssl_domain: data.ssl_domain },
        function (response) {
          t.loading = false
          t.onCurrentChange(t.currentPage)
        },
        function () {
          t.loading = false
        }
      )
    },
    handleExceedCrt(files, fileList) {
      let t = this
      let file = files[0]
      t.$refs.uploadCrt.clearFiles()
      setTimeout(function () {
        t.$refs.uploadCrt.handleStart(file)
      }, 1000)
    },
    changeCrt(files, fileList) {
      let file = fileList[0]
      let t = this
      let reader = new FileReader()
      reader.readAsText(file.raw)
      reader.onload = (e) => {
        const fileString = e.target.result
        t.sslForm.public_key = fileString
      }
    },
    handleExceedKey(files, fileList) {
      let t = this
      let file = files[0]
      t.$refs.uploadKey.clearFiles()
      setTimeout(function () {
        t.$refs.uploadKey.handleStart(file)
      }, 1000)
    },
    changeKey(files, fileList) {
      let file = fileList[0]
      let t = this
      let reader = new FileReader()
      reader.readAsText(file.raw)
      reader.onload = (e) => {
        const fileString = e.target.result
        t.sslForm.private_key = fileString
      }
    },
    onCurrentChange() {
      if (this.dataSearch == '') {
        this.getData(this.currentPage)
      } else {
        this.onChangeSearch()
      }
      this.$nextTick(() => {
        window.scroll(0, 0)
      })
    },
    onChangeSearch() {
      var t = this
      if (t.dataSearch) {
        JXAjax(
          'post',
          '/user/get_ssl_manage_search_list',
          { page: t.currentPage, search: t.dataSearch },
          function (response) {
            t.loadingPage = false
            t.tableData = response.data.records
            t.currentPage = response.data.page
            if (response.data.total_pages == 0) {
              t.tableTotal = 1
            } else {
              t.tableTotal = response.data.total_pages
            }
            t.tableData.forEach((item) => {
              item.isVisiblePopover = false
              item.update_time = formatterTime(item.update_time)
            })
          },
          function () {
            t.loadingPage = false
          },
          'no-message'
        )
      } else {
        t.getData(1)
      }
    },
    onClickSslFreeSubmit(sslFreeForm) {
      var t = this
      this.$refs[sslFreeForm].validate((valid) => {
        if (valid) {
          t.loading = true
          var postData = JSON.parse(JSON.stringify(t.sslFreeForm))
          if (postData.dns_type == 'cloudflare') {
            postData.dns_api_secret = ''
          }
          if (t.sslFreeType == 'edit') {
            postData.ssl_domain = '*.' + postData.ssl_domain
            JXAjax(
              'post',
              '/user/edit_ssl_cert_config',
              postData,
              function (response) {
                t.loading = false
                t.dialogSslFreeVisible = false
                t.onCurrentChange(t.currentPage)
              },
              function () {
                t.loading = false
              }
            )
          } else {
            postData.ssl_domain = '*.' + postData.ssl_domain
            JXAjax(
              'post',
              '/user/request_wildcard_cert',
              postData,
              function (response) {
                t.loading = false
                t.dialogSslFreeVisible = false
                t.onCurrentChange(t.currentPage)
              },
              function () {
                t.loading = false
              }
            )
          }
        }
      })
    }
  }
}
</script>
<style>
.el-button.button-block {
  display: block;
  margin-left: 0px;
  text-align: right;
  width: 100%;
}
.icon-success {
  color: #67c23a;
  margin-right: 5px;
}
.icon-error {
  color: #f56c6c;
  margin-right: 5px;
}
.icon-warning {
  color: #e6a23c;
  margin-right: 5px;
}
.ssl-setting {
  float: right;
}
.ssl-redirect {
  margin-top: 5px;
  margin-bottom: 0px !important;
}

.el-form-item.is-required .redirect-box .el-form-item__label:before {
  content: '';
}
.ssl-search-input {
  display: block;
  float: left;
  text-align: left;
}
.ssl-search-input .el-input {
  width: 100%;
}
.no-padding {
  padding: 0;
}
.node-detail span {
  font-size: 12px;
}
.upload-ssl {
  margin-top: 10px;
}
.dialog-ssl-manage .form-info-color{
  width: 100%;
  display: flex;
  align-items: center;
  color: #e6a23c;
  justify-content: center;
}
.dialog-ssl-manage .form-info-color i {
  display: inline-block;
  font-size: 14px;
  margin-right: 5px;
}
.dialog-ssl-manage .dns-type-tip {
  margin-top: 6px;
  font-size: 12px;
  color: #909399;
  line-height: 1.5;
}
.dialog-ssl-manage .dns-type-tip span {
  display: inline-block;
}
</style>
