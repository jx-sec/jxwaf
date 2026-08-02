<template>
  <div>
    <el-row class="breadcrumb-style">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>账号设置</el-breadcrumb-item>
      </el-breadcrumb>
    </el-row>
    <el-row class="container-style">
      <el-col :span="12">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>修改密码</span>
            </div>
          </template>
          <el-form :model="passwordForm" :rules="passwordRules" ref="passwordFormRef" label-width="100px">
            <el-form-item label="旧密码" prop="old_password">
              <el-input v-model="passwordForm.old_password" type="password" show-password placeholder="请输入旧密码" />
            </el-form-item>
            <el-form-item label="新密码" prop="new_password">
              <el-input v-model="passwordForm.new_password" type="password" show-password placeholder="请输入新密码(至少6位)" />
            </el-form-item>
            <el-form-item label="确认新密码" prop="confirm_password">
              <el-input v-model="passwordForm.confirm_password" type="password" show-password placeholder="请再次输入新密码" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="submitPassword">确认修改</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import { ref, reactive, onMounted } from 'vue'
import { JXAjax } from '../assets/scripts/common'

export default {
  setup() {
    const passwordFormRef = ref(null)
    const passwordForm = reactive({
      old_password: '',
      new_password: '',
      confirm_password: ''
    })
    const validateConfirm = (rule, value, callback) => {
      if (value !== passwordForm.new_password) {
        callback(new Error('两次输入的密码不一致'))
      } else {
        callback()
      }
    }
    const passwordRules = {
      old_password: [{ required: true, message: '请输入旧密码', trigger: 'blur' }],
      new_password: [
        { required: true, message: '请输入新密码', trigger: 'blur' },
        { min: 6, message: '密码长度至少6位', trigger: 'blur' }
      ],
      confirm_password: [
        { required: true, message: '请确认新密码', trigger: 'blur' },
        { validator: validateConfirm, trigger: 'blur' }
      ]
    }

    const submitPassword = () => {
      passwordFormRef.value.validate((valid) => {
        if (valid) {
          JXAjax('post', '/user/edit_password', {
            old_password: passwordForm.old_password,
            new_password: passwordForm.new_password
          }, function () {
            passwordForm.old_password = ''
            passwordForm.new_password = ''
            passwordForm.confirm_password = ''
          })
        }
      })
    }

    return {
      passwordForm,
      passwordRules,
      passwordFormRef,
      submitPassword
    }
  }
}
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: bold;
}
.el-col {
  padding: 0 10px;
}
</style>
