<template>
  <div>
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>网站接入</el-breadcrumb-item>
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
          <el-button  @click="onClickCreateDomain()" type="primary">
            <el-icon><DocumentAdd /></el-icon>
            <span>新增网站</span>
          </el-button>
        </div>
        <div class="demo-block">
          <el-table :data="tableData" style="width: 100%">
            <el-table-column prop="domain" label="网站地址"></el-table-column>
            <el-table-column prop="detail" label="描述"></el-table-column>
            <el-table-column label="网站配置">
              <template #default="scope">
                <div class="domain-config">
                  <div class="domain-config-row">
                    <span class="domain-config-label">协议类型</span>
                    <el-tag v-if="scope.row.http == 'true'" size="small">HTTP</el-tag>
                    <el-tag v-if="scope.row.https == 'true'" size="small">HTTPS</el-tag>
                  </div>
                  <div class="domain-config-row">
                    <span class="domain-config-label">回源地址</span>
                    <span class="domain-config-tags">
                      <el-tag v-for="(item, index) in JSON.parse(scope.row.source_ip)" :key="index" size="small">{{ item }}</el-tag>
                    </span>
                  </div>
                  <div class="domain-config-row">
                    <span class="domain-config-label">回源协议</span>
                    <el-tag size="small" v-if="scope.row.origin_protocol == 'http'">HTTP</el-tag>
                    <el-tag size="small" v-if="scope.row.origin_protocol == 'https'">HTTPS</el-tag>
                    <el-tag size="small" v-if="scope.row.origin_protocol == 'follow'">协议跟随</el-tag>
                  </div>
                  <div class="domain-config-row">
                    <span class="domain-config-label">回源端口</span>
                    <el-tag size="small">HTTP {{ scope.row.source_http_port }}</el-tag>
                    <el-tag size="small">HTTPS {{ scope.row.source_https_port }}</el-tag>
                  </div>
                  <div class="domain-config-row">
                    <span class="domain-config-label">负载均衡</span>
                    <el-tag size="small" v-if="scope.row.balance_type == 'round_robin'">轮询</el-tag>
                    <el-tag size="small" v-if="scope.row.balance_type == 'ip_hash'">IP_HASH</el-tag>
                  </div>
                </div>
              </template>
            </el-table-column>
            <el-table-column label="CNAME接入">
              <template #default="scope">
                {{ scope.row.cname }}
                <el-button type="text" @click="copyCname(scope.row.cname)">
                  <el-icon><CopyDocument /></el-icon>
                </el-button>
              </template>
            </el-table-column>
            <el-table-column label="接入状态" align="center" width="90">
              <template #default="scope">
                <el-tag v-if="scope.row.cname_status == 'true'" size="small" type="success">已接入</el-tag>
                <el-tag v-else size="small" type="danger">未接入</el-tag>
              </template>
            </el-table-column>

            <el-table-column label="操作" align="right">
              <template #default="scope">
                <el-button
                  v-if="scope.row.cname_status == 'false'"
                  size="small"
                  type="text"
                  :loading="scope.row.autoAccessLoading"
                  @click="onClickAutoAccess(scope.row)"
                  >一键接入</el-button
                >
                <el-button
                  size="small"
                  @click="handleEdit(scope.row)"
                  class="button-block"
                  type="text"
                  :loading="scope.row.loading"
                  >网站配置</el-button
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
        :title="domainTitle"
        v-model="dialogDomainFormVisible"
        width="620px"
        :close-on-click-modal="false"
        @closed="dialogClose"
        align-center
      >
        <el-form
          class="form-tag-dialog"
          :model="domainForm"
          label-position="right"
          label-width="170px"
          :rules="rules"
          ref="domainForm"
        >
          <el-form-item label="域名/IP" prop="domain" key="1">
            <el-input
              v-model="domainForm.domain"
              v-if="domainType == 'new'"
              placeholder="请输入IP或域名，域名支持通配符，例如*.jxwaf.com"
            >
            </el-input>
            <el-input
              v-model="domainForm.domain"
              v-if="domainType == 'edit'"
              disabled="disabled"
            ></el-input>
          </el-form-item>
          <el-form-item label="描述" key="4">
            <el-input v-model="domainForm.detail"> </el-input>
          </el-form-item>
          <el-form-item label="协议类型" prop="checkListProtocol" key="2">
            <el-checkbox-group v-model="domainForm.checkListProtocol">
              <el-checkbox label="HTTP" key="HTTP"></el-checkbox>
              <el-checkbox label="HTTPS" key="HTTPS"></el-checkbox>
            </el-checkbox-group>
          </el-form-item>

          <div v-if="domainForm.checkListProtocol.indexOf('HTTPS') > -1">
            <el-form-item label="SSL证书" key="3" class="is-required">
              <el-select
                v-model="domainForm.ssl_domain"
                placeholder="请选择或输入模糊搜索"
                filterable
              >
                <el-option
                  v-for="item in sslOptions"
                  :key="item.ssl_domain"
                  :label="item.ssl_domain"
                  :value="item.ssl_domain"
                >
                </el-option>
              </el-select>
            </el-form-item>
          </div>
          <el-form-item key="6" label="回源地址" class="is-required">
            <el-tag
              :key="index"
              v-for="(tag, index) in sourceIpList"
              closable
              :disable-transitions="false"
              @close="handleCloseSourceIpList(tag)"
              >{{ tag }}</el-tag
            >
            <el-input
              class="input-new-tag node-ip-list"
              v-if="sourceIpListVisible"
              v-model="sourceIpListValue"
              ref="saveTagSourceIpList"
              @keyup.enter="handleSourceIpListConfirm"
              @blur="handleSourceIpListConfirm"
            ></el-input>
            <el-button v-else class="button-new-tag" @click="showSourceIpList">
              <el-icon><Plus /></el-icon>
            </el-button>
            <p class="form-info-color">（支持IP和域名，域名需要省略https:// 或 http://）</p>
          </el-form-item>

          <el-form-item label="HTTP回源端口" prop="source_http_port" key="7">
            <el-input placeholder="仅支持http" v-model="domainForm.source_http_port"></el-input>
          </el-form-item>
          <el-form-item label="HTTPS回源端口" prop="source_https_port" key="9">
            <el-input placeholder="仅支持https" v-model="domainForm.source_https_port"></el-input>
          </el-form-item>
          <el-form-item label="回源协议" prop="origin_protocol" key="8">
            <el-radio v-model="domainForm.origin_protocol" label="http">http</el-radio>
            <el-radio v-model="domainForm.origin_protocol" label="https">https</el-radio>
            <el-radio v-model="domainForm.origin_protocol" label="follow">协议跟随</el-radio>
          </el-form-item>
          <el-form-item label="负载均衡" prop="balance_type" key="14">
            <el-radio v-model="domainForm.balance_type" label="round_robin">轮询</el-radio>
            <el-radio v-model="domainForm.balance_type" label="ip_hash">IP_HASH</el-radio>
            
          </el-form-item>
          <el-form-item label="WAF前存在代理" key="11" class="is-required" >
            <el-radio v-model="domainForm.pre_proxy" label="true">是</el-radio>
            <el-radio v-model="domainForm.pre_proxy" label="false">否</el-radio>
          </el-form-item>
         
          <el-form-item label="HTTP请求头获取真实IP" key="15" class="is-required"  v-if="domainForm.pre_proxy == 'true'">
            <el-radio v-model="domainForm.real_ip_conf" label="XRI">X-Real-IP</el-radio>
            <el-radio v-model="domainForm.real_ip_conf" label="XFF">X-Forwarded-For</el-radio>
          </el-form-item>
          <el-form-item label="新建连接超时时间" prop="connect_timeout" key="10">
            <el-input placeholder="" v-model="domainForm.connect_timeout"></el-input>
          </el-form-item>
          <el-form-item label="读连接超时时间" prop="read_timeout" key="12">
            <el-input placeholder="" v-model="domainForm.read_timeout"></el-input>
          </el-form-item>
          <el-form-item label="写连接超时时间" prop="send_timeout" key="13">
            <el-input placeholder="" v-model="domainForm.send_timeout"></el-input>
          </el-form-item>
        </el-form>
        <template #footer class="dialog-footer">
          <el-button @click="dialogDomainFormVisible = false"><span>取消</span></el-button>
          <el-button type="primary" @click="onClickDomainSubmit('domainForm')" :loading="loading"
            >确定</el-button>
        </template>
      </el-dialog>
    </el-row>
  </div>
