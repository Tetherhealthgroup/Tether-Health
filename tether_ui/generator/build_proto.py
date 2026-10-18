import json, os, html
from dsl import *
from render_html import render_screen, CSS, e
from validate import validate

OUT = os.path.expanduser('~/tether/tether_ui')

def describe(a):
    if not a: return 'disabled'
    t = a['type']
    if t in ('push', 'replace', 'tab', 'sheet', 'reset', 'popto'):
        s = f'{t} → {a["to"]}'
        if a.get('context'): s += f' (onboarding: {a["context"]["onboarding"]})'
        return s
    if t == 'branch': return ('auth (' + a['provider'] + '): ' if a.get('provider') else ('decide ' + a['decide'] + ': ' if a.get('decide') else 'branch: ')) + a['question'] + ' → ' + ' | '.join(f'{c["label"]}: {describe(c["action"])}' for c in a['cases'])
    if t == 'toast': return f'toast “{a["value"]}”' + (f' then {describe(a["then"])}' if a.get('then') else '')
    if t == 'submit': return f'{a["api"]} then {describe(a["then"])}'
    if t in ('call', 'sms', 'external'): return f'{t} {a["value"]}'
    return t

def meta():
    variants = {}
    for sid, s in SCREENS.items():
        if s['variantOf']: variants.setdefault(s['variantOf'], []).append(sid)
    out = {}
    for sid, s in SCREENS.items():
        out[sid] = {'id': sid, 'name': s['name'], 'route': s['route'], 'flow': s['flow'], 'kind': s['kind'], 'program': s['program'], 'phase': s['phase'],
                    'state': s['state'] or 'default', 'variantOf': s['variantOf'], 'variants': variants.get(sid, []), 'desc': s['desc'], 'api': s['api'],
                    'actions': [{'label': l, 'path': p, 'action': a, 'text': describe(a)} for l, p, a in actions_of(s)]}
    return out

