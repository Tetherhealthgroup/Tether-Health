import os, re, shutil, json
from dsl import *
from rules import RULES
import l10n

def dstr(s):
    if s is None: return 'null'
    s = str(s).replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n')
    return f"'{s}'"

def dcolor(c):
    if c in PROGRAMS: return f"TColors.program('{c}')"
    return {'coral': 'TColors.coral', 'teal': 'TColors.teal'}.get(c, 'TColors.teal')

def rconst(sid): return f'Routes.{camel(sid)}'

def act(a, ap=None):
    """Dart expression performing action `a` (context in scope). `ap` is the
    action's path (`<element path>.action`, then `.then`, `.cases[i].action`):
    member-visible text inside it (toasts) is keyed by that path."""
    t = a['type']
    if t == 'popto': return f"TNav.popTo(context, {rconst(a['to'])})"
    if t in ('push', 'replace', 'tab', 'sheet', 'reset'):
        target = rconst(a['to'])
        if a.get('context'):
            target = f"(TFlow.onboarding ? {rconst(a['context']['onboarding'])} : {target})"
        fn = {'push': 'push', 'replace': 'replace', 'tab': 'tab', 'sheet': 'sheet', 'reset': 'reset'}[t]
        # A screen opened per programme (route with :program) gets the
        # programme of the element that opens it (validate.check_program_context).
        if t == 'push' and ':program' in SCREENS.get(a['to'], {}).get('route', '') and CUR.get('program'):
            return f"TNav.push(context, {target}, program: {dstr(CUR['program'])})"
        return f'TNav.{fn}(context, {target})'
    if t == 'back': return 'TNav.back(context)'
    if t == 'close': return 'TNav.close(context)'
    if t == 'call': return f"TNav.call(context, {dstr(a['value'])}, label: {dstr(a.get('label'))})"
    if t == 'sms': return f"TNav.sms(context, {dstr(a['value'])})"
    if t == 'external': return f"TNav.external(context, {dstr(a['value'])})"
    if t == 'os_settings': return 'TNav.osSettings(context)'
    if t == 'toast':
        then = f", then: () => {act(a['then'], sub(ap, 'then'))}" if a.get('then') else ''
        return f"TNav.toast(context, {T(a['value'], 'value', ap, 'action:toast')}{then})"
    if t == 'submit':
        then = f", then: () => {act(a['then'], sub(ap, 'then'))}" if a.get('then') else ''
        nq = '' if queueable(a['api']) else ', queueable: false'
        return f"TNav.submit(context, {dstr(a['api'])}, screenId: {dstr(CUR['sid'])}{nq}{then}{safety_routes(a.get('then'), sub(ap, 'then'))})"
    if t == 'branch':
        safety_cases(a)  # raises if a safety outcome has no case
        cases = ', '.join(f"{dstr(c['label'])}: () => {act(c['action'], sub(ap, f'cases[{i}].action'))}" for i, c in enumerate(a['cases']))
        extra = ''
        if a.get('decide'): extra += f", decide: {dstr(a['decide'])}"
        if a.get('provider'): extra += f", provider: {dstr(a['provider'])}"
        if a.get('ask') is not None: extra += device_args(a)
        return f"TNav.branch(context, {dstr(a['question'])}, <String, VoidCallback>{{{cases}}}{extra})"
    raise ValueError(t)

def sub(ap, part): return f'{ap}.{part}' if ap else None

def cb(a, ap=None): return f'() => {act(a, ap)}' if a else 'null'

def pcb(a, program, ap=None):
    """cb() for a list row or tile that names its own programme."""
    prev = CUR.get('program')
    CUR['program'] = program or prev
    try:
        return cb(a, ap)
    finally:
        CUR['program'] = prev

def device_args(a):
    """`, device: TBranchRef(...), when: {...}` for a branch decided by the
    device hook (R-31). Raises on an unknown ask or answer, so a typo never
    generates a branch that the kit cannot decide."""
    ask = a['ask']
    if ask not in ASKS: raise ValueError(f"{CUR['sid']}: unknown ask {ask!r}")
    if not isinstance(a.get('id'), str) or not BRANCH_ID.match(a['id']):
        raise ValueError(f"{CUR['sid']}: branch id {a.get('id')!r} must match {BRANCH_ID.pattern}")
    out = f", device: const TBranchRef({dstr(a['id'])}, TAsk.{ask}, {dstr(CUR['sid'])})"
    when = a.get('when') or {}
    plain = {k: v for k, v in when.items() if not isinstance(v, dict)}
    per = {k: v for k, v in when.items() if isinstance(v, dict)}
    for k in list(plain) + list(per):
        if k not in ASKS[ask]: raise ValueError(f"{CUR['sid']}: {ask} never answers {k!r}")
    for k, m in per.items():
        for p in m:
            if p not in ASKS['platform']: raise ValueError(f"{CUR['sid']}: {k!r} per-platform map has {p!r}")
    if plain:
        out += ', when: const <TAnswer, String>{' + ', '.join(f'TAnswer.{k}: {dstr(v)}' for k, v in plain.items()) + '}'
    if per:
        out += ', whenByPlatform: const <TAnswer, Map<TAnswer, String>>{' + ', '.join(
            f'TAnswer.{k}: {{' + ', '.join(f'TAnswer.{p}: {dstr(l)}' for p, l in m.items()) + '}' for k, m in per.items()) + '}'
    return out

def safety_labels(rule_id):
    """Outcome labels that rules.py marks as safety for `rule_id` (none if unmarked)."""
    rule = RULES.get(rule_id) or {}
    ids = rule.get('safety', [])
    unknown = [i for i in ids if i not in rule.get('outcomes', {})]
    if unknown: raise ValueError(f'{rule_id}: safety ids {unknown} are not outcomes')
    return [rule['outcomes'][i] for i in ids]

def safety_cases(a):
    """The cases of branch `a` for its rule's safety outcomes, in safety order.
    Raises when the rule marks a safety outcome that has no case with exactly
    that label: a safety outcome must never be dropped silently."""
    if not a.get('decide') or a['decide'].startswith('choice:'): return []
    by_label = {c['label']: c for c in a['cases']}
    labels = safety_labels(a['decide'])
    missing = [l for l in labels if l not in by_label]
    if missing:
        raise ValueError(f"{CUR['sid']}: branch {a['question']!r} is decided by {a['decide']}, whose safety outcomes {missing} have no case with that exact label")
    return [by_label[l] for l in labels]

SAFETY_ACTION_TYPES = ('replace', 'push')

def check_safety_action(rule_id, case):
    """Raises unless the safety outcome `case` of `rule_id` leaves the screen:
    its action must be a replace or a push to a different screen (with any
    onboarding target also different). Other actions (back, close, toast,
    tab, reset, popto, ...) either stay on the screen or can dismiss a screen
    the member opened."""
    a = case['action']
    sid = CUR['sid']
    where = f"{sid}: safety outcome {case['label']!r} of {rule_id}"
    if a['type'] not in SAFETY_ACTION_TYPES:
        raise ValueError(f"{where} must leave the screen with {' or '.join(SAFETY_ACTION_TYPES)} to a different screen, not {a['type']!r}")
    targets = [a['to']] + ([a['context']['onboarding']] if a.get('context') else [])
    here = SCREENS[sid]['route'] if sid in SCREENS else None
    for t in targets:
        if t == sid or (here is not None and t in SCREENS and SCREENS[t]['route'] == here):
            raise ValueError(f"{where} must leave the screen: its {a['type']} target {t!r} is the screen itself")

