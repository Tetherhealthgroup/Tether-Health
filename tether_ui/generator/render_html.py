import html, json
from dsl import *

def e(s): return html.escape(str(s), quote=True)
def pc(p): return PROGRAMS[p][3] if p in PROGRAMS else p
def color(c):
    if c in PROGRAMS: return PROGRAMS[c][3]
    return {'coral': '#FF7D61', 'teal': '#123C37'}.get(c, c)
CUR = {'sid': ''}
def A(a, path=None):
    pa = f' data-path="{e(path)}"' if path is not None and a else ''
    return (f' data-a="{e(json.dumps(a, ensure_ascii=False))}"' + pa) if a else ''
def DK(n): return f' data-key="{e(CUR["sid"] + "." + n["key"])}"' if n.get('key') else ''

ICONS = {
 'today': '<path d="M4 11.5 12 5l8 6.5V20a1 1 0 0 1-1 1h-4.5v-5.5h-5V21H5a1 1 0 0 1-1-1z"/>',
 'plans': '<path d="M5 5h14M5 12h14M5 19h9"/><circle cx="19" cy="19" r="1.2"/>',
 'progress': '<path d="M5 20V12M10 20V6M15 20v-9M20 20V9"/>',
 'learn': '<path d="M4 5.5C6.5 4.5 9.5 4.5 12 6c2.5-1.5 5.5-1.5 8-.5V19c-2.5-1-5.5-1-8 .5-2.5-1.5-5.5-1.5-8-.5z"/><path d="M12 6v13.5"/>',
 'support': '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>',
}

def badge(p, size=''):
    return f'<span class="pb {size}" style="--c:{pc(p)}" aria-hidden="true">{PROGRAMS[p][4]}</span>'

def tagh(p, extra=None):
    return f'<span class="tag" style="--c:{pc(p)}">{e(PROGRAMS[p][0])}{(" · " + e(extra)) if extra else ""}</span>'

def render_nodes(nodes, base='body'):
    return ''.join(render(n, f'{base}[{i}]') for i, n in enumerate(nodes or []))

def lab(t): return f'<p class="lab">{e(t)}</p>' if t else ''

