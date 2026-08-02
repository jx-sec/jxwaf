<template>
  <div class="operation-center-query-search-wrap">
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>日志查询</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>
    <el-row class="container-style">
      <div class="click-search-input-behave-map">
        <div class="query-search-container">
          <div class="match-box" v-for="(item, index) in querySearchList" :key="index">
            <div class="match-box-content">
              <el-select v-model="item.field" placeholder="日志字段">
                <el-option v-for="data in allFields" :key="data" :label="fieldLabelMap[data]" :value="data" />
              </el-select>
              <el-select v-model="item.operation" placeholder="匹配方式">
                <el-option
                  v-for="data in optionsSelect"
                  :key="data.value"
                  :label="data.label"
                  :value="data.value"
                />
              </el-select>
              <el-input placeholder="请输入查询语句" v-model="item.value"></el-input>
            </div>
            <el-button @click.prevent="removeRuleMatchs(item, index)">删除</el-button>
          </div>
          <el-button @click="addRuleMatchs()" plain type="primary">新增</el-button>
        </div>
        <div class="query-time-container">
          <el-select
            v-model="valueTime"
            placeholder="Select"
            v-show="isShowSelectTime"
            @change="onChangeSelectTime"
            style="max-width: 205px"
          >
            <el-option
              v-for="item in optionTime"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
          <div v-show="!isShowSelectTime">
            <el-date-picker
              v-model="pickerTime"
              type="datetimerange"
              range-separator="-"
              start-placeholder="开始时间"
              end-placeholder="结束时间"
              @change="changeTimeline"
            />
          </div>
          <el-button type="primary" icon="Search" @click="onChangeSearch">查询</el-button>
        </div>
      </div>
      <div style="padding-top: 10px; display: flex; width: 100%">
        <div style="min-width: 60px; line-height: 28px; font-size: 12px">显示字段：</div>
        <el-select v-model="columnValue" multiple placeholder="Select" style="width: 100%">
          <el-option v-for="item in optionsColumn" :key="item" :label="fieldLabelMap[item]" :value="item" />
        </el-select>
      </div>
      <el-divider style="margin: 15px 0" />
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <el-row>
          <el-col :span="24" v-if="mapAttackerEntity.length == 0">
            <el-empty description="NO DATA" />
          </el-col>
          <el-col :span="24">
            <el-timeline class="timeline-box">
              <el-timeline-item
                v-for="(item, index) in mapAttackerEntity"
                :key="index"
                :timestamp="item.request_time"
                placement="top"
                size="large"
                color="#409eff"
              >
                <div class="operation-behave-dialog-box">
                  <el-card shadow="hover" style="margin-left: 15px">
                    <div
                      class="operation-behave-item"
                      v-for="(i, index) in columnValue"
                      :key="index"
                    >
                      <span class="operation-behave-label">{{ fieldLabelMap[i] || i }}</span>
                      <div
                        class="operation-behave-content"
                        v-if="optionsPre.indexOf(i) > -1 && item[i] !=''" 
                        style="background-color: #f4f4f5; padding: 15px"
                      >
                        <span>
                          <pre>{{ item[i] }}</pre>
                        </span>
                      </div>
                      <div class="operation-behave-content" v-else>
                        <span>{{ item[i] }}</span>
                      </div>
                    </div>
                  </el-card>
                </div>
              </el-timeline-item>
            </el-timeline>
          </el-col>
        </el-row>
        <el-pagination
          small
          background
          layout="prev, pager, next"
          :page-count="tableTotal"
          :page-size="20"
          @current-change="onCurrentChange"
          v-model:currentPage="now_page"
        />
      </el-col>
    </el-row>
    <el-dialog
      v-model="confCenterDialogVisible"
      title="Warning"
      width="500"
      align-center
      :close-on-click-modal="false"
    >
      <div>
        <el-alert title="日志查询功能未配置，请点击按钮前往配置" type="warning" show-icon :closable="false" style="background-color: #fff;"/>
      </div>
      <template #footer>
        <div class="dialog-footer">
          <el-button type="primary" @click="onClickConfBtn()">
            点击前往配置
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>
<script>
import { mixin, JXAjax, formatterDateTime } from '../assets/scripts/common'
import { useRoute } from 'vue-router'
export default {
  mixins: [mixin],
  data() {
    return {
      loadingPage: false,
      loading: false,
      mapAttackerEntity: [],
      tableTotal: 0,
      now_page: 1,
      pickerTime: [],
      isShowSelectTime: true,
      valueTime: '1w',
      optionTime: [
        { value: '1h', label: '1小时' },
        { value: '1d', label: '24小时' },
        { value: '1w', label: '7天' },
        { value: '1m', label: '30天' },
        { value: 'default', label: '自定义' }
      ],
      valueSelect: '',
      optionsSelect: [
        { value: 'contains', label: '包含' },
        { value: 'prefix', label: '前缀匹配' },
        { value: 'suffix', label: '后缀匹配' },
        { value: 'equals', label: '等于' },
        { value: 'not_equals', label: '不等于' }
      ],
      querySearchList: [{ field: '', operation: '', value: '' }],
      fieldLabelMap: {
        cookie: 'Cookie',
        host: '域名',
        bytes_received: '接收字节数',
        bytes_sent: '发送字节数',
        iso_code: '国家代码',
        jxwaf_devid: '设备指纹',
        method: '请求方法',
        process_time: 'WAF处理耗时',
        query_string: '查询参数',
        raw_body: '请求体',
        raw_headers: '请求头',
        raw_resp_body: '响应体',
        raw_resp_headers: '响应头',
        raw_src_ip: '原始来源IP',
        request_time: '请求时间',
        request_uri: '完整请求URI',
        request_uuid: '请求UUID',
        scheme: '协议',
        src_ip: '来源IP',
        status: '状态码',
        upstream_addr: '上游地址',
        upstream_response_time: '上游响应耗时',
        upstream_status: '上游状态码',
        uri: '请求路径',
        user_agent: 'UA',
        version: 'HTTP版本',
        waf_action: 'WAF动作',
        waf_extra: '扩展信息',
        waf_module: 'WAF模块',
        waf_node_uuid: 'WAF节点ID',
        waf_policy: 'WAF策略',
        jxwaf_ssl_fingerprint: 'SSL指纹'
      },
      requiredFields: [
        'request_time',
        'host',
        'method',
        'uri',
        'cookie',
        'query_string',
        'raw_body',
        'status',
        'src_ip',
        'user_agent',
        'iso_code',
        'waf_action',
        'waf_module',
        'waf_policy',
        'waf_extra'
      ],
      optionsColumn: [
        'request_time',
        'host',
        'sub_user_name',
        'method',
        'uri',
        'cookie',
        'query_string',
        'raw_body',
        'status',
        'src_ip',
        'user_agent',
        'iso_code',
        'waf_action',
        'waf_module',
        'waf_policy',
        'waf_extra',
        'request_uri',
        'raw_src_ip',
        'upstream_addr',
        'upstream_status',
        'upstream_response_time',
        'process_time',
        'raw_headers',
        'raw_resp_headers',
        'raw_resp_body',
        'scheme',
        'version',
        'bytes_received',
        'bytes_sent',
        'request_uuid',
        'waf_node_uuid',
        'jxwaf_devid',
        'jxwaf_ssl_fingerprint'
      ],
      columnValue: [
        'request_time',
        'host',
        'method',
        'uri',
        'cookie',
        'query_string',
        'raw_body',
        'status',
        'src_ip',
        'user_agent',
        'iso_code',
        'waf_action',
        'waf_module',
        'waf_policy',
        'waf_extra'
      ],
      showColumnValue:"",
      optionsPre: ['raw_resp_body', 'query_string', 'raw_body', 'raw_resp_headers', 'raw_headers'],
      uuid: '',
      host: '',
      uri: '',
      time: '',
      from_time: '',
      to_time: '',
      confCenterDialogVisible:false,
    }
  },
  watch: {
    columnValue: {
      handler(newVal) {
        localStorage.setItem('soc-query-log-columnValue', JSON.stringify(newVal))
      },
      deep: true
    }
  },
  computed: {
    allFields() {
      let data = [...this.requiredFields, ...this.optionsColumn]
      return data
    }
  },
  mounted() {
    var t = this
    const route = useRoute()
    const savedColumnValue = localStorage.getItem('soc-query-log-columnValue')
    if (savedColumnValue) {
      try {
        const parsedValue = JSON.parse(savedColumnValue)
        if (Array.isArray(parsedValue) && parsedValue.length > 0) {
          t.columnValue = parsedValue
        }
      } catch (e) {
        console.error('Failed to parse saved columnValue:', e)
      }
    }
    if (route.params.uuid) {
      t.uuid = route.params.uuid
      if (route.params.time) {
        t.time = JSON.parse(decodeURIComponent(route.params.time))
        t.valueTime = t.time.type
      }
      t.querySearchList[0].field = 'src_ip'
      t.querySearchList[0].operation = 'equals'
      t.querySearchList[0].value = t.uuid
      t.onChangeSearch()
    } else {
      t.getDataConf()
    }
  },
  methods: {
    getDataConf() {
      var t = this
      JXAjax(
        'post',
        '/user/get_sys_report_conf_conf',
        {},
        function (response) {
          t.loadingPage = false
          t.logSource = response.data.message.report_conf
          if (t.logSource == 'false') {
            t.confCenterDialogVisible = true
          } else {
            t.onChangeSearch()
          }
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    getData(now_page) {
      var t = this
      t.loadingPage = true
      var getUrl = '/user/get_log_query_list'
      var postData = {
        sql_rules: t.querySearchList,
        from_time: t.from_time,
        to_time: t.to_time,
        page: now_page
      }
      JXAjax(
        'post',
        getUrl,
        postData,
        function (response) {
          t.mapAttackerEntity = response.data.records
          if (response.data.total_pages == 0) {
            t.tableTotal = 1
          } else {
            t.tableTotal = response.data.total_pages
          }
          t.now_page = response.data.page
          t.loadingPage = false
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    onChangeSearch() {
      this.onChangeSelectTime()
      this.getData(1)
    },
    onCurrentChange() {
      this.getData(this.now_page)
      this.$nextTick(() => {
        window.scroll(0, 0)
      })
    },

    onChangeSelectTime() {
      var t = this
      if (t.valueTime == 'default') {
        t.isShowSelectTime = false
        t.pickerTime = [new Date(new Date().getTime() - 24 * 60 * 60 * 1000), new Date()]
      } else {
        t.isShowSelectTime = true
        if (t.valueTime == '1h') {
          t.pickerTime = [new Date(new Date().getTime() - 1 * 60 * 60 * 1000), new Date()]
        }
        if (t.valueTime == '1d') {
          t.pickerTime = [new Date(new Date().getTime() - 24 * 60 * 60 * 1000), new Date()]
        }
        if (t.valueTime == '1w') {
          t.pickerTime = [new Date(new Date().getTime() - 24 * 60 * 60 * 1000 * 7), new Date()]
        }
        if (t.valueTime == '1m') {
          t.pickerTime = [new Date(new Date().getTime() - 24 * 60 * 60 * 1000 * 30), new Date()]
        }
      }
      if (t.time) {
        t.from_time = t.time.from_time
        t.to_time = t.time.to_time
      } else {
        t.from_time = formatterDateTime(t.pickerTime[0])
        t.to_time = formatterDateTime(t.pickerTime[1])
      }
    },
    changeTimeline(event) {
      var t = this
      if (event == null) {
        t.isShowSelectTime = true
        t.valueTime = '1w'
      } else {
        t.isShowSelectTime = false
      }
    },
    addRuleMatchs() {
      this.querySearchList.push({ operation: '', value: '' })
    },
    removeRuleMatchs(item, index) {
      if (index != -1 && this.querySearchList.length > 1) {
        this.querySearchList.splice(index, 1)
      }
    },
    onClickConfBtn(){
      this.$message({
        message: '请联系管理员配置日志查询功能',
        type: 'warning'
      })
    },
  }
}
</script>
<style>
.operation-center-query-search-wrap .el-checkbox {
  margin-right: 20px;
}
.operation-center-query-search-wrap .el-checkbox__label {
  font-size: 12px;
  padding-left: 5px;
}
.page-owasp-wrap .match-inline-block {
  width: 192px;
}

.engine-form .el-form-item__content {
  margin-left: 40px;
}

.page-owasp-wrap .global-pwd {
  width: calc(100% - 60px);
  margin-right: 4px;
}

.operation-behave-label {
  width: 160px;
  display: inline-block;
  text-align: right;
  padding: 0 20px 0 0;
  box-sizing: border-box;
}
.operation-behave-dialog-box p {
  display: inline-block;
}
.operation-behave-item {
  display: flex;
  padding: 10px 0;
}
.operation-behave-content {
  -webkit-box-flex: 1;
  -ms-flex: 1;
  flex: 1;
  position: relative;
  font-size: 14px;
  white-space: normal;
  word-break: break-all;
  word-wrap: break-word;
}
.operation-behave-content.button button:first-child {
  margin-right: 20px;
}

.operation-search-dialog-box .self-learn-change-audit-label {
  width: 180px;
  display: inline-block;
  text-align: right;
  line-height: 40px;
  padding: 0 12px 0 0;
  box-sizing: border-box;
}
.operation-search-dialog-box p {
  display: inline-block;
}
.self-learn-change-audit-item {
  display: flex;
}
.self-learn-change-audit-content {
  -webkit-box-flex: 1;
  -ms-flex: 1;
  flex: 1;
  line-height: 40px;
  position: relative;
  font-size: 14px;
}
.self-learn-change-audit-content div {
  display: block;
  line-height: 30px;
}

.timeline-box .el-timeline-item__wrapper {
  display: flex;
}
.timeline-box .el-timeline-item__content {
  position: relative;
  top: -8px;
}
.timeline-box .el-timeline-item__timestamp.is-top {
  font-size: 14px;
  color: #000;
}
.click-search-input-behave-map {
  width: 100%;
}
.operation-center-query-search-wrap .el-timeline-item__content {
  width: 100%;
}
.operation-center-query-search-wrap .timeline-box .el-timeline-item__timestamp {
  position: absolute;
  left: -150px;
}
.operation-center-query-search-wrap .el-timeline-item {
  margin-left: 150px;
}
.operation-center-query-search-wrap .el-timeline-item__wrapper {
  padding-left: 18px;
}
.operation-behave-content pre {
  white-space: pre-wrap;
  font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei',
    '微软雅黑', Arial, sans-serif;
  font-size: 12px;
  color: rgb(48, 49, 51);
}
.query-search-container .el-input {
  width: auto;
}

.query-search-container .el-select {
  width: 120px;
  margin-right: 10px;
}
.query-search-container .match-box {
  display: inline-block;
  margin-bottom: 10px;
  margin-right: 6%;
}
.query-search-container .match-box:last-of-type {
  margin-right: 0px;
}

.query-search-container .match-box-content {
  position: relative;
  display: inline-block;
}
.query-time-container {
  display: flex;
}
.query-time-container .el-button {
  margin-left: 10px;
}
.operation-center-query-search-wrap .operation-behave-dialog-box {
  margin-top: 15px;
}
.table-col-tag {
  margin: 5px;
  white-space: normal;
  height: auto;
}
</style>