def safety_routes(then, ap=None):
    """`, safety: TSafetyRoutes(...)` for a submit whose `then` (through toasts)
    is a branch decided by an on-device rule with safety outcomes; '' when the
    branch's rule has no safety outcome (or `then` has no rule-decided branch)."""
    a = then
    while a and a['type'] == 'toast':
        a = a.get('then')
        ap = sub(ap, 'then')
    if not a or a['type'] != 'branch': return ''
    cases = safety_cases(a)
    if not cases: return ''
    for c in cases: check_safety_action(a['decide'], c)
    idx = {id(c): i for i, c in enumerate(a['cases'])}
    routes = ', '.join(f"{dstr(c['label'])}: () => {act(c['action'], sub(ap, 'cases[%d].action' % idx[id(c)]))}" for c in cases)
    return f", safety: TSafetyRoutes({dstr(a['decide'])}, <String, VoidCallback>{{{routes}}})"

def args(**kw):
    parts = []
    for k, v in kw.items():
        if v is None: continue
        parts.append(f'{k}: {v}' if k != '_' else v)
    return ', '.join(parts)

def lst(items): return '[' + ', '.join(items) + ']'

CUR = {'sid': ''}

# The English catalog collected while generating (l10n.Catalog); reset by
# generate().
CAT = l10n.Catalog()

def T(value, prop, path, owner, node_=None, options_with_values=False):
    """Dart expression for a literal of `owner`.`prop` at `path`: a TStrings
    accessor for member-visible text (keyed `<screen>.<path or sid>.<prop>`),
    else the literal itself (l10n.classify)."""
    if value is None: return 'null'
    base = l10n.prop_class(owner, re.sub(r'\[\d+\]', '', prop).split('.')[-1])
    if base is None: raise ValueError(f"{CUR['sid']}: {path} {owner}.{prop} has no literal class (l10n.PROPS)")
    cls = l10n.content_class(value, base, options_with_values)
    if cls != l10n.TEXT:
        if cls in ('brand', 'unit', 'data', 'phone', 'url', 'autonym') and value: CAT.untranslated.add(value)
        return dstr(value)
    sid = CUR['sid']
    where = node_.get('sid') if node_ and node_.get('sid') else path
    key = f'{sid}.{where}.{prop}'
    name = SCREENS.get(sid, {}).get('name', sid)
    CAT.add(key, value, sid, where, prop, f"{name}: {owner.replace('action:', '')} {prop}")
    CUR['uses_s'] = True
    return f's.{l10n.accessor(key)}'

def K(path): return f"const ValueKey('a:{path}')"

def FK(n): return dstr(f"{CUR['sid']}.{n['key']}") if n.get('key') else None

# Settings binding (P-71): the TData key of the member's stored value, and
# the control's class (consent is the kit default; plan screens say so).
def BK(n): return dstr(n['bind']) if n.get('bind') else None

def BC(n):
    from validate import PLAN_SCREENS
    return 'TBindClass.plan' if n.get('bind') and CUR['sid'] in PLAN_SCREENS else None

def options(n, path):
    """(values, labels) of a chips or segmented node: values are the stable
    session values (spec `values`, else today's English options); labels the
    shown text, or None when every label equals its value."""
    vals = n.get('values') or n['options']
    has_values = bool(n.get('values'))
    labels = [T(o, f'options[{i}]', path, n['t'], n, options_with_values=has_values) for i, o in enumerate(n['options'])]
    values = [dstr(v) for v in vals]
    return values, (labels if labels != values else None)

def value_of(n, label):
    """The session value of option `label` of `n` (spec `values`, else the label)."""
    if not n.get('values'): return label
    return n['values'][n['options'].index(label)]

# Member-data binding (P-89, R-163, bindings.py): an element with `data`
# ({property: bind key}) is built by TBoundValues from the member's values;
# BV() reads a bound property from its TValues `v`, with the spec's example
# as the fallback. A card and everything in it is one element (one tag at
# most): its descendants read the card's `v`.
BIND = {'data': {}, 'used': [], 'group': None}

# Where an element's Example tag goes (R-163): after a text or number, at
# the top trailing corner of a container.
INLINE_TAG = ('eyebrow', 'title', 'text', 'quote', 'big')

def BV(prop, expr, series=False):
    """`expr` (the property's example), or a read of the member's value for
    it when the element binds `prop`."""
    key = BIND['data'].get(prop)
    if key is None or expr in (None, 'null'): return expr
    BIND['used'].append(prop)
    BIND['group'].append(key)
    return f"v.{'series' if series else 'text'}({dstr(key)}, {expr})"

def bound_inside(n):
    """Whether `n` or any node inside it binds a property."""
    return any(x.get('data') for x, _ in walk([n]))

def node(n, top=False, path=''):
    """Dart expression for spec node `n`. An element with bound properties is
    built by TBoundValues from the member's values (P-89)."""
    saved = dict(BIND)
    root = BIND['group'] is None and bound_inside(n)
    BIND['data'], BIND['used'] = n.get('data') or {}, []
    if root: BIND['group'] = []
    try:
        code = _node(n, top, path)
        data, used, keys = BIND['data'], BIND['used'], BIND['group']
    finally:
        BIND.update(saved)
    import bindings
    unsupported = sorted(p for p in data if bindings._generic(p) not in bindings.BINDABLE_PROPS.get(n['t'], ()))
    if unsupported:
        raise ValueError(f"{CUR['sid']}: {path} binds {unsupported}, which the generator does not emit for a {n['t']}")
    missing = sorted(set(data) - set(used))
    if missing:
        raise ValueError(f"{CUR['sid']}: {path} binds {missing}, which the generator does not emit for a {n['t']}")
    if not root: return code
    place = ', place: TExamplePlace.inline' if n['t'] in INLINE_TAG else ''
    return f"TBoundValues(keys: const [{', '.join(dstr(k) for k in dict.fromkeys(keys))}]{place}, builder: (context, v) => {code})"

