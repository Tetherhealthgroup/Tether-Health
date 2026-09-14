#!/usr/bin/env python3
"""Generates a clickable prototype from the design JSON.

    python3 tools/prototype.py lookup en > prototype.html

Every tap is real: buttons navigate, back works, dead ends are visible.
A trace panel records the path so you can hand a tester a task and read
back exactly where they went.
"""
import json, pathlib, sys, html

ROOT = pathlib.Path(__file__).resolve().parent.parent
load = lambda p: json.loads((ROOT / p).read_text())
e = lambda s: html.escape(str(s), quote=True)

CSS = """
:root{--ink:#17352C;--inkSoft:#23453A;--cream:#F5F2EC;--card:#fff;--mint:#D7E9DE;
--mintPale:#E9F2EC;--coral:#EE6F55;--coralPale:#FCEBE5;--lime:#D4EC5A;--muted:#6E8078;--line:#E7E3DB}
*{box-sizing:border-box;margin:0;padding:0}
body{background:#EFEBE3;color:var(--ink);font:400 15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Inter,sans-serif}
.stage{display:flex;gap:28px;padding:32px;flex-wrap:wrap;align-items:flex-start;justify-content:center}
.phone{width:330px;min-height:660px;background:var(--cream);border:10px solid var(--ink);border-radius:38px;
padding:14px;display:flex;flex-direction:column}
.phone.dark{background:var(--ink)}
.bar{display:flex;align-items:center;gap:8px;margin-bottom:10px}
.bar .c{width:34px;height:34px;border-radius:50%;background:var(--card);border:0;font-size:15px;cursor:pointer}
.phone.dark .bar .c{background:transparent;border:1px solid #3A5B4E;color:#fff}
.bar .t{flex:1;text-align:center;font-size:14px;font-weight:600}
.phone.dark .bar .t,.phone.dark .hl,.phone.dark .sub{color:#fff}
.bg{background:var(--mint);font-size:10px;font-weight:600;letter-spacing:.08em;text-transform:uppercase;
padding:5px 10px;border-radius:99px;min-width:58px;text-align:center}
.pr{height:3px;background:var(--line);border-radius:2px;margin-bottom:12px}
.pr i{display:block;height:3px;background:var(--coral);border-radius:2px}
.scroll{flex:1;overflow:auto}
.hl{font-size:21px;font-weight:700;letter-spacing:-.3px;line-height:1.22;margin-bottom:5px}
.sub{font-size:13px;color:var(--muted);margin-bottom:14px}
.cd{background:var(--card);border-radius:16px;padding:14px;margin-bottom:10px}
.cd.mint{background:var(--mint)}.cd.mintPale{background:var(--mintPale)}.cd.coral{background:var(--coralPale)}
.cd.ink,.cd.inkSoft{background:var(--ink);color:#fff}.cd.inkSoft{background:var(--inkSoft)}
.cd.tap{cursor:pointer}
.eb{font-size:10px;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);margin-bottom:4px}
.cd.ink .eb,.cd.inkSoft .eb{color:#9FB8AC}
.ct{font-size:15px;font-weight:600;margin-bottom:3px}
.cb{font-size:13px;color:var(--muted);line-height:1.45}
.cd.ink .cb,.cd.inkSoft .cb{color:#9FB8AC}
.chips{display:flex;flex-wrap:wrap;gap:7px;margin-top:10px}
.chip{border:1px solid var(--line);background:var(--card);border-radius:99px;padding:8px 13px;font-size:12.5px;cursor:pointer}
.chip.on{background:var(--mintPale);border-color:var(--coral)}
.opt{border:1px solid var(--line);background:var(--card);border-radius:13px;padding:12px;margin-bottom:8px;
display:flex;gap:10px;align-items:flex-start;cursor:pointer}
.opt.on{border-color:var(--coral);background:var(--mintPale)}
.dot{width:15px;height:15px;border:1.5px solid #C9D3CD;border-radius:50%;flex:0 0 auto;margin-top:2px}
.opt.on .dot{background:var(--ink);border-color:var(--ink)}
.stats{display:flex;gap:9px;margin-bottom:10px}
.st{flex:1;background:var(--card);border-radius:14px;padding:12px}
.st b{font-size:19px;display:block}.st span{font-size:11px;color:var(--muted)}
.mt{background:var(--ink);color:#fff;border-radius:16px;padding:14px;margin-bottom:10px}
.mt .v{font-size:30px;font-weight:700}
.track{height:5px;background:#2E5548;border-radius:3px;margin-top:10px}
.track i{display:block;height:5px;background:var(--lime);border-radius:3px}
.bars{display:flex;align-items:flex-end;gap:4px;height:56px;margin-bottom:12px}
.bars i{flex:1;background:var(--mint);border-radius:3px;min-height:16px}
.bars i.on{background:var(--coral)}
.sl{background:var(--card);border-radius:16px;padding:14px;margin-bottom:10px}
.sl input{width:100%;accent-color:var(--coral)}
.mini{display:flex;justify-content:space-between;font-size:11px;color:var(--muted);margin-top:4px}
.rows{background:var(--card);border-radius:16px;padding:4px 14px;margin-bottom:10px}
.rw{padding:11px 0;border-bottom:1px solid #F0ECE4}.rw:last-child{border:0}
.rw .k{font-size:10px;letter-spacing:.08em;text-transform:uppercase;color:var(--muted)}
.rw .v{font-size:14px;font-weight:600}
.tm{background:var(--ink);border-radius:16px;padding:20px 14px;margin-bottom:10px;text-align:center;color:#fff}
.ring{width:118px;height:118px;border-radius:50%;background:var(--lime);color:var(--ink);margin:0 auto 12px;
display:flex;align-items:center;justify-content:center;font-size:34px;font-weight:700}
.tm .q{font-size:14px;font-weight:600;margin-top:4px}
.inp{background:var(--card);border-radius:16px;padding:14px;margin-bottom:10px}
.inp textarea{width:100%;border:1px solid var(--line);border-radius:10px;padding:10px;font:inherit;font-size:13px;resize:vertical}
.acts{padding-top:8px}
.btn{display:block;width:100%;border:0;border-radius:14px;padding:15px;font:inherit;font-size:14px;
font-weight:600;background:var(--ink);color:#fff;margin-bottom:8px;cursor:pointer;text-align:center}
.btn.ghost{background:var(--card);color:var(--ink);border:1px solid var(--line);font-weight:500}
.btn.lime{background:var(--lime);color:var(--ink)}
.phone.dark .btn.ghost{background:transparent;color:#fff;border-color:#3A5B4E}
.ft{font-size:11px;color:#98A6A0;text-align:center;margin-top:8px}
.side{width:320px}
.side h2{font-size:17px;font-weight:700;margin-bottom:10px}
.panel{background:#fff;border-radius:16px;padding:16px;margin-bottom:16px}
.trace{font:12px/1.7 ui-monospace,SFMono-Regular,Menlo,monospace;max-height:220px;overflow:auto}
.trace div{color:var(--muted)}.trace div b{color:var(--ink);font-weight:600}
.gap{background:var(--coralPale);border-radius:10px;padding:11px;font-size:12.5px;margin-top:10px}
.side button{border:1px solid var(--line);background:#fff;border-radius:10px;padding:9px 13px;
font:inherit;font-size:13px;cursor:pointer;margin-right:6px}
.task{font-size:13px;color:var(--muted);line-height:1.5}
.task b{color:var(--ink)}
"""

