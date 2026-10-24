// Optional rendered QA: PLAYWRIGHT_MODULE and WIDGET_BROWSER select installed tools.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = path.resolve(__dirname, '..');
const web = path.join(root, 'macos/Sources/GPTNiangMac/WebWidget');
const out = path.resolve(process.env.WIDGET_QA_OUTPUT || path.join(root, 'dist/webwidget-qa'));
(async()=>{
  fs.mkdirSync(out,{recursive:true});
  const browser = await chromium.launch({executablePath:process.env.WIDGET_BROWSER || undefined,headless:true,args:['--no-sandbox']});
  const page = await browser.newPage({viewport:{width:1000,height:550},deviceScaleFactor:2});
  const errors=[],blocked=[];
  page.on('pageerror',error=>errors.push(error.message));
  await page.route('**/*',async route=>{
    const url = new URL(route.request().url());
    if(url.origin !== 'https://widget.test') {blocked.push(url.href);return route.abort();}
    let file;
    if(url.pathname==='/normal.png') file=path.join(root,'gpt-niang-usage/assets/gpt-dragon-niang-bust.png');
    else if(url.pathname==='/low.png') file=path.join(root,'gpt-niang-usage/assets/gpt-dragon-niang-low-quota.png');
    else if(['/index.html','/widget.js','/widget.css'].includes(url.pathname)) file=path.join(web,url.pathname.slice(1));
    else if(['/examples/webview-preview/preview.html','/examples/webview-preview/widget.html','/examples/webview-preview/preview-state.js'].includes(url.pathname)) file=path.join(root,url.pathname.slice(1));
    else if(['/macos/Sources/GPTNiangMac/WebWidget/widget.css','/macos/Sources/GPTNiangMac/WebWidget/widget.js','/gpt-niang-usage/assets/gpt-dragon-niang-bust.png','/gpt-niang-usage/assets/gpt-dragon-niang-low-quota.png'].includes(url.pathname)) file=path.join(root,url.pathname.slice(1));
    else return route.abort();
    const type=file.endsWith('.png')?'image/png':file.endsWith('.js')?'text/javascript':file.endsWith('.css')?'text/css':'text/html';
    return route.fulfill({status:200,body:fs.readFileSync(file),contentType:type});
  });
  await page.goto('https://widget.test/index.html');
  const base={
    bubble:true,message:null,low:false,completion:false,scale:1,mirrored:false,hideMenu:false,
    revision:0,refreshing:false,colorScope:'none',palette:['745A98','A28BC8'],colorPaused:false,
    stale:false,ok:true,observedAt:Date.now(),title:'剩余额度',plan:'Pro',error:'暂无法读取',
    windows:[{title:'5 小时',remaining:76,resetsAt:Date.now()+3600000,resetText:'今日重置'},
             {title:'每周',remaining:86,resetsAt:Date.now()+86400000*2,resetText:'10/25 13:24 重置'}],
    labels:{refresh:'刷新额度',settings:'挂件设置',character:'点击查看额度',stale:'旧快照',wait:'等待更新后的额度',
      minutes:'%@ 分钟后重置',hours:'%@ 小时 %@ 分钟后重置'}
  };
  await page.evaluate(state=>window.GPTNiang.render(state),base);
  await page.waitForTimeout(500);
  assert.equal(await page.locator('.percentage').first().innerText(),'76%');
  await page.screenshot({path:path.join(out,'normal.png'),omitBackground:true,clip:{x:0,y:0,width:378,height:378}});
  await page.evaluate(state=>window.GPTNiang.render({...state,low:true,message:'需要重置……'}),base);
  await page.waitForTimeout(300);
  assert.equal(await page.locator('.portrait.low').evaluate(el=>getComputedStyle(el).opacity),'1');
  await page.screenshot({path:path.join(out,'low.png'),omitBackground:true,clip:{x:0,y:0,width:378,height:378}});
  await page.evaluate(state=>window.GPTNiang.render({...state,bubble:false,message:null,low:false}),base);
  await page.waitForTimeout(500);
  assert.equal(await page.locator('.cloud').evaluate(el=>getComputedStyle(el).opacity),'0');
  await page.screenshot({path:path.join(out,'compact.png'),omitBackground:true,clip:{x:0,y:0,width:378,height:378}});
  await page.evaluate(state=>window.GPTNiang.render({...state,message:'<img src=x onerror=alert(1)>'}),base);
  assert.equal(await page.locator('#message img').count(),0);
  await page.evaluate(()=>{const img=new Image();img.src='https://blocked.example/pixel';document.body.append(img);img.id='csp-probe';});
  await page.waitForTimeout(100);
  assert.equal(blocked.length,0,'CSP must stop the network request before routing');
  assert.deepEqual(errors,[]);
  await page.evaluate(()=>document.getElementById('csp-probe').remove());
  await page.evaluate(state=>window.GPTNiang.render({...state,mirrored:true}),base);
  await page.waitForTimeout(450);
  await page.screenshot({path:path.join(out,'mirrored.png'),omitBackground:true,clip:{x:0,y:0,width:378,height:378}});
  console.log('Rendered QA passed: quota, low image, compact, mirror, text injection, CSP.');
  await page.goto('https://widget.test/examples/webview-preview/preview.html');
  await page.waitForTimeout(700);
  const previews=page.frames().filter(frame=>frame.url().includes('/widget.html'));
  assert.equal(previews.length,2);
  assert.equal(await previews[0].locator('.percentage').first().innerText(),'76%');
  assert.equal(await previews[1].locator('#message').innerText(),'需要重置……');
  await page.screenshot({path:path.join(out,'overview.png'),fullPage:true});
  console.log('Source-package preview passed.');
  await browser.close();
})().catch(error=>{console.error(error);process.exit(1);});
