-- Migration: 20260912170000_populate_stops_english_localization.sql
-- Description: Populate name_en and locality_en for all 34 existing route stops in public.stops

DO $$
BEGIN
  -- 1. Create temporary mapping table with English translations
  CREATE TEMP TABLE temp_stops_en (
    name_ar text,
    locality_ar text,
    name_en text,
    locality_en text
  ) ON COMMIT DROP;

  INSERT INTO temp_stops_en (name_ar, locality_ar, name_en, locality_en) VALUES
    -- ZONE 30 (1-5)
    ('كوبرى عزت',       'ميت فضالة',        'Ezzat Bridge',              'Mit Fadala'),
    ('كوبرى الزغبي',     'ميت أبو الحسين',    'El Zoghbi Bridge',          'Mit Abu El Hussein'),
    ('البريد',          'ميت أبو الحسين',    'Post Office',               'Mit Abu El Hussein'),
    ('البنزينة',        'ميت أبو الحسين',    'Gas Station',               'Mit Abu El Hussein'),
    ('صيدلية حسونة',    'أبو داوود العنب',   'Hassouna Pharmacy',         'Abu Dawood El Enab'),

    -- ZONE 25 (6-17)
    ('القنطرة البيضة',    'ميت العامل',       'El Qantara El Baida',       'Mit El Amel'),
    ('الكوخ الخشب',     'ميت العامل',       'Wooden Cottage',            'Mit El Amel'),
    ('مسجد النور',       'ميت العامل',       'Al Nour Mosque',            'Mit El Amel'),
    ('منشار الجوهرى',    'ميت العامل',       'El Gawhary Sawmill',        'Mit El Amel'),
    ('قصر حنان حسني',    'ميت العامل',       'Hanan Hosny Palace',        'Mit El Amel'),
    ('ماركت قزامل',      'ميت العامل',       'Qazamel Market',            'Mit El Amel'),
    ('كوبرى السوق',     'ميت العامل',       'Souq Bridge',               'Mit El Amel'),
    ('قاعة اللؤلؤة',     'ميت العامل',       'El Lolowa Hall',            'Mit El Amel'),
    ('الوحدة الصحية',    'ميت العامل',       'Health Unit',               'Mit El Amel'),
    ('جيم الجوكر',      'ميت العامل',       'Joker Gym',                 'Mit El Amel'),
    ('المدخل الرئيسي',   'سنجيد',           'Main Entrance',             'Sangid'),
    ('معرض السيراميك',   'سنجيد',           'Ceramics Showroom',         'Sangid'),

    -- ZONE 20 (18-34)
    ('ماركت المراعي',    'برج النور الحمص',  'Al Marai Market',           'Borg El Nour El Hommos'),
    ('شركة الحرمين',    'برج النور الحمص',  'El Haramein Company',       'Borg El Nour El Hommos'),
    ('كوبرى الملعب',     'البهو فريك',       'Stadium Bridge',            'El Baho Fereek'),
    ('المدخل الرئيسي',   'البهو فريك',       'Main Entrance',             'El Baho Fereek'),
    ('مصنع الرخام',     'البهو فريك',       'Marble Factory',            'El Baho Fereek'),
    ('اليافطة',          'شبرا البهو',       'The Billboard',             'Shubra El Baho'),
    ('المرشح',          'شبرا البهو',       'Water Plant',               'Shubra El Baho'),
    ('المدرسة',         'شبرا البهو',       'The School',                'Shubra El Baho'),
    ('المدخل الرئيسي',   'قرموط البهو',      'Main Entrance',             'Qarmout El Baho'),
    ('المدخل الرئيسي',   'السبخا',          'Main Entrance',             'El Sabkha'),
    -- Mansoura standalone city landmarks (empty locality in Arabic preserves empty in English)
    ('سندوب',           '',                'Sandoub',                   ''),
    ('جامعة السلاب',     '',                'Al Sallab University',      ''),
    ('احمد ماهر',        '',                'Ahmed Maher',               ''),
    ('جيهان',           '',                'Gehan',                     ''),
    ('الصينية',         '',                'The Roundabout',            ''),
    ('بوابة حاسبات',     '',                'Faculty of Computers Gate', ''),
    ('بوابة توشكى',      '',                'Toshka Gate',               '');

  -- 2. Update existing stops matching (name_ar, locality_ar)
  UPDATE public.stops s
  SET
    name_en = t.name_en,
    locality_en = t.locality_en,
    updated_at = now()
  FROM temp_stops_en t
  WHERE s.name_ar = t.name_ar
    AND (s.locality_ar = t.locality_ar OR (s.locality_ar = '' AND t.locality_ar = ''));

END $$;
