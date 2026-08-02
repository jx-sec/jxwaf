<template>
  <div class="match-condition-builder">
    <el-card class="box-card-rule" shadow="never" v-for="(bigItem, bigIndex) in ruleBigMatchs" :key="bigIndex">
      <div class="card-item">
        <!-- 匹配参数：可多个（组内为"且"） -->
        <el-form-item label="匹配参数" class="is-required">
          <div class="match-box" v-for="(item, index) in bigItem.ruleSmallMatchs" :key="index">
            <div class="match-box-content">
              <div class="match_key_cascader">
                <el-cascader
                  separator=":"
                  v-model="item.rule_match_key_list"
                  :options="optionsMatchKey"
                  :props="propsMatchKey"
                  @change="onChangeRuleMatchs($event, item, bigIndex)"
                  clearable
                  placeholder="请选择匹配参数"
                />
              </div>
              <div v-show="item.showInput" class="match_key_input">
                <el-input
                  v-model="item.rule_match_key"
                  clearable
                  @change="onChangeRuleInput($event, item, bigIndex)"
                  placeholder="自定义参数名"
                />
              </div>
            </div>
            <el-button v-if="bigItem.ruleSmallMatchs.length > 1" @click.prevent="removeRuleMatchs(item, bigIndex)" text type="danger">
              <el-icon><Delete /></el-icon>
            </el-button>
          </div>
          <el-button @click="addRuleMatchs(bigIndex)" plain type="primary" text>
            <el-icon><Plus /></el-icon> 添加参数
          </el-button>
        </el-form-item>

        <!-- 参数处理：可多个（管道式） -->
        <el-form-item label="参数处理" class="is-required">
          <div class="match-box" v-for="(item, index) in bigItem.argsPrepocessList" :key="index">
            <div class="match-box-content">
              <el-select v-model="item.args_prepocess_value" placeholder="请选择处理方式" style="width: 200px;">
                <el-option v-for="i in optionsArgs" :key="i.value" :label="i.label" :value="i.value" />
              </el-select>
            </div>
            <el-button v-if="bigItem.argsPrepocessList.length > 1" @click.prevent="removeArgsPrepocess(item, bigIndex)" text type="danger">
              <el-icon><Delete /></el-icon>
            </el-button>
          </div>
          <el-button @click="addArgsPrepocess(bigIndex)" plain type="primary" text>
            <el-icon><Plus /></el-icon> 添加处理
          </el-button>
        </el-form-item>

        <!-- 匹配方式 -->
        <el-form-item label="匹配方式" class="is-required">
          <el-select v-model="bigItem.match_operator" placeholder="请选择匹配方式" style="width: 200px;">
            <el-option v-for="item in optionsOperator" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>

        <!-- 匹配内容 -->
        <el-form-item label="匹配内容" class="is-required">
          <el-select v-if="bigItem.match_operator == 'status_check'" v-model="bigItem.match_value" placeholder="请选择" style="width: 200px;">
            <el-option label="参数存在" value="exist" />
            <el-option label="参数不存在" value="no_exist" />
          </el-select>
          <el-input v-else v-model="bigItem.match_value" placeholder="请输入匹配内容" />
        </el-form-item>

        <div class="card-item-bottom">
          <el-button v-if="ruleBigMatchs.length > 1" type="danger" plain @click.prevent="removeRuleBigMatchs(bigItem)">
            删除此组
          </el-button>
        </div>
      </div>
    </el-card>

    <div class="card-footer">
      <el-button @click="addRuleBigMatchs()">
        <el-icon><CirclePlus /></el-icon> 新增匹配组
      </el-button>
    </div>
  </div>
</template>

<script>
import { Delete, Plus, CirclePlus } from '@element-plus/icons-vue'
import { JXAjax } from '../assets/scripts/common.js'

