-- Dompetektif · global system categories
--
-- These ids intentionally match lib/domain/services/receipt_parser.dart so
-- local demo data and cloud data resolve to the same category names. Names are
-- canonical English labels; the client localizes system ids for display.

insert into public.categories (
  id, owner_id, name, kind, icon_key, color_hex, keywords, is_system,
  created_at, updated_at
)
values
  (
    '10000000-0000-4000-8000-000000000001', null, 'Food & Drinks', 'expense',
    'restaurant', '#E8B84B',
    array['makan','minum','kopi','cafe','resto','restoran','warung','bakery',
          'indomaret','alfamart','supermarket','grocery','food','drink',
          'coffee','kfc','mcd','starbucks','gofood','grabfood'],
    true, now(), now()
  ),
  (
    '10000000-0000-4000-8000-000000000002', null, 'Transport', 'expense',
    'transport', '#7FB6A4',
    array['gojek','grab','ojek','taksi','taxi','bensin','pertamina','spbu',
          'parkir','tol','transport','mrt','lrt','transjakarta','krl','tiket'],
    true, now(), now()
  ),
  (
    '10000000-0000-4000-8000-000000000003', null, 'Shopping', 'expense',
    'shopping', '#D98C6A',
    array['shopee','tokopedia','lazada','blibli','uniqlo','h&m','mall',
          'store','belanja','shopping','fashion','elektronik','electronics'],
    true, now(), now()
  ),
  (
    '10000000-0000-4000-8000-000000000004', null, 'Bills', 'expense',
    'receipt', '#8CA8C9',
    array['pln','listrik','token','air','pdam','internet','wifi','indihome',
          'telkomsel','xl','tri','pulsa','tagihan','bill','utilities','bpjs',
          'asuransi','insurance','sewa','rent'],
    true, now(), now()
  ),
  (
    '10000000-0000-4000-8000-000000000005', null, 'Health', 'expense',
    'health', '#D96C75',
    array['apotek','apotik','klinik','rumah sakit','hospital','dokter',
          'doctor','obat','medicine','gym','fitness','kesehatan','health'],
    true, now(), now()
  ),
  (
    '10000000-0000-4000-8000-000000000006', null, 'Entertainment', 'expense',
    'entertainment', '#B48CD9',
    array['netflix','spotify','disney','youtube','viu','bioskop','cinema',
          'konser','concert','game','steam','playstation','hiburan',
          'entertainment','liburan','travel','hotel'],
    true, now(), now()
  ),
  (
    '10000000-0000-4000-8000-000000000007', null, 'Salary', 'income',
    'salary', '#6FBF8F',
    array['gaji','salary','payroll','upah','bonus'],
    true, now(), now()
  ),
  (
    '10000000-0000-4000-8000-000000000008', null, 'Freelance', 'income',
    'briefcase', '#6FA7BF',
    array['freelance','proyek','project','klien','client','honor'],
    true, now(), now()
  ),
  (
    '10000000-0000-4000-8000-000000000009', null, 'Other', 'expense',
    'dots', '#9C9A8B',
    array['lainnya','other','misc','uncategorized'],
    true, now(), now()
  ),
  (
    '10000000-0000-4000-8000-000000000010', null, 'Other Income', 'income',
    'income', '#9C9A8B',
    array['pemasukan','income','lainnya','other'],
    true, now(), now()
  )
on conflict (id) do update
set name = excluded.name,
    kind = excluded.kind,
    icon_key = excluded.icon_key,
    color_hex = excluded.color_hex,
    keywords = excluded.keywords,
    is_system = true,
    owner_id = null,
    updated_at = now();
