<template>
  <div class="custom-edit-wrap">
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>防护配置</el-breadcrumb-item>
        <el-breadcrumb-item :to="{ path: '/user/page-tamper-proof' }">网页防篡改</el-breadcrumb-item>
        <el-breadcrumb-item v-if="uuid == 'new'">新增</el-breadcrumb-item>
        <el-breadcrumb-item v-else>编辑</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>
    <el-row class="container-style">
      <el-col :span="24" v-loading.fullscreen.lock="loadingPage">
        <el-form
          class="custom-edit-form"
          :model="pageTamperProofForm"
          :rules="rules"
          ref="pageTamperProofForm"
          label-width="120px"
        >
          <div>
            <el-form-item label="规则名称" prop="rule_name">
              <el-input
                v-if="uuid == 'new'"
                v-model="pageTamperProofForm.rule_name"
                placeholder="请输入字母开头，字母或数字组合，仅支持_-两种符号"
              >
              </el-input>
              <el-input v-else v-model="pageTamperProofForm.rule_name" disabled> </el-input>
            </el-form-item>
            <el-form-item label="规则详情">
              <el-input v-model="pageTamperProofForm.rule_detail"> </el-input>
            </el-form-item>

            <el-card class="box-card-rule" shadow="never" v-for="(bigItem, bigIndex) in ruleBigMatchs" :key="bigIndex">
              <div class="card-item">
                <el-form-item label="匹配参数" class="is-required">
                  <div
                    class="match-box"
                    v-for="(item, index) in bigItem.ruleSmallMatchs"
                    :key="index"
                  >
                    <div class="match-box-content">
                      <div class="match_key_cascader">
                        <el-cascader
                          separator=":"
                          v-model="item.rule_match_key_list"
                          :options="optionsMatchKey"
                          :props="propsMatchKey"
                          @change="onChangeRuleMatchs($event, item, bigIndex)"
                          clearable
                        >
                        </el-cascader>
                      </div>
                      <div v-show="item.showInput" class="match_key_input">
                        <el-input
                          v-model="item.rule_match_key"
                          clearable
                          @change="onChangeRuleInput($event, item, bigIndex)"
                        ></el-input>
                      </div>
                    </div>
                    <el-button @click.prevent="removeRuleMatchs(item, bigIndex)"><el-icon><Delete /></el-icon></el-button>

                  </div>
                  <el-button @click="addRuleMatchs(bigIndex)" plain class="button-add" type="primary"><el-icon><Plus /></el-icon></el-button>
                
                </el-form-item>

                <el-form-item label="参数处理" class="is-required">
                  <div
                    class="match-box"
                    v-for="(item, index) in bigItem.argsPrepocessList"
                    :key="index"
                  >
                    <div class="match-box-content">
                      <div class="match_key_cascader">
                        <el-select v-model="item.args_prepocess_value" placeholder="Select">
                          <el-option
                            v-for="i in optionsArgs"
                            :key="i.value"
                            :label="i.label"
                            :value="i.value"
                          />
                        </el-select>
                      </div>
                    </div>
                    <el-button @click.prevent="removeArgsPrepocess(item, bigIndex)"><el-icon><Delete /></el-icon></el-button>
                  </div>
                  <el-button @click="addArgsPrepocess(bigIndex)" plain class="button-add" type="primary"><el-icon><Plus /></el-icon></el-button>
    
                </el-form-item>
                <el-form-item label="匹配方式" class="is-required">
                  <el-select v-model="bigItem.match_operator" placeholder="请选择">
                    <el-option
                      v-for="item in optionsOperator"
                      :key="item.value"
                      :label="item.label"
                      :value="item.value"
                    >
                    </el-option>
                  </el-select>
                </el-form-item>
                <div v-if="bigItem.match_operator == 'status_check'">
                  <el-form-item label="匹配内容" class="is-required">
                    <el-select v-model="bigItem.match_value" placeholder="请选择">
                      <el-option key="exist" label="参数存在" value="exist"></el-option>
                      <el-option key="no_exist" label="参数不存在" value="no_exist"></el-option>
                    </el-select>
                  </el-form-item>
                </div>
                <div v-else>
                  <el-form-item label="匹配内容" class="is-required">
                    <el-input v-model="bigItem.match_value"></el-input>
                  </el-form-item>
                </div>
                
                <div class="card-item-bottom">
                  <el-button type="danger" plain @click.prevent="removeRuleBigMatchs(bigItem)"
                    >删除</el-button
                  >
                </div>
              </div>
            </el-card>
            <div class="card-footer">
              <el-button class="card-footer-btn" @click="addRuleBigMatchs(bigIndex)"
                ><el-icon><CirclePlus /></el-icon>新增</el-button
              >
            </div>
            <el-form-item label="页面地址" prop="cache_page_url">
              <div class="match-box-url" style="width: 100%">
                <div class="match-box-content" style="width: calc(100% - 150px)">
                  <el-input
                    v-model="pageTamperProofForm.cache_page_url"
                    placeholder="请输入完整地址，例如：https://www.jxwaf.com"
                  >
                  </el-input>
                </div>
                <el-button type="primary" plain @click="getPageUrl()" :loading="loading" class="button-get-content"
                  >获取页面内容</el-button
                >
              </div>
            </el-form-item>
            <el-form-item label="页面内容" prop="cache_page_content">
              <el-input v-model="pageTamperProofForm.cache_page_content" type="textarea" :rows="4">
              </el-input>
            </el-form-item>
            <el-form-item label="内容类型" prop="cache_content_type">
              <el-input v-model="pageTamperProofForm.cache_content_type"> </el-input>
            </el-form-item>
          </div>
        </el-form>
        <el-row type="flex" class="margin-border" justify="space-between">
          <el-col :span="12">
            
            
          </el-col>
          <el-col :span="12" class="text-align-right">
            <el-button
              type="primary"
              @click="onClickWebRuleProSubmit('pageTamperProofForm')"
              :loading="loading"
              >保存
            </el-button>
          </el-col>
        </el-row>
      </el-col>
    </el-row>
  </div>