// 匹配参数级联选项（与标准版一致）
var OPTIONS_MATCH_KEY = [
  {
    value: 'http_args',
    label: 'HTTP参数',
    children: [
      { value: 'path', label: 'URL路径', leaf: true },
      { value: 'query_string', label: '查询字符串', leaf: true },
      { value: 'method', label: '请求方法', leaf: true },
      { value: 'src_ip', label: '源IP', leaf: true },
      { value: 'raw_body', label: '原始请求体', leaf: true },
      { value: 'version', label: 'HTTP版本', leaf: true },
      { value: 'scheme', label: '协议 scheme', leaf: true },
      { value: 'raw_header', label: '原始请求头', leaf: true }
    ]
  },
  {
    value: 'header_args',
    label: '请求头',
    children: [
      { value: 'host', label: 'Host', leaf: true },
      { value: 'cookie', label: 'Cookie', leaf: true },
      { value: 'referer', label: 'Referer', leaf: true },
      { value: 'user_agent', label: 'User-Agent', leaf: true },
      { value: 'default', label: '自定义', leaf: true }
    ]
  },
  {
    value: 'cookie_args',
    label: 'Cookie参数',
    children: [{ value: 'default', label: '自定义', leaf: true }]
  },
  {
    value: 'uri_args',
    label: 'URL参数',
    children: [{ value: 'default', label: '自定义', leaf: true }]
  },
  {
    value: 'post_args',
    label: 'POST参数',
    children: [{ value: 'default', label: '自定义', leaf: true }]
  },
  {
    value: 'json_post_args',
    label: 'JSON参数',
    children: [{ value: 'default', label: '自定义', leaf: true }]
  },
  {
    value: 'ctx_args',
    label: '上下文参数',
    children: [{ value: 'default', label: '自定义', leaf: true }]
  },
  {
    value: 'global_name_list_result',
    label: '全局名单'
  }
]

// 匹配方式（与标准版一致）
var OPTIONS_OPERATOR = [
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
]

// 参数处理（与标准版一致，驼峰命名）
var OPTIONS_ARGS = [
  { value: 'none', label: '不处理' },
  { value: 'lowerCase', label: '小写处理' },
  { value: 'base64Decode', label: 'BASE64解码' },
  { value: 'length', label: '长度计算' },
  { value: 'uriDecode', label: 'URL解码' },
  { value: 'uniDecode', label: 'UNICODE解码' },
  { value: 'hexDecode', label: '十六进制解码' }
]

