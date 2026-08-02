<template>
  <div class="custom-wrap">
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>防护配置</el-breadcrumb-item>
        <el-breadcrumb-item>Web规则配置</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>
    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <div class="container-header only-btn">
          <div>
            <el-button type="success" @click="onClickChangeOrder()">优先级调整</el-button>
            <el-button type="primary" @click="handleAdd">新增规则</el-button>
          </div>
        </div>
        <div class="demo-block">
          <el-table :data="tableData" style="width: 100%">
            <el-table-column prop="rule_name" label="规则名"></el-table-column>
            <el-table-column prop="rule_detail" label="规则详情"></el-table-column>
            <el-table-column prop="rule_action" label="执行动作">
              <template #default="scope">
                <el-tag v-if="scope.row.rule_action == 'reject_response'" size="small" type="danger">拒绝响应</el-tag>
                <el-tag v-if="scope.row.rule_action == 'block'" size="small" type="warning">阻断请求</el-tag>
                <el-tag v-if="scope.row.rule_action == 'watch'" size="small">观察模式</el-tag>
                <el-tag v-if="scope.row.rule_action == 'bot_check'" size="small" type="success">人机识别：
                  <span v-if="scope.row.action_value == 'auto'">无交互验证</span>
                  <span v-if="scope.row.action_value == 'slipper'">滑块验证</span>
                  <span v-if="scope.row.action_value == 'puzzle'">拼图验证</span>
                  <span v-if="scope.row.action_value == 'words'">选字验证</span>
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="rule_status" label="状态">
              <template #default="scope">
                <el-switch
                  v-model="scope.row.status"
                  @change="onChangeRuleStatus(scope.row)"
                  active-value="true"
                  inactive-value="false"
                />
              </template>
            </el-table-column>

            <el-table-column label="操作" align="right">
              <template #default="scope">
                <el-button
                  size="small"
                  @click="handleEdit(scope.row)"
                  class="button-block"
                  type="text"
                  >配置
                </el-button>
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
            <el-table-column label="优先级" align="right" v-if="!isShowOrder">
              <template #default="scope">
                <el-button
                  type="success"
                  icon="Top"
                  circle
                  @click="onClickChangeOrderSubmit(scope.$index, scope.row, 'up')"
                  title="上移"
                  :loading="orderLoading"
                />
                <el-button
                  type="success"
                  icon="Bottom"
                  circle
                  @click="onClickChangeOrderSubmit(scope.$index, scope.row, 'down')"
                  title="下移"
                  :loading="orderLoading"
                />
                <el-button
                  type="success"
                  icon="Upload"
                  circle
                  @click="onClickChangeOrderSubmit(scope.$index, scope.row, 'top')"
                  title="置顶"
                  :loading="orderLoading"
                />
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
  </div>
</template>
<script>
import { mixin, JXAjax } from '../assets/scripts/common'
export default {
  mixins: [mixin],
  data() {
    return {
      loading: false,
      loadingPage: false,
      isShowOrder: true,
      orderLoading: false,
      tableData: [],
      currentPage: 1,
      tableTotal: 1
    }
  },
  mounted() {
    this.onCurrentChange(this.currentPage)
  },
  methods: {
    getData(page) {
      var t = this
      var url = '/user/get_web_rule_protection_list'
      var postData = { page: page }
      JXAjax(
        'post',
        url,
        postData,
        function (response) {
          t.loadingPage = false
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
    handleEdit(data) {
      this.$router.push('/user/web-rule-protection-edit/' + data.rule_name)
    },
    handleAdd() {
      this.$router.push('/user/web-rule-protection-edit/new')
    },
    handleDelete(data) {
      var t = this
      t.loading = true
      var url = '/user/delete_web_rule_protection'
      var postData = { rule_name: data.rule_name }
      JXAjax(
        'post',
        url,
        postData,
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
    onClickChangeOrder() {
      var t = this
      t.isShowOrder = !t.isShowOrder
    },
    onClickChangeOrderSubmit(index, value, operate) {
      var t = this
      var url = '/user/exchange_web_rule_protection_priority'
      var oData = { rule_name: value.rule_name }
      if (index > 0) {
        if (operate == 'top') {
          oData.type = 'top'
        }
        if (operate == 'up') {
          oData.type = 'exchange'
          oData.exchange_rule_name = t.tableData[index - 1].rule_name
        }
      }

      if (index < t.tableData.length - 1) {
        if (operate == 'down') {
          oData.type = 'exchange'
          oData.exchange_rule_name = t.tableData[index + 1].rule_name
        }
      }

      if (oData.type == 'top' || oData.type == 'exchange') {
        t.orderLoading = true
        JXAjax(
          'post',
          url,
          oData,
          function (response) {
            t.orderLoading = false
            t.onCurrentChange(t.currentPage)
          },
          function () {
            t.orderLoading = false
          },
          'no-message'
        )
      }
    },
    onChangeRuleStatus(value) {
      var t = this
      var url = '/user/edit_web_rule_protection_status'
      var postData = { rule_name: value.rule_name, status: value.status }
      JXAjax(
        'post',
        url,
        postData,
        function (response) {
          t.onCurrentChange(t.currentPage)
        },
        function () {},
        'no-message'
      )
    }
  }
}
</script>

<style>

</style>
