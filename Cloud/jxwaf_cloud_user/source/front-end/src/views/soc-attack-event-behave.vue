<template>
  <div class="operation-behave-map-page">
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item :to="{ path: '/user/soc-attack-event' }">攻击事件</el-breadcrumb-item>
        <el-breadcrumb-item>行为追踪</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>
    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <div class="header-container">
          <div class="query-time-container">
            <el-select
              v-model="valueTime"
              placeholder="Select"
              v-show="isShowSelectTime"
              @change="onChangeSelectTime"
              style="width: 205px"
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
          <el-button type="primary" plain @click="handleBack">返回</el-button>
        </div>

        <div v-if="mapAttackerEntity.length == 0">
          <el-empty description="NO DATA" />
        </div>
        <div>
          <el-timeline class="timeline-box">
            <el-timeline-item
              v-for="(item, index) in mapAttackerEntity"
              :key="index"
              :timestamp="item.StartAttackTime"
              placement="top"
              size="large"
              color="#409eff"
            >
              <div class="operation-behave-dialog-box">
                <div class="operation-behave-item" style="color: #409eff; padding: 7px 15px">
                  <div class="operation-behave-content" style="font-size: 18px">
                    <span>{{ item.URL }}</span>
                  </div>
                </div>
                <el-card shadow="hover" style="margin-left: 15px">
                  <div class="operation-behave-item">
                    <span class="operation-behave-label">攻击类型</span>
                    <div class="operation-behave-content">
                      <el-tag v-for="(i, j) in item.AttackTypes" :key="j" style="margin-right: 5px;"> {{ i }}</el-tag>
                    </div>
                  </div>
                  <div class="operation-behave-item">
                    <span class="operation-behave-label">开始攻击时间</span>
                    <div class="operation-behave-content">
                      {{ item.StartAttackTime }}
                    </div>
                  </div>
                  <div class="operation-behave-item">
                    <span class="operation-behave-label">最新攻击时间</span>
                    <div class="operation-behave-content">
                      {{ item.LatestAttackTime }}
                    </div>
                  </div>
                  <div class="operation-behave-item">
                    <span class="operation-behave-label">攻击次数</span>
                    <div class="operation-behave-content">
                      {{ item.AttackCount }}
                    </div>
                  </div>
                  <div class="operation-behave-item">
                    <span class="operation-behave-label">拦截次数</span>
                    <div class="operation-behave-content">
                      {{ item.BlockCount }}
                    </div>
                  </div>
                </el-card>
              </div>
            </el-timeline-item>
          </el-timeline>
        </div>
        <el-row type="flex" class="margin-border" justify="space-between">
          <el-col :span="12"></el-col>
          <el-col :span="12" class="text-align-right">
            <el-button type="primary" plain @click="handleBack">返回</el-button>
          </el-col>
        </el-row>
      </el-col>
    </el-row>
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
      attackIp: '',
      isShowSelectTime: true,
      valueTime: '1w',
      pickerTime: [],
      optionTime: [
        { value: '1h', label: '1小时' },
        { value: '1d', label: '24小时' },
        { value: '1w', label: '7天' },
        { value: '1m', label: '30天' },
        { value: 'default', label: '自定义' }
      ]
    }
  },
  mounted() {
    const route = useRoute()
    var t = this
    t.attackIp = route.params.uuid
    t.onChangeSearch()
  },
  methods: {
    handleBack() {
      this.$router.push('/user/soc-attack-event')
    },
    getData() {
      var t = this
      var getUrl = '/user/get_attack_behave_track'
      var data = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1]),
        attack_ip: t.attackIp
      }
      t.loadingPage = true
      JXAjax(
        'post',
        getUrl,
        data,
        function (response) {
          t.loadingPage = false
          t.mapAttackerEntity = response.data.records
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    onChangeSearch() {
      this.onChangeSelectTime()
      this.getData()
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
        t.valueTime = '1w'
      } else {
        t.isShowSelectTime = false
      }
    }
  }
}
</script>
<style>
.operation-behave-map-page .operation-behave-label {
  width: 120px;
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
.operation-behave-map-page .query-time-container {
  display: flex;
}
.query-time-container .el-button {
  margin-left: 10px;
}
.operation-behave-map-page .el-timeline-item__content {
  width: 100%;
}

.operation-behave-map-page .timeline-box .el-timeline-item__timestamp {
  position: absolute;
  left: -150px;
}

.operation-behave-map-page .el-timeline-item {
  margin-left: 150px;
}

.operation-behave-map-page .el-timeline-item__wrapper {
  padding-left: 18px;
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

.operation-behave-map-page .header-container {
  display: flex;
  justify-content: space-between;
  padding-bottom: 15px;
  margin-bottom: 15px;
  border-bottom: 1px solid #ebeef5;
}
</style>