</template>
<script>
import { mixin, JXAjax, validateRuleName } from '../assets/scripts/common'
import { useRoute } from 'vue-router'
export default {
  mixins: [mixin],
  data() {
    return {
      loading: false,
      loadingPage: false,
      uuid: 'new',
      pageTamperProofForm: {
        rule_detail: ''
      },
      type: 'edit',
      optionsMatchKey: [
        {
          value: 'http_args',
          label: 'http_args',
          children: [
            { value: 'path', label: 'path', leaf: true },
            { value: 'query_string', label: 'query_string', leaf: true },
            { value: 'method', label: 'method', leaf: true },
            { value: 'src_ip', label: 'src_ip', leaf: true },
            { value: 'raw_body', label: 'raw_body', leaf: true },
            { value: 'version', label: 'version', leaf: true },
            { value: 'scheme', label: 'scheme', leaf: true },
            { value: 'raw_header', label: 'raw_header', leaf: true }
          ]
        },
        {
          value: 'header_args',
          label: 'header_args',
          children: [
            { value: 'host', label: 'host', leaf: true },
            { value: 'cookie', label: 'cookie', leaf: true },
            { value: 'referer', label: 'referer', leaf: true },
            { value: 'user_agent', label: 'user_agent', leaf: true },
            { value: 'default', label: '自定义', leaf: true }
          ]
        },
        {
          value: 'cookie_args',
          label: 'cookie_args',
          children: [{ value: 'default', label: '自定义', leaf: true }]
        },
        {
          value: 'uri_args',
          label: 'uri_args',
          children: [{ value: 'default', label: '自定义', leaf: true }]
        },
        {
          value: 'post_args',
          label: 'post_args',
          children: [{ value: 'default', label: '自定义', leaf: true }]
        },
        {
          value: 'json_post_args',
          label: 'json_post_args',
          children: [{ value: 'default', label: '自定义', leaf: true }]
        },
        {
          value: 'ctx_args',
          label: 'ctx_args',
          children: [{ value: 'default', label: '自定义', leaf: true }]
        }
      ],
      propsMatchKey: {
        expandTrigger: 'hover'
      },

      ruleBigMatchs: [
        {
          ruleSmallMatchs: [
            {
              rule_match_key_list: [],
              rule_match_key: '',
              showInput: false
            }
          ],
          match_operator: '',
          match_value: '',
          argsPrepocessList: [{ args_prepocess_value: '' }]
        }
      ],
      operator: '',
      optionsOperator: [
        { value: 'rx', label: '正则匹配' },
        { value: 'str_prefix', label: '前缀匹配' },
        { value: 'str_suffix', label: '后缀匹配' },
        { value: 'str_contain', label: '包含' },
        { value: 'str_ncontain', label: '不包含' },
        { value: 'str_eq', label: '等于' },
        { value: 'str_neq', label: '不等于' },
        { value: 'gt', label: '数字大于' },
        { value: 'lt', label: '数字小于' },
        { value: 'eq', label: '数字等于' },
        { value: 'neq', label: '数字不等于' },
        { value: 'status_check', label: '参数存在判断' }
      ],
      optionsArgs: [
        { value: 'none', label: '不处理', key: 'none' },
        { value: 'lowerCase', label: '小写处理', key: 'lowerCase' },
        { value: 'base64Decode', label: 'BASE64解码', key: 'base64Decode' },
        { value: 'length', label: '长度计算', key: 'length' },
        { value: 'uriDecode', label: 'URL解码', key: 'uriDecode' },
        { value: 'uniDecode', label: 'UNICODE解码', key: 'uniDecode' },
        { value: 'hexDecode', label: '十六进制解码', key: 'hexDecode' }
      ]
    }
  },
  computed: {
    rules() {
      return {
        rule_name: [
          {
            required: true,
            message: '请输入规则名称',
            trigger: ['blur', 'change']
          },
          {
            validator: validateRuleName,
            trigger: ['blur', 'change']
          }
        ],
        cache_page_url: [
          {
            required: true,
            message: '请输入页面地址',
            trigger: ['blur', 'change']
          }
        ],
        cache_page_content: [
          {
            required: true,
            message: '请输入页面内容',
            trigger: ['blur', 'change']
          }
        ],
        cache_content_type: [
          {
            required: true,
            message: '请输入内容类型',
            trigger: ['blur', 'change']
          }
        ],
      }
    }
  },
  mounted() {
    var t = this
    const route = useRoute()
    t.uuid = route.params.uuid
    if (t.uuid != 'new') {
      t.getData()
    }
  },
  methods: {
    getData() {
      var t = this
      var url = '/user/get_web_page_tamper_proof'
      var oData = { rule_name: t.uuid }
      JXAjax(
        'post',
        url,
        oData,
        function (response) {
          t.loadingPage = false
          t.pageTamperProofForm = response.data.message
          t.pageTamperProofForm.rule_name = t.uuid
          var _rule_matchs = JSON.parse(t.pageTamperProofForm.rule_matchs)
          var _ruleBigMatchs = []
          for (var i in _rule_matchs) {
            var _match = []
            var _prepocess = []
            var _default = ['header_args', 'cookie_args', 'uri_args', 'post_args', 'json_post_args']

            for (var j in _rule_matchs[i].match_args) {
              var item = _rule_matchs[i].match_args[j]
              var key = item.key
              var value = item.value
              var show = 'false'
              if (_default.indexOf(key) > -1) {
                show = 'true'
              }
              _match.push({
                rule_match_key_list: [key, value],
                rule_match_key: key + ':' + value,
                showInput: show
              })
            }
            for (var m in _rule_matchs[i].args_prepocess) {
              _prepocess.push({
                args_prepocess_value: _rule_matchs[i].args_prepocess[m]
              })
            }

            _ruleBigMatchs.push({
              ruleSmallMatchs: _match,
              argsPrepocessList: _prepocess,
              match_operator: _rule_matchs[i].match_operator,
              match_value: _rule_matchs[i].match_value
            })
          }
          t.ruleBigMatchs = _ruleBigMatchs
        },
        function () {
          t.loadingPage = false
        },
        'no-message'
      )
    },
    onClickWebRuleProSubmit(pageTamperProofForm) {
      var t = this
      var _temp_matchs = []
      if (t.ruleBigMatchs.length == 0) {
        t.$message({
          showClose: true,
          message: '请输入详细规则',
          type: 'error'
        })
        return false
      }
      for (var i in t.ruleBigMatchs) {
        var _match = []
        var _prepocess = []
        if (t.ruleBigMatchs[i].ruleSmallMatchs.length == 0) {
          t.$message({
            showClose: true,
            message: '请选择匹配参数',
            type: 'error'
          })
          return false
        }

        for (var j in t.ruleBigMatchs[i].ruleSmallMatchs) {
          var item = t.ruleBigMatchs[i].ruleSmallMatchs[j]

          if (item.rule_match_key == '') {
            t.$message({
              showClose: true,
              message: '请选择匹配参数',
              type: 'error'
            })
            return false
          }
          var _str = ''
          var _arr = []
          var _key = ''
          var _value = ''

          if (item.rule_match_key) {
            _arr = item.rule_match_key.split(':')
          }
          if (_arr.length > 0) {
            _key = _arr[0]
            _value = item.rule_match_key.replace(new RegExp(_key + ':'), '')
            _str = '{"key":"' + _key + '" , "value":"' + _value + '"}'
          }

          _match.push(JSON.parse(_str))
        }
        if (t.ruleBigMatchs[i].argsPrepocessList.length == 0) {
          t.$message({
            showClose: true,
            message: '请选择参数处理',
            type: 'error'
          })
          return false
        }
        for (var m in t.ruleBigMatchs[i].argsPrepocessList) {
          if (t.ruleBigMatchs[i].argsPrepocessList[m].args_prepocess_value == '') {
            t.$message({
              showClose: true,
              message: '请选择参数处理',
              type: 'error'
            })
            return false
          }
          _prepocess.push(t.ruleBigMatchs[i].argsPrepocessList[m].args_prepocess_value)
        }

        if (t.ruleBigMatchs[i].match_operator == '') {
          t.$message({
            showClose: true,
            message: '请选择匹配方式',
            type: 'error'
          })
          return false
        }
        if (t.ruleBigMatchs[i].match_value == '') {
          t.$message({
            showClose: true,
            message: '请输入匹配内容',
            type: 'error'
          })
          return false
        }

        _temp_matchs.push({
          match_args: _match,
          args_prepocess: _prepocess,
          match_operator: t.ruleBigMatchs[i].match_operator,
          match_value: t.ruleBigMatchs[i].match_value
        })
      }

      var postUrl = ''

      if (t.uuid == 'new') {
        postUrl = '/user/create_web_page_tamper_proof'
      } else {
        postUrl = '/user/edit_web_page_tamper_proof'
        t.pageTamperProofForm.rule_name = t.uuid
      }
      t.pageTamperProofForm.rule_matchs = JSON.stringify(_temp_matchs)
      this.$refs[pageTamperProofForm].validate((valid) => {
        if (valid) {
          t.loading = true
          JXAjax(
            'post',
            postUrl,
            t.pageTamperProofForm,
            function (response) {
              t.loading = false
              t.$router.push('/user/page-tamper-proof')
            },
            function () {
              t.loading = false
            }
          )
        }
      })
    },
    getPageUrl() {
      var t = this
      var url = t.pageTamperProofForm.cache_page_url
      if (url) {
        t.loading = true
        var oData = {
          cache_page_url: url
        }
        var postUrl = '/user/waf_get_cache_page_url'
        JXAjax(
          'post',
          postUrl,
          oData,
          function (response) {
            t.loading = false
            t.pageTamperProofForm.cache_page_content = response.data.cache_page_content
            t.pageTamperProofForm.cache_content_type = response.data.cache_content_type
          },
          function () {
            t.loading = false
          },
          'no-message'
        )
      } else {
        t.$message({
          message: '请输入页面地址',
          type: 'error'
        })
        return false
      }
    },
    removeArgsPrepocess(item, bigIndex) {
      var index = this.ruleBigMatchs[bigIndex].argsPrepocessList.indexOf(item)
      if (index != -1 && this.ruleBigMatchs[bigIndex].argsPrepocessList.length > 1) {
        this.ruleBigMatchs[bigIndex].argsPrepocessList.splice(index, 1)
      }
    },
    addArgsPrepocess(bigIndex) {
      this.ruleBigMatchs[bigIndex].argsPrepocessList.push({ args_prepocess_value: '' })
    },
    addRuleMatchs(bigIndex) {
      this.ruleBigMatchs[bigIndex].ruleSmallMatchs.push({
        rule_match_key: '',
        rule_match_key_list: [],
        showInput: false
      })
    },
    removeRuleMatchs(item, bigIndex) {
      var index = this.ruleBigMatchs[bigIndex].ruleSmallMatchs.indexOf(item)
      if (index != -1 && this.ruleBigMatchs[bigIndex].ruleSmallMatchs.length > 1) {
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs.splice(index, 1)
      }
    },
    removeRuleBigMatchs(bigItem) {
      var index = this.ruleBigMatchs.indexOf(bigItem)
      if (index != -1 && this.ruleBigMatchs.length > 1) {
        this.ruleBigMatchs.splice(index, 1)
      }
    },

    addRuleBigMatchs(bigIndex) {
      this.ruleBigMatchs.push({
        ruleSmallMatchs: [
          {
            rule_match_key_list: [],
            rule_match_key: '',
            showInput: false
          }
        ],
        match_operator: '',
        match_value: '',
        argsPrepocessList: [{ args_prepocess_value: '' }]
      })
    },

    onChangeRuleMatchs(event, item, bigIndex) {
      var index = this.ruleBigMatchs[bigIndex].ruleSmallMatchs.indexOf(item)
      if (event[1] == 'default') {
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].showInput = true
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].rule_match_key = event[0] + ':'
      } else {
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].rule_match_key =
          event[0] + ':' + event[1]
      }
    },
    onChangeRuleInput(event, item, bigIndex) {
      var index = this.ruleBigMatchs[bigIndex].ruleSmallMatchs.indexOf(item)
      if (event == '') {
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].showInput = false
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].rule_match_key = ''
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].rule_match_key_list = []
      } else {
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].rule_match_key = event
      }
    }
  }
}
</script>
<style>
.custom-edit-wrap {
  min-width: 400px;
}
.custom-edit-wrap .match-inline-block {
  width: 192px;
}
.custom-edit-form .el-checkbox + .el-checkbox {
  margin-left: 0px;
  margin-right: 30px;
}
.custom-edit-form .el-checkbox {
  margin-left: 0px;
  margin-right: 30px;
}
.custom-edit-form .el-select,
.custom-edit-form .el-cascader {
  width: 100%;
  min-width: 220px;
}
.custom-edit-form .match-box {
  display: inline-block;
  margin-bottom: 5px;
}
.match-box-url .button-get-content {
  margin-left: 10px;
  margin-right: 0px;
}

.custom-edit-form .match-box-content {
  position: relative;
  display: inline-block;
}
.custom-edit-form .match_key_cascader {
  position: relative;
  display: inline-block;
}
.custom-edit-form .match_key_input {
  position: absolute;
  display: inline-block;
  top: 0;
  left: 0;
  width: 100%;
}
.custom-edit-form .rule-level-box .el-form-item__content {
  margin-left: 10px;
}
</style>