export default {
  name: 'MatchConditionBuilder',
  components: { Delete, Plus, CirclePlus },
  props: {
    // 外部传入的 rule_matchs JSON 字符串，用于初始化
    modelValue: {
      type: String,
      default: ''
    }
  },
  emits: ['update:modelValue'],
  data() {
    return {
      optionsMatchKey: OPTIONS_MATCH_KEY,
      optionsOperator: OPTIONS_OPERATOR,
      optionsArgs: OPTIONS_ARGS,
      propsMatchKey: {
        expandTrigger: 'hover',
        lazy: true,
        lazyLoad(node, resolve) {
          if (node.value == 'global_name_list_result') {
            var nodes = []
            JXAjax(
              'post',
              '/user/api_get_global_name_list_list',
              {},
              function (response) {
                var _data = response.data.records || []
                if (_data.length > 0) {
                  _data.forEach(function (item) {
                    nodes.push({
                      label: item.name_list_name,
                      value: item.name_list_name,
                      leaf: true
                    })
                  })
                } else {
                  nodes.push({ label: '无', value: 'none', leaf: true, disabled: true })
                }
                resolve(nodes)
              },
              function () { resolve([]) },
              'no-message'
            )
          } else {
            resolve([])
          }
        }
      },
      ruleBigMatchs: [
        {
          ruleSmallMatchs: [{ rule_match_key_list: [], rule_match_key: '', showInput: false }],
          match_operator: '',
          match_value: '',
          argsPrepocessList: [{ args_prepocess_value: 'none' }]
        }
      ]
    }
  },
  watch: {
    modelValue: {
      immediate: true,
      handler(val) {
        if (val) {
          this.deserializeRuleMatchs(val)
        }
      }
    }
  },
  methods: {
    // 反序列化：后端 JSON 字符串 → 前端表单
    deserializeRuleMatchs(ruleMatchsStr) {
      try {
        var _rule_matchs = JSON.parse(ruleMatchsStr)
        if (!Array.isArray(_rule_matchs) || _rule_matchs.length === 0) return
        var _ruleBigMatchs = []
        var _default = ['header_args', 'cookie_args', 'uri_args', 'post_args', 'json_post_args']
        for (var i in _rule_matchs) {
          var _match = []
          var _prepocess = []
          for (var j in _rule_matchs[i].match_args) {
            var item = _rule_matchs[i].match_args[j]
            var key = item.key
            var value = item.value
            var show = 'false'
            if (_default.indexOf(key) > -1) { show = 'true' }
            _match.push({
              rule_match_key_list: [key, value],
              rule_match_key: key + ':' + value,
              showInput: show
            })
          }
          var ap = _rule_matchs[i].args_prepocess || ['none']
          for (var m in ap) {
            _prepocess.push({ args_prepocess_value: ap[m] })
          }
          _ruleBigMatchs.push({
            ruleSmallMatchs: _match.length > 0 ? _match : [{ rule_match_key_list: [], rule_match_key: '', showInput: false }],
            argsPrepocessList: _prepocess.length > 0 ? _prepocess : [{ args_prepocess_value: 'none' }],
            match_operator: _rule_matchs[i].match_operator || '',
            match_value: _rule_matchs[i].match_value || ''
          })
        }
        if (_ruleBigMatchs.length > 0) {
          this.ruleBigMatchs = _ruleBigMatchs
        }
      } catch (e) {
        // 解析失败保持默认
      }
    },
    // 序列化：前端表单 → 后端 JSON 字符串，返回 false 表示校验失败
    serializeRuleMatchs() {
      var _temp_matchs = []
      for (var i in this.ruleBigMatchs) {
        var _match = []
        for (var j in this.ruleBigMatchs[i].ruleSmallMatchs) {
          var item = this.ruleBigMatchs[i].ruleSmallMatchs[j]
          if (!item.rule_match_key) {
            return false
          }
          var _arr = item.rule_match_key.split(':')
          var _key = _arr[0]
          var _value = item.rule_match_key.replace(new RegExp(_key + ':'), '')
          _match.push({ key: _key, value: _value })
        }
        var _prepocess = []
        for (var m in this.ruleBigMatchs[i].argsPrepocessList) {
          _prepocess.push(this.ruleBigMatchs[i].argsPrepocessList[m].args_prepocess_value)
        }
        _temp_matchs.push({
          match_args: _match,
          args_prepocess: _prepocess,
          match_operator: this.ruleBigMatchs[i].match_operator,
          match_value: this.ruleBigMatchs[i].match_value
        })
      }
      return JSON.stringify(_temp_matchs)
    },
    // 校验并 emit
    validateAndEmit() {
      var result = this.serializeRuleMatchs()
      if (result === false) {
        return false
      }
      this.$emit('update:modelValue', result)
      return true
    },
    // ============ 增删操作 ============
    addRuleBigMatchs() {
      this.ruleBigMatchs.push({
        ruleSmallMatchs: [{ rule_match_key_list: [], rule_match_key: '', showInput: false }],
        match_operator: '',
        match_value: '',
        argsPrepocessList: [{ args_prepocess_value: 'none' }]
      })
    },
    removeRuleBigMatchs(bigItem) {
      var index = this.ruleBigMatchs.indexOf(bigItem)
      if (index !== -1 && this.ruleBigMatchs.length > 1) {
        this.ruleBigMatchs.splice(index, 1)
      }
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
      if (index !== -1 && this.ruleBigMatchs[bigIndex].ruleSmallMatchs.length > 1) {
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs.splice(index, 1)
      }
    },
    addArgsPrepocess(bigIndex) {
      this.ruleBigMatchs[bigIndex].argsPrepocessList.push({ args_prepocess_value: 'none' })
    },
    removeArgsPrepocess(item, bigIndex) {
      var index = this.ruleBigMatchs[bigIndex].argsPrepocessList.indexOf(item)
      if (index !== -1 && this.ruleBigMatchs[bigIndex].argsPrepocessList.length > 1) {
        this.ruleBigMatchs[bigIndex].argsPrepocessList.splice(index, 1)
      }
    },
    // ============ cascader 联动 ============
    onChangeRuleMatchs(event, item, bigIndex) {
      var index = this.ruleBigMatchs[bigIndex].ruleSmallMatchs.indexOf(item)
      if (!event || event.length < 2) {
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].rule_match_key = ''
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].showInput = false
        return
      }
      if (event[1] == 'default') {
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].showInput = true
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].rule_match_key = event[0] + ':'
      } else {
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].showInput = false
        this.ruleBigMatchs[bigIndex].ruleSmallMatchs[index].rule_match_key = event[0] + ':' + event[1]
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

<style scoped>
.match-condition-builder {
  width: 100%;
}
.box-card-rule {
  margin-bottom: 12px;
  border: 1px solid #e4e7ed;
}
.card-item {
  padding: 0 8px;
}
.match-box {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
  gap: 8px;
}
.match-box-content {
  position: relative;
  display: inline-block;
  flex: 1;
}
.match_key_cascader {
  position: relative;
  display: inline-block;
  width: 100%;
}
.match_key_input {
  position: absolute;
  display: inline-block;
  top: 0;
  left: 0;
  width: 100%;
}
.card-item-bottom {
  text-align: right;
  margin-top: 8px;
}
.card-footer {
  margin-top: 8px;
}
</style>
