<template>
  <div class="usage-stat-page">
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>数据统计</el-breadcrumb-item>
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
          <el-card class="card card-blue" shadow="hover" v-loading="loading.overview">
            <div class="card-header"><span>总请求数</span></div>
            <div class="card-content">
              <div class="dual-block">
                <div class="dual-item">
                  <div class="dual-label">总计</div>
                  <div class="dual-value">{{ formatNumber(overview.total_request) }}</div>
                </div>
                <div class="dual-divider"></div>
                <div class="dual-item">
                  <div class="dual-label">平均QPS</div>
                  <div class="dual-value">{{ formatAvgQps(overview.total_request) }}</div>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="card card-green" shadow="hover" v-loading="loading.overview">
            <div class="card-header"><span>总带宽</span></div>
            <div class="card-content">
              <div class="dual-block">
                <div class="dual-item">
                  <div class="dual-label">入网</div>
                  <div class="dual-value">{{ formatBandwidth(overview.traffic_in, overview.traffic_out).in }}<span class="dual-unit">Mbps</span></div>
                </div>
                <div class="dual-divider"></div>
                <div class="dual-item">
                  <div class="dual-label">出网</div>
                  <div class="dual-value">{{ formatBandwidth(overview.traffic_in, overview.traffic_out).out }}<span class="dual-unit">Mbps</span></div>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="card card-yellow" shadow="hover" v-loading="loading.overview">
            <div class="card-header"><span>时延</span></div>
            <div class="card-content">
              <div class="dual-block">
                <div class="dual-item">
                  <div class="dual-label">请求</div>
                  <div class="dual-value">{{ overview.request_latency_avg || 0 }}<span class="dual-unit">ms</span></div>
                </div>
                <div class="dual-divider"></div>
                <div class="dual-item">
                  <div class="dual-label">回源</div>
                  <div class="dual-value">{{ overview.upstream_latency_avg || 0 }}<span class="dual-unit">ms</span></div>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="card card-red" shadow="hover" v-loading="loading.overview">
            <div class="card-header"><span>状态码分布</span></div>
            <div class="card-content">
              <div class="status-bar-list">
                <div class="status-bar-row">
                  <span class="status-dot s2xx"></span>
                  <span class="status-label">2xx</span>
                  <span class="status-value">{{ formatStatusPercent(overview, '2xx') }}</span>
                  <div class="status-bar-track">
                    <div class="status-bar-fill s2xx" :style="{ width: formatStatusPercent(overview, '2xx') }"></div>
                  </div>
                  <span class="status-count">{{ overview.status_2xx || 0 }}</span>
                </div>
                <div class="status-bar-row">
                  <span class="status-dot s3xx"></span>
                  <span class="status-label">3xx</span>
                  <span class="status-value">{{ formatStatusPercent(overview, '3xx') }}</span>
                  <div class="status-bar-track">
                    <div class="status-bar-fill s3xx" :style="{ width: formatStatusPercent(overview, '3xx') }"></div>
                  </div>
                  <span class="status-count">{{ overview.status_3xx || 0 }}</span>
                </div>
                <div class="status-bar-row">
                  <span class="status-dot s4xx"></span>
                  <span class="status-label">4xx</span>
                  <span class="status-value">{{ formatStatusPercent(overview, '4xx') }}</span>
                  <div class="status-bar-track">
                    <div class="status-bar-fill s4xx" :style="{ width: formatStatusPercent(overview, '4xx') }"></div>
                  </div>
                  <span class="status-count">{{ overview.status_4xx || 0 }}</span>
                </div>
                <div class="status-bar-row">
                  <span class="status-dot s5xx"></span>
                  <span class="status-label">5xx</span>
                  <span class="status-value">{{ formatStatusPercent(overview, '5xx') }}</span>
                  <div class="status-bar-track">
                    <div class="status-bar-fill s5xx" :style="{ width: formatStatusPercent(overview, '5xx') }"></div>
                  </div>
                  <span class="status-count">{{ overview.status_5xx || 0 }}</span>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>

      <el-row :gutter="15" style="margin-top: 15px">
        <el-col :span="24">
          <el-card class="chart-card qps-card" shadow="hover" v-loading="loading.qps">
            <div class="chart-card-header"><span>QPS 趋势</span></div>
            <div v-if="qpsRecords.length == 0" class="empty-box">
              <el-empty description="NO DATA" />
            </div>
            <div id="qps-trend"></div>
          </el-card>
        </el-col>
      </el-row>

      <el-row :gutter="15" style="margin-top: 15px">
        <el-col :span="24">
          <el-card class="chart-card bandwidth-card" shadow="hover" v-loading="loading.bandwidth">
            <div class="chart-card-header"><span>带宽趋势 (Mbps)</span></div>
            <div v-if="bandwidthRecords.length == 0" class="empty-box">
              <el-empty description="NO DATA" />
            </div>
            <div id="bandwidth-trend"></div>
          </el-card>
        </el-col>
      </el-row>

      <el-row :gutter="15" style="margin-top: 15px">
        <el-col :span="24">
          <el-card class="chart-card latency-card" shadow="hover" v-loading="loading.latency">
            <div class="chart-card-header"><span>时延趋势 (ms)</span></div>
            <div v-if="latencyRecords.length == 0" class="empty-box">
              <el-empty description="NO DATA" />
            </div>
            <div id="latency-trend"></div>
          </el-card>
        </el-col>
      </el-row>

      <el-row :gutter="15" style="margin-top: 15px">
        <el-col :span="24">
          <el-card class="chart-card status-card" shadow="hover" v-loading="loading.status">
            <div class="chart-card-header"><span>状态码分布趋势</span></div>
            <div v-if="statusRecords.length == 0" class="empty-box">
              <el-empty description="NO DATA" />
            </div>
            <div id="status-trend"></div>
          </el-card>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script>