def render(n, p=''):
    t = n['t']
    if t == 'eyebrow': return f'<p class="ey">{e(n["text"])}</p>'
    if t == 'title': return f'<h2 class="ti {n.get("size","m")}{" c" if n.get("align")=="center" else ""}">{e(n["text"])}</h2>'
    if t == 'text': return f'<p class="tx tx-{n.get("tone","body")}{" c" if n.get("align")=="center" else ""}">{e(n["text"])}</p>'
    if t == 'steps':
        return '<div class="steps" role="progressbar" aria-valuenow="%d" aria-valuemax="%d">%s</div>' % (n['n'], n['total'], ''.join(f'<i class="{"on" if i < n["n"] else ""}"></i>' for i in range(n['total'])))
    if t == 'chips':
        dots = n.get('dots') or {}
        out = ''.join(f'<span class="chip{" on" if o in n["selected"] else ""}" data-multi="{1 if n.get("multi") else 0}" role="{"checkbox" if n.get("multi") else "radio"}">{f"""<i class="cd" style="--c:{pc(dots[o])}"></i>""" if o in dots else ""}{e(o)}</span>' for o in n['options'])
        return f'{lab(n.get("label"))}<div class="chips"{DK(n)}>{out}</div>'
    if t == 'segmented':
        return f'{lab(n.get("label"))}<div class="seg" role="radiogroup"{DK(n)}>' + ''.join(f'<span class="{"on" if o == n["selected"] else ""}" role="radio">{e(o)}</span>' for o in n['options']) + '</div>'
    if t == 'radio':
        out = ''
        for i, it in enumerate(n['items']):
            b = f'<span class="pill">{e(it["badge"])}</span>' if it.get('badge') else ''
            sub = f'<span class="sub">{e(it["sub"])}</span>' if it.get('sub') else ''
            out += f'<div class="opt{" on" if i == n["selected"] else ""}" role="radio" data-label="{e(it["label"])}"><span class="rd"></span><span class="ol"><b>{e(it["label"])}</b>{sub}</span>{b}</div>'
        return f'{lab(n.get("label"))}<div class="opts"{DK(n)}>{out}</div>'
    if t == 'checklist':
        out = ''.join(f'<div class="ckr" role="checkbox"><span class="ck{" on" if it.get("done") else ""}"></span><span class="ol"><b>{e(it["label"])}</b>{("<span class=sub>" + e(it["sub"]) + "</span>") if it.get("sub") else ""}</span></div>' for it in n['items'])
        return f'{lab(n.get("label"))}<div class="cklist">{out}</div>'
    if t == 'toggle':
        sub = f'<span class="sub">{e(n["sub"])}</span>' if n.get('sub') else ''
        return f'<div class="tgr"><span class="ol"><b>{e(n["label"])}</b>{sub}</span><span class="tg{" on" if n.get("on") else ""}" role="switch"{DK(n)}></span></div>'
    if t == 'field':
        err = ' err' if n.get('error') else ''
        typ = {'password': 'password', 'email': 'email', 'number': 'text', 'phone': 'tel'}.get(n.get('kind'), 'text')
        im = ' inputmode="decimal"' if n.get('kind') == 'number' else ''
        ro = ' readonly' if n.get('kind') in ('select', 'date') else ''
        val = f'<input class="v" type="{typ}"{im}{ro} value="{e(n.get("value") or "")}" placeholder="{e(n.get("placeholder") or "")}" aria-label="{e(n.get("label") or "")}"{DK(n)}>'
        unit = f'<span class="unit">{e(n["unit"])}</span>' if n.get('unit') else ''
        ico = '<span class="sico">⌕</span>' if n.get('kind') == 'search' else ''
        chev = '<span class="unit">▾</span>' if n.get('kind') in ('select', 'date') else ''
        msg = f'<p class="ferr" role="alert"><b>!</b>{e(n["error"])}</p>' if n.get('error') else (f'<p class="hint">{e(n["hint"])}</p>' if n.get('hint') else '')
        lb = f'<label>{e(n["label"])}</label>' if n.get('kind') != 'search' else ''
        multi = ' multi' if n.get('kind') == 'multiline' else ''
        return f'<div class="fld{err}">{lb}<div class="inp{multi}">{ico}{val}{unit}{chev}</div>{msg}</div>'
    if t == 'fieldrow': return '<div class="frow">' + render_nodes(n['fields'], p + '.fields') + '</div>'
    if t == 'slider':
        pct = max(0, min(100, (n['value'] - n['min']) / ((n['max'] - n['min']) or 1) * 100))
        c = color(n.get('color', 'coral'))
        return (f'<div class="sld"><div class="row sp"><b class="lab" style="margin:0">{e(n["label"])}</b><b class="sv">{e(n["value"])}{e(n.get("suffix") or "")}</b></div>'
                f'<div class="trk"><i style="width:{pct:.0f}%;background:{c}"></i><b style="left:{pct:.0f}%;background:{c}"></b></div><div class="row sp tick"><span>{e(n["minLabel"])}</span><span>{e(n["maxLabel"])}</span></div></div>')
    if t == 'banner':
        icon = {'offline': '≈', 'error': '!', 'success': '✓', 'info': 'i', 'urgent': '!'}[n['kind']]
        act = f'<span class="bnact hot"{A(n.get("action"), p)}>{e(n.get("actionLabel") or "")}</span>' if n.get('action') else ''
        return f'<div class="bn {n["kind"]}" role="{"alert" if n["kind"] in ("error", "urgent") else "status"}"><b>{icon}</b><span>{e(n["text"])}</span>{act}</div>'
    if t == 'card':
        v = n.get('variant', 'plain')
        acc = f' style="border-left:4px solid {pc(n["accent"])}"' if n.get('accent') else ''
        inner = ''
        if n.get('tag'): inner += tagh(n['tag'], n.get('tagExtra'))
        if n.get('eyebrow'): inner += f'<p class="ey">{e(n["eyebrow"])}</p>'
        if n.get('title'): inner += f'<p class="ct">{e(n["title"])}</p>'
        if n.get('text'): inner += f'<p class="cx">{e(n["text"])}</p>'
        inner += render_nodes(n.get('children'), p + '.children')
        hot = ' hot' if n.get('action') else ''
        chev = '<span class="chev">›</span>' if n.get('action') else ''
        if n.get('cta'):
            return f'<div class="card {v}{hot}"{acc}{A(n.get("action"), p)}><div class="crow"><div class="cmain">{inner}</div>{render(n["cta"], p + ".cta[0]")}</div></div>'
        if chev:
            return f'<div class="card {v}{hot}"{acc}{A(n.get("action"), p)}><div class="crow"><div class="cmain">{inner}</div>{chev}</div></div>'
        return f'<div class="card {v}"{acc}>{inner}</div>'
    if t == 'kv':
        return '<div class="card kvc">' + ''.join(f'<div class="kv"><span>{e(k)}</span><b>{e(v)}</b></div>' for k, v in n['rows']) + '</div>'
    if t == 'list':
        out = ''
        for j, r in enumerate(n['rows']):
            lead = ''
            L = r.get('lead') or {}
            if 'program' in L: lead = badge(L['program'], 'm')
            elif 'avatar' in L: lead = f'<span class="av">{e(L["avatar"])}</span>'
            elif 'icon' in L: lead = f'<span class="av ic">{e(L["icon"])}</span>'
            pill = f'<span class="pill">{e(r["pill"])}</span>' if r.get('pill') else ''
            val = f'<span class="rv">{e(r["value"])}</span>' if r.get('value') else ''
            chev = '<span class="chev">›</span>' if r.get('action') else ''
            sub = f'<span class="sub">{e(r["sub"])}</span>' if r.get('sub') else ''
            out += f'<div class="lr{" hot" if r.get("action") else ""}{" danger" if r.get("danger") else ""}"{A(r.get("action"), f"{p}.rows[{j}]")}>{lead}<span class="ol"><b>{e(r["label"])}</b>{sub}</span>{val}{pill}{chev}</div>'
        ttl = f'<p class="ey" style="margin:0 0 2px">{e(n["title"])}</p>' if n.get('title') else ''
        return f'<div class="lgrp">{ttl}<div class="card list{" flat" if n.get("flat") else ""}">{out}</div></div>'
    if t == 'tiles':
        out = ''
        for j, it in enumerate(n['items']):
            lead = badge(it['program'], 'm') if it.get('program') else f'<span class="pb m" style="--c:{color(it.get("color") or "#536F69")}">{e(it.get("glyph") or "•")}</span>'
            sub = f'<span class="sub">{e(it["sub"])}</span>' if it.get('sub') else ''
            out += f'<div class="tile{" on" if it.get("selected") else ""}{" hot" if it.get("action") else ""}"{A(it.get("action"), f"{p}.items[{j}]")} role="{"button" if it.get("action") else "checkbox"}">{lead}<b>{e(it["label"])}</b>{sub}</div>'
        return f'<div class="tiles c{n.get("cols",2)}">{out}</div>'
    if t == 'stats':
        out = ''.join(f'<div class="stat">{tagh(it["program"], it["label"]) if it.get("program") else "<p class=ey>" + e(it["label"]) + "</p>"}<b>{e(it["value"])}</b>{("<span>" + e(it["sub"]) + "</span>") if it.get("sub") else ""}</div>' for it in n['items'])
        return f'<div class="stats c{n.get("cols",2)}">{out}</div>'
    if t == 'chart':
        c = color(n['color'])
        head = f'<div class="row sp">{tagh(n["tag"]) if n.get("tag") else ""}<b class="cht">{e(n.get("title") or "")}</b><span class="chu">{e(n.get("unit") or "")}</span></div>'
        if n['kind'] == 'bars':
            vals = n['values']; mx = max(vals + [n.get('target') or 0]) or 1
            bs = ''.join('<i class="x"></i>' if i in (n.get('missing') or []) else f'<i style="height:{max(4, v / mx * 100):.0f}%;background:{c}"></i>' for i, v in enumerate(vals))
            tg = f'<span class="tgt" style="bottom:{n["target"] / mx * 100:.0f}%"></span>' if n.get('target') else ''
            labs = '<div class="blab">' + ''.join(f'<span>{e(l)}</span>' for l in n['labels']) + '</div>' if n.get('labels') else ''
            body = f'<div class="bars">{bs}{tg}</div>{labs}'
        else:
            vals = n['values']; band = n.get('band')
            lo, hi = min(vals + (band or [])), max(vals + (band or []))
            rng = (hi - lo) or 1; W, Hh = 320, 90
            def y(v): return Hh - (v - lo) / rng * Hh
            pts = ' '.join(f'{i * W / (len(vals) - 1):.1f},{y(v):.1f}' for i, v in enumerate(vals))
            bd = f'<rect x="0" y="{y(band[1]):.1f}" width="{W}" height="{y(band[0]) - y(band[1]):.1f}" fill="#E4F1E9"/>' if band else ''
            dots = ''.join(f'<circle cx="{i * W / (len(vals) - 1):.1f}" cy="{y(v):.1f}" r="3" fill="{c}"/>' for i, v in enumerate(vals))
            body = f'<svg viewBox="-6 -6 {W + 12} {Hh + 12}" class="spark" aria-hidden="true">{bd}<polyline points="{pts}" fill="none" stroke="{c}" stroke-width="2.5"/>{dots}</svg>'
        cap = f'<p class="cx">{e(n["caption"])}</p>' if n.get('caption') else ''
        hot = ' hot' if n.get('action') else ''
        return f'<div class="card chart{hot}"{A(n.get("action"), p)}>{head}{body}{cap}</div>'
    if t == 'zone':
        return f'<div class="zone" role="radiogroup"{(" data-rule=" + chr(34) + n["rule"] + chr(34)) if n.get("rule") else ""}>' + ''.join(f'<span class="z-{z}{" on" if z == n["selected"] else ""}">{z.title()}</span>' for z in ('green', 'yellow', 'red')) + '</div>'
    if t == 'ring':
        pal = {'teal': ('#2B6258', '#1C5149', '#174640'), 'indigo': ('#5566D8', '#4656C9', '#3A49B5')}[n.get('palette', 'teal')]
        return f'<div class="ring" style="background:radial-gradient(circle,{pal[0]} 0 38%,{pal[1]} 39% 58%,{pal[2]} 59% 76%,transparent 77%)"><div><b>{e(n["value"])}</b><span>{e(n["label"])}</span></div></div>'
    if t == 'big':
        u = f'<span class="bu">{e(n["unit"])}</span>' if n.get('unit') else ''
        cap = f'<p class="bc">{e(n["caption"])}</p>' if n.get('caption') else ''
        return f'<div class="big"><b>{e(n["value"])}</b>{u}</div>{cap}'
    if t == 'button':
        st = n.get('state') or ''
        cls = f'btn {n.get("variant","primary")}{" sm" if n.get("small") else ""}{" arr" if n.get("arrow") else ""}'
        if st: cls += f' {st}'
        return f'<button class="{cls}{" hot" if n.get("action") else ""}"{A(n.get("action"), p)}{" disabled" if st == "disabled" else ""}>{e(n["label"])}</button>'
    if t == 'buttons': return '<div class="brow">' + render_nodes(n['items'], p + '.items') + '</div>'
    if t == 'authbuttons': return '<div class="authb">' + render_nodes(n['items'], p + '.items') + '</div>'
    if t == 'authbtn':
        logo = '<svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path fill="currentColor" d="M16.4 12.6c0-2.5 2-3.6 2.1-3.7-1.2-1.7-3-1.9-3.6-2-1.5-.2-3 .9-3.8.9s-2-.9-3.3-.8c-1.7 0-3.3 1-4.1 2.5-1.8 3.1-.5 7.6 1.3 10.1.8 1.2 1.8 2.6 3.1 2.5 1.2 0 1.7-.8 3.2-.8s1.9.8 3.2.8c1.3 0 2.2-1.2 3-2.4.9-1.4 1.3-2.7 1.3-2.8-.1 0-2.4-.9-2.4-3.8zM14 5.2c.7-.8 1.1-1.9 1-3-1 0-2.1.7-2.8 1.5-.6.7-1.2 1.8-1 2.9 1.1.1 2.1-.6 2.8-1.4z"/></svg>' if n['provider'] == 'apple' else '<b class="g">G</b>'
        return f'<button class="abtn {n["provider"]} hot" data-platforms="{" ".join(n["platforms"])}"{A(n.get("action"), p)}>{logo}<span>{e(n["label"])}</span></button>'
    if t == 'link': return f'<button class="lnk {n.get("align","center")} hot"{A(n.get("action"), p)}>{e(n["label"])}</button>'
    if t == 'quote':
        cap = f'<span>{e(n["caption"])}</span>' if n.get('caption') else ''
        return f'<blockquote class="q">“{e(n["text"])}”{cap}</blockquote>'
    if t == 'illus': return f'<div class="ill {n.get("tone","mint")}" aria-hidden="true">{e(n["glyph"])}</div>'
    if t == 'emergency': return f'<div class="card urgent emg" role="note"><p class="ct">{e(n["text"])}</p><div class="brow">{render_nodes(n["actions"], p + ".actions")}</div></div>'
    if t == 'skeleton': return '<div class="card">' + ''.join(f'<div class="sk" style="width:{w}%"></div>' for w in [55, 90, 72, 40][:n['lines']]) + '</div>'
    if t == 'spacer': return f'<div style="height:{n["h"]}px"></div>'
    if t == 'progtag': return tagh(n['program'], n.get('extra'))
    if t == 'calendar':
        days = ''.join(f'<span class="dh">{d}</span>' for d in 'SMTWTFS')
        cells = '<span></span>' * 6  # Aug 1 2026 is Saturday
        for d in range(1, 32):
            cls = 'sel' if d == n['selected'] else ('win' if d in n['window'] else ('today' if d == n.get('today') else ''))
            cells += f'<span class="{cls}">{d}</span>'
        return f'<div class="card cal"><div class="row sp"><b class="cht">{e(n["month"])}</b><span class="chu">‹ ›</span></div><div class="cg">{days}{cells}</div><p class="cx">Recommended window: Aug 28 – Aug 31</p></div>'
    if t == 'timer': return f'<div class="timer"><b>{e(n["value"])}</b><span>{e(n["label"])}</span></div>'
    if t == 'nativeslot': return f'<div class="card" role="img" aria-label="{e(n["label"])}" data-native="{e(n["id"])}" style="min-height:{n.get("height", 120)}px;border:1.5px dashed var(--line);background:repeating-linear-gradient(135deg,#F1F5F1 0 10px,#FBFAF5 10px 20px);display:flex;flex-direction:column;justify-content:center;gap:4px"><span class="pill" style="align-self:flex-start">NATIVE VIEW · {e(n.get("platform", "ios").upper())}</span><p class="ct" style="color:var(--teal)">{e(n["label"])}</p>{("<p class=cx style=color:var(--teal2)>" + e(n["caption"]) + "</p>") if n.get("caption") else ""}</div>'
    raise ValueError(t)