def _node(n, top=False, path=''):
    t = n['t']
    S_ = dstr
    def X(prop, owner=None, item=None, ip=None):
        """Member-visible prop `prop` of this node (or of list item `item` at
        item path `ip`, e.g. 'items[2]')."""
        src = item if item is not None else n
        v = src.get(prop)
        if v is None: return None
        pp = f'{ip}.{prop}' if ip else prop
        return BV(pp, T(v, pp, path, owner or t, n))
    if t == 'eyebrow': return f"TEyebrow({X('text')})"
    if t == 'title':
        return f"TTitle({args(_=X('text'), size='TTitleSize.' + n.get('size', 'm') if n.get('size', 'm') != 'm' else None, center='true' if n.get('align') == 'center' else None)})"
    if t == 'text':
        tone = n.get('tone', 'body')
        return f"TBody({args(_=X('text'), tone='TTextTone.' + tone if tone != 'body' else None, center='true' if n.get('align') == 'center' else None)})"
    if t == 'steps': return f"TSteps(n: {n['n']}, total: {n['total']})"
    if t == 'chips':
        dots = n.get('dots')
        d = '{' + ', '.join(f"{S_(value_of(n, k))}: {dcolor(v)}" for k, v in dots.items()) + '}' if dots else None
        values, labels = options(n, path)
        return f"TChips({args(fieldKey=FK(n), options=lst(values), labels=lst(labels) if labels else None, selected=lst([S_(value_of(n, o)) for o in n['selected']]) if n['selected'] else None, multi='false' if not n.get('multi') else None, dots=d, label=X('label'), bind=BK(n), bindClass=BC(n))})"
    if t == 'segmented':
        values, labels = options(n, path)
        return f"TSegmented({args(fieldKey=FK(n), options=lst(values), labels=lst(labels) if labels else None, selected=S_(value_of(n, n['selected'])), label=X('label'), bind=BK(n), bindClass=BC(n))})"
    if t == 'radio':
        items = []
        for j, i in enumerate(n['items']):
            lab = T(i['label'], f'items[{j}].label', path, 'radio.items', n)
            items.append(f"TRadioItem({args(_=lab, value=S_(i['label']) if lab != S_(i['label']) else None, sub=X('sub', 'radio.items', i, f'items[{j}]'), badge=X('badge', 'radio.items', i, f'items[{j}]'))})")
        return f"TRadioList({args(fieldKey=FK(n), items=lst(items), selected=str(n['selected']), label=X('label'), bind=BK(n), bindClass=BC(n))})"
    if t == 'checklist':
        items = []
        for j, i in enumerate(n['items']):
            lab = T(i['label'], f'items[{j}].label', path, 'checklist.items', n)
            items.append(f"TCheckItem({args(_=lab, value=S_(i['label']) if lab != S_(i['label']) else None, sub=X('sub', 'checklist.items', i, f'items[{j}]'), done='true' if i.get('done') else None)})")
        return f"TChecklist({args(fieldKey=FK(n), items=lst(items), label=X('label'), bind=BK(n), bindClass=BC(n))})"
    if t == 'toggle': return f"TToggleRow({args(fieldKey=FK(n), label=X('label'), sub=X('sub'), value='true' if n.get('on') else None, bind=BK(n), bindClass=BC(n))})"
    if t == 'field':
        kind = n.get('kind', 'text')
        opts = labs = None
        if n.get('options'): opts, labs = options(n, path)
        return f"TField({args(fieldKey=FK(n), label=X('label'), options=lst(opts) if opts else None, optionLabels=lst(labs) if labs else None, value=X('value') if n.get('value') else None, unit=X('unit') if n.get('unit') else None, hint=X('hint') if n.get('hint') else None, error=X('error') if n.get('error') else None, placeholder=X('placeholder') if n.get('placeholder') else None, kind='TFieldKind.' + kind if kind != 'text' else None, bind=BK(n), bindClass=BC(n))})"
    if t == 'fieldrow': return f"TFieldRow(children: {lst([node(x, path=f'{path}.fields[{i}]') for i, x in enumerate(n['fields'])])})"
    if t == 'slider':
        return f"TSliderField({args(fieldKey=FK(n), label=X('label'), value=str(float(n['value'])), min=str(float(n['min'])), max=str(float(n['max'])), minLabel=X('minLabel'), maxLabel=X('maxLabel'), color=dcolor(n.get('color', 'coral')), suffix=X('suffix') if n.get('suffix') else None)})"
    if t == 'banner':
        return f"TBanner({args(kind='TBannerKind.' + n['kind'], text=X('text'), actionLabel=X('actionLabel') if n.get('actionLabel') else None, onAction=cb(n['action'], path + '.action') if n.get('action') else None, actionKey=K(path) if n.get('action') else None)})"
    if t == 'card' and n.get('follows'):
        design = _node(dict(n, follows=None), top, path)
        return f"TDateSummary({args(fieldKey=FK({'key': n['follows']}), eyebrow=X('eyebrow') if n.get('eyebrow') else None, design=design)})"
    if t == 'card':
        v = n.get('variant', 'plain')
        return f"TCard({args(key=K(path) if n.get('action') else None, variant='TCardVariant.' + v if v != 'plain' else None, tag=S_(n['tag']) if n.get('tag') else None, tagExtra=X('tagExtra') if n.get('tagExtra') else None, eyebrow=X('eyebrow') if n.get('eyebrow') else None, title=X('title') if n.get('title') else None, text=X('text') if n.get('text') else None, accent=S_(n['accent']) if n.get('accent') else None, onTap=cb(n['action'], path + '.action') if n.get('action') else None, cta=node(n['cta'], path=path + '.cta[0]') if n.get('cta') else None, children=lst([node(c, path=f'{path}.children[{i}]') for i, c in enumerate(n['children'])]) if n.get('children') else None)})"
    if t == 'kv':
        kvs = ['(%s, %s)' % (BV('rows[%d][0]' % j, T(k, 'rows[%d][0]' % j, path, 'kv', n)), BV('rows[%d][1]' % j, T(v, 'rows[%d][1]' % j, path, 'kv', n))) for j, (k, v) in enumerate(n['rows'])]
        return f"TKeyValue(rows: {lst(kvs)})"
    if t == 'list':
        rows = []
        for j, r in enumerate(n['rows']):
            L = r.get('lead') or {}
            lead = None
            if 'program' in L: lead = f"TLead.program({S_(L['program'])})"
            elif 'avatar' in L: lead = f"TLead.avatar({S_(L['avatar'])})"
            elif 'icon' in L: lead = f"TLead.icon({S_(L['icon'])})"
            ip = f'rows[{j}]'
            rows.append(f"TListRow({args(key=K(f'{path}.rows[{j}]') if r.get('action') else None, label=X('label', 'list.rows', r, ip), sub=X('sub', 'list.rows', r, ip) if r.get('sub') else None, value=X('value', 'list.rows', r, ip) if r.get('value') else None, lead=lead, pill=X('pill', 'list.rows', r, ip) if r.get('pill') else None, danger='true' if r.get('danger') else None, onTap=pcb(r['action'], L.get('program'), f'{path}.rows[{j}].action') if r.get('action') else None)})")
        return f"TListGroup({args(title=X('title') if n.get('title') else None, flat='true' if n.get('flat') else None, rows=lst(rows))})"
    if t == 'tiles':
        tiles = []
        for j, i in enumerate(n['items']):
            ip = f'items[{j}]'
            lab = X('label', 'tiles.items', i, ip)
            tiles.append(f"TTile({args(key=K(f'{path}.items[{j}]') if i.get('action') else None, label=lab, value=S_(i['label']) if lab != S_(i['label']) else None, sub=X('sub', 'tiles.items', i, ip) if i.get('sub') else None, program=S_(i['program']) if i.get('program') else None, glyph=S_(i['glyph']) if i.get('glyph') else None, selected='true' if i.get('selected') else None, onTap=pcb(i['action'], i.get('program'), f'{path}.items[{j}].action') if i.get('action') else None)})")
        return f"TTileGrid({args(fieldKey=FK(n), columns=str(n.get('cols', 2)) if n.get('cols', 2) != 2 else None, tiles=lst(tiles))})"
    if t == 'stats':
        st_ = [f"TStat({args(label=X('label', 'stats.items', i, f'items[{j}]'), value=X('value', 'stats.items', i, f'items[{j}]'), sub=X('sub', 'stats.items', i, f'items[{j}]') if i.get('sub') else None, program=S_(i['program']) if i.get('program') else None)})" for j, i in enumerate(n['items'])]
        return f"TStatGrid({args(columns=str(n.get('cols', 2)) if n.get('cols', 2) != 2 else None, stats=lst(st_))})"
    if t == 'chart':
        common = dict(key=K(path) if n.get('action') else None, title=X('title') if n.get('title') else None, unit=X('unit') if n.get('unit') else None, caption=X('caption') if n.get('caption') else None, tag=S_(n['tag']) if n.get('tag') else None, onTap=cb(n['action'], path + '.action') if n.get('action') else None)
        vals = lst([str(float(v)) for v in n['values']])
        if 'values' in BIND['data']: vals = BV('values', 'const ' + vals, series=True)
        if n['kind'] == 'bars':
            return f"TBarChart({args(values=vals, color=dcolor(n['color']), missing=lst([str(m) for m in n['missing']]) if n.get('missing') else None, target=str(float(n['target'])) if n.get('target') else None, labels=lst([T(l, f'labels[{j}]', path, 'chart', n) for j, l in enumerate(n['labels'])]) if n.get('labels') else None, **common)})"
        return f"TLineChart({args(values=vals, color=dcolor(n['color']), band=lst([str(float(b)) for b in n['band']]) if n.get('band') else None, **common)})"
    if t == 'zone': return f"TZoneSelector({args(selected=S_(n['selected']), rule=S_(n['rule']) if n.get('rule') else None)})"
    if t == 'ring': return f"TBreathRing({args(value=X('value'), label=X('label') if n.get('label') != 'SECONDS' else None, palette='TRingPalette.indigo' if n.get('palette') == 'indigo' else None)})"
    if t == 'big': return f"TBigNumber({args(value=X('value'), unit=X('unit') if n.get('unit') else None, caption=X('caption') if n.get('caption') else None, center='true' if top else None)})"
    if t == 'button':
        v = {'ghostdark': 'ghostDark'}.get(n.get('variant', 'primary'), n.get('variant', 'primary'))
        on = 'null' if n.get('state') == 'disabled' or not n.get('action') else cb(n['action'], path + '.action')
        if n.get('needs'):
            # Ready when the screen's input `needs` holds a value; with a count
            # label the design's own label is not used at all.
            count = n.get('countLabel')
            countfn = f"(n) => {T(count, 'countLabel', path, 'button', n)}(n: n)" if count else None
            return f"TGatedButton({args(key=K(path), fieldKey=FK({'key': n['needs']}), label=X('label') if not count else None, countLabel=countfn, emptyLabel=X('emptyLabel') if n.get('emptyLabel') else None, onPressed=on, variant='TButtonVariant.' + v if v != 'primary' else None, small='true' if n.get('small') else None, arrow='true' if n.get('arrow') else None)})"
        return f"TButton({args(key=K(path) if on != 'null' else None, label=X('label'), onPressed=on, variant='TButtonVariant.' + v if v != 'primary' else None, small='true' if n.get('small') else None, arrow='true' if n.get('arrow') else None)})"
    if t == 'buttons': return f"TButtonRow(children: {lst([node(b, path=f'{path}.items[{i}]') for i, b in enumerate(n['items'])])})"
    if t == 'authbuttons':
        return f"TAuthButtons(children: {lst([node(b, path=f'{path}.items[{i}]') for i, b in enumerate(n['items'])])})"
    if t == 'authbtn':
        return f"TAuthButton({args(key=K(path), provider=S_(n['provider']), label=X('label'), onPressed=cb(n['action'], path + '.action'), platforms=lst([S_(p) for p in n['platforms']]))})"
    if t == 'link': return f"TLink({args(key=K(path), label=X('label'), onTap=cb(n['action'], path + '.action'), alignLeft='true' if n.get('align') == 'left' else None)})"
    if t == 'quote': return f"TQuote({args(_=X('text'), caption=X('caption') if n.get('caption') else None)})"
    if t == 'illus': return f"TIllustration({args(glyph=S_(n['glyph']), tone='TTone.' + n.get('tone', 'mint') if n.get('tone', 'mint') != 'mint' else None)})"
    if t == 'emergency': return f"TEmergencyCard(text: {X('text')}, actions: {lst([node(b, path=f'{path}.actions[{i}]') for i, b in enumerate(n['actions'])])})"
    if t == 'skeleton': return f"TSkeleton(lines: {n['lines']})"
    if t == 'spacer': return f"SizedBox(height: {float(n['h'])})"
    if t == 'progtag': return f"TProgramTag({args(program=S_(n['program']), extra=X('extra') if n.get('extra') else None)})"
    if t == 'calendar':
        year, month_ = (int(x) for x in n['ym'].split('-')) if n.get('ym') else (None, None)
        return f"TCalendar({args(fieldKey=FK(n), month=X('month'), selected=str(n['selected']), window=lst([str(w) for w in n['window']]), today=str(n['today']) if n.get('today') else None, year=str(year) if year else None, monthNumber=str(month_) if month_ else None)})"
    if t == 'timer': return f"TTimer(value: {X('value')}, label: {X('label')})"
    if t == 'nativeslot': return f"TNativeSlot({args(id=S_(n['id']), label=X('label'), caption=X('caption') if n.get('caption') else None, platform=S_(n['platform']) if n.get('platform', 'ios') != 'ios' else None, height=str(float(n['height'])) if n.get('height', 120) != 120 else None)})"
    raise ValueError(t)

