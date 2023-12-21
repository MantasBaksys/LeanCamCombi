/-
Copyright (c) 2023 Mantas Bakšys, Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mantas Bakšys, Yaël Dillies
-/
import Mathlib.Combinatorics.Additive.ETransform
import LeanCamCombi.Mathlib.Algebra.Order.Ring.Canonical
import LeanCamCombi.Mathlib.Data.Finset.Basic
import LeanCamCombi.Mathlib.Data.Finset.Card
import LeanCamCombi.Kneser.MulStab

/-!
# Kneser's addition lemma

This file proves Kneser's lemma. This states that `|s + H| + |t + H| - |H| ≤ |s + t|` where `s`,
`t` are finite nonempty sets in a commutative group and `H` is the stabilizer of `s + t`. Further,
if the inequality is strict, then we in fact have `|s + H| + |t + H| ≤ |s + t|`.

## Main declarations

* `finset.mul_kneser`: Kneser's lemma.
* `finset.mul_strict_kneser`: Strict Kneser lemma.

## References

* [Imre Ruzsa, *Sumsets and structure*][ruzsa2009]
* Matt DeVos, *A short proof of Kneser's addition lemma*
-/

open Function MulAction Subgroup

open scoped Classical Pointwise

variable {α : Type*} [CommGroup α] [DecidableEq α] {s t : Finset α}

namespace Finset

/-! ### Auxiliary results -/


