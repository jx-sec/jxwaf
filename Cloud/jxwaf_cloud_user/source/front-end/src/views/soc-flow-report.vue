<template>
  <div class="echart-container">
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item :to="{ path: '/soc-flow-report' }">运营中心</el-breadcrumb-item>
        <el-breadcrumb-item>流量安全报表</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>
    <div class="container-style" v-loading.fullscreen.lock="loadingPage">
      <el-row>
        <el-col :span="24" style="margin-bottom: 15px">
          <div class="echart-select" style="display: flex">
            
            

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
        </el-col>
      </el-row>
      <el-row :gutter="15">
        <el-col :span="6">
          <el-card
            class="card card-red"
            shadow="hover"
            v-loading="loading.countTotle"
          >
            <div class="card-header">
              <span>流量攻击次数</span>
            </div>
            <div class="card-content">
              <div class="card-text-wrapper">
                <div class="card-text">{{ countTotle.current }}</div>
                <div :class="`card-badge trend-${countTotle.trend === 'flat' ? 'stable' : countTotle.trend}`">
                  <span class="card-badge-icon" v-if="countTotle.trend == 'flat'"><el-icon><SemiSelect /></el-icon></span>
                  <span class="card-badge-icon" v-if="countTotle.trend == 'up'"><el-icon><CaretTop /></el-icon></span>
                  <span class="card-badge-icon" v-if="countTotle.trend == 'down'"><el-icon><CaretBottom /></el-icon></span>
                  <span  v-if="countTotle.trend != 'flat'">{{ ((countTotle.current - countTotle.previous ) / countTotle.previous * 100).toFixed(1) }} %</span>
                  <span  v-if="countTotle.trend == 'flat'">0%</span>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card
            class="card card-yellow"
            shadow="hover"
            v-loading="loading.apiCountTotle"
          >
            <div class="card-header">
              <span>流量攻击接口数</span>
            </div>
            <div class="card-content">
              <div class="card-text-wrapper">
                <div class="card-text">{{ apiCountTotle.current }}</div>
                <div :class="`card-badge trend-${apiCountTotle.trend === 'flat' ? 'stable' : apiCountTotle.trend}`">
                  <span class="card-badge-icon" v-if="apiCountTotle.trend == 'flat'"><el-icon><SemiSelect /></el-icon></span>
                  <span class="card-badge-icon" v-if="apiCountTotle.trend == 'up'"><el-icon><CaretTop /></el-icon></span>
                  <span class="card-badge-icon" v-if="apiCountTotle.trend == 'down'"><el-icon><CaretBottom /></el-icon></span>
                  <span  v-if="countTotle.trend != 'flat'">{{ ((apiCountTotle.current - apiCountTotle.previous ) / apiCountTotle.previous * 100).toFixed(1) }} %</span>
                  <span  v-if="countTotle.trend == 'flat'">0%</span>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card
            class="card card-green"
            shadow="hover"
            v-loading="loading.ipCountTotle"
          >
            <div class="card-header">
              <span>流量攻击IP数</span>
            </div>
            <div class="card-content">
              <div class="card-text-wrapper">
                <div class="card-text">{{ ipCountTotle.current }}</div>
                <div :class="`card-badge trend-${ipCountTotle.trend === 'flat' ? 'stable' : ipCountTotle.trend}`">
                  <span class="card-badge-icon" v-if="ipCountTotle.trend == 'flat'"><el-icon><SemiSelect /></el-icon></span>
                  <span class="card-badge-icon" v-if="ipCountTotle.trend == 'up'"><el-icon><CaretTop /></el-icon></span>
                  <span class="card-badge-icon" v-if="ipCountTotle.trend == 'down'"><el-icon><CaretBottom /></el-icon></span>
                  <span  v-if="countTotle.trend != 'flat'">{{ ((ipCountTotle.current - ipCountTotle.previous ) / ipCountTotle.previous * 100).toFixed(1) }} %</span>
                  <span  v-if="countTotle.trend == 'flat'">0%</span>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card
            class="card card-blue"
            shadow="hover"
            v-loading="loading.isocodeCountTotle"
          >
            <div class="card-header">
              <span>流量攻击来源地区数量</span>
            </div>
            <div class="card-content">
              <div class="card-text-wrapper">
                <div class="card-text">{{ isocodeCountTotle.current }}</div>
                <div :class="`card-badge trend-${isocodeCountTotle.trend === 'flat' ? 'stable' : isocodeCountTotle.trend}`">
                  <span class="card-badge-icon" v-if="isocodeCountTotle.trend == 'flat'"><el-icon><SemiSelect /></el-icon></span>
                  <span class="card-badge-icon" v-if="isocodeCountTotle.trend == 'up'"><el-icon><CaretTop /></el-icon></span>
                  <span class="card-badge-icon" v-if="isocodeCountTotle.trend == 'down'"><el-icon><CaretBottom /></el-icon></span>
                  <span  v-if="countTotle.trend != 'flat'">{{ ((isocodeCountTotle.current - isocodeCountTotle.previous ) / isocodeCountTotle.previous * 100).toFixed(1) }} %</span>
                  <span  v-if="countTotle.trend == 'flat'">0%</span>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
      <el-row :gutter="15" style="margin-top: 15px">
        <el-col :span="12">
          <el-card class="chart-card map-card" shadow="hover">
            <div class="chart-card-header">
              <span>流量攻击来源地区</span>
            </div>
            <div id="attack-geoip"></div>
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card
            class="chart-card trend-card"
            shadow="hover"
            v-loading="loading.countTrend"
          >
            <div class="chart-card-header">
              <span>流量攻击趋势</span>
            </div>
            <div v-if="countTrend.length == 0" class="empty-box">
              <el-empty description="NO DATA" />
            </div>
            <div id="count-trend"></div>
          </el-card>
        </el-col>
      </el-row>
      <el-row :gutter="15" style="margin-top: 15px">
        <el-col :span="12">
          <el-card
            class="chart-card isocode-card"
            shadow="hover"
            v-loading="loading.isocodeTop"
          >
            <div class="chart-card-header">
              <span>流量攻击来源地区 TOP5</span>
            </div>
            <div v-if="isocodeTop.length == 0" class="empty-box">
              <el-empty description="NO DATA" />
            </div>
            <div id="isocode-top"></div>
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card
            class="chart-card type-card"
            shadow="hover"
            v-loading="loading.typeTop"
          >
            <div class="chart-card-header">
              <span>流量攻击防护策略 TOP 5</span>
            </div>
            <div v-if="typeTop.length == 0" class="empty-box">
              <el-empty description="NO DATA" />
            </div>
            <div id="type-top"></div>
          </el-card>
        </el-col>
      </el-row>
      <el-row :gutter="15" style="margin-top: 15px">
        <el-col :span="12">
          <el-card
            class="chart-card api-card"
            shadow="hover"
            v-loading="loading.apiTop"
          >
            <div class="chart-card-header">
              <span>流量攻击接口 TOP 5</span>
            </div>
            <div v-if="apiTop.length == 0" class="empty-box">
              <el-empty description="NO DATA" />
            </div>
            <div id="api-top"></div>
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card
            class="chart-card ip-card"
            shadow="hover"
            v-loading="loading.ipTop"
          >
            <div class="chart-card-header">
              <span>流量攻击IP TOP 5</span>
            </div>
            <div v-if="ipTop.length == 0" class="empty-box">
              <el-empty description="NO DATA" />
            </div>
            <div id="ip-top"></div>
          </el-card>
        </el-col>
      </el-row>
    </div>
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
import echarts from '../assets/scripts/echart'
import world from '../assets/scripts/world.json'
import { mixin, JXAjax, nameMap, formatterDateTime } from '../assets/scripts/common'
import country from '../assets/scripts/country.json'
export default {
  mixins: [mixin],
  data() {
    return {
      loadingPage: false,
      logSource: '',
      isShowSelectTime: true,
      valueTime: '1w',
      pickerTime: [],
      optionTime: [
        { value: '1h', label: '1小时' },
        { value: '1d', label: '24小时' },
        { value: '1w', label: '7天' },
        { value: '1m', label: '30天' },
        { value: 'default', label: '自定义' }
      ],
      loading: {
        countTotle: true,
        apiCountTotle: true,
        ipCountTotle: true,
        isocodeCountTotle: true,
        countTrend: true,
        apiTop: true,
        typeTop: true,
        ipTop: true,
        isocodeTop: true
      },
      countTotle: {},
      apiCountTotle: {},
      ipCountTotle: {},
      isocodeCountTotle: {},
      countTrend: [],
      apiTop: [],
      typeTop: [],
      ipTop: [],
      isocodeTop: [],
      domainList: [],
      domain: '',
      hasDomain: false,
      confCenterDialogVisible:false,
    }
  },
  

  beforeUnmount() {
    const chartIds = ['attack-geoip', 'count-trend', 'api-top', 'type-top', 'ip-top', 'isocode-top']
    chartIds.forEach(id => {
      const chartDom = document.getElementById(id)
      if (chartDom) {
        const chart = echarts.getInstanceByDom(chartDom)
        if (chart) {
          chart.dispose()
        }
      }
    })
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
          t.loadingPage = false
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
            t.getData()
          }
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    getData() {
      this.gatAttackGeoip()
      this.getCountTotle()
      this.getApiCountTotle()
      this.getIsocodeCountTotle()
      this.getIpCountTotle()
      this.getCountTrend()
      this.getApiTop()
      this.getTypeTop()
      this.getIpTop()
      this.getIsocodeTop()
    },
    formatterIsoCode(res_data, type) {
      var data = []
      var cn_all = 0
      var flag = type || 'default'
      if (res_data && res_data.length > 0) {
        res_data.forEach((item) => {
          for (var i = 0; i < country.length; i++) {
            if (item.iso_code == country[i].code && flag == 'default') {
              // 中国 = 中国大陆 + 台湾 + 澳门 + 香港
              if (
                item.iso_code == 'CN' ||
                item.iso_code == 'HK' ||
                item.iso_code == 'MO' ||
                item.iso_code == 'TW'
              ) {
                cn_all = parseInt(cn_all + item.attack_count)
              } else {
                data.push({ name: country[i].cnName, value: item.attack_count })
              }
            }
            if (item.iso_code == country[i].code && flag == 'attack_count') {
              // 中国 = 中国大陆 + 台湾 + 澳门 + 香港
              if (
                item.iso_code == 'CN' ||
                item.iso_code == 'HK' ||
                item.iso_code == 'MO' ||
                item.iso_code == 'TW'
              ) {
                cn_all = parseInt(cn_all + item.attack_count)
              } else {
                data.push({ name: country[i].cnName, attack_count: item.attack_count })
              }
            }
          }
        })

        if (cn_all != 0 && flag == 'default') {
          data.push({ name: '中国', value: cn_all })
        }
        if (cn_all != 0 && flag == 'attack_count') {
          data.push({ name: '中国', attack_count: cn_all })
        }
      }
      console.log(data)
      return data
    },
    gatAttackGeoip() {
      var t = this
      var oData = []
      var _url = '/user/get_flow_attack_geoip'
      var _data = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      }
      if (t.hasGroup) {
        _data.sub_user_name = t.group
      }
      if (t.hasDomain) {
        _data.domain = t.domain
        _data.sub_user_name = t.group
      }
      JXAjax(
        'post',
        _url,
        _data,
        function (response) {
          oData = t.formatterIsoCode(response.data.message)
          t.initMap('attack-geoip', oData)
        },
        function () {
          t.loading.requestCountTotle = false
        },
        'no-message'
      )
    },
    initMap(id, data) {
      var t = this
      echarts.registerMap('world', world)
      var option = {
        tooltip: {
          trigger: 'item',
          formatter: function (params) {
            if (params.name) {
              return params.name + ' : ' + (isNaN(params.value) ? 0 : parseInt(params.value))
            }
          }
        },
        backgroundColor: '#fff',
        // 视觉映射组件
        visualMap: {
          type: 'continuous', // continuous 类型为连续型  piecewise 类型为分段型
          show: true, // 是否显示 visualMap-continuous 组件 如果设置为 false，不会显示，但是数据映射的功能还存在
          // 指定 visualMapContinuous 组件的允许的最小/大值。'min'/'max' 必须用户指定。
          // [visualMap.min, visualMax.max] 形成了视觉映射的『定义域』

          // 文本样式
          textStyle: {
            fontSize: 14,
            color: 'rgb(91 92 110)'
          },
          realtime: false, // 拖拽时，是否实时更新
          calculable: false, // 是否显示拖拽用的手柄
          // 定义 在选中范围中 的视觉元素
          inRange: {
            color: ['#bae7a5', 'rgb(247, 244, 148)', 'rgb(255, 178, 72)', 'rgb(252, 151, 175)'] // 图元的颜色
          }
        },
        series: [
          {
            name: 'Web攻击来源地区',
            type: 'map',
            map: 'world',
            roam: false, // 是否开启鼠标缩放和平移漫游
            zoom: 1.2,
            itemStyle: {
              areaColor: 'rgb(114, 204, 255)', // 地图区域的颜色 如果设置了visualMap，areaColor属性将不起作用
              borderWidth: 0.5, // 描边线宽 为 0 时无描边
              borderColor: '#fff', // 图形的描边颜色 支持的颜色格式同 color，不支持回调函数
              borderType: 'solid' // 描边类型，默认为实线，支持 'solid', 'dashed', 'dotted'
            },
            emphasis: {
              itemStyle: {
                areaColor: '#ff5722',
                label: { show: true }
              }
            },
            label: {
              show: false // 是否显示对应地名
            },
            data: data,
            nameMap: nameMap
          }
        ]
      }
      this.buildChart(id, option)
    },
    getCountTotle() {
      var t = this
      t.loading.countTotle = true
      var postUrl = '/user/get_flow_attack_count_total'
      var oData = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      }
      if (t.hasGroup) {
        oData.sub_user_name = t.group
      }
      if (t.hasDomain) {
        oData.domain = t.domain
        oData.sub_user_name = t.group
      }
      JXAjax(
        'post',
        postUrl,
        oData,
        function (response) {
          t.countTotle = response.data.message
          t.loading.countTotle = false
        },
        function () {
          t.loading.countTotle = false
        },
        'no-message'
      )
    },
    getApiCountTotle() {
      var t = this
      t.loading.apiCountTotle = true
      var postUrl = '/user/get_flow_attack_api_count_total'
      var oData = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      }
      if (t.hasGroup) {
        oData.sub_user_name = t.group
      }
      if (t.hasDomain) {
        oData.domain = t.domain
        oData.sub_user_name = t.group
      }
      JXAjax(
        'post',
        postUrl,
        oData,
        function (response) {
          t.apiCountTotle = response.data.message
          t.loading.apiCountTotle = false
        },
        function () {
          t.loading.apiCountTotle = false
        },
        'no-message'
      )
    },
    getIsocodeCountTotle() {
      var t = this
      t.loading.isocodeCountTotle = true
      var postUrl = '/user/get_flow_attack_isocode_count_total'
      var oData = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      }
      if (t.hasGroup) {
        oData.sub_user_name = t.group
      }
      if (t.hasDomain) {
        oData.domain = t.domain
        oData.sub_user_name = t.group
      }
      JXAjax(
        'post',
        postUrl,
        oData,
        function (response) {
          t.isocodeCountTotle = response.data.message
          t.loading.isocodeCountTotle = false
        },
        function () {
          t.loading.isocodeCountTotle = false
        },
        'no-message'
      )
    },
    getIpCountTotle() {
      var t = this
      t.loading.ipCountTotle = true
      var postUrl = '/user/get_flow_attack_ip_count_total'
      var oData = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      }
      if (t.hasGroup) {
        oData.sub_user_name = t.group
      }
      if (t.hasDomain) {
        oData.domain = t.domain
        oData.sub_user_name = t.group
      }
      JXAjax(
        'post',
        postUrl,
        oData,
        function (response) {
          t.ipCountTotle = response.data.message
          t.loading.ipCountTotle = false
        },
        function () {
          t.loading.ipCountTotle = false
        },
        'no-message'
      )
    },

    getCountTrend() {
      var t = this
      t.loading.countTrend = true
      var postUrl = '/user/get_flow_attack_count_trend'
      var oData = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      }
      if (t.hasGroup) {
        oData.sub_user_name = t.group
      }
      if (t.hasDomain) {
        oData.domain = t.domain
        oData.sub_user_name = t.group
      }
      JXAjax(
        'post',
        postUrl,
        oData,
        function (response) {
          t.countTrend = response.data.message
          t.loading.countTrend = false
          t.initLineChart(t.countTrend, 'count-trend')
        },
        function () {
          t.loading.countTrend = false
        },
        'no-message'
      )
    },

    getApiTop() {
      var t = this
      t.loading.apiTop = true
      var postUrl = '/user/get_flow_attack_api_top'
      var oData = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      }
      if (t.hasGroup) {
        oData.sub_user_name = t.group
      }
      if (t.hasDomain) {
        oData.domain = t.domain
        oData.sub_user_name = t.group
      }
      JXAjax(
        'post',
        postUrl,
        oData,
        function (response) {
          t.loading.apiTop = false
          t.apiTop = response.data.message
          t.initBarChart(t.apiTop, 'api-top', 'api','#E6A23C')
        },
        function () {
          t.loading.apiTop = false
        },
        'no-message'
      )
    },
    getTypeTop() {
      var t = this
      t.loading.typeTop = true
      var postUrl = '/user/get_flow_attack_type_top'
      var oData = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      }
      if (t.hasGroup) {
        oData.sub_user_name = t.group
      }
      if (t.hasDomain) {
        oData.domain = t.domain
        oData.sub_user_name = t.group
      }
      JXAjax(
        'post',
        postUrl,
        oData,
        function (response) {
          t.loading.typeTop = false
          t.typeTop = response.data.message
          t.initBarChart(t.typeTop, 'type-top', 'waf_policy','#F56C6C')
        },
        function () {
          t.loading.typeTop = false
        },
        'no-message'
      )
    },
    getIpTop() {
      var t = this
      t.loading.ipTop = true
      var postUrl = '/user/get_flow_attack_ip_top'
      var oData = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      }
      if (t.hasGroup) {
        oData.sub_user_name = t.group
      }
      if (t.hasDomain) {
        oData.domain = t.domain
        oData.sub_user_name = t.group
      }
      JXAjax(
        'post',
        postUrl,
        oData,
        function (response) {
          t.loading.ipTop = false
          t.ipTop = response.data.message
          t.initBarChart(t.ipTop, 'ip-top', 'src_ip','#67C23A')
        },
        function () {
          t.loading.ipTop = false
        },
        'no-message'
      )
    },
    getIsocodeTop() {
      var t = this
      t.loading.isocodeTop = true
      var postUrl = '/user/get_flow_attack_isocode_top'
      var oData = {
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      }
      if (t.hasGroup) {
        oData.sub_user_name = t.group
      }
      if (t.hasDomain) {
        oData.domain = t.domain
        oData.sub_user_name = t.group
      }
      JXAjax(
        'post',
        postUrl,
        oData,
        function (response) {
          t.loading.isocodeTop = false
          t.isocodeTop = t.formatterIsoCode(response.data.message, 'attack_count')
          t.initBarChart(t.isocodeTop, 'isocode-top', 'name', '#409EFF')
        },
        function () {
          t.loading.isocodeTop = false
        },
        'no-message'
      )
    },

    initLineChart(data, id) {
      var x = []
      var y = []
      data.forEach((item) => {
        y.push(item.AttackCount)
        x.push(item.TimeSlot)
      })
      var option = {
        // title: {
        //   text: title
        // },
        // 全局调色盘。
        color: ['#73c0de'],
        tooltip: {
          trigger: 'axis'
          // formatter: "{c}",
        },

        xAxis: {
          type: 'category',
          data: x,
          show: false,
          boundaryGap: false,
          axisLabel: {
            formatter: function (value) {
              if (value.length > 20) {
                return `${value.slice(0, 20)}...`
              }
              return value
            }
          }
        },
        yAxis: {
          type: 'value'
        },
        series: [
          {
            data: y,
            type: 'line',
            smooth: true,
            areaStyle: {
              color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                { offset: 0, color: '#73c0de' },
                { offset: 0.5, color: '#9fd8ef' },
                { offset: 1, color: '#ffeaea' }
              ])
            }
          }
        ]
      }
      this.buildChart(id, option)
    },
    initBarChart(data, id, key, color) {
      var x = []
      var y = []

      data.forEach((item) => {
        y.push(item.attack_count)
        x.push(item[key])
      })
      var option = {
        color: ['#6366f1'],
        tooltip: {
          trigger: 'axis',
          axisPointer: {
            type: 'shadow'
          }
        },
        grid: {
          top: '2%',
          left: '3%',
          right: '8%',
          bottom: '3%',
          containLabel: true
        },
        xAxis: {
          type: 'value',
          axisLine: {
            show: false
          },
          axisTick: {
            show: false
          },
          // 不显示刻度和数字
          splitLine: { show: false },
          axisLabel: { show: false }
        },
        yAxis: {
          type: 'category',
          data: x,
          inverse: true, //排序
          splitLine: { show: false },
          axisLine: { show: false },
          axisTick: { show: false },
          barGap: 50,
          axisLabel: {
            show: true,
            inside: true,
            interval: 0,
            color: '#000',
            verticalAlign: 'bottom',
            fontSize: 14,
            align: 'left',
            padding: [0, 0, 10, -5]
          }
        },
        series: [
          {
            data: y,
            type: 'bar',
            //柱状图自动排序，排序自动让Y轴名字跟着数据动
            realtimeSort: true,
            barWidth: 10,
            barGap: 50,
            smooth: true,
            valueAnimation: true,
            showBackground: true,
            // Y轴数字显示部分
            label: {
              interval: 0,
              show: true,
              position: 'right',
              valueAnimation: true,
              color: color,
              fontSize: 12
            },
            emphasis: {
              itemStyle: {
                borderRadius: 7
              }
            },
            itemStyle: {
              // 颜色样式部分
              borderRadius: 7,
              color: color
            }
          }
        ]
      }
      this.buildChart(id, option)
    },
    buildChart(id, option) {
      if (document.querySelector('#' + id)) {
        var _option = option || []
        var myChart = echarts.init(document.getElementById(id))
        if (_option && typeof _option === 'object') {
          myChart.setOption(_option, true)
        }
      }
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
    },
    onChangeSearch() {
      this.onChangeSelectTime()
      this.getData()
    },
    onClickConfBtn(){
      this.$router.push('/sys-report-conf')
    },
  }
}
</script>