def block(b):
    t = b.get("t", "card")
    tap = f' onclick="go(\'{b["to"]}\')"' if b.get("to") else ""
    if t == "card":
        tone = b.get("tone", "")
        h = f'<div class="cd {tone}{" tap" if b.get("to") else ""}"{tap}>'
        if b.get("eyebrow"): h += f'<div class="eb">{e(b["eyebrow"])}</div>'
        if b.get("title"): h += f'<div class="ct">{e(b["title"])}</div>'
        if b.get("body"): h += f'<div class="cb">{e(b["body"])}</div>'
        if b.get("pill"): h += f'<div class="chips"><span class="chip on">{e(b["pill"])}</span></div>'
        if b.get("chips"): h += chips(b)
        return h + "</div>"
    if t == "chips":
        return f'<div class="cd">{chips(b)}</div>'
    if t == "options":
        h = ""
        for o in b["items"]:
            h += (f'<div class="opt{" on" if o.get("sel") else ""}" onclick="pick(this)">'
                  f'<span class="dot"></span><div><div class="ct">{e(o["title"])}</div>'
                  + (f'<div class="cb">{e(o["body"])}</div>' if o.get("body") else "") + "</div></div>")
        return h
    if t == "stats":
        return '<div class="stats">' + "".join(
            f'<div class="st"><b>{e(v)}</b><span>{e(l)}</span></div>' for v, l in b["items"]) + "</div>"
    if t == "metric":
        return (f'<div class="mt"><div class="eb">{e(b.get("eyebrow",""))}</div>'
                f'<span class="v">{e(b["value"])}</span> <span class="cb">{e(b.get("unit",""))}</span>'
                f'<div class="track"><i style="width:{b.get("pct",50)}%"></i></div>'
                f'<div class="cb" style="margin-top:8px">{e(b.get("foot",""))}</div></div>')
    if t == "bars":
        return '<div class="bars">' + "".join(
            f'<i class="{"on" if v else ""}" style="height:{max(v,18)}%"></i>' for v in b["values"]) + "</div>"
    if t == "slider":
        h = '<div class="sl">'
        if b.get("title"): h += f'<div class="ct">{e(b["title"])}</div>'
        if b.get("body"): h += f'<div class="cb" style="margin-bottom:8px">{e(b["body"])}</div>'
        h += f'<input type="range" min="0" max="100" value="{b.get("value",50)}">'
        h += (f'<div class="mini"><span>{e(b.get("left",""))}</span>'
              f'<span style="font-weight:600;color:var(--ink)">{e(b.get("mid",""))}</span>'
              f'<span>{e(b.get("right",""))}</span></div>')
        if b.get("foot"): h += f'<div class="cb" style="margin-top:8px">{e(b["foot"])}</div>'
        return h + "</div>"
    if t == "rows":
        return '<div class="rows">' + "".join(
            f'<div class="rw"><div class="k">{e(k)}</div><div class="v">{e(v)}</div></div>'
            for k, v in b["items"]) + "</div>"
    if t == "timer":
        return (f'<div class="tm"><div class="eb" style="color:#9FB8AC">{e(b.get("label",""))}</div>'
                f'<div class="ring" data-secs="{b.get("seconds",90)}">{b.get("seconds",90)}</div>'
                f'<div class="q">{e(b.get("quote",""))}</div></div>')
    if t == "input":
        return (f'<div class="inp"><div class="ct">{e(b.get("title",""))}</div>'
                f'<textarea rows="2">{e(b.get("value",""))}</textarea></div>')
    return ""