def render_header(h, dark):
    if not h: return ''
    left = h.get('left', 'back')
    d = ' dk' if dark or h.get('dark') else ''
    if left == 'logo':
        l = f'<span class="logo"><i></i>{e(h.get("title") or "Tether Health")}</span>'
        mid = '<span class="hsp"></span>'
    elif left == 'none':
        l = f'<span class="lt">{e(h.get("title"))}</span>'
        mid = '<span class="hsp"></span>'
    else:
        sym = '‹' if left == 'back' else '×'
        act = back() if left == 'back' else close()
        l = f'<button class="ib hot" aria-label="{"Back" if left == "back" else "Close"}"{A(act, "header.left")}>{sym}</button>'
        mid = f'<span class="ht">{e(h.get("title") or "")}</span>'
    right = ''
    if h.get('pill'): right += f'<span class="pill">{e(h["pill"])}</span>'
    if h.get('avatar'): right += f'<button class="av hot" aria-label="Account"{A(h.get("avatarAction"), "header.avatar")}>{e(h["avatar"])}</button>'
    if not right and left in ('back', 'close'): right = '<span class="ibsp"></span>'
    return f'<header class="hd{d}">{l}{mid}<span class="hr">{right}</span></header>'

def render_tabbar(active):
    out = ''
    for tname in TABS:
        on = tname == active
        out += f'<button class="tab{" on" if on else ""}{"" if on else " hot"}"{"" if on else A(tab(tname), "tabbar." + tname)}><svg viewBox="0 0 24 24" aria-hidden="true">{ICONS[tname]}</svg><span>{tname.title()}</span></button>'
    return f'<nav class="tabbar">{out}</nav>'

