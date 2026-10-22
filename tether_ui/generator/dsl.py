"""Tether Health UI spec DSL.

Every screen in the product is declared once, as data, with these helpers.
The same data generates: JSON spec, clickable HTML prototype, PNG screens,
flow diagrams and Flutter (Dart) code. Nothing is hand-drawn twice, so
the prototype, the screenshots and the code cannot drift apart.
"""
import re

PROGRAMS = {
    # id: name, area, archetype, color, letter, status, tagline
    'bf': ('BreatheFree', 'Tobacco & nicotine', 'Quit / Reduce', '#B5432A', 'B', 'Approved · in build', 'Your next breath can be different.'),
    'sf': ('ScrollFree', 'Social media use', 'Quit / Reduce', '#3B4CC0', 'S', 'Proposed', 'Your attention is yours.'),
    'ca': ('ClearAir', 'Respiratory health', 'Manage', '#1D6A93', 'C', 'Prototype on develop', 'Follow your action plan, day by day.'),
    'hw': ('Heartwise', 'Cardiovascular health', 'Manage', '#B3263E', 'H', 'Prototype on develop', 'Know your numbers. Share them on your terms.'),
    'st': ('Steady', 'Diabetes & metabolic health', 'Manage', '#8A5A00', 'S', 'Prototype on develop', 'Notice glucose patterns, without judgment.'),
    're': ('Renew', 'Kidney & liver health', 'Manage', '#1E6B68', 'R', 'Planned', 'Look after your kidneys and liver.'),
    'nu': ('Nourish', 'Obesity & nutrition', 'Build habits', '#3F7426', 'N', 'Planned', 'Food without judgment.'),
    'sd': ('Stride', 'Healthy aging', 'Build habits', '#94501F', 'S', 'Planned', 'Move well, stay well.'),
    'ea': ('Ease', 'Mental & behavioral health', 'Support', '#5B4FB8', 'E', 'Planned', 'Support for how you feel.'),
    'ck': ('Checkup', 'Preventive health', 'Prevent', '#5A661A', 'C', 'Planned', 'What’s due for you, in one place.'),
    'be': ('Beacon', 'Cancer', 'Prevent', '#74428F', 'B', 'Planned', 'Lower your risk. Know your options.'),
}
ORDER = ['bf', 'sf', 'ca', 'hw', 'st', 're', 'nu', 'sd', 'ea', 'ck', 'be']
PHASES = ['welcome', 'onboarding', 'plan', 'daily', 'rescue', 'milestone', 'resources', 'account']
TABS = {'today': 'today', 'plans': 'plans', 'progress': 'progress', 'learn': 'learn', 'support': 'support'}

FLOWS = {}   # flow id -> dict(title, desc, program)
SCREENS = {}  # id -> screen dict
ENTRIES = []  # (screen id, trigger)

def flow(fid, title, desc, program=None):
    FLOWS[fid] = {'id': fid, 'title': title, 'desc': desc, 'program': program, 'screens': []}

# ---------------------------------------------------------------- actions
def go(to, **kw): return dict({'type': 'push', 'to': to}, **kw)
def rep(to, **kw): return dict({'type': 'replace', 'to': to}, **kw)
def tab(to, **kw): return dict({'type': 'tab', 'to': to}, **kw)
def back(): return {'type': 'back'}
def close(): return {'type': 'close'}
def sheet(to): return {'type': 'sheet', 'to': to}
def call(num, label=None): return {'type': 'call', 'value': num, 'label': label or num}
def sms(num): return {'type': 'sms', 'value': num}
def ext(url): return {'type': 'external', 'value': url}
def toast(msg, then=None):
    a = {'type': 'toast', 'value': msg}
    if then: a['then'] = then
    return a
