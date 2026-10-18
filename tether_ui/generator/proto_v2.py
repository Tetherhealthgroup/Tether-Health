import json
from dsl import *
from render_html import render_screen, CSS, e

PROTO_JS = r"""
const M = META, F = FLOWS, SC = SCENARIOS, EXP = EXPECT;
let stack=[START], onboarding=false, hot=false, FAST=false, lastRun=null;
const SESSION = new Map(), QUEUE=[]; let FORCE=null, lastToast=null, lastPlatform=null, chooserResolve=null;
const visited = new Set();
const $=s=>document.querySelector(s);
const sleep=ms=>new Promise(r=>setTimeout(r, FAST?0:ms));
function cur(){return stack[stack.length-1]}
function resolveTo(a){ return (a.context && onboarding) ? a.context.onboarding : a.to }
function setV(k,v){ SESSION.delete(k); SESSION.set(k,v); recompute(); }
function toast(t){lastToast=t; const el=$('#toast');el.textContent=t;el.classList.add('on');clearTimeout(el._t);el._t=setTimeout(()=>el.classList.remove('on'),FAST?10:1800)}
/* ---------------- rules (mirror of lib/logic/rules.dart and spec/rules.json) */
const num=v=>{ if(v==null) return null; const m=String(v).match(/-?\d+(\.\d+)?/); return m?parseFloat(m[0]):null };
const list=v=>Array.isArray(v)?v:(v==null?[]:[String(v)]);
function latest(keys){ let out=null; for(const [k,v] of SESSION){ if(keys.includes(k)) out=v } return out }
const RULES = {
 'hw.bp': ()=>{ const P=RULESPEC['hw.bp'].params; const rd=[];
   for(const s of ['hw_log','hw_log2']){ const sy=num(SESSION.get(s+'.systolic')), di=num(SESSION.get(s+'.diastolic')); if(sy==null&&di==null) continue; if(sy==null||di==null) return 'Invalid value'; rd.push([sy,di]); }
   if(!rd.length) return null;
   for(const [sy,di] of rd){ if(sy<P.sys_min||sy>P.sys_max||di<P.dia_min||di>P.dia_max||di>=sy) return 'Invalid value' }
   if(rd.some(([sy,di])=>sy>=P.crisis_sys||di>=P.crisis_dia)) return '≥180 top or ≥120 bottom';
   return 'Valid · below crisis range'; },
 'st.glucose': ()=>{ const P=RULESPEC['st.glucose'].params; const g=num(SESSION.get('st_log.reading')); if(g==null) return null;
   if(g<P.min||g>P.max) return 'Invalid (outside 20–600)'; const low=num(SESSION.get('st_range.low')) ?? P.default_low; return g<low?'Below your low':'In or above range'; },
 'ca.zone': ()=>{ const P=RULESPEC['ca.zone'].params; const pef=num(SESSION.get('ca_zone.peak_flow')); const sym=list(SESSION.get('ca_zone.symptoms'));
   const green=num(SESSION.get('ca_plan.green_from')) ?? P.default_green_from, red=num(SESSION.get('ca_plan.red_below')) ?? P.default_red_below;
   if(pef!=null&&(pef<P.pef_min||pef>P.pef_max)) return 'Invalid peak flow';
   if(sym.some(x=>P.red_symptoms.includes(x))||(pef!=null&&pef<red)) return 'Red';
   if((pef!=null&&pef<green)||sym.length) return 'Yellow'; return 'Green'; },
 'ea.selfharm': ()=> list(SESSION.get('ea_mood.going_on')).some(x=>RULESPEC['ea.selfharm'].params.triggers.includes(x))?'Yes':'No',
 'rec.manual': ()=>{ const R=RULESPEC['rec.manual'].params.ranges; const test=SESSION.get('records_manual.test')||'A1C'; const v=num(latest(['records_manual.value','records_manual_error.value'])); if(v==null) return null;
   const r=R[test]||[0,Infinity]; return (v<r[0]||v>r[1])?'Outside expected range':'Valid'; },
 'sf.unplug.reason': ()=> (list(SESSION.get('sf_unplug_session_end.reason')).length || String(SESSION.get('sf_unplug_session_end.note')||'').trim()) ? 'Reason given' : 'No reason yet',
 'sf.unplug.sentence': ()=>{ const n=s=>String(s||'').toLowerCase().trim().replace(/\s+/g,' ').replace(/[.!]+$/,''); return n(SESSION.get('sf_unplug_gate_commit.sentence'))===n(RULESPEC['sf.unplug.sentence'].params.sentence)?'Step done':'Step not done' },
 'sf.unplug.sum': ()=>{ const P=RULESPEC['sf.unplug.sum'].params; return num(SESSION.get('sf_unplug_gate_sum.answer'))===P.a+P.b?'Step done':'Step not done' },
};
function decide(d){ if(!d) return null; if(d.startsWith('choice:')) return SESSION.get(d.slice(7)); return RULES[d]?RULES[d]():null }
function match(sel, labels){ if(sel==null) return null; const s=String(sel).toLowerCase(); const L=labels.map(l=>l.toLowerCase());
  let i=L.indexOf(s); if(i<0) i=L.findIndex(l=>s.startsWith(l)||l.startsWith(s)); if(i<0) i=L.findIndex(l=>l.includes(s)||s.includes(l.split(' ')[0])); return i>=0?labels[i]:null }
/* ---------------- inputs → session */
function valueOf(el){
  if(el.tagName==='INPUT') return el.value;
  if(el.classList.contains('chips')) return [...el.querySelectorAll('.chip.on')].map(c=>c.textContent.trim());
  if(el.classList.contains('seg')) { const o=el.querySelector('span.on'); return o?o.textContent.trim():null }
  if(el.classList.contains('opts')) { const o=el.querySelector('.opt.on'); return o?o.dataset.label:null }
  if(el.classList.contains('tg')) return el.classList.contains('on');
  return null;
}
function captureAll(){ document.querySelectorAll('#phone [data-key]').forEach(el=>setV(el.dataset.key, valueOf(el))) }
function recompute(){ document.querySelectorAll('#phone .zone[data-rule]').forEach(z=>{ const r=decide(z.dataset.rule); if(!r) return; const k=r.toLowerCase();
  z.querySelectorAll('span').forEach(s=>s.classList.toggle('on', s.className.includes('z-'+k))) }) }
/* ---------------- render */
function render(){
  const id=cur(); visited.add(id); if(id==='ob_setup') onboarding=true;
  const tpl=document.getElementById('t_'+id); $('#phone').innerHTML=tpl.innerHTML;
  captureAll(); recompute();
  const m=M[id]; const base=m.variantOf?M[m.variantOf]:m;
  $('#sname').textContent=m.name; $('#sroute').textContent=m.route; $('#skind').textContent=m.kind+(m.program?' · '+m.program:'')+' · phase: '+m.phase;
  $('#sdesc').textContent=m.desc||''; $('#sapi').innerHTML=(m.api||[]).map(x=>'<code>'+x+'</code>').join(' ');
  const vs=[base.id].concat(base.variants||[]);
  $('#svars').innerHTML=vs.length>1?vs.map(v=>`<button class="chipb${v===id?' on':''}" data-v="${v}">${M[v].state}</button>`).join(''):'<span class="muted">Single state</span>';
  $('#sacts').innerHTML=m.actions.map((a,i)=>`<tr><td>${a.label}</td><td><code>${a.text.replace(/</g,'&lt;')}</code></td><td>${a.action?'<button class="go" data-i="'+i+'">Try</button>':''}</td></tr>`).join('');
  $('#crumbs').innerHTML=stack.map(s=>`<span>${M[s].name}</span>`).join(' › ');
  document.querySelectorAll('.fl li').forEach(li=>li.classList.toggle('on',li.dataset.id===id));
  $('#phone').classList.toggle('showhot',hot);
}
function nav(to,mode){ if(!M[to]){toast('Missing '+to);return}
  if(mode==='replace') stack[stack.length-1]=to; else stack.push(to); render(); }
/* ---------------- decisions */
function chooser(title, sub, cases, provider){
  return new Promise(res=>{ chooserResolve=res; const d=$('#chooser');
    d.className='on'+(provider?' os '+provider:'');
    d.querySelector('h4').textContent=title; d.querySelector('p').textContent=sub;
    d.querySelector('div').innerHTML=cases.map((c,i)=>`<button data-c="${i}" class="${i===0?'primary':''}">${c}</button>`).join(''); }) }
async function branch(a){
  const labels=a.cases.map(c=>c.label); let pick=null;
  if(FORCE && labels.includes(FORCE)) pick=FORCE;
  if(!pick && a.decide) pick=match(decide(a.decide), labels);
  if(!pick && QUEUE.length) pick=match(QUEUE.shift(), labels);
  if(!pick){
    if(a.provider==='apple') pick=labels[await chooser('Sign in with Apple','Use your Apple ID “alex@icloud.com” with Tether Health? · Share My Email / Hide My Email', labels, 'apple')];
    else if(a.provider==='google') pick=labels[await chooser('Choose an account','to continue to Tether Health · Alex · alex@gmail.com', labels, 'google')];
    else pick=labels[await chooser('Simulate: '+a.question,'Real logic decides this in the app. Pick an outcome to follow that path.', labels)];
  }
  const c=a.cases.find(c=>c.label===pick); if(c) await run(c.action);
}
async function run(a){ if(!a) return;
  switch(a.type){
    case 'push': case 'sheet': nav(resolveTo(a),'push'); break;
    case 'replace': nav(resolveTo(a),'replace'); break;
    case 'tab': stack=[a.to]; render(); break;
    case 'reset': stack=[a.to]; onboarding=false; render(); break;
    case 'popto': { const i=stack.lastIndexOf(a.to); if(i>=0){ stack=stack.slice(0,i+1); render() } else nav(a.to,'replace'); break; }
    case 'back': case 'close': if(stack.length>1){stack.pop(); render()} else toast('Start of history'); break;
    case 'toast': toast(a.value); if(a.then){ await sleep(600); await run(a.then) } break;
    case 'submit': toast('✓ '+a.api); await sleep(450); await run(a.then); break;
    case 'call': lastPlatform='call:'+a.value; toast('Would call '+a.label); break;
    case 'sms': lastPlatform='sms:'+a.value; toast('Would open Messages: '+a.value); break;
    case 'external': lastPlatform='external:'+a.value; toast('Would open '+a.value); break;
    case 'os_settings': lastPlatform='os_settings:'; toast('Would open phone Settings'); break;
    case 'branch': await branch(a); break;
  }
}
/* ---------------- interaction */
document.addEventListener('input',ev=>{ const el=ev.target.closest('#phone [data-key]'); if(el) setV(el.dataset.key, valueOf(el)) });
document.addEventListener('click',ev=>{
  const ph=ev.target.closest('#phone');
  if(ph){
    if(ev.target.closest('input')) return;
    const h=ev.target.closest('[data-a]'); if(h){ev.preventDefault(); lastRun=run(JSON.parse(h.dataset.a)); return}
    const chip=ev.target.closest('.chip'); if(chip){ if(chip.dataset.multi==='0') chip.parentNode.querySelectorAll('.chip').forEach(c=>{ if(c!==chip) c.classList.remove('on') }); chip.classList.toggle('on'); const k=chip.parentNode.dataset.key; if(k) setV(k,valueOf(chip.parentNode)); return}
    const sg=ev.target.closest('.seg span'); if(sg){sg.parentNode.querySelectorAll('span').forEach(c=>c.classList.remove('on')); sg.classList.add('on'); const k=sg.parentNode.dataset.key; if(k) setV(k,valueOf(sg.parentNode)); return}
    const z=ev.target.closest('.zone span'); if(z && !z.parentNode.dataset.rule){z.parentNode.querySelectorAll('span').forEach(c=>c.classList.remove('on')); z.classList.add('on'); return}
    const o=ev.target.closest('.opt'); if(o){o.parentNode.querySelectorAll('.opt').forEach(c=>c.classList.remove('on')); o.classList.add('on'); const k=o.parentNode.dataset.key; if(k) setV(k,valueOf(o.parentNode)); return}
    const t=ev.target.closest('.tg'); if(t){t.classList.toggle('on'); if(t.dataset.key) setV(t.dataset.key,valueOf(t)); return}
    const ck=ev.target.closest('.ckr'); if(ck){ck.querySelector('.ck').classList.toggle('on'); return}
    const tl=ev.target.closest('.tile'); if(tl){tl.classList.toggle('on'); return}
    return;
  }
  const li=ev.target.closest('.fl li'); if(li){stack=[li.dataset.id]; onboarding=false; render(); return}
  const v=ev.target.closest('[data-v]'); if(v){stack[stack.length-1]=v.dataset.v; render(); return}
  const g=ev.target.closest('.go'); if(g){run(M[cur()].actions[+g.dataset.i].action); return}
  const c=ev.target.closest('#chooser [data-c]'); if(c){$('#chooser').className=''; const r=chooserResolve; chooserResolve=null; r&&r(+c.dataset.c); return}
  const tb=ev.target.closest('.ptab'); if(tb){ document.querySelectorAll('.ptab').forEach(x=>x.classList.toggle('on',x===tb)); document.querySelectorAll('.pane').forEach(p=>p.hidden=p.id!==tb.dataset.p); return }
  const rs=ev.target.closest('[data-run]'); if(rs){ runScenario(SC.find(s=>s.id===rs.dataset.run)); return }
});
$('#hot').addEventListener('change',e=>{hot=e.target.checked; render()});
$('#plat').addEventListener('change',e=>{document.body.dataset.platform=e.target.value});
$('#restart').addEventListener('click',()=>{stack=[START]; onboarding=false; SESSION.clear(); render()});
$('#back').addEventListener('click',()=>run({type:'back'}));
$('#runall').addEventListener('click',()=>runAll());
/* ---------------- simulator */
function findTap(label){
  const root=$('#phone'); const L=label.trim(); const cands=[];
  root.querySelectorAll('[data-a],.chip,.seg span,.opt,.ckr,.tile,.zone span').forEach(el=>{
    let t; if(el.classList.contains('opt')) t=el.dataset.label;
    else if(el.matches('.lr')) t=(el.querySelector('.ol b')||el).textContent;
    else if(el.matches('.card')) t=(el.querySelector('.ct')||{textContent:''}).textContent;
    else if(el.matches('.tile')) t=(el.querySelector('b')||el).textContent;
    else if(el.matches('.tab')||el.matches('.abtn')) t=(el.querySelector('span')||el).textContent;
    else t=el.textContent;
    if(t && t.trim().replace(/^✓/,'')===L && el.offsetParent!==null) cands.push(el); });
  return cands.length?cands[cands.length-1]:null;
}
async function runScenario(sc, quiet){
  stack=[sc.start]; onboarding=false; SESSION.clear(); QUEUE.length=0; FORCE=null;
  const ios=sc.steps.some(s=>s[0]==='tap'&&s[1].includes('Apple'));
  document.body.dataset.platform=ios?'ios':'android'; $('#plat').value=document.body.dataset.platform;
  render(); const log=[]; let ok=true, why='';
  const row=document.querySelector(`[data-sc="${sc.id}"]`); if(row) row.dataset.state='run';
  for(const st of sc.steps){
    await sleep(quiet?0:380);
    if(st[0]==='tap'){ const el=findTap(st[1]); if(!el){ok=false; why=`No “${st[1]}” on ${cur()}`; break}
      el.classList.add('simhit'); await sleep(quiet?0:220); lastRun=null; el.click(); if(lastRun) await lastRun; await sleep(quiet?0:120); }
    else if(st[0]==='enter'){ const el=document.querySelector(`#phone input[data-key="${st[1]}"]`); if(!el){ok=false; why='No field '+st[1]; break}
      el.value=st[2]; el.dispatchEvent(new Event('input',{bubbles:true})); el.classList.add('simhit'); }
    else if(st[0]==='choose'){ QUEUE.push(st[1]) }
    else if(st[0]==='expect'){ if(cur()!==st[1]){ok=false; why=`Expected ${st[1]}, at ${cur()}`; break} }
    log.push(st);
  }
  if(ok && cur()!==sc.expect){ ok=false; why=`Expected ${sc.expect}, ended at ${cur()}` }
  if(row){ row.dataset.state=ok?'pass':'fail'; row.title=ok?'Passed':why; }
  return {id:sc.id, ok, why, end:cur()};
}
async function settle(){ for(let i=0;i<20;i++){ await new Promise(r=>setTimeout(r, FAST?1:60)); if(!document.querySelector('#chooser.on')) break } }
async function runAll(quiet){
  const res=[]; for(const sc of SC){ res.push(await runScenario(sc, quiet)) }
  const pass=res.filter(r=>r.ok).length; $('#simsum').textContent=`${pass} / ${res.length} scenarios passed · ${visited.size} of ${Object.keys(M).length} screens visited`;
  return res;
}
async function sweep(){
  FAST=true; const out=[];
  for(const x of EXP){
    stack=['today', x.screen]; onboarding=false; SESSION.clear(); QUEUE.length=0; FORCE=x.force; lastToast=null; lastPlatform=null;
    document.body.dataset.platform=x.platform; render(); onboarding=x.onboarding;
    const el=document.querySelector(`#phone [data-path="${x.path}"]`);
    let ok=false, got='';
    if(!el){ got='missing element' } else {
      await run(JSON.parse(el.dataset.a)); await new Promise(r=>setTimeout(r,2));
      const e=x.expect;
      if(e.kind==='route'){ ok=cur()===e.screen; got=cur() }
      else if(e.kind==='pop'){ ok=cur()==='today'; got=cur() }
      else if(e.kind==='toast'){ ok=lastToast===e.text; got=lastToast }
      else if(e.kind==='platform'){ ok=lastPlatform===e.value; got=lastPlatform }
    }
    out.push({screen:x.screen, path:x.path, force:x.force, onboarding:x.onboarding, ok, got});
  }
  FORCE=null; FAST=false; return out;
}
window.__sweep=sweep; window.__runAll=async()=>{FAST=true; const r=await runAll(true); FAST=false; return r};
function fit(){const s=Math.min(1,(innerHeight-80)/868); $('#frame').style.transform=`scale(${s})`; $('#stage').style.height=(868*s+10)+'px'}
addEventListener('resize',fit); fit(); document.body.dataset.platform='ios'; render();
"""