def chips(b):
    sel = set(b.get("selected", []))
    return '<div class="chips">' + "".join(
        f'<span class="chip{" on" if i in sel else ""}" onclick="toggle(this)">{e(c)}</span>'
        for i, c in enumerate(b.get("chips") or b.get("items", []))) + "</div>"

def screen(sid, s, arch):
    dark = " dark" if s.get("dark") else ""
    lead = s.get("lead", "close")
    h = [f'<section class="scr" id="{sid}" style="display:none"><div class="phone{dark}">']
    h.append('<div class="bar">')
    h.append('<button class="c" onclick="back()">' + ("&larr;" if lead == "back" else "&times;") + "</button>"
             if lead != "none" else '<span style="width:34px"></span>')
    h.append(f'<span class="t">{e(s.get("title",""))}</span>')
    h.append(f'<span class="bg">{e(s.get("badge",""))}</span>' if s.get("badge") else '<span style="width:58px"></span>')
    h.append("</div>")
    if s.get("progress"): h.append(f'<div class="pr"><i style="width:{s["progress"]}%"></i></div>')
    h.append('<div class="scroll">')
    if s.get("headline"): h.append(f'<div class="hl">{e(s["headline"])}</div>')
    if s.get("sub"): h.append(f'<div class="sub">{e(s["sub"])}</div>')
    for b in s.get("blocks", []): h.append(block(b))
    h.append("</div>")
    h.append('<div class="acts">')
    for a in s.get("actions", []):
        kind = a.get("kind", "primary")
        cls = "btn" + ("" if kind == "primary" else f" {kind}")
        h.append(f'<button class="{cls}" onclick="go(\'{a["to"]}\')">{e(a["label"])}</button>')
    if s.get("footer"): h.append(f'<div class="ft">{e(s["footer"])}</div>')
    h.append("</div></div>")
    h.append(f'<div class="ft" style="margin-top:10px">{sid} · {arch}</div>')
    return "".join(h) + "</section>"

