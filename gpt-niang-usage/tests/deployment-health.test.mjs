import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {deploymentReady,waitForDeployment} from '../../scripts/deployment-health.mjs';
const record={at:10000,pid:123,appPath:'/Applications/GPTNiangMac.app',version:'1.3.5',
  webViewReady:true,workerReady:true,quotaReady:true};
const options={now:10000,isAlive:()=>true,canonical:x=>x};
test('deployment requires page, worker, quota, live PID and current heartbeat',()=>{
  const app=record.appPath;
  assert.equal(deploymentReady(record,app,options),true);
  for(const field of ['webViewReady','workerReady','quotaReady']) {
    assert.equal(deploymentReady({...record,[field]:false},app,options),false);
    assert.equal(deploymentReady({...record,[field]:undefined},app,options),false);
  }
  assert.equal(deploymentReady(record,app,{...options,isAlive:()=>false}),false);
  assert.equal(deploymentReady({...record,at:5000},app,options),false);
  assert.equal(deploymentReady({...record,at:10001},app,options),false);
  assert.equal(deploymentReady({...record,appPath:'/other.app'},app,options),false);
});
test('deployment waits through partial data and checks the installed app',async()=>{
  const directory=fs.mkdtempSync(path.join(os.tmpdir(),'niang-deployment-'));
  try {
    const file=path.join(directory,'health.json'),app=path.join(directory,'GPTNiangMac.app');
    fs.mkdirSync(app);fs.writeFileSync(file,'{partial');
    const pending=waitForDeployment(file,app,{timeoutMs:1200});
    setTimeout(()=>fs.writeFileSync(file,JSON.stringify({...record,at:Date.now(),pid:process.pid,appPath:app})),30);
    assert.equal((await pending).pid,process.pid);
  } finally {fs.rmSync(directory,{recursive:true,force:true});}
});
