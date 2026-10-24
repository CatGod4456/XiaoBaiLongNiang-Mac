import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const helper=fileURLToPath(new URL('../../script/macos-toolchain.sh',import.meta.url));
function probe(failure='') {
  const temp=fs.mkdtempSync(path.join(os.tmpdir(),'niang-toolchain-'));
  const bin=path.join(temp,'selected-bin'),project=path.join(temp,'Project With Spaces'),sdk=path.join(temp,'MacOSX.sdk');
  fs.mkdirSync(bin);fs.mkdirSync(project);fs.mkdirSync(path.join(project,'macos'));fs.mkdirSync(sdk);
  const executable=(name,lines)=>{const file=path.join(bin,name);fs.writeFileSync(file,'#!/bin/bash\n'+lines.join('\n')+'\n');fs.chmodSync(file,0o755);return file;};
  executable('swift',[
    'if [ "$1" = --version ]; then echo "Swift version 6.1"; exit 0; fi',
    'if [ "$PROBE_FAILURE" = manifest ]; then echo "Undefined symbols: PackageDescription.Package" >&2; exit 1; fi',
    'printf "{}\\n"'
  ]);
  executable('swiftc',[
    'echo "$*" >"$PROBE_PROJECT/swiftui-called"',
    'if [ "$PROBE_FAILURE" = swiftui ]; then echo "missing SwiftUI macro plugin" >&2; exit 1; fi',
    'exit 0'
  ]);
  const xcrun=executable('xcrun',[
    'case "$*" in',
    '  "--find swift") printf "%s\\n" "$PROBE_BIN/swift";;',
    '  "--find swiftc") printf "%s\\n" "$PROBE_BIN/swiftc";;',
    '  "--sdk macosx --show-sdk-path") printf "%s\\n" "$PROBE_SDK";;',
    '  *) exit 90;;',
    'esac'
  ]);
  const select=executable('xcode-select',['echo /Library/Developer/CommandLineTools']);
  const command='source "$1"; gpt_niang_prepare_toolchain "$2" "$3" "$4" || exit $?; printf "PINNED=%s\\nSDK=%s\\n" "$GPT_NIANG_SWIFT" "$SDKROOT"';
  const result=spawnSync('bash',['-c',command,'probe',helper,project,xcrun,select],{encoding:'utf8',env:{...process.env,
    PROBE_BIN:bin,PROBE_PROJECT:project,PROBE_SDK:sdk,PROBE_FAILURE:failure,
    DEVELOPER_DIR:path.join(temp,'Developer'),GPT_NIANG_DEVELOPER_DIR:'',GPT_NIANG_SDK:'',
    GPT_NIANG_TOOLCHAIN_READY:'',GPT_NIANG_BUILD_CACHE:''}});
  return {temp,bin,project,sdk,result};
}
test('build pins Swift and SDK from xcrun and checks SwiftUI with the same compiler',()=>{
  const f=probe();
  try {
    assert.equal(f.result.status,0,f.result.stderr);
    assert.ok(f.result.stdout.includes('PINNED='+path.join(f.bin,'swift')));
    assert.ok(f.result.stdout.includes('SDK='+f.sdk));
    assert.ok(fs.readFileSync(path.join(f.project,'swiftui-called'),'utf8').includes(f.sdk));
  } finally {fs.rmSync(f.temp,{recursive:true,force:true});}
});
test('broken PackageDescription stops before SwiftUI compilation and installation',()=>{
  const f=probe('manifest');
  try {
    assert.notEqual(f.result.status,0);
    assert.match(f.result.stderr,/PackageDescription/);
    assert.match(f.result.stderr,/安装未进行/);
    assert.equal(fs.existsSync(path.join(f.project,'swiftui-called')),false);
  } finally {fs.rmSync(f.temp,{recursive:true,force:true});}
});
test('missing SwiftUI macro plugins produce an actionable failure before app build',()=>{
  const f=probe('swiftui');
  try {
    assert.notEqual(f.result.status,0);
    assert.match(f.result.stderr,/SwiftUI/);
    assert.match(f.result.stderr,/完整 Xcode/);
  } finally {fs.rmSync(f.temp,{recursive:true,force:true});}
});
