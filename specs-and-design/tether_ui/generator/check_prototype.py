import asyncio, json, sys
from playwright.async_api import async_playwright
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page(viewport={'width':1600,'height':1000})
        errs=[]; pg.on('pageerror', lambda e: errs.append(str(e))); pg.on('console', lambda m: errs.append(m.text) if m.type=='error' else None)
        import os; await pg.goto('file://' + os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'prototype', 'index.html')) if os.path.basename(os.path.dirname(os.path.abspath(__file__))) == 'generator' else 'file://' + os.path.abspath(os.path.join('tether_ui', 'prototype', 'index.html'))); await pg.wait_for_timeout(300)
        sc = await pg.evaluate('window.__runAll()')
        sw = await pg.evaluate('window.__sweep()')
        json.dump({'scenarios': sc, 'sweep': sw, 'errors': errs}, open(sys.argv[1], 'w', newline='\n'))
        print('scenarios', sum(r['ok'] for r in sc), '/', len(sc), ' sweep', sum(r['ok'] for r in sw), '/', len(sw), ' js errors', len(errs))
        for r in sc:
            if not r['ok']: print('SC', r)
        for r in sw:
            if not r['ok']: print('SW', r)
        for e_ in errs[:5]: print('ERR', e_)
        await b.close()
asyncio.run(main())