import echarts from '../assets/scripts/echart'
import { mixin, JXAjax, formatterDateTime } from '../assets/scripts/common'

export default {
  mixins: [mixin],
  data() {
    return {
      loadingPage: false,
      isShowSelectTime: true,
      valueTime: '24h',
      pickerTime: [],
      optionTime: [
        { value: '1h', label: '近1小时' },
        { value: '6h', label: '近6小时' },
        { value: '24h', label: '近24小时' },
        { value: '7d', label: '近7天' },
        { value: 'default', label: '自定义' }
      ],
      loading: {
        overview: false,
        qps: false,
        bandwidth: false,
        status: false,
        latency: false
      },
      overview: {},
      qpsRecords: [],
      bandwidthRecords: [],
      statusRecords: [],
      latencyRecords: [],
      resizeHandler: null
    }
  },
  beforeUnmount() {
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler)
    }
    const chartIds = ['qps-trend', 'bandwidth-trend', 'status-trend', 'latency-trend']
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
    this.onChangeSelectTime()
    this.getData()
    this.resizeHandler = () => {
      const chartIds = ['qps-trend', 'bandwidth-trend', 'status-trend', 'latency-trend']
      chartIds.forEach(id => {
        const chartDom = document.getElementById(id)
        if (chartDom) {
          const chart = echarts.getInstanceByDom(chartDom)
          if (chart) {
            chart.resize()
          }
        }
      })
    }
    window.addEventListener('resize', this.resizeHandler)
  },
  methods: {
    onChangeSelectTime() {
      var t = this
      if (t.valueTime == 'default') {
        t.isShowSelectTime = false
        t.pickerTime = [new Date(new Date().getTime() - 60 * 60 * 1000), new Date()]
      } else {
        t.isShowSelectTime = true
        if (t.valueTime == '1h') {
          t.pickerTime = [new Date(new Date().getTime() - 1 * 60 * 60 * 1000), new Date()]
        }
        if (t.valueTime == '6h') {
          t.pickerTime = [new Date(new Date().getTime() - 6 * 60 * 60 * 1000), new Date()]
        }
        if (t.valueTime == '24h') {
          t.pickerTime = [new Date(new Date().getTime() - 24 * 60 * 60 * 1000), new Date()]
        }
        if (t.valueTime == '7d') {
          t.pickerTime = [new Date(new Date().getTime() - 24 * 60 * 60 * 1000 * 7), new Date()]
        }
      }
    },
    changeTimeline(event) {
      var t = this
      if (event == null) {
        t.isShowSelectTime = true
        t.valueTime = '24h'
      } else {
        t.isShowSelectTime = false
      }
    },
    onChangeSearch() {
      this.onChangeSelectTime()
      this.getData()
    },
    getData() {
      this.getOverview()
      this.getQpsTrend()
      this.getBandwidthTrend()
      this.getStatusDistribution()
      this.getLatencyTrend()
    },
    buildParams(extra) {
      var _data = extra || {}
      return _data
    },
    getOverview() {
      var t = this
      t.loading.overview = true
      var _data = t.buildParams({
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      })
      JXAjax(
        'post',
        '/user/get_soc_usage_stat_overview',
        _data,
        function (response) {
          t.loading.overview = false
          var data = response.data
          t.overview = data.overview || {}
        },
        function () {
          t.loading.overview = false
        },
        'no-message'
      )
    },
    getQpsTrend() {
      var t = this
      t.loading.qps = true
      var _data = t.buildParams({
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      })
      JXAjax(
        'post',
        '/user/get_soc_usage_stat_qps_trend',
        _data,
        function (response) {
          t.loading.qps = false
          t.qpsRecords = response.data.records || []
          t.initLineChart(t.qpsRecords, 'qps-trend', 'total_request', 'QPS', '#409EFF')
        },
        function () {
          t.loading.qps = false
        },
        'no-message'
      )
    },
    getBandwidthTrend() {
      var t = this
      t.loading.bandwidth = true
      var _data = t.buildParams({
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      })
      JXAjax(
        'post',
        '/user/get_soc_usage_stat_bandwidth_trend',
        _data,
        function (response) {
          t.loading.bandwidth = false
          t.bandwidthRecords = response.data.records || []
          t.initMultiLineChart(t.bandwidthRecords, 'bandwidth-trend', [
            { key: 'traffic_in', name: '入网带宽', color: '#67C23A' },
            { key: 'traffic_out', name: '出网带宽', color: '#E6A23C' }
          ], 'Mbps')
        },
        function () {
          t.loading.bandwidth = false
        },
        'no-message'
      )
    },
    getStatusDistribution() {
      var t = this
      t.loading.status = true
      var _data = t.buildParams({
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      })
      JXAjax(
        'post',
        '/user/get_soc_usage_stat_status_distribution',
        _data,
        function (response) {
          t.loading.status = false
          t.statusRecords = response.data.records || []
          t.initStatusLineChart(t.statusRecords, 'status-trend')
        },
        function () {
          t.loading.status = false
        },
        'no-message'
      )
    },
    getLatencyTrend() {
      var t = this
      t.loading.latency = true
      var _data = t.buildParams({
        from_time: formatterDateTime(t.pickerTime[0]),
        to_time: formatterDateTime(t.pickerTime[1])
      })
      JXAjax(
        'post',
        '/user/get_soc_usage_stat_latency_trend',
        _data,
        function (response) {
          t.loading.latency = false
          t.latencyRecords = response.data.records || []
          t.initMultiLineChart(t.latencyRecords, 'latency-trend', [
            { key: 'request_latency_avg', name: '请求总耗时', color: '#409EFF' },
            { key: 'upstream_latency_avg', name: '回源耗时', color: '#E6A23C' }
          ], 'ms')
        },
        function () {
          t.loading.latency = false
        },
        'no-message'
      )
    },
    buildXAxis(data) {
      return {
        type: 'category',
        data: data,
        boundaryGap: false,
        axisLine: { lineStyle: { color: '#dcdfe6' } },
        axisLabel: {
          color: '#909399',
          fontSize: 11,
          hideOverlap: true,
          formatter: function (value) {
            if (value && value.length >= 19) {
              return value.slice(11, 16)
            }
            return value
          }
        }
      }
    },
    initLineChart(data, id, valueKey, seriesName, color) {
      var x = []
      var y = []
      data.forEach((item) => {
        x.push(item.stat_time)
        var v = item[valueKey]
        if (valueKey === 'total_request') {
          v = v ? parseFloat((v / 60).toFixed(2)) : 0
        } else {
          v = this.bytesToMbps(v)
        }
        y.push(v)
      })
      var option = {
        color: [color],
        tooltip: { trigger: 'axis' },
        xAxis: this.buildXAxis(x),
        grid: { containLabel: true, bottom: 30 },
        yAxis: {
          type: 'value',
          name: seriesName,
          axisLine: { show: true, lineStyle: { color: '#dcdfe6' } },
          axisTick: { show: false },
          axisLabel: { color: '#909399', fontSize: 11 }
        },
        series: [{
          name: seriesName,
          data: y,
          type: 'line',
          smooth: true,
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: color },
              { offset: 0.5, color: this.lightenColor(color) },
              { offset: 1, color: '#ffeaea' }
            ])
          }
        }]
      }
      this.buildChart(id, option)
    },
    initMultiLineChart(data, id, series, yAxisName) {
      var x = []
      data.forEach((item) => { x.push(item.stat_time) })
      var colors = series.map(s => s.color)
      var seriesData = series.map(s => {
        return {
          name: s.name,
          type: 'line',
          smooth: true,
          data: data.map(item => {
            var v = item[s.key]
            if (yAxisName === 'Mbps') {
              return this.bytesToMbps(v)
            }
            return v || 0
          }),
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: s.color },
              { offset: 0.5, color: this.lightenColor(s.color) },
              { offset: 1, color: '#ffeaea' }
            ])
          }
        }
      })
      var option = {
        color: colors,
        tooltip: { trigger: 'axis' },
        legend: { data: series.map(s => s.name) },
        xAxis: this.buildXAxis(x),
        grid: { containLabel: true, bottom: 30 },
        yAxis: {
          type: 'value',
          name: yAxisName,
          axisLine: { show: true, lineStyle: { color: '#dcdfe6' } },
          axisTick: { show: false },
          axisLabel: { color: '#909399', fontSize: 11 }
        },
        series: seriesData
      }
      this.buildChart(id, option)
    },
    initStatusLineChart(data, id) {
      var x = []
      data.forEach((item) => { x.push(item.stat_time) })
      var series = [
        { key: 'status_2xx', name: '2xx', color: '#67C23A' },
        { key: 'status_3xx', name: '3xx', color: '#409EFF' },
        { key: 'status_4xx', name: '4xx', color: '#E6A23C' },
        { key: 'status_5xx', name: '5xx', color: '#F56C6C' }
      ]
      var seriesData = series.map(s => {
        return {
          name: s.name,
          type: 'line',
          smooth: true,
          data: data.map(item => item[s.key] || 0),
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: s.color },
              { offset: 0.5, color: this.lightenColor(s.color) },
              { offset: 1, color: '#ffeaea' }
            ])
          }
        }
      })
      var option = {
        color: series.map(s => s.color),
        tooltip: { trigger: 'axis' },
        legend: { data: series.map(s => s.name) },
        xAxis: this.buildXAxis(x),
        grid: { containLabel: true, bottom: 30 },
        yAxis: {
          type: 'value',
          name: '请求数',
          axisLine: { show: true, lineStyle: { color: '#dcdfe6' } },
          axisTick: { show: false },
          axisLabel: { color: '#909399', fontSize: 11 }
        },
        series: seriesData
      }
      this.buildChart(id, option)
    },
    buildChart(id, option) {
      if (document.querySelector('#' + id)) {
        var _option = option || []
        var chartDom = document.getElementById(id)
        var myChart = echarts.getInstanceByDom(chartDom)
        if (myChart) {
          myChart.dispose()
        }
        myChart = echarts.init(chartDom)
        if (_option && typeof _option === 'object') {
          myChart.setOption(_option, true)
        }
      }
    },
    bytesToMbps(bytes) {
      if (!bytes) return 0
      return parseFloat((bytes * 8 / 60 / 1024 / 1024).toFixed(2))
    },
    lightenColor(color) {
      var map = {
        '#409EFF': '#79bbff',
        '#67C23A': '#95d475',
        '#E6A23C': '#eebe77',
        '#F56C6C': '#f89898'
      }
      return map[color] || color
    },
    formatBandwidth(trafficIn, trafficOut) {
      var inMbps = this.bytesToMbps(trafficIn)
      var outMbps = this.bytesToMbps(trafficOut)
      return {
        in: inMbps.toFixed(2),
        out: outMbps.toFixed(2),
        total: (inMbps + outMbps).toFixed(2)
      }
    },
    formatNumber(num) {
      if (!num) return '0'
      return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',')
    },
    formatStatusPercent(overview, type) {
      var total = parseInt(overview.total_request) || 0
      var val = parseInt(overview['status_' + type]) || 0
      if (total == 0) return '0%'
      return ((val / total) * 100).toFixed(1) + '%'
    },
    formatAvgQps(totalRequest) {
      if (!totalRequest) return '0'
      if (!this.pickerTime || !this.pickerTime[0] || !this.pickerTime[1]) return '0'
      var seconds = (this.pickerTime[1].getTime() - this.pickerTime[0].getTime()) / 1000
      if (seconds <= 0) return '0'
      return (totalRequest / seconds).toFixed(2)
    }
  }
}
</script>

