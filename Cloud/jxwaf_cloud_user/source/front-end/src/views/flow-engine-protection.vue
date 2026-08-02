<template>
  <div class="flow-engine-wrap">
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>防护配置</el-breadcrumb-item>
        <el-breadcrumb-item>流量防护引擎</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>
    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <el-form
          class="flow-engine-form"
          :model="flowEngineForm"
          :rules="rules"
          ref="flowEngineForm"
          label-width="130px"
        >
          <el-form-item label="流量防护引擎状态">
            <el-switch
              v-model="engineStatus"
              active-value="true"
              inactive-value="false"
            ></el-switch>
          </el-form-item>
          <div v-if="engineStatus == 'true'">
            <el-form-item label="防护预案" class="is-required">
              <el-radio-group v-model="currentPlan" @change="onClickRadioGroup('flowEngineForm')">
                <el-radio-button label="daily_observe">日常观察</el-radio-button> 
                <el-radio-button label="daily_protect">日常防护</el-radio-button>
                <el-radio-button label="attack_protect">攻击防护</el-radio-button>
                <el-radio-button label="emergency_protect">紧急防护</el-radio-button>
              </el-radio-group>
            </el-form-item>
            <el-form-item></el-form-item>
            <el-divider border-style="dashed" content-position="center">防护功能配置</el-divider>
            <el-form-item label="IP访问限制">
              <el-switch
                v-model="flowEngineForm.ip_access_limit_status"
                active-value="true"
                inactive-value="false"
              ></el-switch>
            </el-form-item>
            <div v-if="flowEngineForm.ip_access_limit_status=='true'" class="form-box-fa">
              <el-form-item label="触发条件" class="is-required">
                统计时间
                <el-form-item prop="ip_access_limit_stat_time" class="form-item-inline">
                  <el-input-number class="input-num-margin" v-model="flowEngineForm.ip_access_limit_stat_time" :min="1" controls-position="right"/>
                </el-form-item>
                 秒，同一IP请求次数 > 
                <el-form-item prop="ip_access_limit_threshold" class="form-item-inline">
                  <el-input-number class="input-num-margin" v-model="flowEngineForm.ip_access_limit_threshold" :min="1" controls-position="right"/> 
                </el-form-item>
                次
              </el-form-item>
              <el-form-item label="执行动作" class="is-required">
                对该IP执行
                <el-form-item prop="ip_access_limit_action" class="form-item-inline">
                  <el-select @change="onChangeAction()" class="input-num-margin" v-model="flowEngineForm.ip_access_limit_action" placeholder="Select" style="margin-right: 0;">
                    <el-option
                      v-for="item in ruleAction"
                      :key="item.value"
                      :label="item.label"
                      :value="item.value"
                    />  
                  </el-select>
                </el-form-item>
                <el-form-item prop="ip_access_limit_action_extra_parameter" class="form-item-inline" v-if="flowEngineForm.ip_access_limit_action=='bot_check'">
                  <el-select class="input-num-margin" v-model="flowEngineForm.ip_access_limit_action_extra_parameter" placeholder="请选择" >
                    <el-option
                      v-for="item in optionsBotCheck"
                      :key="item.value"
                      :label="item.label"
                      :value="item.value"
                    >
                    </el-option>
                  </el-select> 
                </el-form-item>
                <span v-if="flowEngineForm.ip_access_limit_action=='network_block'" style="margin-left: 10px;">
                  封禁时间
                  <el-form-item class="form-item-inline" prop="ip_access_limit_action_extra_parameter_time">
                    <el-input-number class="input-num-margin" v-model="flowEngineForm.ip_access_limit_action_extra_parameter_time" :min="1" controls-position="right"/> 秒
                  </el-form-item>
                </span>
                
                ，持续时间
                <el-form-item class="form-item-inline" prop="ip_access_limit_duration">
                  <el-input-number class="input-num-margin" v-model="flowEngineForm.ip_access_limit_duration" :min="1" controls-position="right"/> 秒
                </el-form-item>
              </el-form-item>
            </div>
            <el-form-item label="IP数量限制">
              <el-switch
                v-model="flowEngineForm.ip_count_limit_status"
                active-value="true"
                inactive-value="false"
              ></el-switch>
            </el-form-item>
            <div v-if="flowEngineForm.ip_count_limit_status=='true'" class="form-box-fa">
              <el-form-item label="触发条件" class="is-required">
                统计时间
                <el-form-item prop="ip_count_limit_stat_time" class="form-item-inline">
                  <el-input-number class="input-num-margin" v-model="flowEngineForm.ip_count_limit_stat_time" :min="1" controls-position="right"/> 
                </el-form-item>
                秒，访问的独立IP数 > 
                <el-form-item prop="ip_count_limit_threshold" class="form-item-inline">
                  <el-input-number class="input-num-margin" v-model="flowEngineForm.ip_count_limit_threshold" :min="1" controls-position="right"/> 次
                </el-form-item>
                
              </el-form-item>
              <el-form-item label="执行动作" class="is-required">
                对超出限制的新访问IP执行
                <el-form-item prop="ip_count_limit_action" class="form-item-inline">
                  <el-select @change="onChangeAction()" class="input-num-margin" v-model="flowEngineForm.ip_count_limit_action" placeholder="Select" style="margin-right: 0;">
                    <el-option
                      v-for="item in ruleAction"
                      :key="item.value"
                      :label="item.label"
                      :value="item.value"
                    />  
                  </el-select>
                </el-form-item>
                <el-form-item prop="ip_count_limit_action_extra_parameter" class="form-item-inline">
                  <el-select class="input-num-margin" v-model="flowEngineForm.ip_count_limit_action_extra_parameter" placeholder="请选择" v-if="flowEngineForm.ip_count_limit_action=='bot_check'">
                    <el-option
                      v-for="item in optionsBotCheck"
                      :key="item.value"
                      :label="item.label"
                      :value="item.value"
                    >
                    </el-option>
                  </el-select>
                </el-form-item> 
                <span v-if="flowEngineForm.ip_count_limit_action=='network_block'" style="margin-left: 10px;">
                  封禁时间
                  <el-form-item class="form-item-inline" prop="ip_count_limit_action_extra_parameter_time">
                    <el-input-number class="input-num-margin" v-model="flowEngineForm.ip_count_limit_action_extra_parameter_time" :min="1" controls-position="right"/> 秒
                  </el-form-item>
                </span>
              </el-form-item>
            </div>
            <el-form-item label="域名访问限制">
              <el-switch
                v-model="flowEngineForm.domain_access_limit_status"
                active-value="true"
                inactive-value="false"
              ></el-switch>
            </el-form-item>
            <div v-if="flowEngineForm.domain_access_limit_status=='true'" class="form-box-fa">
              <el-form-item label="触发条件" class="is-required">
                统计时间
                <el-form-item prop="domain_access_limit_stat_time" class="form-item-inline">
                  <el-input-number class="input-num-margin" v-model="flowEngineForm.domain_access_limit_stat_time" :min="1" controls-position="right"/>
                </el-form-item>
                 秒，对同一域名的请求次数 > 
                <el-form-item prop="domain_access_limit_threshold" class="form-item-inline">
                  <el-input-number class="input-num-margin" v-model="flowEngineForm.domain_access_limit_threshold" :min="1" controls-position="right"/> 次
                </el-form-item>
              </el-form-item>
              <el-form-item label="执行动作" class="is-required">
                对超出限制的请求执行
                <el-form-item prop="domain_access_limit_action" class="form-item-inline">
                  <el-select class="input-num-margin" v-model="flowEngineForm.domain_access_limit_action" placeholder="Select" style="margin-right: 0;">
                    <el-option
                      v-for="item in ruleAction"
                      :key="item.value"
                      :label="item.label"
                      :value="item.value"
                    />  
                  </el-select>
                </el-form-item>
                <el-form-item prop="domain_access_limit_action_extra_parameter" class="form-item-inline">
                  <el-select  @change="onChangeAction()" class="input-num-margin" v-model="flowEngineForm.domain_access_limit_action_extra_parameter" placeholder="请选择" v-if="flowEngineForm.domain_access_limit_action=='bot_check'">
                    <el-option
                      v-for="item in optionsBotCheck"
                      :key="item.value"
                      :label="item.label"
                      :value="item.value"
                    >
                    </el-option>
                  </el-select>
                </el-form-item>
                <span v-if="flowEngineForm.domain_access_limit_action=='network_block'" style="margin-left: 10px;">
                  封禁时间
                  <el-form-item class="form-item-inline" prop="domain_access_limit_action_extra_parameter_time">
                    <el-input-number class="input-num-margin" v-model="flowEngineForm.domain_access_limit_action_extra_parameter_time" :min="1" controls-position="right"/> 秒
                  </el-form-item>
                </span>
              </el-form-item>
            </div>
            <el-form-item label="SSL指纹防护">
              <el-switch
                v-model="flowEngineForm.ssl_fingerprint_protection_status"
                active-value="true"
                inactive-value="false"
              ></el-switch>
            </el-form-item>
            <div v-if="flowEngineForm.ssl_fingerprint_protection_status=='true'" class="form-box-fa">
              <el-form-item label="触发条件" class="is-required">
                检测到非浏览器的SSL指纹，即脚本、爬虫或自动化工具等
              </el-form-item>
              <el-form-item label="执行动作" class="is-required">
                对非浏览器SSL指纹访问执行
                <el-form-item prop="ssl_fingerprint_protection_action" class="form-item-inline">
                  <el-select class="input-num-margin" v-model="flowEngineForm.ssl_fingerprint_protection_action" placeholder="Select" style="margin-right: 0;">
                    <el-option
                      v-for="item in ruleAction"
                      :key="item.value"
                      :label="item.label"
                      :value="item.value"
                    />  
                  </el-select>
                </el-form-item>
                <el-form-item prop="ssl_fingerprint_protection_action_extra_parameter" class="form-item-inline">
                  <el-select  @change="onChangeAction()" class="input-num-margin" v-model="flowEngineForm.ssl_fingerprint_protection_action_extra_parameter" placeholder="请选择" v-if="flowEngineForm.ssl_fingerprint_protection_action=='bot_check'">
                    <el-option
                      v-for="item in optionsBotCheck"
                      :key="item.value"
                      :label="item.label"
                      :value="item.value"
                    >
                    </el-option>
                  </el-select>
                </el-form-item>
                <span v-if="flowEngineForm.ssl_fingerprint_protection_action=='network_block'" style="margin-left: 10px;">
                  封禁时间
                  <el-form-item class="form-item-inline" prop="ssl_fingerprint_protection_action_extra_parameter_time">
                    <el-input-number class="input-num-margin" v-model="flowEngineForm.ssl_fingerprint_protection_action_extra_parameter_time" :min="1" controls-position="right"/> 秒
                  </el-form-item>
                </span>
              </el-form-item>
            </div>
            <el-form-item label="无差别紧急防护">
              <el-switch
                v-model="flowEngineForm.emergency_protection_status"
                active-value="true"
                inactive-value="false"
              ></el-switch>
            </el-form-item>
            <div v-if="flowEngineForm.emergency_protection_status=='true'" class="form-box-fa">
              <el-form-item label="触发条件" class="is-required">
                所有请求生效
              </el-form-item>
              <el-form-item label="执行动作" class="is-required">
                对所有请求执行
                <el-form-item prop="emergency_protection_action" class="form-item-inline">
                  <el-select  @change="onChangeAction()" class="input-num-margin" v-model="flowEngineForm.emergency_protection_action" placeholder="Select" style="margin-right: 0;">
                    <el-option
                      v-for="item in ruleAction"
                      :key="item.value"
                      :label="item.label"
                      :value="item.value"
                    />  
                  </el-select>
                </el-form-item>
                <el-form-item prop="emergency_protection_action_extra_parameter" class="form-item-inline">
                  <el-select class="input-num-margin" v-model="flowEngineForm.emergency_protection_action_extra_parameter" placeholder="请选择" v-if="flowEngineForm.emergency_protection_action=='bot_check'">
                    <el-option
                      v-for="item in optionsBotCheck"
                      :key="item.value"
                      :label="item.label"
                      :value="item.value"
                    >
                    </el-option>
                  </el-select>
                </el-form-item>
                <span v-if="flowEngineForm.emergency_protection_action=='network_block'" style="margin-left: 10px;">
                  封禁时间
                  <el-form-item class="form-item-inline" prop="emergency_protection_action_extra_parameter_time">
                    <el-input-number class="input-num-margin" v-model="flowEngineForm.emergency_protection_action_extra_parameter_time" :min="1" controls-position="right"/> 秒
                  </el-form-item>
                </span>
              </el-form-item>
            </div>
          </div>
        </el-form>
        <el-row type="flex" justify="space-between" class="margin-border">
          <el-col :span="12">
            
          </el-col>
          <el-col :span="12" class="text-align-right">
            <el-button
              type="primary"
              @click="onClickFlowEngineSubmit('flowEngineForm')"
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
import { mixin, JXAjax, validatePositiveInt } from '../assets/scripts/common'
import { useRoute } from 'vue-router'
export default {
  mixins: [mixin],
  data() {
    return {
      loading: false,
      loadingPage: false,
      ruleType: '',
      currentPlan:'daily_observe',
      engineStatus:'false',
      flowEngineForm: {},
      ruleAction: [
        { value: 'block', label: '阻断请求' },
        { value: 'reject_response', label: '拒绝响应' },
        { value: 'watch', label: '观察模式' },
        { value: 'bot_check', label: '人机验证' },
        { value: 'network_block', label: '网络封禁' }
      ],
      optionsBotCheck: [
        { value: 'auto', label: '无交互验证' },
        { value: 'slipper', label: '滑块验证' },
        { value: 'puzzle', label: '拼图验证' },
        { value: 'words', label: '选字验证' },
      ],
    }
  },
  computed: {
    rules() {
      const validateAction = (rule, value, callback) => {
        if (!value) {
          callback(new Error('请选择执行动作'))
        } else {
          callback()
        }
      }
      const validateActionExtraParameter_1 = (rule, value, callback) => {
        if (this.flowEngineForm.ip_access_limit_action === 'bot_check' && !value) {
          callback(new Error('请选择人机验证类型'))
        } else {
          callback()
        }
      }
      const validateActionExtraParameter_2 = (rule, value, callback) => {
        if (this.flowEngineForm.ip_count_limit_action === 'bot_check' && !value) {
          callback(new Error('请选择人机验证类型'))
        } else {
          callback()
        }
      }
      const validateActionExtraParameter_3 = (rule, value, callback) => {
        if (this.flowEngineForm.domain_access_limit_action === 'bot_check' && !value) {
          callback(new Error('请选择人机验证类型'))
        } else {
          callback()
        }
      }
      const validateActionExtraParameter_4 = (rule, value, callback) => {
        if (this.flowEngineForm.ssl_fingerprint_protection_action === 'bot_check' && !value) {
          callback(new Error('请选择人机验证类型'))
        } else {
          callback()
        }
      }
      const validateActionExtraParameter_5 = (rule, value, callback) => {
        if (this.flowEngineForm.emergency_protection_action === 'bot_check' && !value) {
          callback(new Error('请选择人机验证类型'))
        } else {
          callback()
        }
      }
      
      //ip_access_limit_action_extra_parameter_time
      return {
        ip_access_limit_stat_time: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { required: true, validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
        ip_access_limit_threshold: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { required: true, validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
        ip_access_limit_duration: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
        ip_access_limit_action: [
          { required: true, validator: validateAction, trigger: ['blur', 'change'] }
        ],
        ip_access_limit_action_extra_parameter: [
          { validator: validateActionExtraParameter_1, trigger: ['blur', 'change'] }
        ],

        ip_count_limit_stat_time: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
        ip_count_limit_threshold: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
        ip_count_limit_action: [
          { required: true, validator: validateAction, trigger: ['blur', 'change'] }
        ],
        ip_count_limit_action_extra_parameter: [
          { validator: validateActionExtraParameter_2, trigger: ['blur', 'change'] }
        ],


        domain_access_limit_stat_time: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
        domain_access_limit_threshold: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
        domain_access_limit_action: [
          { required: true, validator: validateAction, trigger: ['blur', 'change'] }
        ],
        domain_access_limit_action_extra_parameter: [
          { validator: validateActionExtraParameter_3, trigger: ['blur', 'change'] }
        ],


        ssl_fingerprint_protection_action: [
          { required: true, validator: validateAction, trigger: ['blur', 'change'] }
        ],
        ssl_fingerprint_protection_action_extra_parameter: [
          { validator: validateActionExtraParameter_4, trigger: ['blur', 'change'] }
        ],


        emergency_protection_action: [
          { required: true, validator: validateAction, trigger: ['blur', 'change'] }
        ],
        emergency_protection_action_extra_parameter: [
          { validator: validateActionExtraParameter_5, trigger: ['blur', 'change'] }
        ],


        ip_access_limit_action_extra_parameter_time: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
        emergency_protection_action_extra_parameter_time: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
        domain_access_limit_action_extra_parameter_time: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
        ip_count_limit_action_extra_parameter_time: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
        ssl_fingerprint_protection_action_extra_parameter_time: [
          { required: true, message: '请输入', trigger: ['blur', 'change'] },
          { validator: validatePositiveInt, trigger: ['blur', 'change'] }
        ],
      }
    }
  },

  mounted() {
    const route = useRoute()
    this.getData()
  },
  methods: {
    getData() {
      var t = this
      var url = '/user/get_flow_engine_protection'
      var postData = {  }
      JXAjax(
        'post',
        url,
        postData,
        function (response) {
          t.loadingPage = false
          t.flowEngineForm = response.data.message
          t.engineStatus = t.flowEngineForm.engine_status
          t.currentPlan = t.flowEngineForm.protection_plan
          t.getExtraParameterTime()
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },

    onClickRadioGroup(flowEngineForm){
      var t = this
      var url = '/user/get_flow_engine_protection'
      var postData = { protection_plan: t.currentPlan}
      JXAjax(
        'post',
        url,
        postData,
        function (response) {
          t.loadingPage = false
          t.$refs[flowEngineForm].clearValidate()
          t.flowEngineForm = response.data.message
          t.getExtraParameterTime()
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    getExtraParameterTime(){
      var t = this;
      t.flowEngineForm.ip_access_limit_action_extra_parameter_time = t.checkAndOutput(t.flowEngineForm.ip_access_limit_action_extra_parameter)
      t.flowEngineForm.ip_count_limit_action_extra_parameter_time = t.checkAndOutput(t.flowEngineForm.ip_count_limit_action_extra_parameter)
      t.flowEngineForm.emergency_protection_action_extra_parameter_time = t.checkAndOutput(t.flowEngineForm.emergency_protection_action_extra_parameter)
      t.flowEngineForm.ssl_fingerprint_protection_action_extra_parameter_time = t.checkAndOutput(t.flowEngineForm.ssl_fingerprint_protection_action_extra_parameter)
      t.flowEngineForm.domain_access_limit_action_extra_parameter_time = t.checkAndOutput(t.flowEngineForm.domain_access_limit_action_extra_parameter)
    },
    checkAndOutput(param) {
      // 只处理字符串和数字类型，其他类型直接输出默认值
      if (typeof param !== 'string' && typeof param !== 'number') {
        return '3600';
      }

      // 尝试转换为数字
      const num = Number(param);

      // 必须是整数且大于 0
      if (Number.isInteger(num) && num > 0) {
        // 输出字符串形式：字符串直接输出原值，数字转换为字符串
        return typeof param === 'string' ? param : String(param);
      } else {
        return '3600';
      }
    },
    onClickFlowEngineSubmit(flowEngineForm) {
      var t = this
      var url = '/user/edit_flow_engine_protection'
      t.flowEngineForm.protection_plan = t.currentPlan
      t.flowEngineForm.engine_status = t.engineStatus
      if(t.flowEngineForm.ip_access_limit_action == 'network_block') {
        t.flowEngineForm.ip_access_limit_action_extra_parameter = t.flowEngineForm.ip_access_limit_action_extra_parameter_time
      }
      if(t.flowEngineForm.ip_count_limit_action == 'network_block') {
        t.flowEngineForm.ip_count_limit_action_extra_parameter = t.flowEngineForm.ip_count_limit_action_extra_parameter_time
      }
      if(t.flowEngineForm.ssl_fingerprint_protection_action == 'network_block') {
        t.flowEngineForm.ssl_fingerprint_protection_action_extra_parameter = t.flowEngineForm.ssl_fingerprint_protection_action_extra_parameter_time
      }
      if(t.flowEngineForm.emergency_protection_action == 'network_block') {
        t.flowEngineForm.emergency_protection_action_extra_parameter = t.flowEngineForm.emergency_protection_action_extra_parameter_time
      }
      if(t.flowEngineForm.domain_access_limit_action == 'network_block') {
        t.flowEngineForm.domain_access_limit_action_extra_parameter = t.flowEngineForm.domain_access_limit_action_extra_parameter_time
      }

      this.$refs[flowEngineForm].validate((valid) => {
        if (valid) {
          t.loading = true
          JXAjax(
            'post',
            url,
            t.flowEngineForm,
            function (response) {
              t.loading = false
              t.getData()
            },
            function () {
              t.loading = false
            }
          )
        }
      })
    },
    processParam(param) {
      let num;
      // 仅尝试转换字符串和数字，避免布尔等被意外转换
      if (typeof param === 'string' || typeof param === 'number') {
        num = Number(param);
      }
      
      if (Number.isInteger(num) && num > 0) {
        return 'auto';
      } else {
       return param;
      }
    },
    onChangeAction(){
      var t = this;
      if(t.flowEngineForm.ip_access_limit_action == 'bot_check') {
        t.flowEngineForm.ip_access_limit_action_extra_parameter = t.processParam(t.flowEngineForm.ip_access_limit_action_extra_parameter)
      }
      if(t.flowEngineForm.ip_count_limit_action == 'bot_check') {
        t.flowEngineForm.ip_count_limit_action_extra_parameter = t.processParam(t.flowEngineForm.ip_count_limit_action_extra_parameter)
      }
      if(t.flowEngineForm.ssl_fingerprint_protection_action == 'bot_check') {
        t.flowEngineForm.ssl_fingerprint_protection_action_extra_parameter = t.processParam(t.flowEngineForm.ssl_fingerprint_protection_action_extra_parameter)
      }
      if(t.flowEngineForm.emergency_protection_action == 'bot_check') {
        t.flowEngineForm.emergency_protection_action_extra_parameter = t.processParam(t.flowEngineForm.emergency_protection_action_extra_parameter)
      }
      if(t.flowEngineForm.domain_access_limit_action == 'bot_check') {
        t.flowEngineForm.domain_access_limit_action_extra_parameter = t.processParam(t.flowEngineForm.domain_access_limit_action_extra_parameter)
      }
    },
  }
}
</script>
<style>
.flow-engine-form .input-num-margin {
  margin: 0 8px;
  width: 150px;
}
.flow-engine-form .form-box-fa {
  background: #fafafa;
  padding: 20px 0 2px;
  margin-left: 50px;
  margin-bottom: 18px;
}
.flow-engine-form .form-box-fa .el-form-item__label {
  width: 90px !important;
}
.flow-engine-form .form-box-fa .form-item-inline {
  display: inline-block; 
  margin-bottom: 0px;
}
.flow-engine-form .form-box-fa .form-item-inline .el-form-item__error {
  left:10px
}
</style>
