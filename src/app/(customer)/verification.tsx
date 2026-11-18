import { useEffect, useState } from 'react';
import { Stack } from 'expo-router';
import * as DocumentPicker from 'expo-document-picker';
import { useAuth } from '../../auth/provider';
import { requireBackend } from '../../lib/backend';
import { Button, Card, Copy, Page } from '../../components/ui';
type Requirement={id:string;label:string};
function documentPath(authUserId:string, requirementId:string) {
 return authUserId+'/'+requirementId+'/'+Date.now()+'-'+Math.random().toString(36).slice(2);
}
export default function Verification(){
 const {state,refresh}=useAuth();
 const accountType=state.account!.account_type;
 const [requirements,setRequirements]=useState<Requirement[]>([]),[message,setMessage]=useState(''),[busy,setBusy]=useState(false),[loading,setLoading]=useState(true);
 useEffect(()=>{let active=true;void requireBackend().from('verification_requirements').select('id,label').eq('account_type',accountType).eq('active',true).then(({data,error})=>{if(!active)return;setRequirements(data??[]);setMessage(error?'Document requirements could not be loaded.':'');setLoading(false);});return()=>{active=false;};},[accountType]);
 async function upload(requirement:Requirement){
  setBusy(true);setMessage('');
  try{
   const picked=await DocumentPicker.getDocumentAsync({type:['application/pdf','image/jpeg','image/png'],copyToCacheDirectory:true,multiple:false});
   if(picked.canceled)return;
   const file=picked.assets[0];
   if(!file.size||file.size>10485760)throw new Error('Choose a document smaller than 10 MB.');
   const mime=file.mimeType;
   if(!mime||!['application/pdf','image/jpeg','image/png'].includes(mime))throw new Error('Choose a PDF, JPEG or PNG.');
   const bytes=await (await fetch(file.uri)).arrayBuffer();
   const path=documentPath(state.account!.auth_user_id,requirement.id);
   const client=requireBackend();
   const result=await client.storage.from('verification').upload(path,bytes,{contentType:mime,upsert:false});
   if(result.error)throw new Error('Document upload failed. Please retry.');
   const submitted=await client.rpc('submit_verification_document',{requirement:requirement.id,object_path:path});
   if(submitted.error)throw new Error('Your upload was received but submission could not be confirmed. Contact support before uploading again.');
   setMessage('Document submitted securely. Approval requires review.');
  }catch(e){setMessage(e instanceof Error?e.message:'Verification is unavailable.');}finally{setBusy(false);}
 }
 const canUpload=['not_started','corrections_required','rejected'].includes(state.account!.verification_status);
 return <Page><Stack.Screen options={{title:'Verification centre'}}/><Card><Copy title>Your verification</Copy><Copy>Status: {state.account!.verification_status.replaceAll('_',' ')}</Copy><Copy>Uploading a document does not grant approval.</Copy>{loading?<Copy>Loading requirements…</Copy>:!requirements.length?<Copy>Document requirements are awaiting configuration. Contact support for assistance.</Copy>:requirements.map(r=><Button key={r.id} label={'Upload: '+r.label} disabled={busy||!canUpload} onPress={()=>void upload(r)}/>)}<Button label="Refresh review status" disabled={busy} onPress={()=>void refresh()}/>{!!message&&<Copy>{message}</Copy>}</Card></Page>;
}

