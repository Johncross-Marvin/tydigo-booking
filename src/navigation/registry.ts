export const screens = {
  signIn: { path: '/sign-in', title: 'Welcome to TYDIGO', access: 'public' },
  register: { path: '/register', title: 'Create your account', access: 'public' },
  recovery: { path: '/recover-password', title: 'Reset password', access: 'public' },
  dashboard: { path: '/', title: 'Your TYDIGO', access: 'customer' },
  verification: { path: '/verification', title: 'Verification centre', access: 'customer' },
  booking: { path: '/booking', title: 'Book a collection', access: 'customer' },
  history: { path: '/history', title: 'Your bookings', access: 'customer' },
  profile: { path: '/profile', title: 'Your account', access: 'customer' },
  support: { path: '/support', title: 'Help & support', access: 'customer' },
} as const;

