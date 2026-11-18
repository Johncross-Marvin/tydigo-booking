import { Redirect, Stack } from 'expo-router';
import { useAuth } from '../../auth/provider';
import { Button, Copy, Loading, Page } from '../../components/ui';
export default function Layout(){const {state,refresh,signOut}=useAuth();if(state.status==='loading')return <Loading/>;if(state.status==='signed_out')return <Redirect href="/sign-in"/>;if(state.status==='error')return <Page><Copy title>Account needs attention</Copy><Copy>{state.message}</Copy><Button label="Retry account lookup" onPress={()=>void refresh()}/><Button label="Return to secure sign in" onPress={()=>void signOut()}/></Page>;return <Stack key={state.account!.auth_user_id} screenOptions={{headerTitle:'TYDIGO',headerTintColor:'#0B2545',headerShadowVisible:false}}/>;}