<style>
#attack-geoip,
#count-trend {
  width: 100%;
  height: 300px;
}

#api-top,
#type-top,
#ip-top,
#isocode-top {
  width: 100%;
  height: 300px;
}

.echart-container .el-card__header {
  color: #fff;
  border-bottom: none;
  font-weight: bolder;
}

.echart-container .el-card__body {
  padding: 0px;
}

.echart-container .card-text {
  font-size: 32px;
  font-weight: 600;
  color: #24292e;
  letter-spacing: -0.5px;
  line-height: 1;
}

.echart-container .text-align-right {
  margin-bottom: 15px;
}
.echart-container .el-card {
  position: relative;
}

.echart-container .empty-box {
  position: absolute;
  width: 100%;
}
.echart-container .card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 3px;
}
.echart-container .card-red::before {
    background: #F56C6C;
}
.echart-container .card-yellow::before {
    background: #E6A23C;
}
.echart-container .card-green::before {
    background: #67C23A;
}
.echart-container .card-blue::before {
    background: #409EFF;
}
.echart-container .card{
  border-radius: 12px;
  padding: 24px;
  background: #fff;
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: 140px;
}
.echart-container .card-header {
    font-size: 13px;
    margin-bottom: 16px;
    font-weight: 500;
    color: #606266;
    letter-spacing: 0.5px;
}
.echart-container .card-content {
    display: flex;
    align-items: flex-end;
    justify-content: space-between;
    margin-top: 30px;
}
.echart-container .card-text-wrapper {
    position: relative;
    display: flex;
    align-items: baseline;
    gap: 8px;
}
.echart-container .card-red .card-text {
    color: #F56C6C;
}
.echart-container .card-yellow .card-text {
    color: #E6A23C;
}
.echart-container .card-green .card-text {
    color: #67C23A;
}
.echart-container .card-blue .card-text {
    color: #409EFF;
}
.echart-container .card-badge {
    display: flex;
    align-items: center;
    gap: 3px;
    font-size: 13px;
    font-weight: 500;
    white-space: nowrap;
    padding: 4px 8px;
    border-radius: 4px;
    background: rgba(0, 0, 0, 0.04);
}
.echart-container .trend-up {
    color: #F56C6C;
}
.echart-container .trend-down {
    color: #67C23A;
}
.echart-container .trend-stable {
    color: #909399;
}
.echart-container .card-badge-icon {
  display: flex;
  width: 12px;
  height: 12px;
  margin-right: 2px;
  align-items: center;
}

.echart-container .chart-card {
    border-radius: 12px;
    padding: 0;
    background: #fff;
    overflow: hidden;
}
.echart-container .chart-card-header {
    padding: 16px 24px;
    color: #24292e;
    font-weight: 600;
    font-size: 15px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid #e1e4e8;
}
.echart-container .chart-card-header span {
  color: #24292e;
  font-weight: 600;
}
.echart-container .chart-card-body {
    padding: 0;
    position: relative;
}
</style>
