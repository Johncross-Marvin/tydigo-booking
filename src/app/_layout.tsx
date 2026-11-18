import { Stack } from 'expo-router';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { useFonts, Inter_400Regular, Inter_700Bold } from '@expo-google-fonts/inter';
import { AuthProvider } from '../auth/provider';
export default function Layout(){const [loaded,error]=useFonts({Inter_400Regular,Inter_700Bold}); if(!loaded&&!error)return null; return <SafeAreaProvider><AuthProvider><Stack screenOptions={{headerTintColor:'#0B2545',headerTitle:'TYDIGO',headerShadowVisible:false}}><Stack.Screen name="(customer)" options={{headerShown:false}}/><Stack.Screen name="sign-in" options={{title:'Welcome to TYDIGO'}}/><Stack.Screen name="register" options={{title:'Create your account'}}/></Stack></AuthProvider></SafeAreaProvider>;}

