const routes = [
  {
    path: '/',
    component: () => import('src/layouts/MainLayout.vue'),
    children: [
      {
        name: 'index',
        path: '',
        component: () => import('src/pages/IndexPage.vue'),
      },
    ],
  },
  {
    path: '/:catchAll(.*)*',
    component: () => import('src/handlers/NotFoundHandler.vue'),
  },
]

export default routes
