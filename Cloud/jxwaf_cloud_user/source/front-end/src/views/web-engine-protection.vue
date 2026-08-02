<template>
  <div>
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>防护配置</el-breadcrumb-item>
        <el-breadcrumb-item>Web引擎配置</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>

    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <div class="form-container form-engine-protection">
          <el-form
            :model="webEngineForm"
            :rules="rules"
            ref="webEngineForm"
            label-width="130px"
            class="engine-form"
          >
            <el-form-item label="Web防护引擎状态">
              <el-switch
                v-model="webEngineForm.ai_protection"
                active-value="true"
                inactive-value="false"
              ></el-switch>
            </el-form-item>
            <div v-if="webEngineForm.ai_protection == 'true'">
              <el-form-item label="防护模式" prop="protection_mode">
                <el-radio-group v-model="webEngineForm.protection_mode" @change="onChangeProMode">
                  <el-radio-button label="learn">模型训练</el-radio-button>
                  <el-radio-button label="business_priority">日常防护</el-radio-button>
                  <el-radio-button label="security_priority">重保防护</el-radio-button>
                  <el-radio-button label="offline">离线防护</el-radio-button>
                </el-radio-group>
                <p v-show="webEngineForm.protection_mode=='learn'" class="form-info-block mode-desc-text">只分析不拦截，本地模型通过在线蒸馏技术实时训练，增量更新模型参数</p>
                <p v-show="webEngineForm.protection_mode=='business_priority'" class="form-info-block mode-desc-text">所有AI一致判定为攻击才拦截，任意AI判定正常即放行；未知请求先放行，实时训练完成后再处置；训练期间语义引擎补位检测</p>
                <p v-show="webEngineForm.protection_mode=='security_priority'" class="form-info-block mode-desc-text">任意AI判定为攻击即拦截；未知请求先拦截，实时训练完成后再处置</p>
                <p v-show="webEngineForm.protection_mode=='offline'" class="form-info-block mode-desc-text">本地模型训练冻结，参数固化；本地模型任意AI判定为攻击即拦截；本地模型与语义引擎同时检测，任一检出即拦截</p>
              </el-form-item>
              <div v-if="webEngineForm.protection_mode=='learn'">
                <el-form-item label="未知请求处置">
                  <el-radio-group v-model="webEngineForm.unknown_request">                 
                  <el-radio-button label="pass">放行</el-radio-button>
                </el-radio-group>
                </el-form-item>
                <el-form-item label="语义分析防护">
                  <el-radio-group v-model="webEngineForm.engine_protection">                 
                    <el-radio-button label="watch">观察</el-radio-button>      
                  </el-radio-group>
                </el-form-item>
              </div>
              <div v-if="webEngineForm.protection_mode=='business_priority'">
                <el-form-item label="未知请求处置">
                  <el-radio-group v-model="webEngineForm.unknown_request">                 
                  <el-radio-button label="pass">放行</el-radio-button>
                </el-radio-group>
                </el-form-item>
                <el-form-item label="语义分析防护">
                  <el-radio-group v-model="webEngineForm.engine_protection">
                    <el-radio-button label="block">开启</el-radio-button>
                    <el-radio-button label="watch">观察</el-radio-button>
                    <el-radio-button label="close">关闭</el-radio-button>
                  </el-radio-group>
                </el-form-item>
              </div>
              <div v-if="webEngineForm.protection_mode=='security_priority'">
                <el-form-item label="未知请求处置">
                  <el-radio-group v-model="webEngineForm.unknown_request">                 
                  <el-radio-button label="block">拦截</el-radio-button>
                </el-radio-group>
                </el-form-item>
                <el-form-item label="语义分析防护">
                  <el-radio-group v-model="webEngineForm.engine_protection">                 
                    <el-radio-button label="close">关闭</el-radio-button>
                  </el-radio-group>
                </el-form-item>
              </div>
              <div v-if="webEngineForm.protection_mode=='offline'">
                <el-form-item label="未知请求处置">
                  <el-radio-group v-model="webEngineForm.unknown_request">                 
                    <el-radio-button label="block">拦截</el-radio-button>
                    <el-radio-button label="pass">放行</el-radio-button>
                </el-radio-group>
                </el-form-item>
                <el-form-item label="语义分析防护">
                  <el-radio-group v-model="webEngineForm.engine_protection">
                    <el-radio-button label="block">开启</el-radio-button>
                    <el-radio-button label="watch">观察</el-radio-button>
                    <el-radio-button label="close">关闭</el-radio-button>
                  </el-radio-group>
                </el-form-item>
              </div>
            </div>
          </el-form>
        </div>
        <el-row class="margin-border">
          <el-col :span="12">
            
          </el-col>
          <el-col :span="12" class="text-align-right">
            <el-button
              type="primary"
              @click="onClickWebEngineFormSubmit('webEngineForm')"
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
import { useRoute } from 'vue-router'
export default {
  mixins: [mixin],
  data() {
    return {
      loadingPage: false,
      loading: false,
      webEngineForm: {
        ai_protection: 'false',
        protection_mode: 'business_priority',
        engine_protection: 'block',
        unknown_request:'',
      },
      old_unknown_request:'',
      old_engine_protection:'',
    }
  },
  computed: {
    rules() {
      return {
        protection_mode: [
          { required: true, message: '请选择防护模式', trigger: 'change' }
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
      var url = '/user/get_web_engine_protection'
      var postData = {  }
      JXAjax(
        'post',
        url,
        postData,
        function (response) {
          t.loadingPage = false
          if (response.data.message) {
            t.webEngineForm = response.data.message
            t.old_engine_protection = t.webEngineForm.engine_protection
            t.old_unknown_request = t.webEngineForm.unknown_request
            if(t.webEngineForm.ai_protection == 'false') {
              t.onChangeProMode()
            }
          }
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    onChangeProMode() {
      if(this.webEngineForm.protection_mode == 'learn') {
        this.webEngineForm.unknown_request = 'pass'
        this.webEngineForm.engine_protection = 'watch'
      }else if(this.webEngineForm.protection_mode == 'business_priority'){
        this.webEngineForm.unknown_request = 'pass'
        this.webEngineForm.engine_protection = this.old_engine_protection
      }else if(this.webEngineForm.protection_mode == 'security_priority'){
        this.webEngineForm.unknown_request = 'block'
        this.webEngineForm.engine_protection = 'close'
      }else if(this.webEngineForm.protection_mode == 'offline'){
        this.webEngineForm.unknown_request = this.old_unknown_request
        this.webEngineForm.engine_protection = this.old_engine_protection
      }else {
        this.webEngineForm.unknown_request = ''
        this.webEngineForm.engine_protection = ''
      }
    },
    onClickWebEngineFormSubmit(webEngineForm) {
      var t = this
      var url = '/user/edit_web_engine_protection'
      this.$refs[webEngineForm].validate((valid) => {
        if (valid) {
          t.loading = true
          JXAjax(
            'post',
            url,
            t.webEngineForm,
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
    }
  }
}
</script>
<style scoped>
.page-owasp-wrap {
  max-width: 800px;
  min-width: 400px;
}

.page-owasp-wrap .match-inline-block {
  width: 192px;
}

.engine-form .el-form-item__content {
  margin-left: 40px;
}

.form-container {
  padding-bottom: 6px;
}
.form-engine-protection .el-radio-button {
    margin-right: 0px;
}
.mode-desc-text {
  color: #303133;
  font-size: 12px;
  line-height: 18px;
}
</style>