def submit(api, then, **kw): return dict({'type': 'submit', 'api': api, 'then': then}, **kw)
def branch(question, cases, on=None, key=None, decide=None, id=None, ask=None, when=None):
    """cases: list of (label, action). on: 'radio' / 'zone' / 'chips' if the choice is visible in UI.

    A branch that a device or OS answer decides (R-31: permission prompts,
    SMART sign-in, the FHIR server check, the platform) names a stable `id`
    (BRANCH_ID), the device question `ask` (a key of ASKS) and `when`, a map
    from each of that ask's answers to a case label. A `when` value may be a
    per-platform map ({'ios': label, 'android': label}). Reference surfaces
    use ask='reference' with no `when`. The question text is for the preview
    only: production never decides on it."""
    if on and key and not decide: decide = 'choice:' + key
    b = {'type': 'branch', 'question': question, 'on': on, 'decide': decide, 'cases': [{'label': l, 'action': a} for l, a in cases]}
    if id is not None: b['id'] = id
    if ask is not None: b['ask'] = ask
    if when is not None: b['when'] = dict(when)
    return b

# Device questions a branch can ask (R-31), each with its fixed answer
# set. The Flutter kit mirrors this table as TAsk / TAnswer (lib/ui/nav.dart);
# validate.py checks that the two match. 'reference' marks a preview-only
# branch on a reference surface: it has no answers and production never
# decides it in the app.
ASKS = {
    'platform': ('ios', 'android'),
    'notificationsRequest': ('granted', 'denied', 'unavailable'),
    'notificationsCheck': ('granted', 'denied'),
    'healthRecordsRequest': ('granted', 'denied', 'unavailable'),
    'screenTimeRequest': ('granted', 'denied', 'unavailable'),
    'unplugAuthIos': ('granted', 'grantedNotificationsOff', 'denied', 'unavailable'),
    'usageAccessSettings': ('granted', 'denied'),
    'unplugAndroidCheck': ('allOn', 'notificationsOff', 'missing'),
    'unplugTrackingCheck': ('healthy', 'failing'),
    'smartConnect': ('approved', 'cancelled', 'failed'),
    'fhirServerCheck': ('supported', 'unsupported'),
    'reference': (),
}

# Stable branch id: three dot-separated lower-case segments, chosen by hand
# (never derived from the screen or the element path, which move when the
# layout changes).
BRANCH_ID = re.compile(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2}$')

# Submit endpoints that are never queued (R-31): the sign-in and account
# endpoints. A queued result counts as failed('not_queueable') and a failure
# shows the generic message, not the save message. validate.py checks that
# every submit endpoint on "supabase /auth/" is listed and every entry is used.
NOT_QUEUEABLE = (
    'POST supabase /auth/v1/recover',
    'POST supabase /auth/v1/signup',
    'POST supabase /auth/v1/token',
    'POST supabase /auth/v1/user/identities (linkIdentity)',
    'PUT supabase /auth/v1/user',
)

def queueable(endpoint): return endpoint not in NOT_QUEUEABLE

def is_auth_endpoint(endpoint):
    """True for a submit endpoint whose path is on supabase /auth/."""
    parts = endpoint.split(' ', 1)
    return len(parts) == 2 and parts[1].startswith('supabase /auth/')
def settings(): return {'type': 'os_settings'}
def reset(to): return {'type': 'reset', 'to': to}
def popto(to): return {'type': 'popto', 'to': to}
def auth(provider, cases):
    name = {'apple': 'Apple', 'google': 'Google'}[provider]
    return {'type': 'branch', 'question': f'Sign in with {name} result', 'provider': provider, 'on': None, 'decide': None, 'cases': [{'label': l, 'action': a} for l, a in cases]}
def authbuttons(apple=None, google=None, verb='Continue'):
    items = []
    if apple: items.append({'t': 'authbtn', 'provider': 'apple', 'label': f'{verb} with Apple', 'action': apple, 'platforms': ['ios']})
    if google: items.append({'t': 'authbtn', 'provider': 'google', 'label': f'{verb} with Google', 'action': google, 'platforms': ['ios', 'android']})
    return {'t': 'authbuttons', 'items': items}

