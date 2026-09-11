# 11 — Points Engine & Financial Architecture

## 1. Engine Fundamentals & Philosophy
Amomy Bus enforces a closed-loop **Internal Points Economy**. Passengers cannot pay directly in cash or by credit card at the bus door or per trip checkout. All trip bookings, seat reservations, and cancellations operate exclusively through points.

---

## 2. Point Types & Characteristics

| Dimension | Cash Points | Subscription Points |
| :--- | :--- | :--- |
| **Origin** | Manual recharge (Vodafone Cash, Orange Cash, Bank) | Monthly subscription tier purchase |
| **Verification** | Super Admin approves uploaded receipt | Automatic/Admin grant upon subscription cycle |
| **Expiration** | **Never expires** (`expires_at = NULL`) | **Strict expiration** (e.g. 30 days from cycle start) |
| **Spending Priority** | **Secondary** (Consumed only when subscription points are 0) | **Primary** (Must be consumed first) |
| **Refunds** | Credited as non-expiring cash points | Credited back with original or extended validity |

---

## 3. Financial Ground Truth vs. Cached Balance

```
   ┌──────────────────────────────────────────────────────────┐
   │             point_batches (Source of Truth)             │
   │  - Batch A: Subscription (remaining: 300, exp: 5 days)   │
   │  - Batch B: Cash         (remaining: 700, exp: NULL)     │
   └─────────────────────────────┬────────────────────────────┘
                                 │
                 Atomic PostgreSQL Functions Only
                                 │
                                 ▼
   ┌──────────────────────────────────────────────────────────┐
   │             wallets (Read-Optimized Cache)               │
   │  - cached_available_balance: 1000                        │
   │  - cached_held_balance:      0                           │
   └─────────────────────────────┬────────────────────────────┘
                                 │
                                 ▼
   ┌──────────────────────────────────────────────────────────┐
   │          point_transactions (Immutable Ledger)           │
   │  - Row 1: CREDIT  1000 (Subscription)                    │
   │  - Row 2: CREDIT   700 (Cash Top-up)                     │
   │  - Row 3: EXPIRE   300 (Batch A Remaining expired)       │
   └──────────────────────────────────────────────────────────┘
```

1. **`point_batches`**: Every credit operation creates a batch. When points are spent, batches are decremented.
2. **`wallets`**: Stores `cached_available_balance` and `cached_held_balance` for lightning-fast reads by the Flutter client. Never modified directly by client queries.
3. **`point_transactions`**: Append-only double-entry audit ledger recording every point delta (`credit`, `debit`, `hold`, `release`, `expire`, `refund`, `manual_adjustment`).

---

## 4. Spending Priority Algorithm
When a booking requires $N$ points, the spending algorithm executes in the following deterministic sequence:

1. **Priority 1: Active, Unexpired Subscription Point Batches**
   - Ordered by **Earliest Expiry First** (`ORDER BY expires_at ASC`).
   - Ensures the passenger uses points that would expire soonest.
2. **Priority 2: Cash Point Batches**
   - Ordered by **Oldest Batch First** (`ORDER BY created_at ASC`, FIFO).
3. **Multi-Batch Deduction**:
   - If a single batch has insufficient remaining balance, the function consumes the entire batch remainder and draws the difference from the next batch in line.
   - A distinct `debit` ledger transaction is created for each batch affected, referencing the booking ID.

---

## 5. Expiration Engine (`expire_point_batches`)
- Subscription points expire automatically when `now() >= expires_at`.
- The database function `expire_point_batches()` runs server-side hourly via `pg_cron` (`0 * * * *`).
- **Hold-Safe Idempotency**:
  - Point batches may have active holds on them during the expiration run.
  - The function joins `point_hold_allocations` on active, unexpired `point_holds` to determine `v_held_amount`.
  - It only expires unreserved points: `v_expirable = GREATEST(0, remaining_amount - held_amount)`.
  - Points reserved in active seat holds are completely protected from premature cancellation.
- **Transactional Steps**:
  1. Uses `FOR UPDATE SKIP LOCKED` on expired batches where `remaining_amount > 0`.
  2. Deducts `v_expirable` from `wallets.cached_available_balance`.
  3. Writes an `expire` transaction to `point_transactions`.
  4. Deducts `v_expirable` from `point_batches.remaining_amount`.
  5. If batch balance reaches zero, marks related `subscriptions.status = 'expired'`.

---