def ind(code, level=3):
    return code

def screen_file(s, describe):
    cls = pascal(s['id']) + 'Screen'
    CUR['sid'] = s['id']
    CUR['program'] = s['program']
    CUR['uses_s'] = False
    kids = ',\n        '.join(node(n, top=True, path=f'body[{i}]') for i, n in enumerate(s['body']))
    foot = ',\n        '.join(node(n, path=f'footer[{i}]') for i, n in enumerate(s['footer']))
    acts = '\n'.join(f'///   • {l} → {describe(a)}' for l, p, a in actions_of(s))
    doc = f"""/// {s['name']}  ·  route `{s['route']}`  ·  flow `{s['flow']}`  ·  kind `{s['kind']}`
/// {('State: ' + s['state'] + ' of ' + s['variantOf']) if s['variantOf'] else 'Default state'}{(' · program ' + s['program']) if s['program'] else ''} · phase {s['phase']}
/// {s['desc']}
///
/// Actions (generated from spec/screens/{s['id']}.json):
{acts}
/// API: {', '.join(s['api']) or '—'}"""
    if s['kind'] == 'sheet':
        body = f"""    return TSheet(
      children: [
        {kids},
      ],
      footer: [
        {foot}{',' if foot else ''}
      ],
    );"""
    else:
        h = s.get('header')
        hdr = ''
        if h:
            left = {'back': 'THeaderLeft.back', 'close': 'THeaderLeft.close', 'none': 'THeaderLeft.none', 'logo': 'THeaderLeft.logo'}[h.get('left', 'back')]
            hdr = f"      header: THeader({args(title=T(h.get('title') or '', 'title', 'header', 'header'), left=left if left != 'THeaderLeft.back' else None, pill=T(h['pill'], 'pill', 'header', 'header') if h.get('pill') else None, avatar=dstr(h['avatar']) if h.get('avatar') else None, onAvatar=cb(h['avatarAction'], 'header.avatar.action') if h.get('avatarAction') else None)}),\n"
        bg = ''
        if s.get('bg') == 'indigo': bg = '      background: TBackground.indigo,\n'
        elif s['dark']: bg = '      background: TBackground.dark,\n'
        tabl = f"      tab: '{s['tab']}',\n" if s.get('tab') else ''
        footer = f"      footer: [\n        {foot},\n      ],\n" if foot else ''
        body = f"""    return TScreen(
{hdr}{bg}{tabl}      children: [
        {kids},
      ],
{footer}    );"""
    routes_imp = "import '../../router/routes.dart';\n" if 'Routes.' in body else ''
    hook = "    TFlow.onboarding = true; // program setups now return here\n" if s['id'] == 'ob_setup' else ''
    if CUR['uses_s']: hook += '    final s = TStrings.of(context);\n'
    return f"""// GENERATED from spec/screens/{s['id']}.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

{routes_imp}import '../../ui/ui.dart';

{doc}
class {cls} extends StatelessWidget {{
  const {cls}({{super.key}});

  @override
  Widget build(BuildContext context) {{
{hook}{body}
  }}
}}
"""