PROTO_JS = r"""
const M = META, F = FLOWS; let stack=[START], onboarding=false, hot=false;
const $=s=>document.querySelector(s);
function cur(){return stack[stack.length-1]}
function resolve(a){ return (a.context && onboarding) ? a.context.onboarding : a.to }
function toast(t){const el=$('#toast');el.textContent=t;el.classList.add('on');clearTimeout(el._t);el._t=setTimeout(()=>el.classList.remove('on'),1800)}
function render(){
  const id=cur(); if(id==='ob_setup') onboarding=true;
  const tpl=document.getElementById('t_'+id); $('#phone').innerHTML=tpl.innerHTML;
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
function nav(to,mode){ if(!M[to]&&['today','plans','progress','learn','support'].indexOf(to)<0){toast('Missing '+to);return}
  if(mode==='replace') stack[stack.length-1]=to; else stack.push(to); render(); }
function matchCase(a){
  const root=$('#phone'); let sel=null;
  if(a.on==='radio'){const o=root.querySelector('.opt.on'); sel=o&&o.dataset.label}
  if(a.on==='segmented'){const o=root.querySelector('.seg span.on'); sel=o&&o.textContent}
  if(a.on==='zone'){const o=root.querySelector('.zone span.on'); sel=o&&o.textContent}
  if(!sel) return null; sel=sel.toLowerCase();
  const L=a.cases.map(c=>c.label.toLowerCase());
  let i=L.indexOf(sel); if(i<0) i=L.findIndex(l=>sel.startsWith(l)||l.startsWith(sel)); if(i<0) i=L.findIndex(l=>l.includes(sel)||sel.includes(l.split(' ')[0]));
  return i>=0?a.cases[i]:null;
}
function choose(a){
  const c=matchCase(a); if(c){run(c.action);return}
  const d=$('#chooser'); d.querySelector('h4').textContent='Simulate: '+a.question;
  d.querySelector('div').innerHTML=a.cases.map((c,i)=>`<button data-c="${i}">${c.label}</button>`).join('');
  d._a=a; d.classList.add('on');
}
function run(a){ if(!a) return;
  switch(a.type){
    case 'push': case 'sheet': nav(resolve(a),'push'); break;
    case 'replace': nav(resolve(a),'replace'); break;
    case 'tab': stack=[a.to]; render(); break;
    case 'reset': stack=[a.to]; onboarding=false; render(); break;
    case 'back': case 'close': if(stack.length>1){stack.pop(); render()} else toast('Start of history'); break;
    case 'toast': toast(a.value); if(a.then) setTimeout(()=>run(a.then),600); break;
    case 'submit': toast('✓ '+a.api); setTimeout(()=>run(a.then),450); break;
    case 'call': toast('Would call '+a.label); break;
    case 'sms': toast('Would open Messages: '+a.value); break;
    case 'external': toast('Would open '+a.value); break;
    case 'os_settings': toast('Would open phone Settings'); break;
    case 'branch': choose(a); break;
  }
}
document.addEventListener('click',ev=>{
  const ph=ev.target.closest('#phone');
  if(ph){
    const h=ev.target.closest('[data-a]'); if(h){ev.preventDefault(); run(JSON.parse(h.dataset.a)); return}
    const chip=ev.target.closest('.chip'); if(chip){ if(chip.dataset.multi==='0') chip.parentNode.querySelectorAll('.chip').forEach(c=>c.classList.remove('on')); chip.classList.toggle('on'); return}
    const sg=ev.target.closest('.seg span'); if(sg){sg.parentNode.querySelectorAll('span').forEach(c=>c.classList.remove('on')); sg.classList.add('on'); return}
    const z=ev.target.closest('.zone span'); if(z){z.parentNode.querySelectorAll('span').forEach(c=>c.classList.remove('on')); z.classList.add('on'); return}
    const o=ev.target.closest('.opt'); if(o){o.parentNode.querySelectorAll('.opt').forEach(c=>c.classList.remove('on')); o.classList.add('on'); return}
    const t=ev.target.closest('.tg'); if(t){t.classList.toggle('on'); return}
    const ck=ev.target.closest('.ckr'); if(ck){ck.querySelector('.ck').classList.toggle('on'); return}
    const tl=ev.target.closest('.tile'); if(tl){tl.classList.toggle('on'); return}
    return;
  }
  const li=ev.target.closest('.fl li'); if(li){stack=[li.dataset.id]; onboarding=false; render(); return}
  const v=ev.target.closest('[data-v]'); if(v){stack[stack.length-1]=v.dataset.v; render(); return}
  const g=ev.target.closest('.go'); if(g){run(M[cur()].actions[+g.dataset.i].action); return}
  const c=ev.target.closest('#chooser [data-c]'); if(c){const d=$('#chooser'); d.classList.remove('on'); run(d._a.cases[+c.dataset.c].action); return}
  if(ev.target.id==='chooser') ev.target.classList.remove('on');
});
$('#hot').addEventListener('change',e=>{hot=e.target.checked; render()});
$('#restart').addEventListener('click',()=>{stack=[START]; onboarding=false; render()});
$('#back').addEventListener('click',()=>run({type:'back'}));
function fit(){const s=Math.min(1,(innerHeight-70)/868); $('#frame').style.transform=`scale(${s})`; $('#stage').style.height=(868*s+10)+'px'}
addEventListener('resize',fit); fit(); render();
"""

