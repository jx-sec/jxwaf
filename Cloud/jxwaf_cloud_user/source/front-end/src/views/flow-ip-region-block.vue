<template>
  <div class="page-owasp-wrap">
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>防护配置</el-breadcrumb-item>
        <el-breadcrumb-item>IP区域封禁</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>

    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <div>
          <el-form
            :model="flowIpRegionBlockForm"
            :rules="rules"
            ref="flowIpRegionBlockForm"
            label-width="120px"
            class="flow-ip-region-block-form"
          >
            <el-form-item label="IP区域封禁状态">
              <el-switch
                v-model="flowIpRegionBlockForm.ip_region_block"
                active-value="true"
                inactive-value="false"
              ></el-switch>
            </el-form-item>
            <div v-show="flowIpRegionBlockForm.ip_region_block == 'true'">
              <el-form-item label="匹配模式">
                <el-radio-group v-model="flowIpRegionBlockForm.check_model">
                  <el-radio value="white">白名单模式</el-radio>
                  <el-radio value="black">黑名单模式</el-radio>
                </el-radio-group>
              </el-form-item>
              <el-form-item label="名单区域">
                <el-checkbox v-model="checkAll" @change="handleCheckAllChange" class="checked-all">全选</el-checkbox>
                <el-tabs v-model="activeName" class="geoip-select-country">
                  <el-tab-pane
                    v-for="(item, kinds) in countries"
                    :label="kinds"
                    :name="kinds"
                    :key="kinds"
                  >
                    <dl v-for="(couns, kind) in item" :key="kind">
                      <dt>{{ kind }}</dt>
                      <dd>
                        <el-checkbox
                          v-for="country in couns"
                          :label="country.name"
                          :key="country.code"
                          @change="selectCountry($event, country)"
                          v-model="country.checked"
                          :class="'country-' + country.code"
                          >{{ country.name }}</el-checkbox
                        >
                      </dd>
                    </dl>
                  </el-tab-pane>
                </el-tabs>
              </el-form-item>
              <el-form-item label="名单区域" v-show="blackCountryList.length > 0">
                <el-tag
                  v-for="tag in blackCountryList"
                  :key="tag.code"
                  closable
                  @close="handleClose(tag)"
                  >{{ tag.name }}</el-tag
                >
              </el-form-item>
              <el-form-item label="执行动作" prop="block_action">
              <el-select
                v-model="flowIpRegionBlockForm.block_action"
                placeholder="请选择"
                @change="onChangeRuleAction()"
                >
                  <el-option
                    v-for="item in ruleAction"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value"
                  >
                  </el-option>
                </el-select>
              </el-form-item>
              <el-form-item v-if="flowIpRegionBlockForm.block_action == 'bot_check'">
                <el-select v-model="action_value" placeholder="请选择">
                  <el-option
                    v-for="item in optionsBotCheck"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value"
                  >
                  </el-option>
                </el-select>
              </el-form-item>
              <el-form-item
                v-if="flowIpRegionBlockForm.block_action == 'network_block'"
                label="网络封禁持续时间（秒）"
                class="is-required"
              >
                <el-input v-model="action_value" placeholder="请输入大于0的数字"> </el-input>
              </el-form-item>
            </div>
            
          </el-form>
        </div>

        <el-row type="flex" class="margin-border" justify="space-between">
          <el-col :span="12">
            
          </el-col>
          <el-col :span="12" class="text-align-right">
            <el-button
              type="primary"
              @click="onClickflowIpRegionBlockFormSubmit('flowIpRegionBlockForm')"
              :loading="loading"
              >保存</el-button
            >
          </el-col>
        </el-row>
      </el-col>
    </el-row>
  </div>
</template>
<script>
import { mixin, JXAjax } from '../assets/scripts/common'
import data from '../assets/scripts/country.json'
import { useRoute } from 'vue-router'
const REGEXP = {
  0: /^[A-C]$/i,
  1: /^[D-F]$/i,
  2: /^[G-I]$/i,
  3: /^[J-L]$/i,
  4: /^[M-N]$/i,
  5: /^[O-Q]$/i,
  6: /^[R-T]$/i,
  7: /^[U-W]$/i,
  8: /^[X-Z]$/i
}