def settings_file():
    """lib/router/settings_screens.dart: the pinned consent- and plan-class
    settings screens (validate.CONSENT_SCREENS, PLAN_SCREENS; P-71)."""
    from validate import CONSENT_SCREENS, PLAN_SCREENS
    def ids(xs): return '\n'.join(f'  {dstr(sid)},' for sid in sorted(xs))
    return f"""// GENERATED — settings screens (P-71): screens whose submit updates
// existing state, by the class of their bound controls (spec `bind`).
//
// Consent class: a control starts from the member's stored value only.
// Nothing stored (TData.unset) and not loaded (null) both show it off and
// write nothing; TSession.touched lists what the member changed, and a
// submit must carry only those keys (nothing to send when there are none).
const Set<String> consentSettingsScreens = <String>{{
{ids(CONSENT_SCREENS)}
}};

// Plan class: a stored value seeds the control and is written to the
// session; nothing stored (TData.unset) seeds the designed starting value;
// not loaded (null) writes nothing. A submit carries the whole screen state,
// and must not be sent while any bound control on the screen is not loaded.
const Set<String> planSettingsScreens = <String>{{
{ids(PLAN_SCREENS)}
}};
"""

def generate(out_dir, describe, static_dir):
    global CAT
    CAT = l10n.Catalog()
    l10n.add_kit(CAT)
    lib = os.path.join(out_dir, 'lib')
    if os.path.exists(out_dir): shutil.rmtree(out_dir)
    shutil.copytree(static_dir, out_dir)
    # barrel
    open(os.path.join(lib, 'ui', 'ui.dart'), 'w', newline='\n').write("export '../l10n/strings.g.dart';\nexport '../logic/rules.dart';\nexport 'components.dart';\nexport 'data.dart';\nexport 'environment.dart';\nexport 'nav.dart';\nexport 'strings.dart';\nexport 'tokens.dart';\n")
    # routes
    lines = ['// GENERATED — route names for every screen and state in spec/screens.json.', 'abstract final class Routes {']
    for sid, s in SCREENS.items():
        lines.append(f"  /// {s['name']}{' (' + s['state'] + ')' if s['variantOf'] else ''}")
        lines.append(f"  static const {camel(sid)} = {dstr(s['route'])};")
    lines.append('}')
    os.makedirs(os.path.join(lib, 'router'), exist_ok=True)
    open(os.path.join(lib, 'router', 'routes.dart'), 'w', newline='\n').write('\n'.join(lines) + '\n')
    open(os.path.join(lib, 'router', 'settings_screens.dart'), 'w', newline='\n').write(settings_file())
    # screens
    imports = []
    for sid, s in SCREENS.items():
        d = os.path.join(lib, 'screens', s['flow'])
        os.makedirs(d, exist_ok=True)
        open(os.path.join(d, f'{sid}_screen.dart'), 'w', newline='\n').write(screen_file(s, describe))
        imports.append(f"import '../screens/{s['flow']}/{sid}_screen.dart';")
    builders = '\n'.join(f"    Routes.{camel(sid)}: (_) => const {pascal(sid)}Screen()," for sid in SCREENS)
    sheets = ', '.join(f'Routes.{camel(sid)}' for sid, s in SCREENS.items() if s['kind'] == 'sheet')
    catalog = '\n'.join(f"    ({dstr(sid)}, {dstr(s['name'] + (' · ' + s['state'] if s['variantOf'] else ''))}, {dstr(FLOWS[s['flow']]['title'])}, Routes.{camel(sid)})," for sid, s in SCREENS.items())
    tabs = ', '.join(f"'{t}': Routes.{camel(t)}" for t in TABS)
    router = f"""// GENERATED — every screen in spec/screens.json, registered by route name.
import 'package:flutter/material.dart';

import 'routes.dart';
{chr(10).join(imports)}

abstract final class AppRouter {{
  static final Map<String, WidgetBuilder> screens = <String, WidgetBuilder>{{
{builders}
  }};

  /// Routes presented as modal bottom sheets.
  static const Set<String> sheets = {{{sheets}}};

  static const Map<String, String> tabRoutes = {{{tabs}}};

  /// (id, name, flow title, route) — drives the dev gallery and tests.
  static const List<(String, String, String, String)> catalog = [
{catalog}
  ];

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {{
    final builder = screens[settings.name];
    if (builder == null) return null;
    if (sheets.contains(settings.name)) {{
      return ModalBottomSheetRoute<void>(
        builder: builder,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        settings: settings,
      );
    }}
    return MaterialPageRoute<void>(builder: builder, settings: settings);
  }}
}}
"""
    open(os.path.join(lib, 'router', 'app_router.dart'), 'w', newline='\n').write(router)
    bindings_test(out_dir)
    # localized strings: spec/l10n/en.arb (generated) and lib/l10n/strings.g.dart
    l10n_dir = os.path.join(os.path.dirname(os.path.abspath(out_dir)), 'spec', 'l10n')
    LOCALES[:] = l10n.write_outputs(CAT, l10n_dir, lib, untranslated_dart(CAT))
    return len(SCREENS)


# (locale, status, missing keys) of the hand-maintained translations, set by generate().
LOCALES = []


def untranslated_dart(cat):
    """Member-visible literals the generated screens show as they are
    (brands, units, numbers, phone numbers, autonyms): the pseudo-locale test
    accepts them un-pseudo'd."""
    vals = sorted(cat.untranslated)
    return ('\n/// Member-visible literals shown as they are in every language (brands,\n/// units, numbers, phone numbers, language names).\n'
            'const Set<String> tUntranslatedLiterals = <String>{\n' + ''.join(f'  {dstr(v)},\n' for v in vals) + '};\n')