PROTO_CSS = r"""
*{box-sizing:border-box}body{margin:0;font-family:"Helvetica Neue",Helvetica,Arial,system-ui,sans-serif;background:#EEF1EC;color:#123C37;display:grid;grid-template-columns:290px 1fr 420px;height:100vh;overflow:hidden}
aside,section.info{overflow-y:auto;padding:16px 18px;background:#FBF8F0;border-right:1px solid #DCE6E0}
section.info{border-right:0;border-left:1px solid #DCE6E0}
h1{font:800 18px/1.2 inherit;margin:0 0 4px;display:flex;gap:8px;align-items:center}h1 i{width:26px;height:26px;border-radius:50%;background:#123C37;display:inline-block}
.muted{color:#5A726C;font-size:12.5px}
.fl{margin:14px 0 0}.fl h3{font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:#5A726C;margin:16px 0 6px;display:flex;align-items:center;gap:6px}.fl h3 b{width:10px;height:10px;border-radius:3px;display:inline-block}
.fl ul{list-style:none;margin:0;padding:0}.fl li{font-size:13px;padding:5px 8px;border-radius:8px;cursor:pointer;display:flex;justify-content:space-between;gap:6px}.fl li:hover{background:#E8EFEA}.fl li.on{background:#123C37;color:#fff}
.fl li small{opacity:.7;font-size:11px}
main{display:flex;flex-direction:column;align-items:center;padding:12px;gap:8px;overflow:hidden}
.bar{display:flex;gap:10px;align-items:center;font-size:13px;width:100%;justify-content:center;flex-wrap:wrap}
.bar button{border:1.5px solid #B6C8C2;background:#FFFDF7;border-radius:10px;padding:6px 12px;font-weight:700;color:#123C37;cursor:pointer}
#crumbs{font-size:12px;color:#5A726C;max-width:680px;text-align:center;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#stage{width:100%;display:flex;justify-content:center}
#frame{transform-origin:top center;width:414px;height:868px;border-radius:56px;background:#0B2320;padding:12px;box-shadow:0 40px 60px -30px rgba(18,60,55,.5);position:relative}
#phone{border-radius:44px;overflow:hidden;width:390px;height:844px}
#phone.showhot .hot{outline:2.5px solid #FF3B7F!important;outline-offset:-1px}
#toast{position:absolute;left:50%;top:110px;transform:translateX(-50%) translateY(-10px);background:#123C37;color:#fff;padding:10px 16px;border-radius:12px;font-size:14px;font-weight:700;opacity:0;transition:all .25s;z-index:20;max-width:340px;text-align:center;pointer-events:none}
#toast.on{opacity:1;transform:translateX(-50%) translateY(0)}
#chooser{position:fixed;inset:0;background:rgba(11,35,32,.45);display:none;place-items:center;z-index:50}#chooser.on{display:grid}
#chooser>section{background:#FFFDF7;border-radius:18px;padding:18px;width:360px}#chooser h4{margin:0 0 4px}#chooser p{margin:0 0 12px;font-size:12.5px;color:#5A726C}
#chooser div{display:flex;flex-direction:column;gap:8px}#chooser button{border:1.5px solid #B6C8C2;background:#fff;border-radius:12px;padding:11px;font-weight:700;color:#123C37;cursor:pointer;text-align:left}
.info h2{font:800 22px/1.2 inherit;margin:0}.info code{font-size:11.5px;background:#EAF1EC;padding:1px 5px;border-radius:5px;word-break:break-word}
.info h4{font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:#5A726C;margin:18px 0 6px}
.info table{width:100%;border-collapse:collapse;font-size:12.5px}.info td{border-top:1px solid #DCE6E0;padding:7px 4px;vertical-align:top}.info td:first-child{font-weight:700;width:34%}
.go{border:0;background:#123C37;color:#fff;border-radius:8px;padding:4px 9px;font-size:11.5px;cursor:pointer;font-weight:700}
.chipb{border:1.5px solid #B6C8C2;background:#fff;border-radius:16px;padding:4px 10px;margin:0 6px 6px 0;font-size:12px;font-weight:700;color:#123C37;cursor:pointer}.chipb.on{background:#123C37;color:#fff;border-color:#123C37}
label{font-size:13px;font-weight:700;display:flex;gap:6px;align-items:center}
"""