def onboarding_or(normal_to, onboarding_to='ob_setup', kind='replace'):
    return {'type': kind, 'to': normal_to, 'context': {'onboarding': onboarding_to}}

# ---------------------------------------------------------------- nodes
def N(t, **kw):
    d = {'t': t}
    d.update({k: v for k, v in kw.items() if v is not None})
    return d

def header(title='', left='back', pill=None, avatar=None, dark=False, avatar_to='account'):
    a = go(avatar_to) if avatar else None
    return N('header', title=title, left=left, pill=pill, avatar=avatar, dark=dark or None, avatarAction=a)
def steps(n, total): return N('steps', n=n, total=total)
def eyebrow(text): return N('eyebrow', text=text)
def title(text, size='m', align=None): return N('title', text=text, size=size, align=align)
def text(t, tone='body', align=None): return N('text', text=t, tone=tone, align=align)
def chips(options, selected=(), multi=True, dots=None, label=None, key=None, bind=None): return N('chips', options=list(options), selected=list(selected), multi=multi, dots=dots, label=label, key=key, bind=bind)
def seg(options, selected, label=None, key=None, bind=None): return N('segmented', options=list(options), selected=selected, label=label, key=key, bind=bind)
def radio(items, selected=0, label=None, key=None, bind=None):
    its = [i if isinstance(i, dict) else {'label': i} for i in items]
    return N('radio', items=its, selected=selected, label=label, key=key, bind=bind)
def ri(label, sub=None, badge=None): return {k: v for k, v in {'label': label, 'sub': sub, 'badge': badge}.items() if v}
def checklist(items, label=None, key=None, bind=None): return N('checklist', items=[i if isinstance(i, dict) else {'label': i} for i in items], label=label, key=key, bind=bind)
def ci(label, sub=None, done=False): return {k: v for k, v in {'label': label, 'sub': sub, 'done': done or None}.items() if v}
def toggle(label, sub=None, on=False, key=None, bind=None): return N('toggle', label=label, sub=sub, on=on, key=key, bind=bind)
def field(label, example=None, unit=None, hint=None, error=None, placeholder=None, kind='text', key=None, bind=None):
    """A text input. P-31: a field never starts with a value. The example
    renders as placeholder (hint) text, and the field writes null until the
    user types. If the field already has its own placeholder, the example is
    dropped."""
    return N('field', label=label, unit=unit, hint=hint, error=error, placeholder=placeholder if placeholder is not None else example, kind=kind, key=key, bind=bind)
def fieldrow(*fields): return N('fieldrow', fields=list(fields))
def slider(label, value, mn=0, mx=10, lo=None, hi=None, color='coral', suffix='', key=None):
    return N('slider', label=label, value=value, min=mn, max=mx, minLabel=lo or str(mn), maxLabel=hi or str(mx), color=color, suffix=suffix or None, key=key)
def banner(kind, t, action=None, action_label=None): return N('banner', kind=kind, text=t, action=action, actionLabel=action_label)
def card(*kids, v='plain', tag=None, tagx=None, eyebrow=None, title=None, text=None, action=None, accent=None, cta=None, children=None):
    ch = list(kids) + list(children or [])
    return N('card', variant=v, tag=tag, tagExtra=tagx, eyebrow=eyebrow, title=title, text=text, action=action, accent=accent, children=ch or None, cta=cta)
def kv(rows, inset=False): return N('kv', rows=[list(r) for r in rows], inset=inset or None)
def row(label, sub=None, value=None, action=None, lead=None, pill=None, danger=False):
    return {k: v for k, v in {'label': label, 'sub': sub, 'value': value, 'action': action, 'lead': lead, 'pill': pill, 'danger': danger or None}.items() if v is not None}