def bindings_test(out_dir):
    """test/bindings_test.dart (P-89): spec/bindings.json lists every bound
    element of every generated screen, an element without the member's value
    shows its example with the Example tag, and one with the member's values
    shows them without it."""
    import bindings
    rows = bindings.catalogue()['bindings']
    by_screen = {}
    for r in rows: by_screen.setdefault(r['screen'], []).append(r)
    expected = '\n'.join(f"  ({dstr(r['screen'])}, {dstr(r['path'])}, {dstr(r['bind'])})," for r in rows)
    screens = '\n'.join(f"  ({dstr(sid)}, Routes.{camel(sid)}, {dstr('bf') if ':program' in SCREENS[sid]['route'] else 'null'})," for sid in by_screen)
    code = f"""// GENERATED — member-data bindings (P-89, R-163). spec/bindings.json lists
// every bound value of the generated screens (generator/bindings.py). Every
// screen is opened: the bound elements it renders must be exactly the ones
// listed for it. Preview answers (TData.example) show the examples with no
// tag; with every key unset (loaded, no member value) every bound element
// shows its example with one Example tag; with the member's values none
// does. Binding never writes to the session, so an example never reaches a
// payload or a decision rule.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

/// (screen, element path + property, bind key), as generated.
const _expected = <(String, String, String)>[
{expected}
];

/// Screens with bound values: (id, route, programme it is opened for).
const _bound = <(String, String, String?)>[
{screens}
];

List<Map<String, Object?>> _catalogue() {{
  final json = jsonDecode(File('../spec/bindings.json').readAsStringSync()) as Map<String, Object?>;
  return [for (final r in json['bindings']! as List<Object?>) (r! as Map<Object?, Object?>).cast<String, Object?>()];
}}

/// A TData for the display keys [display]: the given value per key, or
/// [fallback] (null = not loaded, TData.unset = no member value,
/// TData.example = preview). Every other key (settings controls, P-71)
/// keeps the preview answer, so only the display values change.
class _Data implements TData {{
  _Data(this.values, {{this.display = const <String>{{}}, this.fallback}});
  final Map<String, Object?> values;
  final Set<String> display;
  final Object? fallback;
  @override
  ValueListenable<Object?> watch(String bindKey) => ValueNotifier<Object?>(
      values.containsKey(bindKey) ? values[bindKey] : (display.contains(bindKey) ? fallback : TData.example));
}}

Future<void> _open(WidgetTester tester, String route, String? program) async {{
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  TSession.clear();
  final builder = AppRouter.screens[route]!;
  final sheet = AppRouter.sheets.contains(route);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    onGenerateRoute: AppRouter.onGenerateRoute,
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(
        settings: RouteSettings(name: route, arguments: program == null ? null : TRouteArgs(program: program)),
        builder: (c) => sheet ? TSheetPreview(child: builder(c)) : builder(c),
      ),
    ],
  ));
  await tester.pump(const Duration(milliseconds: 50));
}}

List<String> _renderedKeys(WidgetTester tester) => [
      for (final w in tester.widgetList<TBoundValues>(find.byType(TBoundValues, skipOffstage: false))) ...w.keys,
    ]..sort();

Finder _tags() => find.byType(TExampleTag, skipOffstage: false);

void main() {{
  tearDown(() {{
    TData.instance = PreviewData();
    TSession.clear();
  }});

  test('spec/bindings.json lists exactly the generated bindings', () {{
    final rows = _catalogue();
    expect([for (final r in rows) (r['screen'], r['path'], r['bind'])], _expected);
    for (final r in rows) {{
      expect(r['example'], isNotNull, reason: '${{r['path']}}');
      expect(['text', 'series'], contains(r['type']));
      expect(r['kind'], isA<String>());
    }}
  }});

  testWidgets('screens without bindings render no bound element and no tag', (tester) async {{
    final bound = {{for (final b in _bound) b.$1}};
    TData.instance = _Data({{}}, fallback: TData.unset);
    for (final s in AppRouter.catalog) {{
      if (bound.contains(s.$1)) continue;
      await _open(tester, s.$4, null);
      expect(_renderedKeys(tester), isEmpty, reason: '${{s.$1}} renders a bound element not in spec/bindings.json');
      expect(_tags(), findsNothing, reason: s.$1);
    }}
  }});

  for (final (sid, route, program) in _bound) {{
    testWidgets('$sid: bound values are listed; unset values are tagged, member and preview values are not; the session is unchanged', (tester) async {{
      final rows = [for (final r in _catalogue()) if (r['screen'] == sid) r];
      final keys = [for (final r in rows) r['bind']! as String];
      final display = {{for (final k in keys) TData.resolve(k, program)!}};

      // Preview: the examples, no tag.
      await _open(tester, route, program);
      expect(_renderedKeys(tester), (keys.toSet().toList()..sort()), reason: 'bound keys on $sid');
      expect(_tags(), findsNothing, reason: 'preview shows no tag');
      final elements = find.byType(TBoundValues, skipOffstage: false).evaluate().length;
      final session = Map<String, Object?>.of(TSession.values);

      // Loaded, no member value: every bound element carries one tag.
      for (final fallback in [TData.unset, null]) {{
        TData.instance = _Data({{}}, display: display, fallback: fallback);
        await _open(tester, route, program);
        expect(_tags(), findsNWidgets(elements), reason: 'every bound element is tagged ($fallback)');
        expect(TSession.values, session, reason: 'examples never enter the session');
      }}

      // The member's values: shown, no tag.
      final values = <String, Object?>{{}};
      final shown = <String>[];
      for (final (i, r) in rows.indexed) {{
        final key = TData.resolve(r['bind']! as String, program)!;
        if (r['type'] == 'series') {{
          values[key] = [1, 2, 3 + i];
        }} else {{
          // Upper case, so an eyebrow shows it unchanged; X ends it, so M1X
          // never matches inside M11X.
          values[key] = 'M${{i}}X';
          shown.add('M${{i}}X');
        }}
      }}
      TData.instance = _Data(values, display: display, fallback: TData.unset);
      await _open(tester, route, program);
      expect(_tags(), findsNothing, reason: 'member values carry no tag');
      for (final t in shown) {{
        expect(find.textContaining(t, skipOffstage: false), findsWidgets, reason: 'member value $t on $sid');
      }}
      expect(TSession.values, session, reason: 'member display values never enter the session');
      expect(tester.takeException(), isNull);
    }});
  }}
}}
"""
    open(os.path.join(out_dir, 'test', 'bindings_test.dart'), 'w', newline='\n').write(code)


JOURNEYS = [
    ('first run: choose programs, set up BreatheFree, continue as guest', 'welcome',
     ['Get started', 'BreatheFree', 'ScrollFree', 'Continue with 2 programs', 'Continue', 'Agree and continue', 'Continue', 'BreatheFree', 'Next', 'Next', 'Save my reasons',
      'Continue with this path', 'Confirm this date', 'Review my plan', 'Start my plan', 'Continue', 'Not now', 'Continue on this phone only'], 'today'),
    ('craving rescue from Today', 'today', ['Rescue', 'A cigarette', 'I’m done', 'Back to Today'], 'today'),
    ('Heartwise: log two readings, see trends', 'hw_home', ['Log blood pressure', 'Next reading', 'Save readings', 'See trends'], 'hw_trends'),
    ('ClearAir: zone check routes by computed zone', 'ca_home', ['Check my zone', 'Save and see my steps'], 'ca_home'),
    ('delete account with receipt', 'account', ['Your data', 'Delete account and all data', 'Delete everything', 'Done'], 'welcome'),
    ('switch tabs from Today', 'today', ['Plans', 'Progress', 'Learn', 'Support', 'Today'], 'today'),
]

def journeys_test(out_dir):
    cases = []
    for name, start, taps, end in JOURNEYS:
        steps = '\n'.join(f"      await _tap(tester, {dstr(t)});" for t in taps)
        cases.append(f"""  testWidgets({dstr(name)}, (tester) async {{
    await _start(tester, Routes.{camel(start)});
{steps}
    expect(find.byType({pascal(end)}Screen), findsOneWidget);
    expect(tester.takeException(), isNull);
  }});""")
    imports = sorted({f"import 'package:tether_ui/screens/{SCREENS[e]['flow']}/{e}_screen.dart';" for _, _, _, e in JOURNEYS})
    code = f"""// GENERATED — end-to-end journeys that tap real buttons through the app.
// Branches pick their first outcome (TNav.branchResolver), so each journey
// follows the main path defined in spec/flows.json.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';
{chr(10).join(imports)}

Future<void> _settle(WidgetTester tester) async {{
  for (var i = 0; i < 8; i++) {{
    await tester.pump(const Duration(milliseconds: 120));
  }}
}}

Future<void> _start(WidgetTester tester, String route) async {{
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  TFlow.onboarding = false;
  TNav.branchResolver = (context, question, outcomes) async => outcomes.first;
  await tester.pumpWidget(MaterialApp(
    theme: tetherTheme(),
    onGenerateRoute: AppRouter.onGenerateRoute,
    onGenerateInitialRoutes: (_) => [AppRouter.onGenerateRoute(RouteSettings(name: route))!],
  ));
  await _settle(tester);
}}

Future<void> _tap(WidgetTester tester, String label) async {{
  final finder = find.text(label, skipOffstage: true);
  expect(finder, findsWidgets, reason: 'No visible "$label"');
  await tester.ensureVisible(finder.last);
  await tester.tap(finder.last);
  await _settle(tester);
}}

void main() {{
{chr(10).join(cases)}
}}
"""
    open(os.path.join(out_dir, 'test', 'journeys_test.dart'), 'w', newline='\n').write(code)


