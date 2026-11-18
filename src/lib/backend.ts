import { createClient, processLock } from '@supabase/supabase-js';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';
import type { Database } from './database.types';
const url = process.env.EXPO_PUBLIC_SUPABASE_URL;
const key = process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
// Explicitly reject accidental reuse of the old production project.
export const configured = Boolean(url && key && !url.includes('gwsywtptelowvbcwplsj'));
export const recoveryConfigured = configured && process.env.EXPO_PUBLIC_ENABLE_PASSWORD_RECOVERY === 'true';
const storage = {
  getItem: async (name: string) => Platform.OS === 'web' ? (typeof sessionStorage === 'undefined' ? null : sessionStorage.getItem(name)) : SecureStore.getItemAsync(name),
  setItem: async (name: string, value: string) => { if (Platform.OS === 'web') sessionStorage.setItem(name, value); else await SecureStore.setItemAsync(name, value); },
  removeItem: async (name: string) => { if (Platform.OS === 'web') sessionStorage.removeItem(name); else await SecureStore.deleteItemAsync(name); },
};
export const backend = configured ? createClient<Database>(url!, key!, { auth: { storage, storageKey: 'tydigo-booking-session', persistSession: true, autoRefreshToken: true, detectSessionInUrl: false, lock: processLock } }) : null;
export function requireBackend() { if (!backend) throw new Error('Booking service is not configured yet. Please try again later.'); return backend; }

// Recovery runs in a temporary in-memory session that never opens customer navigation.
export function recoveryClient() {
 requireBackend();
 return createClient<Database>(url!, key!, {auth:{storageKey:'tydigo-booking-recovery',persistSession:false,autoRefreshToken:false,detectSessionInUrl:false}});
}

