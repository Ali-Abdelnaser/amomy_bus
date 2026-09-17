-- Migration: 20260913070000_seed_instapay_payment_method.sql
-- Description: Seed InstaPay payment method and configure active payment methods

INSERT INTO public.payment_methods (code, name_ar, name_en, account_identifier, instructions_ar, instructions_en, icon_key, is_active, sort_order)
VALUES
  (
    'INSTAPAY',
    'إنستاباي',
    'InstaPay',
    '01014045363',
    'قم بالتحويل عبر تطبيق إنستاباي إلى رقم الهاتف أو الحساب أعلاه. بعد إتمام التحويل، احتفظ برقم العملية والتقط صورة لإيصال التحويل لإرفاقها.',
    'Transfer via the InstaPay app to the phone number or username above. After completing the transfer, keep the reference number and take a screenshot of the receipt to attach.',
    'instapay',
    true,
    2
  )
ON CONFLICT (code) DO UPDATE SET
  name_ar = EXCLUDED.name_ar,
  name_en = EXCLUDED.name_en,
  account_identifier = EXCLUDED.account_identifier,
  instructions_ar = EXCLUDED.instructions_ar,
  instructions_en = EXCLUDED.instructions_en,
  icon_key = EXCLUDED.icon_key,
  is_active = true,
  sort_order = EXCLUDED.sort_order;

UPDATE public.payment_methods SET sort_order = 1 WHERE code = 'VODAFONE_CASH';
UPDATE public.payment_methods SET is_active = false WHERE code = 'ORANGE_CASH';