</template>
<script>
import { validatePort, validateDomainPort, mixin, JXAjax } from '../assets/scripts/common'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
export default {
  mixins: [mixin],
  data() {
    return {
      domainTitle: '新增网站',
      domainType: 'new',
      dataSearch: '',
      flag: 'false',
      loadingPage: false,
      dialogDomainFormVisible: false,
      loading: false,
      domainForm: {
        source_http_port: '80',
        source_https_port: '443',
        origin_protocol: 'http',
        pre_proxy: 'false',
        balance_type: 'round_robin',
        connect_timeout: '5',
        send_timeout: '60',
        read_timeout: '60',
        checkListProtocol: ['HTTP'],
        detail: '',
        real_ip_conf: 'XRI',
        ssl_domain: ''
      },

      tableData: [],
      sourceIpList: [],
      sourceIpListVisible: false,
      sourceIpListValue: '',
      flagTag: true,
      sslOptions: [],
      currentPage: 1,
      tableTotal: 0,
      path: ''
    }
  },
  computed: {
    rules() {
      return {
        domain: [
          {
            required: true,
            message: '请输入网站地址',
            trigger: ['blur', 'change']
          },
          {
            validator: validateDomainPort,
            trigger: ['blur', 'change']
          }
        ],
        source_http_port: [
          {
            required: true,
            message: '请输入源站端口信息',
            trigger: ['blur', 'change']
          },
          {
            validator: validatePort,
            trigger: ['blur', 'change']
          }
        ],
        source_https_port: [
          {
            required: true,
            message: '请输入源站端口信息',
            trigger: ['blur', 'change']
          },
          {
            validator: validatePort,
            trigger: ['blur', 'change']
          }
        ],
        checkListProtocol: [
          {
            type: 'array',
            required: true,
            message: '请至少选择一项协议类型',
            trigger: 'change'
          }
        ],
        origin_protocol: [{ required: true, message: '请选择回源协议', trigger: 'change' }],
        balance_type: [{ required: true, message: '请选择', trigger: 'change' }],
        connect_timeout: [{ required: true, message: '请输入新建连接超时时间（秒）', trigger: ['blur', 'change']}],
        read_timeout: [{ required: true, message: '请输入读连接超时时间（秒）', trigger: ['blur', 'change']}],
        send_timeout: [{ required: true, message: '请输入写连接超时时间（秒）', trigger: ['blur', 'change']}],
      }
    }
  },

  mounted() {
    const route = useRoute()
    this.onCurrentChange(this.currentPage)
  },
  methods: {
    copyCname(text) {
      try {
        // 使用现代 Clipboard API（推荐）
        navigator.clipboard.writeText(text);
        ElMessage.success('复制成功');
      } catch (err) {
        // 降级方案：使用 input 复制
        this.fallbackCopy(text);
      }
    },
    fallbackCopy(text) {
      const input = document.createElement('input');
      input.value = text;
      document.body.appendChild(input);
      input.select();
      document.execCommand('copy');
      document.body.removeChild(input);
      ElMessage.success('复制成功');
    },
    handleCloseSourceIpList(tag) {
      this.sourceIpList.splice(this.sourceIpList.indexOf(tag), 1)
    },
    showSourceIpList() {
      this.sourceIpListVisible = true
      this.$nextTick((_) => {
        this.$refs.saveTagSourceIpList.$refs.input.focus()
      })
    },
    handleSourceIpListConfirm() {
      let t = this
      let sourceIpListValue = this.sourceIpListValue
      let pattern = /^(((https|http)?:\/)?\/)/
      if (t.flagTag) {
        t.flagTag = false
        if (sourceIpListValue) {
          if (pattern.test(sourceIpListValue)) {
            t.$message({
              showClose: true,
              message: '请输入正确的域名格式',
              type: 'error'
            })
          } else {
            t.sourceIpList.push(sourceIpListValue)
            t.sourceIpListVisible = false
            t.sourceIpListValue = ''
          }
        } else {
          t.sourceIpListVisible = false
          t.sourceIpListValue = ''
        }
        setTimeout(function () {
          t.flagTag = true
        }, 50)
      }
    },

    getData(page) {
      var t = this
      var _url = '/user/get_domain_list'
      var _data = { page: page }
      JXAjax(
        'post',
        _url,
        _data,
        function (response) {
          t.tableData = response.data.records
          t.tableData.forEach((item) => {
            item.isVisiblePopover = false
            item.autoAccessLoading = false
          })

          if (response.data.total_pages == 0) {
            t.tableTotal = 1
          } else {
            t.tableTotal = response.data.total_pages
          }
          t.currentPage = response.data.page
        },
        function () {
          //t.loadingPage = false;
        },
        'no-message'
      )
    },

    dialogClose() {
      this.domainForm = {
        source_http_port: '80',
        source_https_port: '443',
        origin_protocol: 'http',
        pre_proxy: 'false',
        balance_type: 'round_robin',
        connect_timeout: '5',
        send_timeout: '60',
        read_timeout: '60',
        checkListProtocol: ['HTTP'],
        detail: '',
        real_ip_conf: 'XRI',
        ssl_domain: ''
      }
      this.sourceIpListVisible = false
      this.sourceIpListValue = ''
      this.sourceIpList = []
      this.$refs['domainForm'].resetFields()
    },

    onClickDomainSubmit(domainForm) {
      var t = this
      var arrProtocol = t.domainForm.checkListProtocol
      var postUrl = '/user/create_domain'
      if (t.domainType == 'edit') {
        postUrl = '/user/edit_domain'
      }
      if (t.sourceIpList.length == 0) {
        t.$message({
          message: '源站地址不能为空',
          type: 'error'
        })
        return false
      }

      if (t.domainForm.checkListProtocol.indexOf('HTTPS') > -1) {
        if (t.domainForm.ssl_domain == undefined || t.domainForm.ssl_domain == '') {
          t.$message({
            message: '请选择SSL证书',
            type: 'error'
          })
          return false
        }
      }

      t.domainForm.source_ip = JSON.stringify(t.sourceIpList)
      t.domainForm.http = arrProtocol.indexOf('HTTP') > -1 ? 'true' : 'false'
      t.domainForm.https = arrProtocol.indexOf('HTTPS') > -1 ? 'true' : 'false'
      t.domainForm.origin_protocol = t.domainForm.origin_protocol
      this.$refs[domainForm].validate((valid) => {
        if (valid) {
          t.loading = true
          JXAjax(
            'post',
            postUrl,
            t.domainForm,
            function (response) {
              t.loading = false
              t.dialogDomainFormVisible = false
              t.sourceIpListVisible = false
              t.sourceIpListValue = ''
              t.sourceIpList = []
              t.onCurrentChange(t.currentPage)
            },
            function () {
              t.loading = false
            }
          )
        }
      })
    },

    onClickCreateDomain() {
      var t = this
      t.domainTitle = '新增网站'
      t.domainType = 'new'
      t.dialogDomainFormVisible = true
      t.getSSL()
    },

    handleEdit(data) {
      var t = this
      data.loading = true
      t.getSSL()
      JXAjax(
        'post',
        '/user/get_domain',
        { domain: data.domain },
        function (response) {
          data.loading = false
          var oGetData = response.data.message
          t.domainForm.domain = oGetData.domain
          t.domainForm.ssl_domain = oGetData.ssl_domain
          t.domainForm.origin_protocol = oGetData.origin_protocol
          t.domainForm.source_http_port = oGetData.source_http_port
          t.domainForm.source_https_port = oGetData.source_https_port
          t.domainForm.pre_proxy = oGetData.pre_proxy
          t.domainForm.balance_type = oGetData.balance_type
          t.domainForm.detail = oGetData.detail
          t.domainForm.connect_timeout = oGetData.connect_timeout || '60'
          t.domainForm.send_timeout = oGetData.send_timeout || '60'
          t.domainForm.read_timeout = oGetData.read_timeout || '60'
          t.domainForm.real_ip_conf = oGetData.real_ip_conf || 'XRI'

          var _sourceIp = JSON.parse(oGetData.source_ip)
          if (_sourceIp.length > 0) {
            t.sourceIpList = _sourceIp
          } else {
            t.sourceIpList = []
          }

          t.domainForm.isVisiblePopover = false

          if (oGetData.http == 'true') {
            t.domainForm.checkListProtocol.push('HTTP')
          }
          if (oGetData.https == 'true') {
            t.domainForm.checkListProtocol.push('HTTPS')
          }
          t.domainTitle = '编辑网站'
          t.domainType = 'edit'
          t.dialogDomainFormVisible = true
        },
        function () {
          data.loading = false
        },
        'no-message'
      )
    },
    handleDelete(data) {
      var t = this
      t.loading = true
      JXAjax(
        'post',
        '/user/delete_domain',
        { domain: data.domain },
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

    onClickAutoAccess(row) {
      var t = this
      row.autoAccessLoading = true
      JXAjax(
        'post',
        '/user/auto_access_domain',
        { domain: row.domain },
        function (response) {
          row.autoAccessLoading = false
          ElMessage.success('接入成功，CNAME 记录已自动添加到您的 DNS 服务商')
          t.onCurrentChange(t.currentPage)
        },
        function () {
          row.autoAccessLoading = false
        }
      )
    },

    getSSL() {
      var t = this
      JXAjax(
        'post',
        '/user/get_ssl_manage_list',
        { page: 1 },
        function (response) {
          t.sslOptions = response.data.records
        },
        function () {},
        'no-message'
      )
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
          '/user/get_domain_search_list',
          { page: t.currentPage, search_domain: t.dataSearch },
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
              item.autoAccessLoading = false
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
    }
  }
}
</script>
<style scoped>
.domain-setting {
  float: right;
}
.cname-text-row {
  display: flex;
  align-items: center;
  gap: 4px;
}
.cname-text {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 13px;
  color: #606266;
}
.cname-copy-btn {
  padding: 0;
  flex-shrink: 0;
}
.domain-redirect {
  margin-top: 5px;
  margin-bottom: 0px !important;
}

.el-form-item.is-required :deep(.redirect-box) :deep(.el-form-item__label):before {
  content: '';
}

.no-padding {
  padding: 0;
}
.node-detail span {
  font-size: 12px;
}
.domain-tabs {
  margin-bottom: 18px;
}
.el-tabs-myitem {
  color: #409eff;
  height: 40px;
  -webkit-box-sizing: border-box;
  box-sizing: border-box;
  line-height: 40px;
  display: inline-block;
  list-style: none;
  font-size: 14px;
  font-weight: 500;
  position: relative;
}
:deep(.el-table__body) p {
  font-size: 14px;
  line-height: 30px;
}
:deep(.el-table__body) .el-tag {
  margin-right: 5px;
}
.domain-config :deep(.el-tag) {
  margin-right: 0;
}
.col-item-box {
  display: flex;
}
.col-item-content {
  flex: 1;
}
.col-item-protection-title {
  display: inline-block;
  width: 120px;
}
.domain-config {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.domain-config-row {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
  font-size: 12px;
}
.domain-config-label {
  color: #909399;
  flex-shrink: 0;
}
.domain-config-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}
.domain-config-sep {
  color: #dcdfe6;
  margin: 0 2px;
}
</style>
