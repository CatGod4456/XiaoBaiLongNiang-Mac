"use strict";
(()=>{
 const low=new URLSearchParams(location.search).has("low");
 const state={bubble:true,message:low?"需要重置……":null,low,scale:1,mirrored:false,hideMenu:true,revision:0,refreshing:false,colorScope:"none",colorPaused:false,observedAt:Date.now(),stale:false,ok:true,title:"剩余额度",plan:"示例数据",error:"示例数据",windows:[{title:"5 小时",remaining:low?4:76,resetsAt:Date.now()+3600000,resetText:"今日重置"},{title:"每周",remaining:86,resetsAt:Date.now()+172800000,resetText:"10/25 13:24 重置"}],labels:{stale:"旧快照",wait:"等待更新后的额度",minutes:"%@ 分钟后重置",hours:"%@ 小时 %@ 分钟后重置",character:"点击查看示例额度",refresh:"刷新示例",settings:"预览"}};
 function render(){window.GPTNiang.render(state);document.querySelector(".portrait.normal").src="../../gpt-niang-usage/assets/gpt-dragon-niang-bust.png";document.querySelector(".portrait.low").src="../../gpt-niang-usage/assets/gpt-dragon-niang-low-quota.png";}
 window.addEventListener("widget-action",event=>{if(event.detail==="character"){state.bubble=!state.bubble;}else if(event.detail==="bubble"){state.message=state.message===null?(low?"需要重置……":"Token 来，Token 来"):null;}render();});
 render();
})();