PROTO_CSS = r"""
*{box-sizing:border-box}body{margin:0;font-family:"Helvetica Neue",Helvetica,Arial,system-ui,sans-serif;background:#EEF1EC;color:#123C37;display:grid;grid-template-columns:300px 1fr 420px;height:100vh;overflow:hidden}
aside,section.info{overflow-y:auto;padding:16px 18px;background:#FBF8F0;border-right:1px solid #DCE6E0}
section.info{border-right:0;border-left:1px solid #DCE6E0}
h1{font:800 18px/1.2 inherit;margin:0 0 4px;display:flex;gap:8px;align-items:center}h1 i{width:26px;height:26px;border-radius:50%;background:#123C37;display:inline-block}
.muted{color:#5A726C;font-size:12.5px}
.ptabs{display:flex;gap:6px;margin:12px 0 4px}.ptab{flex:1;border:1.5px solid #B6C8C2;background:#fff;border-radius:10px;padding:7px;font-weight:800;color:#123C37;cursor:pointer;font-size:12.5px}.ptab.on{background:#123C37;color:#fff;border-color:#123C37}
.fl h3,.sim h3{font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:#5A726C;margin:16px 0 6px;display:flex;align-items:center;gap:6px}.fl h3 b,.sim h3 b{width:10px;height:10px;border-radius:3px;display:inline-block}
.fl ul,.sim ul{list-style:none;margin:0;padding:0}.fl li{font-size:13px;padding:5px 8px;border-radius:8px;cursor:pointer;display:flex;justify-content:space-between;gap:6px}.fl li:hover{background:#E8EFEA}.fl li.on{background:#123C37;color:#fff}
.fl li small{opacity:.7;font-size:11px}
.sim li{font-size:12.5px;padding:6px 8px;border-radius:8px;display:flex;gap:8px;align-items:center;cursor:pointer}.sim li:hover{background:#E8EFEA}
.sim li::before{content:"○";width:16px;text-align:center;color:#8BA09A;font-weight:800}
.sim li[data-state=run]::before{content:"◔";color:#3B4CC0}.sim li[data-state=pass]::before{content:"✓";color:#2E6B3A}.sim li[data-state=fail]::before{content:"✕";color:#B3261E}
.sim li small{color:#5A726C;margin-left:auto;font-size:10.5px;white-space:nowrap}
#runall{width:100%;border:0;background:#123C37;color:#fff;border-radius:12px;padding:10px;font-weight:800;cursor:pointer;margin-top:8px}
#simsum{font-size:12.5px;font-weight:700;margin-top:8px}
main{display:flex;flex-direction:column;align-items:center;padding:12px;gap:8px;overflow:hidden}
.bar{display:flex;gap:10px;align-items:center;font-size:13px;width:100%;justify-content:center;flex-wrap:wrap}
.bar button,.bar select{border:1.5px solid #B6C8C2;background:#FFFDF7;border-radius:10px;padding:6px 12px;font-weight:700;color:#123C37;cursor:pointer}
#crumbs{font-size:12px;color:#5A726C;max-width:680px;text-align:center;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#stage{width:100%;display:flex;justify-content:center}
#frame{transform-origin:top center;width:414px;height:868px;border-radius:56px;background:#0B2320;padding:12px;box-shadow:0 40px 60px -30px rgba(18,60,55,.5);position:relative}
#phone{border-radius:44px;overflow:hidden;width:390px;height:844px}
#phone.showhot .hot{outline:2.5px solid #FF3B7F!important;outline-offset:-1px}
#phone .simhit{outline:3px solid #3B4CC0!important;outline-offset:1px;transition:outline .1s}
#toast{position:absolute;left:50%;top:76px;transform:translateX(-50%) translateY(-10px);background:#123C37;color:#fff;padding:10px 16px;border-radius:12px;font-size:14px;font-weight:700;opacity:0;transition:all .25s;z-index:20;max-width:340px;text-align:center;pointer-events:none}
#toast.on{opacity:1;transform:translateX(-50%) translateY(0)}
#chooser{position:fixed;inset:0;background:rgba(11,35,32,.45);display:none;place-items:center;z-index:50}#chooser.on{display:grid}
#chooser>section{background:#FFFDF7;border-radius:18px;padding:18px;width:360px}#chooser h4{margin:0 0 4px}#chooser p{margin:0 0 12px;font-size:12.5px;color:#5A726C}
#chooser div{display:flex;flex-direction:column;gap:8px}#chooser button{border:1.5px solid #B6C8C2;background:#fff;border-radius:12px;padding:11px;font-weight:700;color:#123C37;cursor:pointer;text-align:left}
#chooser.os.apple>section{background:#1C1C1E;color:#fff}#chooser.os.apple p{color:#AEAEB2}#chooser.os.apple button{background:#2C2C2E;color:#fff;border-color:#3A3A3C}#chooser.os.apple button.primary{background:#fff;color:#000}
#chooser.os.google>section{background:#fff}#chooser.os.google h4{font-family:Roboto,Arial,sans-serif}#chooser.os.google button.primary{background:#1A73E8;color:#fff;border-color:#1A73E8}
.info h2{font:800 22px/1.2 inherit;margin:0}.info code{font-size:11.5px;background:#EAF1EC;padding:1px 5px;border-radius:5px;word-break:break-word}
.info h4{font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:#5A726C;margin:18px 0 6px}
.info table{width:100%;border-collapse:collapse;font-size:12.5px}.info td{border-top:1px solid #DCE6E0;padding:7px 4px;vertical-align:top}.info td:first-child{font-weight:700;width:34%}
.go{border:0;background:#123C37;color:#fff;border-radius:8px;padding:4px 9px;font-size:11.5px;cursor:pointer;font-weight:700}
.chipb{border:1.5px solid #B6C8C2;background:#fff;border-radius:16px;padding:4px 10px;margin:0 6px 6px 0;font-size:12px;font-weight:700;color:#123C37;cursor:pointer}.chipb.on{background:#123C37;color:#fff;border-color:#123C37}
label{font-size:13px;font-weight:700;display:flex;gap:6px;align-items:center}
"""

