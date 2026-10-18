from dsl import *

H = header

def records():
    flow('records', 'Health records (FHIR & manual)', 'Connect Epic MyChart, Oracle Health, Medicare Blue Button 2.0, Apple Health Records / Health Connect or any SMART on FHIR R4 server, or enter values by hand. Every value is validated (units, plausibility, duplicates, conflicts) and reviewed before it reaches a program.')

    S('records_hub', 'Health records', '/records', 'records', phase='resources', hdr=H('Health records'), body=[
        banner('info', 'Read-only. Tether never writes to your health record, and each program only gets the data it needs.'),
        rows([row('Patel Family Medicine', 'Epic MyChart · synced today 7:02 AM', lead=L_icon('E'), action=go('records_source')),
              row('Medicare', 'Blue Button 2.0 · synced Oct 12', lead=L_icon('M'), action=go('records_source'))], title='Connected sources'),
        rows([row('Blood pressure', '12 readings · Heartwise', action=go('records_item')), row('Lab results', 'A1C, lipids, eGFR · Steady, Heartwise, Renew', action=go('records_item')),
              row('Immunizations', '6 · Checkup', action=go('records_item')), row('Smoking status', 'Every day smoker (Aug 2026) · BreatheFree', action=go('records_item')),
              row('Medications & conditions', 'Shown for reference only', action=go('records_item'))], title='Imported data'),
        card(v='warn', title='2 items need your review', text='A value that differs from what you entered, and one that looks like a typo.', action=go('records_conflict')),
    ], footer=[button('Add a source', go('records_add')), button('Enter a value manually', go('records_manual'), v='secondary')],
       api=['GET /v1/records/fhir/sources', 'GET /v1/records/fhir/summary'])
    S('records_hub_empty', 'Health records · empty', '/records?state=empty', 'records', phase='resources', variant_of='records_hub', state='empty', hdr=H('Health records'), body=[
        illus('+'), title('No health records connected', 'l', align='center'),
        text('Bring in readings, labs and vaccinations from your clinic or Medicare, or type them in. Your programs work either way.', 'muted', align='center'),
        kv([('Epic MyChart', 'most US hospitals and clinics'), ('Medicare', 'Blue Button 2.0'), ('Other', 'any SMART on FHIR R4 server')]),
    ], footer=[button('Connect a health system', go('records_add')), button('Enter a value manually', go('records_manual'), v='secondary')])

    S('records_add', 'Add a source', '/records/add', 'records', phase='resources', hdr=H('Add a source'), body=[
        title('Where is your health information?'), text('You sign in with your provider. Tether never sees that password.', 'muted'),
        rows([row('Hospital or clinic', 'Epic MyChart · find yours', lead=L_icon('E'), action=go('records_search')),
              row('Oracle Health (Cerner)', 'Patient portal', lead=L_icon('O'), action=go('records_search')),
              row('Medicare · Blue Button 2.0', 'Claims, prescriptions, diagnoses', lead=L_icon('M'), action=go('records_consent_bb')),
              row('Apple Health Records', 'iPhone · records you already added to Health', lead=L_icon(''), action=go('records_consent_device')),
              row('Health Connect', 'Android · readings from your devices', lead=L_icon('H'), action=go('records_consent_device')),
              row('Other FHIR server', 'Enter the address your provider gave you', lead=L_icon('F'), action=go('records_fhir_url'))], title='Connect'),
        rows([row('Enter manually', 'Type a value from a paper report', lead=L_icon('+'), action=go('records_manual'))], title='Or'),
        text('Uses SMART on FHIR R4 with OAuth 2.0 + PKCE in your phone’s browser.', 'small'),
    ])
    S('records_search', 'Find your provider', '/records/search', 'records', phase='resources', hdr=H('Find your provider'), body=[
        field('Search', 'Patel', placeholder='Search hospital, clinic or doctor', kind='search', key='query'),
        rows([row('Patel Family Medicine', 'Epic · San Jose, CA', lead=L_icon('E'), action=go('records_consent')),
              row('Patel Heart Institute', 'Epic · Fremont, CA', lead=L_icon('E'), action=go('records_consent')),
              row('Stanford Health Care', 'Epic · Palo Alto, CA', lead=L_icon('E'), action=go('records_consent'))], title='Results'),
        link('Can’t find it? Enter a FHIR address', go('records_fhir_url')),
    ], api=['GET /v1/records/fhir/directory?q='], desc='Directory built from Epic’s published patient-facing FHIR endpoints plus partner registries.')
    S('records_fhir_url', 'Other FHIR server', '/records/fhir-url', 'records', phase='resources', hdr=H('Other FHIR server'), body=[
        title('Enter your provider’s FHIR address'), field('FHIR server address', 'https://fhir.example-health.org/r4', kind='text', key='base_url', hint='Starts with https:// · your provider gives you this'),
        text('We check it supports SMART on FHIR R4 (/.well-known/smart-configuration) before you sign in.', 'small'),
    ], footer=[button('Check and continue', branch('Server check', [('SMART on FHIR R4 supported', go('records_consent')), ('Not a FHIR R4 server', go('records_error'))]))],
       api=['GET {base}/.well-known/smart-configuration', 'GET {base}/metadata'])

    consent_body = lambda name, src: [
        title(f'Connect {name}?'),
        kv([('Source', src), ('Access', 'Read-only'), ('Refresh', 'Daily while connected'), ('Stop', 'Disconnect anytime')]),
        checklist([ci('Conditions', 'Condition', True), ci('Vital signs', 'Observation · blood pressure, weight', True), ci('Lab results', 'Observation · A1C, lipids, eGFR', True),
                   ci('Medications', 'MedicationRequest', True), ci('Immunizations', 'Immunization', True), ci('Smoking status', 'Observation · LOINC 72166-2', True), ci('Clinical notes', 'Not requested')], label='What Tether will read'),
        card(v='mint', title='Only the programs you joined get data', text='Heartwise ← blood pressure, lipids · Steady ← A1C, glucose · Renew ← eGFR · Checkup ← immunizations · BreatheFree ← smoking status. Ease and ScrollFree get nothing.'),
    ]
    S('records_consent', 'Consent: Epic', '/records/consent', 'records', phase='resources', hdr=H('Connect', pill='Read-only'), body=consent_body('Patel Family Medicine', 'Epic MyChart · SMART on FHIR R4'),
      footer=[button('Continue to MyChart', branch('MyChart sign-in result', [('Approved', go('records_importing')), ('Cancelled', toast('Connection cancelled. Nothing was imported.')), ('Denied or error', go('records_error'))])),
              button('Not now', back(), v='secondary')],
      api=['GET /v1/records/fhir/authorize (PKCE) → system browser', 'POST /v1/records/fhir/callback (code exchange on server)'],
      desc='Authorization code + PKCE in ASWebAuthenticationSession / Custom Tabs. The code is exchanged by records-service; refresh tokens are stored encrypted server-side, never on the phone.')
    S('records_consent_bb', 'Consent: Medicare', '/records/consent?source=medicare', 'records', phase='resources', variant_of='records_consent', state='Medicare', hdr=H('Connect', pill='Read-only'),
      body=consent_body('Medicare', 'CMS Blue Button 2.0 · FHIR R4 (claims)'),
      footer=[button('Continue to Medicare.gov', branch('Medicare sign-in result', [('Approved', go('records_importing')), ('Cancelled', toast('Connection cancelled. Nothing was imported.')), ('Denied or error', go('records_error'))])),
              button('Not now', back(), v='secondary')])
    S('records_consent_device', 'Consent: phone health data', '/records/consent?source=device', 'records', phase='resources', variant_of='records_consent', state='Apple Health / Health Connect', hdr=H('Connect', pill='Read-only'),
      body=[title('Use health data on this phone?'), text('iPhone: Apple Health Records (FHIR) and readings. Android: Health Connect readings. You choose each type in the system screen next.', 'muted'),
            checklist([ci('Blood pressure', None, True), ci('Blood glucose', None, True), ci('Clinical records (iPhone)', 'Labs, immunizations, conditions', True), ci('Steps and sleep', 'Not requested')], label='What Tether will ask for')],
      footer=[button('Continue', branch('System permission result', [('Allowed', go('records_importing')), ('Not allowed', go('records_error'))])), button('Not now', back(), v='secondary')],
      desc='HealthKit clinical records (HKClinicalType) on iOS; Health Connect permissions on Android. Data stays on the device until you review it.')

    S('records_importing', 'Importing', '/records/importing', 'records', phase='resources', state='loading', hdr=H('Importing', left='close'), body=[
        title('Importing your records…'), text('Usually under a minute. You can leave this screen.', 'muted'),
        card(checklist([ci('Conditions', '4 found', True), ci('Vital signs', '12 blood pressure readings', True), ci('Lab results', '9 results', True), ci('Immunizations', 'Checking…'), ci('Smoking status', 'Waiting')])),
        skeleton(2),
    ], footer=[button('Review imported data', rep('records_review')), link('Cancel import', popto('records_hub'))],
       api=['POST /v1/records/fhir/sources/:id/sync'])
    S('records_review', 'Review imported data', '/records/review', 'records', phase='resources', hdr=H('Review', left='close', pill='Not added yet'), body=[
        title('Review before adding'), text('Nothing reaches your programs until you confirm.', 'muted'),
        banner('offline', '2 items need your review.', go('records_conflict'), 'Review'),
        card(checklist([ci('12 blood pressure readings', 'Jun – Oct 2026', True), ci('Lipid panel', 'LDL 138 · Sep 30', True)]), tag='hw'),
        card(checklist([ci('A1C 7.6%', 'Oct 1 · differs from your entry (7.4%)')]), tag='st'),
        card(checklist([ci('Flu vaccine', 'Oct 12, 2025', True), ci('Tdap', '2019', True)]), tag='ck'),
        card(checklist([ci('Smoking status: every day smoker', 'Aug 2026 · sets your baseline', True)]), tag='bf'),
        card(checklist([ci('eGFR 58', 'Oct 3', True)]), tag='re'),
        eyebrow('Checked automatically'),
        kv([('Units converted', '2 glucose results · mmol/L → mg/dL'), ('Duplicates skipped', '3 readings you already entered'), ('Held as likely typo', '1 · BP 1290/80'), ('Future dates rejected', '0')]),
    ], footer=[button('Add 21 items to my programs', submit('POST /v1/records/fhir/accept', toast('Added to Heartwise, Steady, Checkup, BreatheFree and Renew', popto('records_hub')))),
               link('Review conflicts first', go('records_conflict'))],
       desc='Validation pipeline: FHIR R4 schema → code mapping (LOINC, SNOMED CT, CVX, RxNorm) → unit normalisation (UCUM) → plausibility ranges → duplicate detection (code + date + value) → conflict with manual entries → member review.')
    S('records_conflict', 'Resolve conflicts', '/records/conflicts', 'records', phase='resources', hdr=H('Needs review', pill='2 items'), body=[
        card(radio([ri('From Patel Family Medicine (Epic): 7.6%', 'Lab result · final · LOINC 4548-4'), ri('Entered by you: 7.4%', 'Oct 1, 2026'), ri('Keep both', 'Your clinician’s value is used in summaries')], 0, key='a1c'),
             eyebrow='A1C · Oct 1, 2026', title='Two values for the same test'),
        card(radio([ri('Discard', 'Likely a typo in the source'), ri('Keep as 129/80', 'Corrected by you, marked as edited'), ri('Ask my care team', 'Sends a question with the original value')], 1, key='bp'),
             eyebrow='Blood pressure · Aug 4, 2026', title='1290/80 is outside the possible range'),
    ], footer=[button('Save choices', submit('POST /v1/records/fhir/conflicts', toast('Saved', back())))])
    S('records_error', 'Connection problem', '/records/error', 'records', phase='resources', state='error', hdr=H('Connect'), body=[
        illus('!', 'error'), title('Couldn’t connect', 'l', align='center'),
        text('Sign-in was cancelled, denied, or the server isn’t a SMART on FHIR R4 server. Nothing was imported.', 'muted', align='center'),
    ], footer=[button('Try again', back()), button('Choose another source', rep('records_add'), v='secondary'), link('Enter manually instead', rep('records_manual'))])
    S('records_source', 'Source details', '/records/source', 'records', phase='resources', hdr=H('Patel Family Medicine'), body=[
        kv([('Connection', 'Epic MyChart · SMART on FHIR R4'), ('Last sync', 'Today 7:02 AM'), ('Next sync', 'Tomorrow'), ('Access', 'Read-only · 6 categories'), ('Connected', 'Oct 3, 2026')]),
        rows([row('Sync now', None, action=submit('POST /v1/records/fhir/sources/:id/sync', toast('Synced · 2 new results'))), row('What we read', None, action=go('records_consent'))]),
    ], footer=[button('Disconnect', sheet('records_disconnect'), v='danger')])
    S('records_disconnect', 'Disconnect source', '/records/source/disconnect', 'records', phase='resources', kind='sheet', over='Patel Family Medicine', body=[
        title('Disconnect Patel Family Medicine?'), text('Tether stops reading new records and revokes its access token.', 'muted'),
        radio([ri('Keep imported data', 'Marked “from Patel Family Medicine”'), ri('Delete data imported from this source', '21 items removed from your programs')], 0, key='keep'),
    ], footer=[button('Disconnect source', submit('DELETE /v1/records/fhir/sources/:id', toast('Disconnected', popto('records_hub'))), v='danger'), button('Cancel', close(), v='secondary')])

    S('records_manual', 'Enter a value', '/records/manual', 'records', phase='resources', hdr=H('Enter a value'), body=[
        title('Add a health value'), chips(['Blood pressure', 'Glucose', 'Lab result', 'Vaccine', 'Medication', 'Condition'], ['Lab result'], multi=False, key='type', label='Type'),
        field('Test', 'A1C', kind='select', key='test'), field('Value', '7.4', unit='%', kind='number', key='value'), field('Date', 'Oct 1, 2026', kind='date', key='date'),
        text('Checked against plausible ranges and your connected records. Manual values are labelled “Entered by you”.', 'small'),
    ], footer=[button('Save', submit('POST /v1/records/manual', branch('Validation', [('Valid', toast('Saved · shared with Steady', popto('records_hub'))), ('Outside expected range', rep('records_manual_error')), ('Matches an imported value', toast('Already in your records from Epic. Not added twice.', back()))], decide='rec.manual')))])
    S('records_manual_error', 'Enter a value · out of range', '/records/manual?state=error', 'records', phase='resources', variant_of='records_manual', state='error', hdr=H('Enter a value'), body=[
        title('Add a health value'), field('Test', 'A1C', kind='select', key='test'),
        field('Value', '74', unit='%', kind='number', key='value', error='A1C is usually between 4% and 15%. Did you mean 7.4?'), field('Date', 'Oct 1, 2026', kind='date', key='date'),
    ], footer=[button('Save', submit('POST /v1/records/manual', branch('Validation', [('Valid', toast('Saved · shared with Steady', popto('records_hub'))), ('Outside expected range', toast('Still outside the expected range'))], decide='rec.manual'))),
               link('Ask my care team instead', go('support_message_care'))])
    S('records_item', 'Imported values', '/records/item', 'records', phase='resources', hdr=H('Blood pressure', pill='12 + 36'), body=[
        line([142, 140, 138, 139, 135, 133, 136, 131, 129, 130, 128, 127], 'hw', title='Systolic · all sources', unit='mmHg'),
        rows([row('128/82 · Oct 15', 'Patel Family Medicine (Epic) · clinic reading'), row('135/85 · Oct 14', 'Entered by you · home monitor'), row('131/80 · Oct 2', 'Patel Family Medicine (Epic)')], title='Latest'),
        kv([('Coded as', 'LOINC 85354-9 (8480-6 / 8462-4)'), ('Used by', 'Heartwise')]),
    ], footer=[button('Open in Heartwise', go('hw_trends'), v='secondary')])

    entry('records_hub', 'Account → Health records')