def main():
    pid = sys.argv[1] if len(sys.argv) > 1 else "lookup"
    loc = sys.argv[2] if len(sys.argv) > 2 else "en"
    product = load(f"data/products/{pid}.json")
    content = load(f"data/content/{pid}.{loc}.json")
    archof = {s["id"]: s["archetype"] for s in product["screens"]}

    covered = set(content["screens"])
    missing = [s for s in product["screens"] if s["id"] not in covered]
    targets = {a["to"] for s in content["screens"].values() for a in s.get("actions", [])}
    targets |= {b["to"] for s in content["screens"].values() for b in s.get("blocks", []) if b.get("to")}
    dead = sorted(t for t in targets if t not in covered)

    scr = "".join(screen(sid, s, archof.get(sid, "?")) for sid, s in content["screens"].items())
    gaps = ("".join(f'<div class="gap"><b>{m["id"]}</b> · {m["archetype"]} — no content yet</div>'
                    for m in missing)
            + "".join(f'<div class="gap"><b>Dead end</b> — a button points at {d}, which has no screen</div>'
                      for d in dead)) or '<div class="gap">No gaps. Every button lands somewhere.</div>'

    print(f"""<!doctype html><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{e(product['name'])} prototype</title><style>{CSS}</style>
<div class="stage"><div>{scr}</div>
<div class="side">
<div class="panel"><h2>{e(product['name'])} prototype</h2>
<div class="task">Generated from the design JSON — {len(covered)} of {len(product['screens'])} screens.
Hand a tester a task, then read the trace.</div>
<div style="margin-top:12px"><button onclick="go('{content['start']}',1)">Restart</button>
<button onclick="go('S17',1)">Start mid-urge</button>
<button onclick="go('S22',1)">Fire an intercept</button></div></div>
<div class="panel"><h2>Trace</h2><div class="trace" id="tr"></div></div>
<div class="panel"><h2>Coverage</h2>{gaps}</div></div></div>
<script>
let stack=[],t0=Date.now();
function show(id){{document.querySelectorAll('.scr').forEach(s=>s.style.display='none');
const el=document.getElementById(id); if(!el){{log('dead end: '+id);return;}} el.style.display='';
el.querySelectorAll('.ring').forEach(r=>{{let n=+r.dataset.secs;r.textContent=n;
clearInterval(r._i);r._i=setInterval(()=>{{n--;r.textContent=n>0?n:0;if(n<=0)clearInterval(r._i);}},1000);}});}}
function go(id,reset){{if(reset){{stack=[];t0=Date.now();document.getElementById('tr').innerHTML='';}}
else if(stack.length)stack.push(cur); cur=id; if(!stack.length)stack=[id];
log(id); show(id);}}
function back(){{if(stack.length>1){{stack.pop();cur=stack[stack.length-1];log('back to '+cur);show(cur);}}}}
function log(m){{const s=((Date.now()-t0)/1000).toFixed(1);
document.getElementById('tr').insertAdjacentHTML('beforeend','<div>'+s+'s <b>'+m+'</b></div>');
document.getElementById('tr').scrollTop=9e9;}}
function toggle(el){{el.classList.toggle('on');}}
function pick(el){{el.parentElement.querySelectorAll('.opt').forEach(o=>o.classList.remove('on'));el.classList.add('on');}}
let cur='{content['start']}'; go(cur,1);
</script>""")

if __name__ == "__main__":
    main()