def L_prog(pid): return {'program': pid}
def L_av(ch): return {'avatar': ch}
def L_icon(ch): return {'icon': ch}
def rows(items, title=None, flat=False): return N('list', title=title, rows=items, flat=flat or None)
def tiles(items, cols=2, key=None): return N('tiles', items=items, cols=cols, key=key)
def tl(label, sub=None, program=None, glyph=None, selected=False, action=None, color=None):
    return {k: v for k, v in {'label': label, 'sub': sub, 'program': program, 'glyph': glyph, 'selected': selected or None, 'action': action, 'color': color}.items() if v is not None}
def stats(items, cols=2): return N('stats', items=items, cols=cols)
def st(label, value, sub=None, program=None): return {k: v for k, v in {'label': label, 'value': value, 'sub': sub, 'program': program}.items() if v is not None}
def bars(values, color, title=None, unit=None, missing=(), target=None, labels=None, caption=None, tag=None, action=None):
    return N('chart', kind='bars', values=values, color=color, title=title, unit=unit, missing=list(missing) or None, target=target, labels=labels, caption=caption, tag=tag, action=action)
def line(values, color, title=None, unit=None, band=None, caption=None, tag=None, action=None, labels=None):
    return N('chart', kind='line', values=values, color=color, title=title, unit=unit, band=band, caption=caption, tag=tag, action=action, labels=labels)
def zone(selected, rule=None): return N('zone', selected=selected, rule=rule)
def ring(value, label='SECONDS', palette='teal'): return N('ring', value=value, label=label, palette=palette)
def big(value, unit=None, caption=None): return N('big', value=value, unit=unit, caption=caption)
def button(label, action, v='primary', state=None, arrow=None, small=False):
    if arrow is None: arrow = v in ('primary', 'rescue', 'lime', 'white') and not small
    return N('button', label=label, action=action, variant=v, state=state, arrow=arrow, small=small or None)
def buttons(*bs): return N('buttons', items=list(bs))
def link(label, action, align='center'): return N('link', label=label, action=action, align=align)
def quote(t, caption=None): return N('quote', text=t, caption=caption)
def illus(glyph, tone='mint'): return N('illus', glyph=glyph, tone=tone)
def emergency(t='Thoughts of harming yourself? Call or text 988. Emergency: 911.', actions=None):
    acts = actions or [button('Call or text 988', go('crisis'), v='danger', small=True), button('Call 911', call('911'), v='secondary', small=True)]
    return N('emergency', text=t, actions=acts)
def skeleton(lines=3): return N('skeleton', lines=lines)
def spacer(h=8): return N('spacer', h=h)
def progtag(pid, extra=None): return N('progtag', program=pid, extra=extra)
def calendar(month, selected, window, today=None): return N('calendar', month=month, selected=selected, window=window, today=today)
def timer(value, label): return N('timer', value=value, label=label)

# ---------------------------------------------------------------- screens
def S(id, name, route, fl, body, footer=None, program=None, phase=None, kind='screen', tabname=None, variant_of=None, state=None, dark=False, bg=None, desc='', notes=None, over=None, hdr=None, api=None):
    if id in SCREENS:
        # An explicit error, not an assert: `python -O` must not skip it.
        raise ValueError(f'duplicate screen {id}')
    s = {'id': id, 'name': name, 'route': route, 'flow': fl, 'program': program, 'phase': phase, 'kind': kind, 'tab': tabname,
         'variantOf': variant_of, 'state': state or ('default' if not variant_of else None), 'dark': dark, 'bg': bg, 'desc': desc,
         'header': hdr, 'body': body, 'footer': footer or [], 'notes': notes or [], 'over': over, 'api': api or []}
    _assign_keys(s)
    SCREENS[id] = s
    FLOWS[fl]['screens'].append(id)
    return s

def slug(t):
    return re.sub(r'[^a-z0-9]+', '_', (t or '').lower()).strip('_')[:32] or 'value'

