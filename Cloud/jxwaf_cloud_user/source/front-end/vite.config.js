import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

// 开发模式：代理 API 请求到 Cloud_user Go 后端（默认 8080 端口，与后端 HTTP_PORT 默认值一致）
const API_TARGET = process.env.VITE_API_TARGET || 'http://127.0.0.1:8080'

export default defineConfig({
  plugins: [
    vue()
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  server: {
    port: 3000,
    host: '0.0.0.0',
    proxy: {
      '/api': {
        target: API_TARGET,
        changeOrigin: true
      },
      '/user': {
        target: API_TARGET,
        changeOrigin: true,
        bypass(req) {
          // 只代理 POST 请求（API 调用），GET 请求是前端页面路由，由 Vite 处理
          if (req.method !== 'POST') {
            return req.url
          }
        }
      }
    }
  },
  build: {
    outDir: 'dist',
    rollupOptions: {
      output: {
        entryFileNames: 'assets/index/[name]-[hash].js',
        chunkFileNames: 'assets/index/[name]-[hash].js',
        assetFileNames: 'assets/index/[name]-[hash].[ext]',
        manualChunks(id) {
          if (id.includes('node_modules')) {
            return 'vendor'
          }
        }
      }
    }
  }
})