def _expect(ok, message):
    """An explicit error, not an assert: `python -O` must not skip the check."""
    if not ok: raise AssertionError(message)


def _self_test():
    """python3 gen_dart.py: the safety checks raise on a missing safety case
    and on a safety action that does not leave the screen."""
    rule = {'outcomes': {'ok': 'Fine', 'bad': 'Danger'}, 'safety': ['bad']}
    RULES['selftest.rule'] = rule
    CUR['sid'] = 'selftest'
    added = [k for k in ('selftest', 'selftest_alias') if k not in SCREENS]
    for k in added: SCREENS[k] = {'route': '/selftest'}  # two screen ids, one route
    try:
        def branch(danger):
            return {'type': 'branch', 'question': 'Q', 'decide': 'selftest.rule', 'cases': [{'label': 'Fine', 'action': {'type': 'back'}}, {'label': 'Danger', 'action': danger}]}
        good = branch({'type': 'replace', 'to': 'crisis'})
        _expect('TSafetyRoutes' in safety_routes(good), 'a replace to another screen was not generated')
        _expect('TNav.push(context, Routes.crisis)' in safety_routes(branch({'type': 'push', 'to': 'crisis'})), 'a push to another screen was not generated')
        stays = [
            ({'type': 'back'}, "not 'back'"),
            ({'type': 'close'}, "not 'close'"),
            ({'type': 'toast', 'value': 'Saved'}, "not 'toast'"),
            ({'type': 'tab', 'to': 'crisis'}, "not 'tab'"),
            ({'type': 'reset', 'to': 'crisis'}, "not 'reset'"),
            ({'type': 'popto', 'to': 'crisis'}, "not 'popto'"),
            ({'type': 'replace', 'to': 'selftest'}, "target 'selftest' is the screen itself"),
            ({'type': 'push', 'to': 'selftest'}, "target 'selftest' is the screen itself"),
            ({'type': 'replace', 'to': 'crisis', 'context': {'onboarding': 'selftest'}}, "target 'selftest' is the screen itself"),
            ({'type': 'replace', 'to': 'selftest_alias'}, "target 'selftest_alias' is the screen itself"),
            ({'type': 'push', 'to': 'selftest_alias'}, "target 'selftest_alias' is the screen itself"),
        ]
        for danger, why in stays:
            submit = {'type': 'submit', 'api': 'POST /x', 'then': {'type': 'toast', 'value': 'Saved', 'then': branch(danger)}}
            for f, a in ((safety_routes, branch(danger)), (act, submit)):
                try:
                    f(a)
                except ValueError as e:
                    _expect("safety outcome 'Danger' of selftest.rule must leave the screen" in str(e) and why in str(e), str(e))
                else:
                    raise AssertionError(f'{f.__name__} did not raise for the safety action {danger}')
        bad = dict(good, cases=[{'label': 'Fine', 'action': {'type': 'back'}}, {'label': 'Danger zone', 'action': {'type': 'close'}}])
        for f in (safety_routes, act):
            try:
                f(bad)
            except ValueError as e:
                _expect('Danger' in str(e), str(e))
            else:
                raise AssertionError(f'{f.__name__} did not raise for a missing safety case')
        rule['safety'] = ['nope']
        try:
            safety_routes(good)
        except ValueError:
            pass
        else:
            raise AssertionError('an unknown safety id did not raise')
    finally:
        del RULES['selftest.rule']
        for k in added: del SCREENS[k]
    _device_self_test()
    _bind_self_test()
    _data_self_test()
    _l10n_self_test()
    print('gen_dart self-test: ok')


def _l10n_self_test():
    """Member-visible text is emitted as a TStrings accessor keyed by screen,
    path (or sid) and property; identifiers, brands and numbers stay
    literals; option values stay the English source; the catalog and the
    generated Dart carry the release and draft locales."""
    global CAT
    saved = CAT
    CAT = l10n.Catalog()
    CUR['sid'], CUR['program'] = 'selftest', None
    try:
        code = node(title('Hello there'), path='body[0]')
        _expect(code == 'TTitle(s.selftestBodyN0Text)' and CAT.entries['selftest.body[0].text']['text'] == 'Hello there', code)
        _expect(node(title('BreatheFree'), path='body[1]') == "TTitle('BreatheFree')" and 'BreatheFree' in CAT.untranslated, 'a brand was translated')
        _expect(node(with_sid(title('Moved'), 'headline'), path='body[9]') == 'TTitle(s.selftestHeadlineText)', 'sid did not key the string')
        b = node(button('Save', toast('Saved', then=toast('Again'))), path='footer[0]')
        _expect('TNav.toast(context, s.selftestFooterN0ActionValue, then: () => TNav.toast(context, s.selftestFooterN0ActionThenValue))' in b, b)
        sg = node(seg(['English', 'Español'], 'English', values=['en', 'es'], key='l'), path='body[2]')
        _expect("options: ['en', 'es'], labels: ['English', 'Español'], selected: 'en'" in sg, sg)
        ch = node(chips(['Morning', 'Evening'], selected=['Evening'], key='c', dots={'Evening': 'bf'}), path='body[3]')
        _expect("options: ['Morning', 'Evening'], labels: [s.selftestBodyN3OptionsN0, s.selftestBodyN3OptionsN1], selected: ['Evening']" in ch and "dots: {'Evening':" in ch, ch)
        r = node(radio(['Yes', 'No'], key='r'), path='body[4]')
        _expect("TRadioItem(s.selftestBodyN4ItemsN0Label, value: 'Yes')" in r, r)
        try:
            CAT.add('selftest.body[0].text', 'Different', 'selftest', 'body[0]', 'text', '')
        except ValueError:
            pass
        else:
            raise AssertionError('two English texts for one key did not raise')
        dart = l10n.strings_dart(CAT, [('es', 'draft', {'selftest.body[0].text': 'Hola'}, 3, [])])
        _expect("const List<String> tReleaseLocales = <String>['en'];" in dart and "const List<String> tDraftLocales = <String>['es'];" in dart, 'locale lists')
        _expect("return release ? null : _es;" in dart and "return release ? null : _pseudo;" in dart and "return _en;" in dart, 'drafts and pseudo are debug only')
        _expect('String get selftestBodyN0Text => get(' in dart, 'typed accessor')
        dart = l10n.strings_dart(CAT, [('es', 'release', {k: 'x' for k in CAT.entries}, 0, [])])
        _expect("tReleaseLocales = <String>['en', 'es'];" in dart and "      return _es;" in dart, 'a release locale is always offered')
    finally:
        CAT = saved