def _assign_keys(s):
    # Explicit keys (key=) are the stable session keys the API adapters map,
    # so a copy edit to a label cannot change a payload. They must be unique
    # on a screen. Inputs without one still get a label slug, but validate.py
    # rejects them (AUTO_KEYS).
    used = set()
    for part in ('body', 'footer'):
        for n, p in walk(s[part], part):
            if (n['t'] in INPUTS or n['t'] in KEYED) and n.get('key'):
                if n['key'] in used:
                    # An explicit error, not an assert: `python -O` must not skip it.
                    raise ValueError(f"{s['id']}: duplicate key {n['key']!r} at {p}")
                used.add(n['key'])
    for part in ('body', 'footer'):
        for n, p in walk(s[part], part):
            if n['t'] in INPUTS and not n.get('key'):
                k = slug(n.get('label')) or n['t']
                base, i = k, 2
                while k in used:
                    k = f'{base}_{i}'; i += 1
                used.add(k); n['key'] = k
                AUTO_KEYS.append((s['id'], p, k))
    def q(a):
        if not a: return
        if a.get('decide', '') and a['decide'].startswith('choice:') and '.' not in a['decide']:
            a['decide'] = 'choice:' + s['id'] + '.' + a['decide'][7:]
        for c in a.get('cases', []): q(c['action'])
        q(a.get('then'))
    for _, _, a in actions_of(s): q(a)
    for part in ('body', 'footer'):
        for n, p in walk(s[part], part):
            if n['t'] == 'zone' and n.get('rule'): pass

def entry(screen, trigger): ENTRIES.append({'screen': screen, 'trigger': trigger})

# ---------------------------------------------------------------- graph helpers
INTERACTIVE = ('button', 'link', 'authbtn')
INPUTS = ('field', 'chips', 'segmented', 'radio', 'toggle', 'slider')
# Checklists and selection tiles write to the session only when they have an
# explicit key (consent checklists, the program picker). They are never
# auto-keyed.
KEYED = ('checklist', 'tiles')
AUTO_KEYS = []  # (screen id, path, key) of inputs without an explicit key
# Settings binding (P-71, TH-1008). On a consent- or plan-class settings
# screen (validate.CONSENT_SCREENS, PLAN_SCREENS) every input control that
# writes to the session carries `bind=`: the TData key of the member's stored
# value. The kit starts the control from that value, writes nothing to the
# session while it is not loaded (null), and records which keys the member
# changed (TSession.touched). BINDABLE lists the
# controls the kit can bind; among fields only kind 'select' is bound (text
# fields already start empty, P-31). The bind key itself is never written to
# the session. A ":program" segment stands for the programme the screen was
# opened for (screens whose route has ":program").
BINDABLE = ('toggle', 'checklist', 'chips', 'segmented', 'radio', 'field')
BIND_KEY = re.compile(r'^[a-z][a-z0-9_]*(\.([a-z][a-z0-9_]*|:program))+$')

def walk(nodes, path='body'):
    for i, n in enumerate(nodes or []):
        p = f'{path}[{i}]'
        yield n, p
        if n.get('children'):
            yield from walk(n['children'], p + '.children')
        if n['t'] in ('buttons', 'authbuttons'):
            yield from walk(n['items'], p + '.items')
        if n['t'] == 'emergency':
            yield from walk(n['actions'], p + '.actions')
        if n['t'] == 'fieldrow':
            yield from walk(n['fields'], p + '.fields')
        if n.get('cta'):
            yield from walk([n['cta']], p + '.cta')