def build_prototype(m, expect, scenarios, rules):
    flows_html = ''
    for fid, f in FLOWS.items():
        dot = PROGRAMS[f['program']][3] if f.get('program') else '#123C37'
        items = ''.join(f'<li data-id="{sid}"><span>{e(SCREENS[sid]["name"])}</span><small>{e(SCREENS[sid]["state"] if SCREENS[sid]["variantOf"] else SCREENS[sid]["kind"] if SCREENS[sid]["kind"] != "screen" else "")}</small></li>' for sid in f['screens'])
        flows_html += f'<h3><b style="background:{dot}"></b>{e(f["title"])}</h3><ul>{items}</ul>'
    groups = {}
    for scn in scenarios: groups.setdefault(scn['program'] or 'shell', []).append(scn)
    sim_html = ''
    for g, items in groups.items():
        name = PROGRAMS[g][0] if g in PROGRAMS else 'Account, records & app shell'
        dot = PROGRAMS[g][3] if g in PROGRAMS else '#123C37'
        sim_html += f'<h3><b style="background:{dot}"></b>{e(name)}</h3><ul>' + ''.join(f'<li data-sc="{s["id"]}" data-run="{s["id"]}">{e(s["title"])}<small>{e(s["function"])}</small></li>' for s in items) + '</ul>'
    tpls = ''.join(f'<template id="t_{sid}">{render_screen(s)}</template>' for sid, s in SCREENS.items())
    flows = {fid: {'title': f['title'], 'screens': f['screens']} for fid, f in FLOWS.items()}
    return f'''<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Tether Health · Clickable prototype & simulator</title>
<style>{CSS}{PROTO_CSS}</style></head><body>
<aside><h1><i></i>Tether Health</h1><p class="muted">{len(SCREENS)} screens · {sum(len(m[k]["actions"]) for k in m)} wired actions · {len(scenarios)} end-to-end scenarios. Generated from <code>spec/</code>; decisions use the same rules as the Flutter app.</p>
<div class="ptabs"><button class="ptab on" data-p="p_screens">Screens</button><button class="ptab" data-p="p_sim">Simulator</button></div>
<div class="pane fl" id="p_screens">{flows_html}</div>
<div class="pane sim" id="p_sim" hidden><p class="muted">Each scenario drives the real screens: taps buttons, types simulated data (BP 186/122, glucose 62, peak flow 150…) and checks where it lands. Click one to watch it, or run all.</p><button id="runall">▶ Run all scenarios</button><div id="simsum"></div>{sim_html}</div></aside>
<main><div class="bar"><button id="restart">⟲ Restart</button><button id="back">‹ Back</button><select id="plat" aria-label="Platform"><option value="ios">iPhone</option><option value="android">Android</option></select><label><input type="checkbox" id="hot"> Show tap targets</label></div><div id="crumbs"></div>
<div id="stage"><div id="frame"><div id="phone"></div><div id="toast"></div></div></div></main>
<section class="info"><p class="muted">Screen</p><h2 id="sname"></h2><p><code id="sroute"></code></p><p class="muted" id="skind"></p><p id="sdesc" style="font-size:13.5px"></p>
<h4>States</h4><div id="svars"></div><h4>Actions on this screen</h4><table id="sacts"></table><h4>API</h4><div id="sapi" class="muted"></div></section>
<div id="chooser"><section><h4></h4><p></p><div></div></section></div>
{tpls}
<script>const META={json.dumps(m, ensure_ascii=False)};const FLOWS={json.dumps(flows, ensure_ascii=False)};const SCENARIOS={json.dumps(scenarios, ensure_ascii=False)};const EXPECT={json.dumps(expect, ensure_ascii=False)};const RULESPEC={json.dumps(rules, ensure_ascii=False)};const START="welcome";{PROTO_JS}</script></body></html>'''