def _bind_self_test():
    """Settings binding (P-71): a bound control is emitted with its bind key
    and, on a plan screen, its class; an unbound one with neither; a push to
    a per-programme screen carries the element's programme; and
    settings_screens.dart lists both pinned classes."""
    from validate import CONSENT_SCREENS, PLAN_SCREENS, load
    load()
    for sid, cls in ((CONSENT_SCREENS[0], None), (PLAN_SCREENS[0], 'TBindClass.plan')):
        CUR['sid'] = sid
        for n in (toggle('A', key='a', bind='x.a'), chips(['A'], key='a', bind='x.a'), seg(['A'], 'A', key='a', bind='x.a'),
                  radio(['A'], key='a', bind='x.a'), checklist(['A'], key='a', bind='x.a'), field('A', kind='select', key='a', bind='x.a')):
            code = node(n)
            _expect("bind: 'x.a'" in code and f"fieldKey: '{sid}.a'" in code and (('bindClass: ' + cls) in code if cls else 'bindClass' not in code), code)
            n.pop('bind')
            _expect('bind:' not in node(n) and 'bindClass' not in node(n), node(n))
    per = next(sid for sid, s in SCREENS.items() if ':program' in s['route'])
    plain = next(sid for sid, s in SCREENS.items() if ':program' not in s['route'])
    CUR['sid'], CUR['program'] = 'selftest', 'bf'
    try:
        _expect(act(go(per)) == f"TNav.push(context, {rconst(per)}, program: 'bf')", act(go(per)))
        _expect(act(go(plain)) == f'TNav.push(context, {rconst(plain)})', act(go(plain)))
        row_ = node(rows([row('Sf', lead=L_prog('sf'), action=go(per))]))
        _expect("program: 'sf'" in row_, row_)
        CUR['program'] = None
        _expect(act(go(per)) == f'TNav.push(context, {rconst(per)})', act(go(per)))
    finally:
        CUR['program'] = None
    text = settings_file()
    _expect(all(f"  '{sid}'," in text for sid in CONSENT_SCREENS + PLAN_SCREENS) and text.count("',") == len(CONSENT_SCREENS) + len(PLAN_SCREENS), text)
    _expect(text.index('consentSettingsScreens') < text.index(f"'{CONSENT_SCREENS[0]}'") < text.index('planSettingsScreens') < text.index(f"'{PLAN_SCREENS[0]}'"), text)

def _data_self_test():
    """Member-data binding (P-89): a bound property is read from TValues with
    the example as fallback; an unbound element is unchanged; a binding the
    generator cannot emit fails generation."""
    CUR['sid'], CUR['program'] = 'selftest', None
    plain = node(big('128/82', 'mmHg'), path='body[0]')
    _expect('TBoundValues' not in plain, plain)
    code = node(dict(big('128/82', 'mmHg', 'Average of 2'), data={'value': 'hw.last_bp'}), path='body[0]')
    _expect(code.startswith("TBoundValues(keys: const ['hw.last_bp'], place: TExamplePlace.inline, builder: (context, v) => TBigNumber(") and "value: v.text('hw.last_bp', '128/82')" in code and 'v.text' not in code.split('caption:')[1], code)
    kv_ = node(dict(kv([('Programs', '4'), ('Check-ins', '63')]), data={'rows[1][1]': 'account.data.check_ins'}), path='body[1]')
    _expect("('63')" not in kv_ and "v.text('account.data.check_ins', '63')" in kv_ and "'4')" in kv_, kv_)
    ch = node(dict(bars([1, 2], 'teal', title='Week'), data={'values': 'hw.week'}), path='body[2]')
    _expect("values: v.series('hw.week', const [1.0, 2.0])" in ch, ch)
    card_ = node(dict(card(dict(big('7 days'), data={'value': 'bf.days'}), eyebrow='Your quit day'), data={'eyebrow': 'bf.heading'}), path='body[3]')
    _expect(card_.count('TBoundValues(') == 1 and card_.startswith("TBoundValues(keys: const ['bf.heading', 'bf.days'], builder: (context, v) => TCard(") and "v.text('bf.days', s." in card_, card_)
    inner = node(card(dict(big('7 days'), data={'value': 'bf.days'}), eyebrow='Your quit day'), path='body[4]')
    _expect(inner.startswith("TBoundValues(keys: const ['bf.days'], builder: (context, v) => TCard("), inner)
    _expect("place:" not in kv_ and "place:" not in ch, 'containers carry the tag at the corner')
    try:
        node(dict(button('Go', back()), data={'label': 'x.y'}), path='footer[0]')
    except ValueError as e:
        _expect('does not emit' in str(e), str(e))
    else:
        raise AssertionError('an unsupported binding generated')


def _device_self_test():
    """Device branches and non-queueable submits generate as R-31 says, and
    a branch the kit could not decide fails generation."""
    CUR['sid'] = 'selftest'
    def dev(**kw):
        return dict({'type': 'branch', 'question': 'Q', 'cases': [{'label': 'Yes', 'action': {'type': 'back'}}, {'label': 'No', 'action': {'type': 'close'}}],
                     'id': 'selftest.screen.check', 'ask': 'notificationsCheck', 'when': {'granted': 'Yes', 'denied': 'No'}}, **kw)
    code = act(dev())
    _expect("device: const TBranchRef('selftest.screen.check', TAsk.notificationsCheck, 'selftest')" in code, code)
    _expect("when: const <TAnswer, String>{TAnswer.granted: 'Yes', TAnswer.denied: 'No'}" in code, code)
    _expect('whenByPlatform' not in code, code)
    per = act(dev(when={'granted': {'ios': 'Yes', 'android': 'No'}, 'denied': 'No'}))
    _expect("whenByPlatform: const <TAnswer, Map<TAnswer, String>>{TAnswer.granted: {TAnswer.ios: 'Yes', TAnswer.android: 'No'}}" in per, per)
    _expect("when: const <TAnswer, String>{TAnswer.denied: 'No'}" in per, per)
    ref = act(dev(ask='reference', when=None))
    _expect('TAsk.reference' in ref and 'when:' not in ref, ref)
    for bad, why in ((dev(ask='nope'), 'unknown ask'), (dev(id='Bad.Id'), 'must match'), (dev(id=None), 'must match'),
                     (dev(when={'granted': 'Yes', 'maybe': 'No'}), 'never answers'), (dev(when={'granted': {'ios': 'Yes', 'web': 'No'}, 'denied': 'No'}), 'per-platform')):
        try:
            act(bad)
        except ValueError as e:
            _expect(why in str(e), str(e))
        else:
            raise AssertionError(f'a device branch with {why} generated')
    plain = act(dev(id=None, ask=None, when=None))
    _expect('device:' not in plain and 'when:' not in plain, plain)
    auth = act({'type': 'submit', 'api': 'POST supabase /auth/v1/token', 'then': {'type': 'back'}})
    _expect("screenId: 'selftest', queueable: false, then:" in auth, auth)
    save = act({'type': 'submit', 'api': 'POST /v1/records/check-ins', 'then': {'type': 'back'}})
    _expect('queueable' not in save, save)
    _expect(all(not queueable(e) and (is_auth_endpoint(e) or e == 'POST /v1/enrolments') for e in NOT_QUEUEABLE), 'NOT_QUEUEABLE holds an unexpected endpoint')
    learn = act({'type': 'submit', 'api': 'POST /v1/enrolments', 'then': {'type': 'back'}})
    _expect("screenId: 'selftest', queueable: false, then:" in learn, learn)


if __name__ == '__main__':
    _self_test()
    import dsl, validate
    dsl._self_test()
    l10n._self_test()
    validate._self_test()
    import bindings
    bindings._self_test()
