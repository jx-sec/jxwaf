<template>
  <div>
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>攻击事件</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>
    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
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
          <el-button
            @click="onChangeSearch"
            class="search-icon-btn"
            icon="Search"
            style="margin-left: 10px"
          />
        </div>
        <div class="demo-block">
          <el-table :data="tableData" style="width: 100%">
            <el-table-column prop="AttackIP" label="攻击IP"></el-table-column>
            <el-table-column label="攻击详情">
              <template #default="scope">
                <p v-if="logConfig == 'true'">
                  <span class="col-item-protection-title">请求总数：</span>
                  <span>
                    <el-tag size="small">{{ scope.row.AttackCount }}</el-tag>
                  </span>
                </p>
                <p>
                  <span class="col-item-protection-title">攻击次数：</span>
                  <span>
                    <el-tag size="small">{{ scope.row.AttackCount }}</el-tag>
                  </span>
                </p>
                <p>
                  <span class="col-item-protection-title">拦截次数：</span>
                  <span>
                    <el-tag size="small">{{ scope.row.BlockCount }}</el-tag>
                  </span>
                </p>
                <p>
                  <span class="col-item-protection-title">攻击接口数量：</span>
                  <span>
                    <el-tag size="small">{{ scope.row.UniqueAttackInterfaces }}</el-tag>
                  </span>
                </p>
                <p>
                  <span class="col-item-protection-title">拦截接口数量：</span>
                  <span>
                    <el-tag size="small">{{ scope.row.UniqueBlockedInterfaces }}</el-tag>
                  </span>
                </p>
              </template>
            </el-table-column>
            <el-table-column label="防护策略">
              <template #default="scope">
                <p v-for="(item, key) in scope.row.AttackTypes" :key="key">
                  {{ item }}
                </p>
              </template>
            </el-table-column>
            <el-table-column label="时间" width="250">
              <template #default="scope">
                <p v-if="logConfig == 'false'">
                  <span class="col-item-protection-title">开始攻击时间：</span>
                  <span>
                    <el-tag size="small">{{ scope.row.StartTime }}</el-tag>
                  </span>
                </p>
                <p v-if="logConfig == 'false'">
                  <span class="col-item-protection-title">最新攻击时间：</span>
                  <span>
                    <el-tag size="small">{{ scope.row.LatestTime }}</el-tag>
                  </span>
                </p>
                <p v-if="logConfig == 'true'">
                  <span class="col-item-protection-title">开始请求时间：</span>
                  <span>
                    <el-tag size="small">{{ scope.row.FirstRequestTime }}</el-tag>
                  </span>
                </p>
                <p v-if="logConfig == 'true'">
                  <span class="col-item-protection-title">开始攻击时间：</span>
                  <span>
                    <el-tag size="small">{{ scope.row.FirstAttackTime }}</el-tag>
                  </span>
                </p>
                <p v-if="logConfig == 'true'">
                  <span class="col-item-protection-title">最新攻击时间：</span>
                  <span>
                    <el-tag size="small">{{ scope.row.LatestAttackTime }}</el-tag>
                  </span>
                </p>
              </template>
            </el-table-column>
            <el-table-column label="操作" align="right">
              <template #default="scope">
                <el-button
                  size="small"
                  @click="handleLookBehave(scope.row)"
                  class="button-block"
                  type="text"
                  >查看行为轨迹
                </el-button>
                <el-button
                  size="small"
                  @click="handleLookAttack(scope.row)"
                  class="button-block"
                  type="text"
                  >查看攻击详情
                </el-button>
              </template>
            </el-table-column>
          </el-table>

          <el-pagination
            small
            background
            layout="prev, pager, next"
            :page-count="tableTotal"
            :page-sizes="50"
            v-model:current-page="currentPage"
            @current-change="onCurrentChange"
          />
        </div>
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
export default {
  mixins: [mixin],
  data() {
    return {
      loadingPage: false,
      tableData: [],
      currentPage: 1,
      tableTotal: 0,

      isShowSelectTime: true,
      valueTime: '1d',
      pickerTime: [],
      optionTime: [
        { value: '1h', label: '1小时' },
        { value: '1d', label: '24小时' },
        { value: '1w', label: '7天' },
        { value: '1m', label: '30天' },
        { value: 'default', label: '自定义' }
      ],
      logConfig: 'false',
      domainList: [],
      domain: '',
      hasDomain: false,
      confCenterDialogVisible:false,
    }
  },

  mounted() {
    this.getGroupListData()
    this.onChangeSelectTime()
    this.getDataConf()
  },
  methods: {
    getGroupListData() {
      var t = this
      JXAjax(
        'post',
        '/user/api_get_sub_account_list',
        {},
        function (response) {
          t.loadingPage = false
          t.groupList = response.data.records
          t.groupList.unshift({ })
          t.group = t.groupList[0].sub_user_name
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    getdomainListData() {
      var t = this
      JXAjax(
        'post',
        '/user/get_domain_list',
        {  },
        function (response) {
          t.loadingPage = false
          t.domainList = response.data.records
          t.domainList.unshift({ domain: '全部' })
          t.domain = t.domainList[0].domain
        },
        function () {
          //t.loadingPage = false
        },
        'no-message'
      )
    },
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
            t.getData(1)
          }
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    getData(page) {
      var t = this
      var url = '/user/get_attack_event_list'
      var data = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1]),
        page: page
      }
      if (t.hasGroup) {
        data.sub_user_name = t.group
      }
      if (t.hasDomain) {
        data.domain = t.domain
        data.sub_user_name = t.group
      }
      JXAjax(
        'post',
        url,
        data,
        function (response) {
          t.tableData = response.data.records
          t.tableData.forEach((item) => {
            item.isVisiblePopover = false
          })
          if (response.data.total_pages == 0) {
            t.tableTotal = 1
          } else {
            t.tableTotal = response.data.total_pages
          }
          t.currentPage = response.data.page
        },
        function () {},
        'no-message'
      )
    },

    handleLookBehave(data) {
      this.$router.push('/user/soc-attack-event-behave/' + data.AttackIP)
    },
    handleLookAttack(data) {
      var t = this
      var time = {}
      time.type = t.valueTime
      time.from_time = formatterDateTime(t.pickerTime[0])
      time.to_time = formatterDateTime(t.pickerTime[1])
      const routeData = this.$router.resolve({ name: 'soc-query-log', params: { uuid: data.AttackIP, time: encodeURIComponent(JSON.stringify(time)) } })
      window.open(routeData.href, '_blank')
    },
    onCurrentChange() {
      this.onChangeSelectTime()
      this.getData(this.currentPage)
      this.$nextTick(() => {
        window.scroll(0, 0)
      })
    },
    onChangeSearch() {
      this.onChangeSelectTime()
      this.getData(1)
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
    },
    changeTimeline(event) {
      var t = this
      if (event == null) {
        t.isShowSelectTime = true
        t.valueTime = '1d'
      } else {
        t.isShowSelectTime = false
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
.query-time-container {
  display: flex;
}
.query-time-container .el-button {
  margin-left: 10px;
}
.col-item-protection-title {
  display: inline-block;
  width: 100px;
}
.el-table__body p {
  font-size: 14px;
  line-height: 30px;
}
</style>