def actions_of(s):
    """Yield (element label, path, action) for every interactive element of a screen."""
    out = []
    h = s.get('header')
    if h:
        if h.get('left') == 'back': out.append(('Back', 'header.left', back()))
        if h.get('left') == 'close': out.append(('Close', 'header.left', close()))
        if h.get('avatarAction'): out.append(('Avatar · Account', 'header.avatar', h['avatarAction']))
    for part in ('body', 'footer'):
        for n, p in walk(s[part], part):
            t = n['t']
            if t in INTERACTIVE:
                out.append((n['label'], p, n.get('action')))
            elif t == 'card' and n.get('action'):
                out.append((n.get('title') or n.get('eyebrow') or 'Card', p, n['action']))
            elif t == 'chart' and n.get('action'):
                out.append((n.get('title') or 'Chart', p, n['action']))
            elif t == 'banner' and n.get('action'):
                out.append((n.get('actionLabel') or 'Banner action', p, n['action']))
            elif t == 'list':
                for j, r in enumerate(n['rows']):
                    if r.get('action'): out.append((r['label'], f'{p}.rows[{j}]', r['action']))
            elif t == 'tiles':
                for j, r in enumerate(n['items']):
                    if r.get('action'): out.append((r['label'], f'{p}.items[{j}]', r['action']))
    if s.get('tab'):
        for tname in TABS:
            if tname != s['tab']:
                out.append((f'Tab · {tname.title()}', f'tabbar.{tname}', tab(tname)))
    return out

def targets(a):
    """All screen ids an action can lead to."""
    if not a: return []
    t = a['type']
    res = []
    if t in ('push', 'replace', 'tab', 'sheet', 'reset', 'popto'):
        res.append(a['to'])
        if a.get('context'):
            res += list(a['context'].values())
    if t == 'branch':
        for c in a['cases']: res += targets(c['action'])
    if t in ('toast', 'submit'):
        res += targets(a.get('then'))
    return res

def leaves(a):
    """True if the action takes the user off the current screen."""
    if not a: return False
    t = a['type']
    if t in ('push', 'replace', 'tab', 'sheet', 'reset', 'popto', 'back', 'close', 'branch'): return True
    if t in ('toast', 'submit'): return leaves(a.get('then'))
    return False

def camel(s):
    parts = re.split(r'[_\-/]+', s)
    return parts[0] + ''.join(p[:1].upper() + p[1:] for p in parts[1:])

def pascal(s):
    c = camel(s); return c[:1].upper() + c[1:]


def _self_test():
    """python3 dsl.py (also run by gen_dart.py): a duplicate screen id and a
    duplicate explicit key on a screen raise ValueError, also under
    `python -O`. Uses no assert, so the check itself survives -O."""
    def keys(*ks):
        s = {'id': 'selftest', 'header': None, 'body': [field(f'Field {k}', key=k) for k in ks], 'footer': []}
        _assign_keys(s)
        return [n['key'] for n, _ in walk(s['body'])]
    if keys('a', 'b') != ['a', 'b']:
        raise AssertionError('distinct keys were not kept')
    try:
        keys('a', 'a')
    except ValueError as e:
        if "duplicate key 'a'" not in str(e):
            raise AssertionError(f'unexpected message: {e}')
    else:
        raise AssertionError('a duplicate key did not raise ValueError')
    if 'selftest_flow' in FLOWS or 'selftest_screen' in SCREENS:
        raise AssertionError('self-test ids already in use')
    flow('selftest_flow', 'Self-test', 'Self-test')
    try:
        S('selftest_screen', 'Self-test', '/selftest', 'selftest_flow', [])
        try:
            S('selftest_screen', 'Self-test again', '/selftest2', 'selftest_flow', [])
        except ValueError as e:
            if 'duplicate screen selftest_screen' not in str(e):
                raise AssertionError(f'unexpected message: {e}')
        else:
            raise AssertionError('a duplicate screen id did not raise ValueError')
        if FLOWS['selftest_flow']['screens'] != ['selftest_screen']:
            raise AssertionError('the duplicate screen was registered')
    finally:
        SCREENS.pop('selftest_screen', None)
        FLOWS.pop('selftest_flow', None)
    print('dsl self-test: ok')


if __name__ == '__main__':
    _self_test()
