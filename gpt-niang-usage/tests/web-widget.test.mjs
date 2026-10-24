import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const web = new URL('../../macos/Sources/GPTNiangMac/WebWidget/', import.meta.url);
const script = fs.readFileSync(new URL('widget.js', web), 'utf8');

// Minimal DOM fixture exercises the actual renderer without npm dependencies.
function fixture() {
  class Element {
    constructor() {
      this.children = []; this.textContent = ''; this.hidden = false; this.attrs = {};
      this.classes = new Set(); this.events = {};
      this.classList = {add: name => this.classes.add(name), remove: name => this.classes.delete(name),
        toggle: (name, value) => value ? this.classes.add(name) : this.classes.delete(name)};
      this.style = {setProperty: (name, value) => { this.style[name] = value; }};
    }
    set innerHTML(_) { throw new Error('Renderer must never interpret text as HTML'); }
    setAttribute(name, value) { this.attrs[name] = value; }
    getAttribute(name) { return this.attrs[name] ?? null; }
    addEventListener(name, callback) { this.events[name] = callback; }
    append(child) { child.parent = this; this.children.push(child); }
    remove() { this.parent.children.splice(this.parent.children.indexOf(this), 1); }
    get lastElementChild() { return this.children.at(-1); }
    querySelector(selector) { return this.parts[selector]; }
  }
  const ids = Object.fromEntries(['stage','rows','quota-row','viewport','quota-title','stale','content','quota','message','character','settings','refresh','error','egg-portrait'].map(id => [id,new Element()]));
  ids['quota-row'].content = {cloneNode() {
    const row = new Element();
    row.parts = Object.fromEntries(['.window-title','.percentage','.fill','.reset'].map(x => [x,new Element()]));
    return row;
  }};
  const images = {'.portrait.normal':new Element(),'.portrait.low':new Element()};
  const actions = [], timers = new Map(), docEvents = {}; let time = 1000000, nextTimer = 0;
  const document = {getElementById: id => ids[id], querySelector: selector => images[selector],
    querySelectorAll: () => [new Element(),new Element(),new Element()], hidden:false,
    addEventListener: (name, callback) => { docEvents[name] = callback; }};
  const window = {webkit:{messageHandlers:{widget:{postMessage: value => actions.push(value.action)}}}};
  vm.runInNewContext(script, {document,window,Date:{now:()=>time},
    setInterval: callback => {const id=++nextTimer;timers.set(id,callback);return id;},
    clearInterval: id => timers.delete(id)});
  const state = overrides => ({
    bubble:true,message:null,low:false,scale:1,mirrored:false,hideMenu:false,revision:0,
    colorScope:'none',colorPaused:false,refreshing:false,title:'剩余额度',plan:'Pro',error:'不可用',
    stale:false,observedAt:time,windows:[{title:'5 小时',remaining:76,resetsAt:time+3600000,resetText:'稍后重置'}],
    labels:{stale:'旧快照',wait:'等待更新',minutes:'%@ 分钟后重置',hours:'%@ 小时 %@ 分钟后重置'},...overrides
  });
  return {ids,images,actions,timers,document,state,
    render: overrides => window.GPTNiang.render(state(overrides)),
    tick: value => {time=value;for(const callback of timers.values())callback();},
    visibility: hidden => {document.hidden=hidden;docEvents.visibilitychange();}};
}
test('renderer updates quota, progress, language text and a correlated refresh action',()=>{
  const f=fixture();f.render();
  const row=f.ids.rows.children[0];
  assert.equal(row.parts['.percentage'].textContent,'76%');
  assert.equal(row.parts['.fill'].style.width,'76%');
  f.ids.refresh.events.click({stopPropagation(){}});
  assert.deepEqual(f.actions,['ready','refresh']);
});
test('low image, dedicated quote and confirmed normal rendering switch together',()=>{
  const f=fixture();f.render({low:true,message:'需要重置……'});
  assert.ok(f.ids.stage.classes.has('is-low'));assert.equal(f.ids.message.textContent,'需要重置……');
  assert.ok(f.ids.quota.hidden);assert.equal(f.timers.size,0);
  f.render({low:false,message:null});
  assert.ok(!f.ids.stage.classes.has('is-low'));assert.ok(f.ids.message.hidden);
  assert.equal(f.ids.rows.children[0].parts['.percentage'].textContent,'76%');
});
test('expiry clock never changes character or fabricates a replenished percentage',()=>{
  const f=fixture();f.render({low:true,windows:[{title:'每周',remaining:0,resetsAt:1001000}]});
  f.tick(1002000);
  assert.ok(f.ids.stage.classes.has('is-low'));
  assert.equal(f.ids.rows.children[0].parts['.percentage'].textContent,'—');
  assert.equal(f.ids.rows.children[0].parts['.reset'].textContent,'等待更新');
});
test('only a visible quota bubble has a one-second countdown, with no hidden-page polling',()=>{
  const f=fixture();f.render();assert.equal(f.timers.size,1);
  f.visibility(true);assert.equal(f.timers.size,0);
  f.visibility(false);assert.equal(f.timers.size,1);
  f.render({bubble:false});assert.equal(f.timers.size,0);
  f.render({message:'台词'});assert.equal(f.timers.size,0);
});
test('quotes and labels are inserted as text and cannot become scripts or HTML',()=>{
  const f=fixture(),html='<img src=x onerror="alert(1)"><script>steal()</script>';
  f.render({message:html});assert.equal(f.ids.message.textContent,html);
  f.render({windows:[{title:html,remaining:4,resetsAt:null}]});
  assert.equal(f.ids.rows.children[0].parts['.window-title'].textContent,html);
  assert.deepEqual(f.actions,['ready']);
});
test('custom-image cache revisions are local, mirrored text stays readable and rows do not accumulate',()=>{
  const f=fixture();f.render({revision:7,mirrored:true});
  assert.equal(f.images['.portrait.normal'].src,'normal.png?revision=7');
  assert.equal(f.ids.stage.style['--mirror'],'-1');
  f.render({windows:[]});assert.equal(f.ids.rows.children.length,0);assert.ok(!f.ids.error.hidden);
  f.render();f.render();assert.equal(f.ids.rows.children.length,1);
});
test('embedded page denies remote connections, frames and scripts and has no dynamic HTML sink',()=>{
  const html=fs.readFileSync(new URL('index.html',web),'utf8');
  assert.match(html,/connect-src 'none'/);assert.match(html,/frame-src 'none'/);
  assert.match(html,/script-src 'self'/);assert.doesNotMatch(html,/<script[^>]*>\s*[^<\s]/);
  assert.doesNotMatch(script,/innerHTML|eval\(|new Function|fetch\(|XMLHttpRequest|WebSocket/);
});
test('easter egg stretches in place around the visible feet and restores the quota',()=>{
  const f=fixture();f.render({egg:'squish',eggGeneration:2,characterBaseline:.96});
  assert.ok(f.ids.stage.classes.has('egg-squish'));
  assert.equal(f.ids.stage.style['--baseline'],'96%');
  assert.equal(f.ids['egg-portrait'].attrs.src,'egg-squish.png?revision=2');
  assert.equal(f.timers.size,0);
  f.render({egg:null,eggGeneration:2});
  assert.ok(!f.ids.stage.classes.has('is-easter-egg'));
  assert.equal(f.timers.size,1);
  const css=fs.readFileSync(new URL('widget.css',web),'utf8');
  const animation=css.match(/@keyframes dragon-squish\{([\s\S]*?)\n\}/)[1];
  assert.doesNotMatch(animation,/translate|rotate/);
});
test('loop controls support finite and continuous stretch, and reload each single dance cycle',()=>{
  const f=fixture();
  f.render({egg:'squish',eggLoops:3,eggGeneration:1});
  assert.equal(f.ids.stage.style['--egg-iterations'],'3');
  f.render({egg:'squish',eggLoops:0,eggGeneration:1});
  assert.equal(f.ids.stage.style['--egg-iterations'],'infinite');
  f.render({egg:'dance',eggLoops:2,eggGeneration:2});
  assert.equal(f.ids['egg-portrait'].attrs.src,'egg-dance.gif?revision=2');
  f.render({egg:'dance',eggLoops:2,eggGeneration:3});
  assert.equal(f.ids['egg-portrait'].attrs.src,'egg-dance.gif?revision=3');
});
