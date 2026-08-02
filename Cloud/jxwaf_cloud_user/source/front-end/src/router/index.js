import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    redirect: '/user/usage-stat'
  },
  {
    path: '/user/login',
    name: 'login',
    component: () => import('../views/Login.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/user/register',
    name: 'register',
    component: () => import('../views/Register.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/user/settings',
    name: 'settings',
    component: () => import('../views/Settings.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/usage-stat',
    name: 'usage-stat',
    component: () => import('../views/usage-stat.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/soc-attack-event',
    name: 'soc-attack-event',
    component: () => import('../views/soc-attack-event.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/soc-attack-event-behave/:uuid',
    name: 'soc-attack-event-behave',
    component: () => import('../views/soc-attack-event-behave.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/domain',
    name: 'domain',
    component: () => import('../views/domain.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/dns-config',
    name: 'dns-config',
    component: () => import('../views/dns-config.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/ssl-manage',
    name: 'ssl-manage',
    component: () => import('../views/ssl-manage.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/web-engine-protection',
    name: 'web-engine-protection',
    component: () => import('../views/web-engine-protection.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/web-rule-protection',
    name: 'web-rule-protection',
    component: () => import('../views/web-rule-protection.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/web-rule-protection-edit/:uuid',
    name: 'web-rule-protection-edit',
    component: () => import('../views/web-rule-protection-edit.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/page-tamper-proof',
    name: 'page-tamper-proof',
    component: () => import('../views/page-tamper-proof.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/page-tamper-proof-edit/:uuid',
    name: 'page-tamper-proof-edit',
    component: () => import('../views/page-tamper-proof-edit.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/web-white-rule',
    name: 'web-white-rule',
    component: () => import('../views/web-white-rule.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/web-white-rule-edit/:uuid',
    name: 'web-white-rule-edit',
    component: () => import('../views/web-white-rule-edit.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/flow-engine-protection',
    name: 'flow-engine-protection',
    component: () => import('../views/flow-engine-protection.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/flow-rule-protection',
    name: 'flow-rule-protection',
    component: () => import('../views/flow-rule-protection.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/flow-rule-protection-edit/:uuid',
    name: 'flow-rule-protection-edit',
    component: () => import('../views/flow-rule-protection-edit.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/flow-ip-region-block',
    name: 'flow-ip-region-block',
    component: () => import('../views/flow-ip-region-block.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/flow-white-rule',
    name: 'flow-white-rule',
    component: () => import('../views/flow-white-rule.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/flow-white-rule-edit/:uuid',
    name: 'flow-white-rule-edit',
    component: () => import('../views/flow-white-rule-edit.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/cache-policy',
    name: 'cache-policy',
    component: () => import('../views/cache-policy.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/cache-warmup',
    name: 'cache-warmup',
    component: () => import('../views/cache-warmup.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/cache-refresh',
    name: 'cache-refresh',
    component: () => import('../views/cache-refresh.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/user/soc-query-log/:uuid?/:time?',
    name: 'soc-query-log',
    component: () => import('../views/soc-query-log.vue'),
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const isLogin = localStorage.getItem('isLogin')
  if (to.meta.requiresAuth !== false && !isLogin) {
    next('/user/login')
  } else if ((to.path === '/user/login' || to.path === '/user/register') && isLogin) {
    next('/user/usage-stat')
  } else {
    next()
  }
})

export default router