def render_screen(s, export=False):
    dark = s['dark']
    bg = {'indigo': 'background:linear-gradient(170deg,#1F2A6B,#3B4CC0)'}.get(s.get('bg'), '')
    CUR['sid'] = s['id']
    body = render_nodes(s['body'], 'body')
    foot = render_nodes(s['footer'], 'footer')
    tb = render_tabbar(s['tab']) if s.get('tab') else ''
    status = f'<div class="sb{" dk" if dark else ""}"><span>9:41</span><span class="di"></span><span class="bat"><i></i></span></div>'
    if s['kind'] == 'sheet':
        return (f'<div class="scr sheetbg" data-id="{s["id"]}">{status}<div class="under"><p class="ut">{e(s.get("over") or "")}</p><div class="usk"></div><div class="usk s"></div><div class="usk"></div></div><div class="dim"></div>'
                f'<div class="sheet" role="dialog"><div class="grab"></div><div class="body">{body}</div>{"<div class=foot>" + foot + "</div>" if foot else ""}<div class="hbar"></div></div></div>')
    cls = 'scr' + (' dark' if dark else '') + (' hastab' if tb else '')
    footer = f'<div class="foot">{foot}</div>' if foot else ''
    hb = '' if tb else '<div class="hbar"></div>'
    return f'<div class="{cls}" data-id="{s["id"]}" style="{bg}">{status}{render_header(s.get("header"), dark)}<div class="body">{body}</div>{footer}{tb}{hb}</div>'