def build_prototype(m):
    flows_html = ''
    for fid, f in FLOWS.items():
        dot = PROGRAMS[f['program']][3] if f.get('program') else '#123C37'
        items = ''.join(f'<li data-id="{sid}"><span>{e(SCREENS[sid]["name"])}</span><small>{e(SCREENS[sid]["state"] if SCREENS[sid]["variantOf"] else SCREENS[sid]["kind"] if SCREENS[sid]["kind"] != "screen" else "")}</small></li>' for sid in f['screens'])
        flows_html += f'<h3><b style="background:{dot}"></b>{e(f["title"])}</h3><ul>{items}</ul>'
    tpls = ''.join(f'<template id="t_{sid}">{render_screen(s)}</template>' for sid, s in SCREENS.items())
    flows = {fid: {'title': f['title'], 'screens': f['screens']} for fid, f in FLOWS.items()}
    return f'''<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Tether Health · Clickable prototype</title>
<style>{CSS}{PROTO_CSS}</style></head><body>
<aside><h1><i></i>Tether Health</h1><p class="muted">Clickable prototype · {len(SCREENS)} screens · generated from <code>spec/screens.json</code>. Every button, row, tab and link is wired; branches let you pick the outcome.</p><div class="fl">{flows_html}</div></aside>
<main><div class="bar"><button id="restart">⟲ Restart</button><button id="back">‹ Back</button><label><input type="checkbox" id="hot"> Show tap targets</label></div><div id="crumbs"></div>
<div id="stage"><div id="frame"><div id="phone"></div><div id="toast"></div></div></div></main>
<section class="info"><p class="muted">Screen</p><h2 id="sname"></h2><p><code id="sroute"></code></p><p class="muted" id="skind"></p><p id="sdesc" style="font-size:13.5px"></p>
<h4>States</h4><div id="svars"></div><h4>Actions on this screen</h4><table id="sacts"></table><h4>API</h4><div id="sapi" class="muted"></div></section>
<div id="chooser"><section><h4></h4><p>Real logic decides this in the app. Pick an outcome to follow that path.</p><div></div></section></div>
{tpls}
<script>const META={json.dumps(m, ensure_ascii=False)};const FLOWS={json.dumps(flows, ensure_ascii=False)};const START="welcome";{PROTO_JS}</script></body></html>'''

def build_gallery():
    cells = ''.join(f'<div class="cell" data-id="{sid}">{render_screen(s).replace("class=\"scr", "class=\"scr export", 1)}</div>' for sid, s in SCREENS.items())
    return f'<!DOCTYPE html><html><head><meta charset="UTF-8"><style>{CSS} body{{margin:0;background:#fff;display:flex;flex-wrap:wrap;gap:20px;padding:20px;align-items:flex-start}} .cell{{width:390px}} .ring,.sk{{animation:none!important}}</style></head><body>{cells}</body></html>'

