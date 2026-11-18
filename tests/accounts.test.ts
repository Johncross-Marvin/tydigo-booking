import { test } from 'node:test';
import assert from 'node:assert/strict';
import { accountTypes, resolveAccount, canTransact, isAccountType } from '../src/domain/accounts.ts';
const account={auth_user_id:'test-user',account_type:'household',display_name:'Isolated test',status:'active',verification_status:'not_started'};
for(const account_type of accountTypes) {
 test(account_type+' resolves without granting transaction access',()=>{
  const resolved=resolveAccount({...account,account_type},'test-user');
  assert.equal(resolved.account_type,account_type);
  assert.equal(canTransact(resolved),false);
  assert.equal(canTransact({...resolved,verification_status:'approved'}),true);
 });
}
test('missing, wrong UUID and unsupported roles fail closed',()=>{
 for(const input of [null,{...account,auth_user_id:'other'},{...account,account_type:'collector'},{...account,account_type:'admin'},{...account,account_type:null}]) assert.throws(()=>resolveAccount(input,'test-user'));
});
test('suspended and unknown verification states cannot resolve',()=>{
 assert.throws(()=>resolveAccount({...account,status:'suspended'},'test-user'));
 assert.throws(()=>resolveAccount({...account,verification_status:'uploaded'},'test-user'));
});
test('only three public categories accepted',()=>{
 for(const role of ['collector','fleet_owner','government','recycler','corporate_partner','organic_partner','',null,undefined]) assert.equal(isAccountType(role),false);
});