-- Lemma 3.3 in Ruzsa's notes
@[to_additive]
lemma le_card_union_add_card_mulStab_union :
    min (s.card + s.mulStab.card) (t.card + t.mulStab.card) ≤ (s ∪ t).card + (s ∪ t).mulStab.card := by
  obtain rfl | hs := s.eq_empty_or_nonempty
  · simp [-zero_le']
  -- TODO: `to_additive` chokes on `zero_le'`
  obtain rfl | ht := t.eq_empty_or_nonempty
  · simp [-zero_le']
  set Hs := s.mulStab with hHs
  set Ht := t.mulStab with hHt
  set H := Hs * Ht with hH
  have hHs : Hs.Nonempty := hs.mulStab
  have hHt : Ht.Nonempty := ht.mulStab
  have hH : H.Nonempty := hHs.mul hHt
  wlog h1: Hs ∩ Ht = 1
  · set N := stabilizer α s ⊓ stabilizer α t with hN
    have hNmulstab : (N : Set α) = ↑(Hs ∩ Ht) := by aesop
    replace h1 : mulStab (image (QuotientGroup.mk (s := N)) s) ∩
      mulStab (image QuotientGroup.mk t) = 1 := by
      ext x
      constructor
      · simp only [Nonempty.image_iff, mem_one, and_imp, ← QuotientGroup.mk_one]
        intro hx
        rw [←  mul_stab_quotient_commute_subgroup N s,
            ← mul_stab_quotient_commute_subgroup N t] at hx
        simp only [mem_inter, mem_image] at hx
        obtain ⟨⟨y, hy, hyx⟩, ⟨z, hz, hzx⟩⟩ := hx
        obtain ⟨w, hwx⟩ := Quotient.exists_rep x
        have : ⟦w⟧ = QuotientGroup.mk (s := N) w := by exact rfl
        rw [← hwx, this, QuotientGroup.eq] at hyx hzx ⊢
        simp only [mul_one, ge_iff_le, inv_mem_iff, mem_inf, mem_stabilizer_iff] at hyx hzx ⊢
        constructor
        · convert hyx.1 using 1
          rw [mul_comm, mul_smul]
          congr
          simp only [← inv_smul_eq_iff, inv_inv, ← (mem_mulStab hs), hy]
        · convert hzx.2 using 1
          rw [mul_comm, mul_smul]
          congr
          simp only [← inv_smul_eq_iff, inv_inv, ← (mem_mulStab ht), hz]
        all_goals { aesop }
      · aesop
    specialize this (α := α ⧸ N) (s := s.image (↑)) (t := t.image (↑))
    simp only [Nonempty.image_iff, mulStab_nonempty, mul_nonempty, ge_iff_le, and_imp,
      forall_true_left, hs, ht, h1] at this
    calc
    min (card s + card Hs) (card t + card Ht) =
      min (Nat.card N * card (s.image (QuotientGroup.mk (s := N))) +
      Nat.card N * card (Hs.image (QuotientGroup.mk (s := N))))
      (Nat.card N * card (t.image (QuotientGroup.mk (s := N))) +
      Nat.card N * card (Ht.image (QuotientGroup.mk (s := N)))) := by
        rw [← subgroup_mul_card_eq_mul_of_mul_stab_subset N s,
        ← subgroup_mul_card_eq_mul_of_mul_stab_subset N t,
        ← subgroup_mul_card_eq_mul_of_mul_stab_subset N Hs,
        ← subgroup_mul_card_eq_mul_of_mul_stab_subset N Ht]
        all_goals { aesop }
    _ = Nat.card N * min (card (s.image (QuotientGroup.mk (s := N))) +
      card (Hs.image (QuotientGroup.mk (s := N)))) (card (t.image (QuotientGroup.mk (s := N))) +
      card (Ht.image (QuotientGroup.mk (s := N)))) := by
        rw [← mul_add, ← mul_add, Nat.mul_min_mul_left]
    _ = Nat.card N * min (card (image (QuotientGroup.mk (s := N)) s) +
      card (mulStab (image (QuotientGroup.mk (s := N)) s)))
      (card (image (QuotientGroup.mk (s := N)) t) +
      card (mulStab (image (QuotientGroup.mk (s := N)) t))) := by
        rw [mul_stab_quotient_commute_subgroup N t, mul_stab_quotient_commute_subgroup N s]
        all_goals { aesop }
    _ ≤ Nat.card N * (card (image (QuotientGroup.mk (s := N)) s ∪
      image (QuotientGroup.mk (s := N)) t) +
      card (mulStab (image (QuotientGroup.mk (s := N)) s ∪
      image (QuotientGroup.mk (s := N)) t))) := Nat.mul_le_mul_left _ this
    _ ≤ card (s ∪ t) + card (mulStab (s ∪ t)) := by
      rw [mul_add, ← image_union, subgroup_mul_card_eq_mul_of_mul_stab_subset N (s ∪ t),
          ← mul_stab_quotient_commute_subgroup N (s ∪ t),
          subgroup_mul_card_eq_mul_of_mul_stab_subset N (mulStab (s ∪ t))]
      all_goals
      { simp only [hNmulstab, mulStab_idem]; norm_cast; exact inter_mulStab_subset_mulStab_union }
  obtain hst | hst := (subset_union_left s t).eq_or_ssubset
  · simp [hst.symm]
  obtain hts | hts := (subset_union_right s t).eq_or_ssubset
  · simp [hts.symm]
  have : H.card = Hs.card * Ht.card := by
    refine' card_mul_iff.2 fun a ha b hb hab => _
    replace hab : a.2 * b.2⁻¹ = a.1⁻¹ * b.1 := by
      rw [mul_inv_eq_iff_eq_mul, mul_assoc, ← inv_mul_eq_iff_eq_mul, inv_inv]
      exact hab
    have : a.1⁻¹ * b.1 ∈ Hs ∩ Ht := by
      simp only [mem_inter]
      constructor
      · rw [mem_mulStab hs, mul_smul, inv_smul_eq_iff,
          (mem_mulStab hs).mp (show b.1 ∈ mulStab s by aesop),
          (mem_mulStab hs).mp (show a.1 ∈ mulStab s by aesop)]
      · rw [← hab, mem_mulStab ht, mul_comm, mul_smul, inv_smul_eq_iff,
          (mem_mulStab ht).mp (show b.2 ∈ mulStab t by aesop),
          (mem_mulStab ht).mp (show a.2 ∈ mulStab t by aesop)]
    simp only [h1, mem_one] at this
    ext
    · rw [← inv_mul_eq_one, this]
    · rw [← mul_inv_eq_one, hab, this]
  -- mistake in proof sketch, need to interchange `Hs` and `Ht`
  suffices h2 : Hs.card - (mulStab (s ∪ t)).card ≤ (s \ t).card ∨
                Ht.card - (mulStab (s ∪ t)).card ≤ (t \ s).card
  · simp only [ge_iff_le, min_le_iff]
    cases' h2 with h2 h2
    · left
      sorry
    · right
      sorry
  have Hst : (mulStab (s ∪ t)).Nonempty := Nonempty.mulStab (Nonempty.inr ht)
  set k : α → ℕ := fun a =>
    card ((a • H).image (QuotientGroup.mk (s := stabilizer α s)) ∩ s.image QuotientGroup.mk)
  set l : α → ℕ := fun a =>
   card ((a • H).image (QuotientGroup.mk (s := stabilizer α t)) ∩ t.image QuotientGroup.mk)
  have hkt : ∀ a, k a ≤ Ht.card := sorry
  have hls : ∀ a, l a ≤ Hs.card := sorry
  have hk : ∀ a, (s \ t ∩ a • H).card = k a * (Hs.card - l a) := by sorry
  have hl : ∀ a, (t \ s ∩ a • H).card = l a * (Ht.card - k a) := by sorry
  by_cases hkl :
    (∀ a, k a = 0 ∨ k a = Ht.card ∨ l a = 0 ∨ l a = Hs.card) ∧
      ((∀ a, k a = 0 → l a = 0) ∨ ∀ a, l a = 0 → k a = 0)
  · obtain ⟨hkl, hkl' | hkl'⟩ := hkl
    · refine' Or.inl ((tsub_eq_zero_of_le <| card_mono _).trans_le <| zero_le _)
      sorry
    · refine' Or.inr ((tsub_eq_zero_of_le <| card_mono _).trans_le <| zero_le _)
      sorry
  -- the remaining sketch is flawed since `H` is defined to be `Hbar` in Ruzsa's notes and
  -- `mulStab (s ∪ t) = H` in the notes
  suffices hHst : (Hs.card - 1) * (Ht.card - 1) ≤ (s \ t).card * (t \ s).card
  · by_contra!
    exact
      hHst.not_lt
        (mul_lt_mul_of_lt_of_lt'' (this.1.trans_le <| tsub_le_tsub_left (one_le_card.2 Hst) _) <|
          this.2.trans_le <| tsub_le_tsub_left (one_le_card.2 Hst) _)
  simp (config := {zeta := false}) only
    [not_and_or, not_or, Classical.not_forall, not_ne_iff, not_imp] at hkl
  obtain ⟨a, hka, hka', hla, hla'⟩ | ⟨⟨a, hka, hla⟩, b, hlb, hkb⟩ := hkl
  · refine'
      le_trans _
        (mul_le_mul' (card_mono <| inter_subset_left _ <| a • H) <|
          card_mono <| inter_subset_left _ <| a • H)
    rw [hk, hl, mul_comm (k a), mul_mul_mul_comm, mul_comm (k a)]
    refine'
      le_trans _
        (mul_le_mul' (Nat.add_sub_one_le_mul (tsub_pos_of_lt <| (hls _).lt_of_ne hla').ne' hla) <|
          Nat.add_sub_one_le_mul (tsub_pos_of_lt <| (hkt _).lt_of_ne hka').ne' hka)
    rw [tsub_add_cancel_of_le (hkt _), tsub_add_cancel_of_le (hls _)]
  refine'
    mul_le_mul' (tsub_le_self.trans <| le_trans _ <| card_mono <| inter_subset_left _ <| b • H)
      (tsub_le_self.trans <| le_trans _ <| card_mono <| inter_subset_left _ <| a • H)
  · rw [hk, hlb, tsub_zero]
    exact le_mul_of_one_le_left' (pos_iff_ne_zero.2 hkb)
  · rw [hl, hka, tsub_zero]
    exact le_mul_of_one_le_left' (pos_iff_ne_zero.2 hla)

-- Lemma 3.4 in Ruzsa's notes
@[to_additive]
lemma le_card_sup_add_card_mulStab_sup {ι : Type*} {s : Finset ι} {f : ι → Finset α}
    (hs : s.Nonempty) :
    (s.inf' hs fun i => (f i).card + (f i).mulStab.card) ≤
      (s.sup f).card + (s.sup f).mulStab.card := by
  induction' s using Finset.cons_induction with i s hi ih
  · cases not_nonempty_empty hs
  obtain rfl | hs := s.eq_empty_or_nonempty
  · simp
  simp only [hs, inf'_cons, sup_cons, sup_eq_union]
  exact (inf_le_inf_left _ <| ih hs).trans le_card_union_add_card_mulStab_union

/-! ### Kneser's lemma -/

@[to_additive]
lemma le_card_mul_add_card_mulStab_mul (hs : s.Nonempty) (ht : t.Nonempty) :
    s.card + t.card ≤ (s * t).card + (s * t).mulStab.card := by
  -- For every `b ∈ t`, consider sets `s_b, t_b` such that
  -- * `b ∈ s_b`
  -- * `s ⊆ s_b`
  -- * `s_b * t_b ⊆ s * t`
  -- * `|s_b| + |t_b| = |s| + |t|`
  -- Such sets exist because we can take `s_b = s, t_b = t`. So pick `s_b, t_b` such that `|t_b|` is
  -- minimal among such sets.
  have :
    ∀ b : t,
      ∃ n s' t',
        ↑b ∈ t' ∧ s ⊆ s' ∧ s' * t' ⊆ s * t ∧ s'.card + t'.card = s.card + t.card ∧ n = t'.card :=
    fun b => ⟨_, s, t, b.2, Subset.rfl, Subset.rfl, rfl, rfl⟩
  choose s' t' hbt' hs' hst' hstcard ht' using fun b => Nat.find_spec (this b)
  -- We have  `⋃ b ∈ t, s_b * t_b = s * t` because `s_b * t_b ⊆ s * t` and
  -- `∀ b ∈ t, s • b ⊆ s * t_b ⊆ s_b * t_b`.
  have : s * t = univ.sup fun b => s' b * t' b := by
    refine' le_antisymm _ (Finset.sup_le_iff.2 fun _ _ => hst' _)
    exact
      mul_subset_iff_right.2 fun b hb =>
        (smul_finset_subset_smul_finset <| hs' ⟨b, hb⟩).trans <|
          (op_smul_finset_subset_mul <| hbt' ⟨b, hb⟩).trans <|
            @le_sup _ _ _ _ _ (fun b => s' b * t' b) _ <| mem_univ _
  rw [this]
  refine' (le_inf' ht.attach _ fun b _ => _).trans (le_card_sup_add_card_mulStab_sup _)
  rw [← hstcard b]
  refine'
    add_le_add (card_le_card_mul_right _ ⟨_, hbt' _⟩)
      ((card_mono <| subset_mulStab_mul_left ⟨_, hbt' _⟩).trans' _)
  rw [← card_smul_finset (b : α)⁻¹ (t' _)]
  refine' card_mono ((mul_subset_left_iff <| hs.mono <| hs' _).1 _)
  refine' mul_subset_iff_left.2 fun c hc => _
  rw [← mul_smul]
  refine'
    smul_finset_subset_iff.2
      (inter_eq_left.1 <| eq_of_subset_of_card_le (inter_subset_left _ _) _)
  rw [← ht']
  refine'
    Nat.find_min' _
      ⟨_, _, mem_inter.2 ⟨hbt' _, _⟩, (hs' _).trans <| subset_union_left _ _,
        (mulDysonETransform.subset _ (s' b, t' b)).trans <| hst' _,
        (mulDysonETransform.card _ _).trans <| hstcard _, rfl⟩
  rwa [mem_inv_smul_finset_iff, smul_eq_mul, inv_mul_cancel_right]

/-- **Kneser's multiplication lemma**: A lower bound on the size of `s * t` in terms of its
stabilizer. -/
@[to_additive
      "**Kneser's addition lemma**: A lower bound on the size of `s + t` in terms of its\nstabilizer."]
lemma mul_kneser' (s t : Finset α) :
    (s * (s * t).mulStab).card + (t * (s * t).mulStab).card ≤
      (s * t).card + (s * t).mulStab.card := by
  -- The cases `s = ∅` and `t = ∅` are easily taken care of.
  obtain rfl | hs := s.eq_empty_or_nonempty
  · simp
  obtain rfl | ht := t.eq_empty_or_nonempty
  · simp
  refine'
    (le_card_mul_add_card_mulStab_mul (hs.mul (hs.mul ht).mulStab) <|
          ht.mul (hs.mul ht).mulStab).trans_eq
      _
  rw [mul_mulStab_mul_mul_mul_mulStab_mul]

/-- The strict version of **Kneser's multiplication lemma**. If the LHS of `finset.mul_kneser`
does not equal the RHS, then it is in fact much smaller. -/
@[to_additive
      "The strict version of **Kneser's addition lemma**. If the LHS of\n`finset.add_kneser` does not equal the RHS, then it is in fact much smaller."]
lemma mul_strict_kneser'
    (h :
      (s * (s * t).mulStab).card + (t * (s * t).mulStab).card <
        (s * t).card + (s * t).mulStab.card) :
    (s * (s * t).mulStab).card + (t * (s * t).mulStab).card ≤ (s * t).card :=
  Nat.le_of_lt_add_of_dvd h
      ((card_mulStab_dvd_card_mul_mulStab _ _).add <| card_mulStab_dvd_card_mul_mulStab _ _) <|
    card_mulStab_dvd_card _

end Finset