export default {
  mixins: [mixin],
  data() {
    return {
      loadingPage: false,
      loading: false,
      flowIpRegionBlockForm: {
      },
      ruleAction: [
        { value: 'block', label: '阻断请求' },
        { value: 'reject_response', label: '拒绝响应' },
        { value: 'watch', label: '观察模式' },
        { value: 'bot_check', label: '人机识别' },
      ],
      optionsBotCheck: [
        { value: 'auto', label: '无交互验证' },
        { value: 'slipper', label: '滑块验证' },
        { value: 'puzzle', label: '拼图验证' },
        { value: 'words', label: '选字验证' },
      ],
      data: data,
      countries: {},
      activeName: 'ABC',
      blackCountryList: [],
      geoipForm: {},
      action_value: '',
      checkAll: false
    }
  },
  computed: {
    rules() {
      return {
        block_action: [
          {
            required: true,
            message: '请选择执行动作',
            trigger: 'change'
          }
        ]
      }
    }
  },

  mounted() {
    const route = useRoute()
    this.getData()
    this.formatCountry()
  },
  methods: {
    getData() {
      var t = this
      var url = '/user/get_flow_ip_region_block'
      var postData = {  }
      t.blackCountryList = []
      JXAjax(
        'post',
        url,
        postData,
        function (response) {
          t.loadingPage = false
          t.flowIpRegionBlockForm = response.data.message
          //执行动作
          if (t.flowIpRegionBlockForm.block_action == 'bot_check') {
            t.action_value = t.flowIpRegionBlockForm.action_value
          }
          if (t.flowIpRegionBlockForm.block_action == 'network_block') {
            t.action_value = t.flowIpRegionBlockForm.action_value
          }
          //白名单区域
          t.stringToArr(t.flowIpRegionBlockForm.country_list)
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    onChangeRuleAction() {
      var t = this
      t.action_value = ''
    },
    onClickflowIpRegionBlockFormSubmit(flowIpRegionBlockForm) {
      var t = this
      var url = '/user/edit_flow_ip_region_block'
      if (t.flowIpRegionBlockForm.block_action == 'bot_check' && t.action_value == '') {
        t.$message({
          message: '请选择人机识别方式',
          type: 'error'
        })
        return false
      }
      if (t.flowIpRegionBlockForm.block_action == 'network_block') {
        let r = /^\+?[1-9][0-9]*$/ //正整数
        let flag = r.test(t.action_value)
        if (!flag) {
          t.$message({
            message: '请输入大于0的数字',
            type: 'error'
          })
          return false
        }
      }

      this.flowIpRegionBlockForm.country_list = JSON.stringify(t.jsonToArr(t.blackCountryList))
      if (t.flowIpRegionBlockForm.block_action == 'bot_check') {
        t.flowIpRegionBlockForm.action_value = t.action_value
      } else if (t.flowIpRegionBlockForm.block_action == 'network_block') {
        t.flowIpRegionBlockForm.action_value = t.action_value
      } else {
        t.flowIpRegionBlockForm.action_value = ''
      }
      this.$refs[flowIpRegionBlockForm].validate((valid) => {
        if (valid) {
          t.loading = true
          JXAjax(
            'post',
            url,
            t.flowIpRegionBlockForm,
            function (response) {
              t.loading = false
            },
            function () {
              t.loading = false
            }
          )
        }
      })
    },
    formatCountry() {
      let countries = {
        ABC: {},
        DEF: {},
        GHI: {},
        JKL: {},
        MN: {},
        OPQ: {},
        RST: {},
        UVW: {},
        XYZ: {}
      }

      let keys = Object.keys(countries)
      let initial = ''
      this.data.forEach((country, index) => {
        initial = this.getInitial(country)

        for (var i = 0; i < keys.length; i++) {
          if (REGEXP[i].test(initial)) {
            if (!countries[keys[i]][initial]) countries[keys[i]][initial] = []
            this.pushCountries(countries[keys[i]][initial], country)
            break
          }
        }
      })
      this.countries = countries
    },
    // 根据语言获取国家首字母，用来进行国家分类
    getInitial(country) {
      let initial = ''
      initial = country.cnSpell.substr(0, 1)
      return initial
    },

    // 根据语言向countries中push country
    pushCountries(arr, country) {
      if (this.checkAll) {
        arr.push({
          name: country.cnName,
          code: country.code,
          checked: true
        })
      } else {
        arr.push({
          name: country.cnName,
          code: country.code,
          checked: false
        })
      }
    },

    selectCountry(event, country) {
      if (event == true) {
        country.checked = true
        this.blackCountryList.push(country)
      } else {
        country.checked = false
        for (var i = 0; i < this.blackCountryList.length; i++) {
          if (this.blackCountryList[i].code == country.code) {
            this.blackCountryList.splice(i, 1)
            break
          }
        }
      }

      if (this.blackCountryList.length == this.data.length) {
        this.checkAll = true
      } else {
        this.checkAll = false
      }
    },
    handleClose(tag) {
      let scrollTop = window.scrollY
      document.querySelector('.country-' + tag.code).click()
      window.scrollTo(0, scrollTop)
    },

    handleAdd(tag) {
      let scrollTop = window.scrollY
      document.querySelector('.country-' + tag.code).click()
      window.scrollTo(0, scrollTop)
    },

    handleCheckAllChange(event) {
      this.blackCountryList = []
      for (var i = 0; i < this.data.length; i++) {
        var item = {}
        item.code = this.data[i].code
        item.name = this.data[i].cnName
        this.selectCountry(event, item)
      }
      this.formatCountry()
    },
    jsonToArr(data) {
      let t = this
      let arr = []
      data.forEach((country, index) => {
        arr.push(country.code)
      })
      return arr
    },
    arrToString(arr) {
      let countriesString = ''
      arr.forEach((item) => {
        countriesString = countriesString + '|' + item.code
      })
      countriesString = countriesString.substr(1)
      return countriesString
    },
    stringToArr(arr) {
      let t = this
      let arrStr = JSON.parse(arr) || []
      this.data.forEach((country, index) => {
        for (var i = 0; i < arrStr.length; i++) {
          var item = {}
          if (country.code == arrStr[i]) {
            item.name = country.cnName
            item.code = country.code
            item.checked = true
            t.handleAdd(item)
            break
          }
        }
      })
    }
  }
}
</script>
<style>
.flow-ip-region-block-form .el-select {
  width: 100%;
}
.flow-ip-region-block-form .checked-all {
  width: 100%;
}
.flow-ip-region-block-form .el-tag {
  margin-right: 10px;
  margin-bottom: 8px;
}
</style>