<style>
#qps-trend,
#bandwidth-trend,
#status-trend,
#latency-trend {
  width: 100%;
  height: 300px;
}

.usage-stat-page .card .card-content {
  min-height: 110px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.usage-stat-page .card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 3px;
}
.usage-stat-page .card-red::before {
    background: #F56C6C;
}
.usage-stat-page .card-yellow::before {
    background: #E6A23C;
}
.usage-stat-page .card-green::before {
    background: #67C23A;
}
.usage-stat-page .card-blue::before {
    background: #409EFF;
}
.usage-stat-page .card{
  border-radius: 12px;
  padding: 24px;
  background: #fff;
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: 140px;
}
.usage-stat-page .el-card__body {
  padding: 0px;
}
.usage-stat-page  .card-header {
    font-size: 13px;
    margin-bottom: 16px;
    font-weight: 500;
    color: #606266;
    letter-spacing: 0.5px;
}
.usage-stat-page .dual-block {
  display: flex;
  align-items: stretch;
}

.usage-stat-page .dual-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 0 8px;
}

.usage-stat-page .dual-item:first-child {
  padding-left: 0;
}

.usage-stat-page .dual-item:last-child {
  padding-right: 0;
}

.usage-stat-page .dual-label {
  font-size: 13px;
  color: #909399;
  margin-bottom: 4px;
}