## 6. Seat Hold & Point Hold Allocations (`point_hold_allocations`)
During seat selection:
1. Passenger selects a seat -> triggers a 5-minute atomic hold.
2. `point_holds` row is inserted for the required points with `expires_at = now() + interval '5 minutes'`.
3. To prepare for split payment (e.g. 30 Subscription Points + 10 Cash Points), `point_hold_allocations` rows are inserted:
   - Tuple: `(hold_id, batch_id, amount)`.
   - Explicitly records which batches are reserved.
4. `wallets.cached_held_balance` is incremented by the total hold amount, reducing effective available balance.
5. If booking is confirmed within 5 minutes:
   - Hold status transitions to `consumed`.
   - The allocated batches are debited by their allocated amounts.
   - Corresponding `debit` transactions are recorded in `point_transactions`.
   - `cached_held_balance` is decremented.
6. If hold expires without confirmation:
   - Hold status transitions to `released`.
   - `cached_held_balance` is decremented, restoring the passenger's available balance.
   - Allocated points return to full unheld status immediately.
   - The seat transitions back to `available`.

---

## 7. Specification: Future `spend_points_for_booking` Stored Procedure

```sql
-- Architectural Blueprint for Booking Phase
CREATE OR REPLACE FUNCTION public.spend_points_for_booking(
  p_booking_id uuid,
  p_user_id uuid,
  p_required_points numeric
)
RETURNS jsonb AS $$
DECLARE
  v_wallet RECORD;
  v_remaining_to_deduct numeric := p_required_points;
  v_batch RECORD;
  v_deduct_amount numeric;
  v_balance_before numeric;
  v_balance_after numeric;
BEGIN
  -- 1. Lock user wallet
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF v_wallet.cached_available_balance < p_required_points THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS';
  END IF;

  v_balance_before := v_wallet.cached_available_balance;
  v_balance_after := v_balance_before - p_required_points;

  -- 2. Consume from active Subscription Batches (earliest expiry first)
  FOR v_batch IN
    SELECT *
    FROM public.point_batches
    WHERE user_id = p_user_id
      AND source_type = 'subscription'
      AND (expires_at IS NULL OR expires_at > now())
      AND remaining_amount > 0
    ORDER BY expires_at ASC
    FOR UPDATE
  LOOP
    EXIT WHEN v_remaining_to_deduct <= 0;
    v_deduct_amount := LEAST(v_batch.remaining_amount, v_remaining_to_deduct);

    UPDATE public.point_batches
    SET remaining_amount = remaining_amount - v_deduct_amount
    WHERE id = v_batch.id;

    INSERT INTO public.point_transactions (
      user_id, wallet_id, batch_id, transaction_type, amount,
      reference_type, reference_id, description
    ) VALUES (
      p_user_id, v_wallet.id, v_batch.id, 'debit', v_deduct_amount,
      'bookings', p_booking_id, 'Trip booking seat payment (Subscription)'
    );

    v_remaining_to_deduct := v_remaining_to_deduct - v_deduct_amount;
  END LOOP;

  -- 3. Consume remaining needed points from Cash Batches (FIFO)
  IF v_remaining_to_deduct > 0 THEN
    FOR v_batch IN
      SELECT *
      FROM public.point_batches
      WHERE user_id = p_user_id
        AND source_type IN ('cash', 'manual_adjustment', 'refund', 'promo')
        AND remaining_amount > 0
      ORDER BY created_at ASC
      FOR UPDATE
    LOOP
      EXIT WHEN v_remaining_to_deduct <= 0;
      v_deduct_amount := LEAST(v_batch.remaining_amount, v_remaining_to_deduct);

      UPDATE public.point_batches
      SET remaining_amount = remaining_amount - v_deduct_amount
      WHERE id = v_batch.id;

      INSERT INTO public.point_transactions (
        user_id, wallet_id, batch_id, transaction_type, amount,
        reference_type, reference_id, description
      ) VALUES (
        p_user_id, v_wallet.id, v_batch.id, 'debit', v_deduct_amount,
        'bookings', p_booking_id, 'Trip booking seat payment (Cash)'
      );

      v_remaining_to_deduct := v_remaining_to_deduct - v_deduct_amount;
    END LOOP;
  END IF;

  -- 4. Update cached wallet balance
  UPDATE public.wallets
  SET cached_available_balance = v_balance_after,
      updated_at = now()
  WHERE id = v_wallet.id;

  RETURN jsonb_build_object('success', true, 'new_balance', v_balance_after);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```