CSS = r"""
:root{--teal:#123C37;--teal2:#536F69;--muted:#5A726C;--mint:#DFF2E7;--mint2:#BFE1D2;--cream:#F8F5EC;--paper:#FFFDF7;--coral:#FF7D61;--coralT:#B5432A;--lime:#D5EF75;--line:#B6C8C2;--line2:#DCE6E0;--err:#B3261E;--errL:#FDECEA;--warn:#8A5A00;--warnL:#FFF5DB;--ok:#2E6B3A;--okL:#E5F3E8;
--sans:"Nimbus Sans","Helvetica Neue",Helvetica,Arial,system-ui,sans-serif;--serif:Georgia,"Times New Roman",serif}
.scr,.scr *{box-sizing:border-box;margin:0;padding:0}
.scr{width:390px;height:844px;position:relative;display:flex;flex-direction:column;overflow:hidden;background:linear-gradient(160deg,#FBF8F0,#F3F0E6);color:var(--teal2);font-family:var(--sans);font-size:15px;line-height:1.45;-webkit-font-smoothing:antialiased}
.scr.export{height:auto;min-height:844px}
.scr.export .body{overflow:visible;flex:1 0 auto}
.scr.dark{background:linear-gradient(170deg,#123C37,#1C5149);color:#D3E2DC}
.sb{height:54px;flex:none;display:flex;align-items:center;justify-content:space-between;padding:0 30px 0 34px;font-weight:700;font-size:17px;color:var(--teal);position:relative}
.sb .di{position:absolute;left:50%;top:11px;width:124px;height:36px;margin-left:-62px;background:#000;border-radius:20px}
.sb .bat{width:27px;height:13px;border:1.6px solid currentColor;border-radius:4px;padding:1.5px}.sb .bat i{display:block;height:100%;width:75%;background:currentColor;border-radius:1.5px}
.sb.dk,.dark .hd .ht,.dark .ti,.dark .ct,.dark .tx{color:#fff}
.hd{height:52px;flex:none;display:flex;align-items:center;gap:8px;padding:0 16px}
.hd .ht{flex:1;text-align:center;font-weight:700;font-size:17px;color:var(--teal);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.hd .hsp{flex:1}
.hd .hr{display:flex;align-items:center;gap:8px;min-width:44px;justify-content:flex-end}
.hd .lt{font-size:30px;font-weight:800;letter-spacing:-.6px;color:var(--teal);padding-left:4px}
.ib{width:40px;height:40px;border-radius:50%;border:1px solid var(--line);background:var(--paper);color:var(--teal);font-size:22px;font-weight:700;display:grid;place-items:center;flex:none;cursor:pointer;font-family:var(--sans)}
.dk .ib{background:transparent;color:#fff;border-color:#3F6660}
.ibsp{width:40px}
.logo{display:flex;align-items:center;gap:10px;font-weight:800;font-size:20px;color:var(--teal)}
.logo i{width:32px;height:32px;border-radius:50%;background:var(--teal);display:grid;place-items:center}
.logo i::after{content:"";width:14px;height:9px;border:2.6px solid var(--lime);border-radius:14px 0 14px 0;transform:rotate(-30deg)}
.av{width:36px;height:36px;border-radius:50%;background:var(--mint);color:var(--teal);font-weight:800;font-size:15px;display:grid;place-items:center;border:1px solid var(--mint2);flex:none;cursor:pointer;font-family:var(--sans)}
.av.ic{background:var(--paper);border-color:var(--line);font-size:18px}
.pill{font-size:11px;letter-spacing:.08em;font-weight:800;background:#E4F1E9;color:var(--teal);border-radius:12px;padding:5px 9px;text-transform:uppercase;white-space:nowrap;flex:none}
.dark .pill{background:#234E48;color:var(--lime)}
.body{flex:1 1 auto;overflow-y:auto;overflow-x:hidden;padding:6px 20px 20px;display:flex;flex-direction:column;gap:12px;scrollbar-width:none}
.body::-webkit-scrollbar{display:none}
.foot{flex:none;padding:10px 20px 12px;display:flex;flex-direction:column;gap:8px;background:linear-gradient(to bottom,rgba(248,245,236,0),rgba(248,245,236,.96) 22%)}
.scr:not(.hastab) .foot{padding-bottom:34px}
.dark .foot{background:transparent}
.ey{font-size:11.5px;letter-spacing:.12em;text-transform:uppercase;color:var(--muted);font-weight:800}
.dark .ey,.card.dark .ey,.card.dark2 .ey{color:#B9D1C8}
.ti{color:var(--teal);font-weight:800;letter-spacing:-.4px;line-height:1.15}
.ti.m{font-size:24px}.ti.l{font-size:28px}.ti.xl{font-size:32px;letter-spacing:-.8px}
.c{text-align:center}
.tx-body{font-size:15.5px}.tx-muted{font-size:15px;color:var(--teal2)}.tx-small{font-size:13px;color:var(--muted)}
.dark .tx{color:#D3E2DC}
.lab{font-size:14px;font-weight:700;color:var(--teal);margin-bottom:-4px}
.dark .lab{color:#fff}
.steps{display:flex;gap:4px}.steps i{flex:1;height:5px;border-radius:3px;background:var(--line2)}.steps i.on{background:var(--teal)}
.chips{display:flex;flex-wrap:wrap;gap:8px}
.chip{display:inline-flex;align-items:center;gap:6px;min-height:38px;padding:0 14px;border-radius:19px;border:1.5px solid #C8D8D1;background:var(--paper);color:var(--teal);font-weight:700;font-size:14px;cursor:pointer;user-select:none}
.chip.on{background:var(--mint);border-color:var(--teal)}
.chip.on::before{content:"✓";font-size:12px}
.dark .chip{background:#1D514A;color:#fff;border-color:#3F6660}.dark .chip.on{background:#2B6258;border-color:var(--lime)}
.cd{width:10px;height:10px;border-radius:3px;background:var(--c)}
.seg{display:flex;background:#E8EFEA;border-radius:12px;padding:3px;gap:3px}
.seg span{flex:1;text-align:center;font-weight:700;font-size:13.5px;padding:9px 2px;border-radius:9px;color:var(--teal2);cursor:pointer;user-select:none;white-space:nowrap}
.seg span.on{background:var(--paper);color:var(--teal);box-shadow:0 2px 5px rgba(18,60,55,.14)}
.opts{display:flex;flex-direction:column;gap:8px}
.opt{display:flex;align-items:center;gap:12px;background:var(--paper);border:1.5px solid var(--line2);border-radius:14px;padding:12px 14px;min-height:52px;cursor:pointer}
.opt.on{border-color:var(--teal);background:#F1F8F3}
.rd{width:20px;height:20px;border-radius:50%;border:2px solid var(--line);flex:none}
.opt.on .rd{border:6px solid var(--teal)}
.ol{flex:1;display:flex;flex-direction:column;min-width:0}
.ol b{font-size:15.5px;color:var(--teal);font-weight:700;line-height:1.3}
.sub{font-size:13px;color:var(--muted);line-height:1.35}
.cklist{display:flex;flex-direction:column}
.ckr{display:flex;gap:12px;align-items:flex-start;padding:10px 0;border-top:1px solid var(--line2);cursor:pointer}
.ckr:first-child{border-top:0;padding-top:4px}
.ck{width:22px;height:22px;border-radius:50%;border:2px solid var(--line);flex:none;position:relative;margin-top:1px}
.ck.on{background:var(--teal);border-color:var(--teal)}
.ck.on::after{content:"";position:absolute;left:6px;top:2.5px;width:5px;height:10px;border:solid var(--lime);border-width:0 2.2px 2.2px 0;transform:rotate(45deg)}
.tgr{display:flex;align-items:center;gap:12px;padding:8px 0}
.tg{width:51px;height:31px;border-radius:16px;background:#9AABA6;position:relative;flex:none;cursor:pointer;transition:background .2s}
.tg::after{content:"";position:absolute;top:2px;left:2px;width:27px;height:27px;border-radius:50%;background:#fff;box-shadow:0 2px 4px rgba(0,0,0,.2);transition:left .2s}
.tg.on{background:var(--teal)}.tg.on::after{left:22px}
.card .tgr+.tgr{border-top:1px solid var(--line2)}
.fld label{display:block;font-size:13.5px;font-weight:700;color:var(--teal);margin-bottom:6px}
.inp{display:flex;align-items:center;gap:8px;background:var(--paper);border:1.5px solid var(--line);border-radius:12px;padding:0 14px;min-height:50px;font-size:16px;color:var(--teal);font-weight:600}
.inp.multi{min-height:76px;align-items:flex-start;padding-top:12px}
.inp .v,.inp .ph{flex:1;min-width:0}
.inp input.v{border:0;background:transparent;font:inherit;color:inherit;outline:none;padding:12px 0;width:100%}
.inp input.v::placeholder{color:#6B7F79;font-weight:400}
.inp:focus-within{border-color:var(--teal);box-shadow:0 0 0 2px rgba(18,60,55,.12)}
.authb{display:flex;flex-direction:column;gap:8px}
.abtn{font-family:var(--sans);display:flex;align-items:center;justify-content:center;gap:10px;min-height:52px;border-radius:14px;font-weight:700;font-size:16px;cursor:pointer;width:100%}
.abtn.apple{background:#000;color:#fff;border:1.5px solid #000}
.abtn.google{background:#fff;color:#1F1F1F;border:1.5px solid var(--line)}
.abtn .g{font-size:19px;color:#4285F4;font-weight:800}
body[data-platform=android] .abtn[data-platforms="ios"]{display:none}
.inp .ph{color:#6B7F79;font-weight:400}
.unit{font-size:13px;color:var(--muted);font-weight:700;white-space:nowrap}
.sico{font-size:18px;color:var(--muted)}
.hint{font-size:12.5px;color:var(--muted);margin-top:5px}
.fld.err .inp{border-color:var(--err);background:#FFFBFA}
.ferr{font-size:13px;color:var(--err);font-weight:700;margin-top:6px;display:flex;gap:6px;align-items:flex-start}
.ferr b{display:inline-grid;place-items:center;min-width:16px;height:16px;border-radius:50%;background:var(--err);color:#fff;font-size:11px;margin-top:1px}
.frow{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.sld{display:flex;flex-direction:column;gap:6px}.sv{font-size:22px;color:var(--teal)}
.trk{position:relative;height:6px;border-radius:3px;background:var(--line2);margin:12px 0 4px}
.trk i{position:absolute;left:0;top:0;bottom:0;border-radius:3px}
.trk b{position:absolute;top:-10px;width:26px;height:26px;border-radius:50%;border:4px solid #fff;margin-left:-13px;box-shadow:0 1px 4px rgba(0,0,0,.25)}
.tick{font-size:12px;color:var(--muted)}
.row{display:flex;align-items:center;gap:8px}.sp{justify-content:space-between}
.bn{display:flex;gap:10px;align-items:flex-start;border-radius:12px;padding:12px 14px;font-size:14px;font-weight:600;line-height:1.4}
.bn>b{width:20px;height:20px;border-radius:50%;display:grid;place-items:center;font-size:12px;flex:none;color:#fff}
.bn>span{flex:1}
.bn.offline{background:var(--warnL);color:#5C3D00}.bn.offline>b{background:var(--warn)}
.bn.error{background:var(--errL);color:#7A1A14}.bn.error>b{background:var(--err)}
.bn.urgent{background:var(--err);color:#fff}.bn.urgent>b{background:#fff;color:var(--err)}
.bn.success{background:var(--okL);color:#1D4A26}.bn.success>b{background:var(--ok)}
.bn.info{background:#EAF1EC;color:var(--teal)}.bn.info>b{background:var(--teal)}
.bnact{text-decoration:underline;font-weight:800;cursor:pointer}
.card{background:var(--paper);border-radius:18px;padding:14px 16px;box-shadow:0 10px 20px -14px rgba(18,60,55,.28);border:1px solid rgba(182,200,194,.55);display:flex;flex-direction:column;gap:6px}
.card.hot{cursor:pointer}
.card.dark{background:var(--teal);border:0;color:#D3E2DC}.card.dark .ct,.card.dark .big b{color:#fff}.card.dark .cx,.card.dark .bc{color:#B9D1C8}
.card.dark2{background:#1D514A;border:0;color:#D3E2DC}.card.dark2 .ct{color:#fff}.card.dark2 .cx{color:#B9D1C8}
.bg-indigo .card.dark2,.scr[style*="3B4CC0"] .card.dark2{background:#2E3B99}
.card.coral{background:#FFE9E2;border-color:#FFC6B7}
.card.mint{background:linear-gradient(135deg,#E4F2EA,#CDE7DB);border-color:#B8D7C9}
.card.urgent{background:var(--errL);border:1.5px solid #E8A39D}.card.urgent .ct{color:#7A1A14}.card.urgent .cx{color:#7A1A14}
.card.warn{background:var(--warnL);border-color:#EBCB7E}
.card.flat{box-shadow:none}
.crow{display:flex;align-items:center;gap:12px}.cmain{flex:1;min-width:0;display:flex;flex-direction:column;gap:5px}
.ct{font-size:16px;font-weight:700;color:var(--teal);line-height:1.3}
.cx{font-size:13.5px;color:var(--teal2);line-height:1.4}
.chev{color:var(--muted);font-size:24px;font-weight:600;line-height:1}
.kvc{gap:0;padding:6px 16px}
.kv{display:flex;justify-content:space-between;gap:16px;padding:10px 0;border-top:1px solid var(--line2);font-size:14px}
.kv:first-child{border-top:0}.kv span{color:var(--teal2)}.kv b{color:var(--teal);text-align:right}
.lgrp{display:flex;flex-direction:column;gap:6px}
.card.list{padding:2px 16px;gap:0}
.card.list.flat{box-shadow:none;background:transparent;border:0;padding:0}
.lr{display:flex;align-items:center;gap:12px;min-height:58px;padding:9px 0;border-top:1px solid var(--line2)}
.lr:first-child{border-top:0}.lr.hot{cursor:pointer}
.lr.danger .ol b{color:var(--err)}
.rv{font-size:13px;color:var(--teal);font-weight:700}
.pb{display:inline-grid;place-items:center;color:#fff;font-weight:800;background:var(--c);flex:none;width:24px;height:24px;border-radius:8px;font-size:12px}
.pb.m{width:36px;height:36px;border-radius:11px;font-size:15px}
.tag{display:inline-flex;align-items:center;gap:6px;font-size:11.5px;font-weight:800;letter-spacing:.07em;text-transform:uppercase;color:var(--c)}
.tag::before{content:"";width:9px;height:9px;border-radius:3px;background:var(--c)}
.card.dark .tag,.dark .tag{filter:brightness(2.1) saturate(.8)}
.tiles{display:grid;gap:10px}.tiles.c2{grid-template-columns:1fr 1fr}.tiles.c3{grid-template-columns:1fr 1fr 1fr}
.tile{background:var(--paper);border:1.5px solid var(--line2);border-radius:16px;padding:13px;display:flex;flex-direction:column;gap:5px;position:relative;cursor:pointer;min-height:104px}
.tile b{font-size:15px;color:var(--teal);line-height:1.25}
.tile.on{border-color:var(--teal);background:#F1F8F3}
.tile.on::after{content:"✓";position:absolute;top:10px;right:10px;width:22px;height:22px;border-radius:50%;background:var(--teal);color:var(--lime);font-size:12px;display:grid;place-items:center;font-weight:800}
.stats{display:grid;gap:10px}.stats.c2{grid-template-columns:1fr 1fr}.stats.c3{grid-template-columns:1fr 1fr 1fr}
.stat{background:var(--paper);border:1px solid var(--line2);border-radius:16px;padding:12px 14px;display:flex;flex-direction:column;gap:3px}
.stat b{font-size:26px;font-weight:800;color:var(--teal);letter-spacing:-.6px;line-height:1.1}.stat span{font-size:12.5px;color:var(--muted)}
.cht{font-size:14px;color:var(--teal);flex:1}.chu{font-size:12.5px;color:var(--muted)}
.bars{display:flex;align-items:flex-end;gap:8px;height:96px;position:relative;margin-top:6px}
.bars i{flex:1;border-radius:5px 5px 0 0;opacity:.9}
.bars i.x{height:26%;background:repeating-linear-gradient(45deg,var(--line2) 0 4px,transparent 4px 8px);border:1px dashed var(--line)}
.bars .tgt{position:absolute;left:0;right:0;border-top:2px dashed var(--teal)}
.blab{display:flex;gap:8px;font-size:11px;color:var(--muted)}.blab span{flex:1;text-align:center}
.spark{width:100%;height:110px;display:block}
.zone{display:flex;gap:8px}.zone span{flex:1;border-radius:12px;padding:16px 4px;text-align:center;font-weight:800;font-size:15px;border:2px solid transparent;cursor:pointer}
.z-green{background:#E5F3E8;color:#1D4A26}.z-yellow{background:#FFF5DB;color:#5C3D00}.z-red{background:#FDECEA;color:#7A1A14}
.zone span.on{border-color:var(--teal);box-shadow:inset 0 0 0 2px #fff}
.ring{width:210px;height:210px;border-radius:50%;margin:6px auto;display:grid;place-items:center;color:#fff;text-align:center;animation:br 8s ease-in-out infinite}
.ring b{font-size:46px;display:block;line-height:1}.ring span{font-size:11px;letter-spacing:.12em}
@keyframes br{0%,100%{transform:scale(.9)}45%{transform:scale(1.04)}}
@media (prefers-reduced-motion:reduce){.ring{animation:none}}
.big{display:flex;align-items:baseline;gap:6px;justify-content:flex-start}.big b{font-size:44px;font-weight:800;color:var(--teal);letter-spacing:-1.4px;line-height:1}
.big .bu{font-size:15px;color:var(--muted);font-weight:700}.bc{font-size:13px;color:var(--teal2)}
.body>.big{justify-content:center;margin:8px 0}
.btn{font-family:var(--sans);border:0;background:var(--teal);color:#fff;border-radius:14px;min-height:52px;padding:0 18px;font-weight:700;font-size:16px;display:flex;align-items:center;justify-content:center;gap:10px;cursor:pointer;width:100%;text-align:center}
.btn.arr{justify-content:space-between;text-align:left}.btn.arr::after{content:"→";color:var(--lime);font-size:20px}
.btn.rescue{background:var(--coral);color:var(--teal)}.btn.rescue.arr::after{color:var(--teal)}
.btn.lime{background:var(--lime);color:var(--teal)}.btn.lime.arr::after{color:var(--teal)}
.btn.white{background:#fff;color:var(--teal)}.btn.white.arr::after{color:var(--teal)}
.btn.secondary{background:transparent;color:var(--teal);border:1.5px solid var(--line)}
.dark .btn.secondary{color:#fff;border-color:#3F6660}
.btn.ghostdark{background:transparent;color:#fff;border:1.5px solid #3F6660}
.btn.danger{background:var(--err);color:#fff}
.btn.disabled{background:#DCE3E0;color:#5E6E69;cursor:not-allowed}.btn.disabled.arr::after{color:#5E6E69}
.btn.sm{width:auto;min-height:38px;font-size:14px;padding:0 14px;border-radius:11px;flex:none;white-space:nowrap}
.brow{display:flex;gap:8px;flex-wrap:wrap}
.lnk{font-family:var(--sans);background:none;border:0;color:var(--teal);font-weight:700;font-size:15px;text-decoration:underline;text-underline-offset:3px;min-height:40px;cursor:pointer;padding:0 4px}
.lnk.center{align-self:center}.lnk.left{align-self:flex-start}
.dark .lnk{color:#fff}
.q{font-family:var(--serif);font-style:italic;color:var(--teal);font-size:20px;line-height:1.35}.q span{display:block;font-family:var(--sans);font-style:normal;font-size:12.5px;color:var(--muted);margin-top:4px}
.ill{width:88px;height:88px;border-radius:50%;margin:10px auto 2px;display:grid;place-items:center;background:var(--mint);color:var(--teal);font-size:36px;font-weight:800;font-family:var(--serif);flex:none}
.ill.error{background:var(--errL);color:var(--err)}.ill.warn{background:var(--warnL);color:var(--warn)}.ill.dark{background:#234E48;color:var(--lime)}
.emg .ct{font-size:15px}
.sk{height:12px;border-radius:6px;background:linear-gradient(90deg,#E8EEEA 0%,#F4F7F5 50%,#E8EEEA 100%);background-size:200% 100%;animation:shim 1.4s infinite;margin:5px 0}
@keyframes shim{to{background-position:-200% 0}}
.cal .cg{display:grid;grid-template-columns:repeat(7,1fr);gap:4px;text-align:center;font-size:14px;color:var(--teal);margin-top:6px}
.cal .cg span{height:36px;display:grid;place-items:center;border-radius:10px;font-weight:600}
.cal .cg .dh{height:22px;font-size:11.5px;color:var(--muted);font-weight:800}
.cal .cg .sel{background:var(--teal);color:#fff;font-weight:800}.cal .cg .win{background:var(--mint)}.cal .cg .today{box-shadow:inset 0 0 0 1.5px var(--teal)}
.timer{text-align:center;margin:6px 0}.timer b{display:block;font-size:56px;font-weight:800;color:var(--teal);letter-spacing:-2px;font-variant-numeric:tabular-nums}.timer span{font-size:13px;color:var(--muted)}
.tabbar{flex:none;height:84px;background:var(--paper);border-top:1px solid var(--line2);display:flex;justify-content:space-around;padding:6px 6px 30px;position:relative}
.tab{font-family:var(--sans);background:none;border:0;display:flex;flex-direction:column;align-items:center;gap:2px;font-size:11px;color:var(--muted);width:68px;cursor:pointer;font-weight:600}
.tab svg{width:44px;height:28px;padding:3px 10px;border-radius:14px;fill:none;stroke:currentColor;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round}
.tab.on{color:var(--teal);font-weight:800}.tab.on svg{background:var(--mint)}
.hbar{position:absolute;bottom:8px;left:50%;width:134px;height:5px;margin-left:-67px;border-radius:3px;background:var(--teal);z-index:5;pointer-events:none}
.dark .hbar{background:#fff}
.sheetbg .under{padding:8px 20px;opacity:.9}.ut{font-size:28px;font-weight:800;color:var(--teal)}
.usk{height:80px;border-radius:18px;background:var(--paper);margin-top:12px;border:1px solid var(--line2)}.usk.s{height:44px}
.dim{position:absolute;inset:0;background:rgba(11,35,32,.45);z-index:2}
.sheet{position:absolute;left:0;right:0;bottom:0;max-height:86%;background:var(--paper);border-radius:26px 26px 0 0;z-index:3;display:flex;flex-direction:column;box-shadow:0 -14px 30px rgba(18,60,55,.25)}
.sheet .grab{width:40px;height:5px;border-radius:3px;background:var(--line);margin:9px auto 6px;flex:none}
.sheet .body{padding:6px 20px 12px}
.sheet .foot{background:var(--paper);padding-bottom:34px}
.scr.export.sheetbg{height:auto}
.scr.export .sheet{position:relative;max-height:none;margin-top:auto}
.scr.export.sheetbg .dim{position:absolute}
"""