def build_flowboard(fid):
    f = FLOWS[fid]
    ids = f['screens']
    adj = {}
    ext = {}
    for sid in ids:
        for l, p, a in actions_of(SCREENS[sid]):
            for t in targets(a):
                if a['type'] == 'tab' and t != sid and SCREENS[sid].get('tab') and p.startswith('tabbar'):
                    continue
                adj.setdefault(sid, []).append((t, l))
    # levels by BFS from first screen; variants sit next to base
    level = {ids[0]: 0}
    q = [ids[0]]
    while q:
        x = q.pop(0)
        for t, l in adj.get(x, []):
            if t in ids and t not in level:
                level[t] = level[x] + 1; q.append(t)
    for sid in ids:
        if sid not in level:
            b = SCREENS[sid]['variantOf']
            level[sid] = level.get(b, 0) if b else max(level.values()) + 1
    cols = {}
    for sid in ids: cols.setdefault(level[sid], []).append(sid)
    externals = sorted({t for sid in ids for t, l in adj.get(sid, []) if t not in ids})
    colhtml = ''
    for lv in sorted(cols):
        cells = ''.join(f'<div class="nd" id="n_{sid}"><div class="th">{render_screen(SCREENS[sid])}</div><b>{e(SCREENS[sid]["name"])}</b><small>{e(SCREENS[sid]["route"])}</small></div>' for sid in cols[lv])
        colhtml += f'<div class="col">{cells}</div>'
    if externals:
        ex = ''.join(f'<div class="ex" id="n_{t}">→ {e(SCREENS[t]["name"] if t in SCREENS else t.title() + " tab")}<small>{e(FLOWS[SCREENS[t]["flow"]]["title"] if t in SCREENS else "Tab")}</small></div>' for t in externals)
        colhtml += f'<div class="col exc"><p class="exh">Leaves this flow</p>{ex}</div>'
    edges = [(s, t, l) for s in ids for t, l in adj.get(s, []) if t != s]
    seen = set(); E = []
    for s, t, l in edges:
        if (s, t) in seen: continue
        seen.add((s, t)); E.append([s, t, l])
    css = CSS + r"""
body{margin:0;background:#F4F1E8;font-family:"Helvetica Neue",Helvetica,Arial,sans-serif;color:#123C37}
.wrap{position:relative;padding:28px 36px 40px;display:inline-block;min-width:100%}
h1{font-size:28px;margin:0 0 4px}.sub2{color:#5A726C;font-size:14px;margin:0 0 24px;max-width:900px}
.board{display:flex;gap:90px;align-items:flex-start;position:relative;z-index:1}
.col{display:flex;flex-direction:column;gap:26px}
.nd{width:156px;display:flex;flex-direction:column;gap:3px}
.th{width:156px;height:337.6px;overflow:hidden;border-radius:20px;box-shadow:0 10px 24px -12px rgba(18,60,55,.45);border:3px solid #0B2320;background:#0B2320}
.th>.scr{transform:scale(.4);transform-origin:top left}
.nd b{font-size:13px}.nd small,.ex small{font-size:10.5px;color:#5A726C;display:block;font-weight:400}
.ex{background:#FFFDF7;border:1.5px dashed #B6C8C2;border-radius:12px;padding:8px 10px;font-size:12.5px;font-weight:700;width:170px}
.exh{font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:#5A726C;margin:0}
svg.edges{position:absolute;left:0;top:0;z-index:2;pointer-events:none;overflow:visible}
.ring,.sk{animation:none!important}
"""
    js = r"""
const E=EDGES, wrap=document.querySelector('.wrap'), svg=document.querySelector('svg.edges');
const W=wrap.scrollWidth,H=wrap.scrollHeight; svg.setAttribute('width',W); svg.setAttribute('height',H);
const wr=wrap.getBoundingClientRect(); let out='<defs><marker id="ar" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0L10,5L0,10z" fill="#B5432A"/></marker></defs>';
const lab=[];
E.forEach(([s,t,l],i)=>{const a=document.getElementById('n_'+s),b=document.getElementById('n_'+t); if(!a||!b) return;
 const ra=(a.querySelector('.th')||a).getBoundingClientRect(), rb=(b.querySelector('.th')||b).getBoundingClientRect();
 let x1,y1,x2,y2; const fwd=rb.left>ra.right-1;
 if(fwd){x1=ra.right-wr.left;y1=ra.top-wr.top+ra.height*(0.3+0.4*((i*37)%10)/10);x2=rb.left-wr.left-2;y2=rb.top-wr.top+Math.min(rb.height/2,60)}
 else if(Math.abs(rb.left-ra.left)<5){x1=ra.right-wr.left;y1=ra.top-wr.top+ra.height*0.8;x2=rb.right-wr.left+2;y2=rb.top-wr.top+rb.height*0.2}
 else {x1=ra.left-wr.left;y1=ra.top-wr.top+ra.height*0.7;x2=rb.right-wr.left+2;y2=rb.top-wr.top+rb.height*0.6}
 const dx=Math.max(40,Math.abs(x2-x1)/2); const c1=fwd?x1+dx:x1+(Math.abs(rb.left-ra.left)<5?60:-dx), c2=fwd?x2-dx:x2+(Math.abs(rb.left-ra.left)<5?60:dx);
 const back=!fwd; out+=`<path d="M${x1},${y1} C${c1},${y1} ${c2},${y2} ${x2},${y2}" fill="none" stroke="${back?'#7A918B':'#B5432A'}" stroke-width="1.6" ${back?'stroke-dasharray="5 4"':''} marker-end="url(#ar)" opacity=".85"/>`;
 if(fwd && l.length<40) lab.push(`<text x="${x1+8}" y="${y1-4}" font-size="10.5" fill="#123C37" font-weight="700" paint-order="stroke" stroke="#F4F1E8" stroke-width="3">${l.replace(/&/g,'&amp;').replace(/</g,'&lt;')}</text>`);
});
svg.innerHTML=out+lab.join('');
"""
    return f'''<!DOCTYPE html><html><head><meta charset="UTF-8"><style>{css}</style></head><body><div class="wrap"><h1>{e(f["title"])}</h1><p class="sub2">{e(f["desc"])} Solid red = forward navigation (label = the button or row that triggers it). Dashed grey = return/back paths.</p>
<div class="board">{colhtml}</div><svg class="edges"></svg></div><script>const EDGES={json.dumps(E, ensure_ascii=False)};{js}</script></body></html>'''