.usage-stat-page .dual-value {
  font-size: 28px;
  font-weight: 600;
  color: #24292e;
  line-height: 1.2;
  display: flex;
  align-items: baseline;
  gap: 4px;
}

.usage-stat-page .dual-unit {
  font-size: 13px;
  color: #909399;
  font-weight: normal;
}

.usage-stat-page .dual-divider {
  width: 1px;
  background: #e4e7ed;
  margin: 4px 0;
}

.usage-stat-page .status-bar-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.usage-stat-page .status-bar-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
}

.usage-stat-page .status-bar-row .status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.usage-stat-page .status-bar-row .status-dot.s2xx { background: #67c23a; }
.usage-stat-page .status-bar-row .status-dot.s3xx { background: #409eff; }
.usage-stat-page .status-bar-row .status-dot.s4xx { background: #e6a23c; }
.usage-stat-page .status-bar-row .status-dot.s5xx { background: #f56c6c; }

.usage-stat-page .status-bar-row .status-label {
  color: #606266;
  font-weight: 500;
  min-width: 28px;
}

.usage-stat-page .status-bar-row .status-value {
  color: #24292e;
  font-weight: 600;
  min-width: 42px;
}

.usage-stat-page .status-bar-row .status-bar-track {
  flex: 1;
  height: 6px;
  background: #f0f2f5;
  border-radius: 3px;
  overflow: hidden;
}

.usage-stat-page .status-bar-row .status-bar-fill {
  height: 100%;
  border-radius: 3px;
  transition: width 0.3s ease;
}

.usage-stat-page .status-bar-row .status-bar-fill.s2xx { background: #67c23a; }
.usage-stat-page .status-bar-row .status-bar-fill.s3xx { background: #409eff; }
.usage-stat-page .status-bar-row .status-bar-fill.s4xx { background: #e6a23c; }
.usage-stat-page .status-bar-row .status-bar-fill.s5xx { background: #f56c6c; }

.usage-stat-page .status-bar-row .status-count {
  color: #909399;
  font-size: 12px;
  min-width: 36px;
  text-align: right;
}
.usage-stat-page .chart-card-header {
    padding: 16px 24px;
    color: #24292e;
    font-weight: 600;
    font-size: 15px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid #e1e4e8;
}
.usage-stat-page .chart-card-header span {
  color: #24292e;
  font-weight: 600;
}
</style>
