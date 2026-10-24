import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const alive = pid => { try { process.kill(pid, 0); return true; } catch { return false; } };
export function deploymentReady(record, app, {now=Date.now(), isAlive=alive, canonical=fs.realpathSync}={}) {
  if (!record || !Number.isSafeInteger(record.pid) || record.pid <= 0 || !isAlive(record.pid)) return false;
  if (record.webViewReady !== true || record.workerReady !== true || record.quotaReady !== true) return false;
  if (!Number.isFinite(record.at) || now-record.at < 0 || now-record.at >= 5000) return false;
  if (typeof record.appPath !== 'string' || typeof record.version !== 'string' || !/^\d+\.\d+\.\d+$/.test(record.version)) return false;
  try { return canonical(record.appPath) === canonical(app); } catch { return false; }
}
export async function waitForDeployment(file, app, {timeoutMs=60000}={}) {
  const deadline=Date.now()+timeoutMs;
  while (Date.now()<deadline) {
    try {
      const record=JSON.parse(fs.readFileSync(file,'utf8'));
      if (deploymentReady(record,app)) return record;
    } catch {}
    await new Promise(resolve=>setTimeout(resolve,250));
  }
  throw new Error('启动检查未通过：需要 WebView、后台心跳和当前账号额度同时就绪。');
}
if (process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  try {
    const record=await waitForDeployment(process.argv[2],process.argv[3]);
    console.log('启动检查通过。PID: '+record.pid+'，版本: '+record.version);
  } catch(error) { console.error(error.message); process.exitCode=1; }
}
