/-
Copyright (c) 2022 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies
-/
import Mathlib.Combinatorics.SetFamily.Shatter

/-!
# Shattering families

This file defines the shattering property and VC-dimension of set families.

## Main declarations

* `Finset.StronglyShatters`:
* `Finset.OrderShatters`:

## TODO

* Order-shattering
* Strong shattering
-/

open scoped BigOperators FinsetFamily

namespace Finset
variable {α : Type*} [DecidableEq α] {𝒜 ℬ : Finset (Finset α)} {s t : Finset α} {a : α} {n : ℕ}

/-! ### Strong shattering -/

def StronglyShatters (𝒜 : Finset (Finset α)) (s : Finset α) : Prop :=
  ∃ t, ∀ ⦃u⦄, u ⊆ s → ∃ v ∈ 𝒜, s ∩ v = u ∧ v \ s = t

/-! ### Order shattering -/

section order
variable [LinearOrder α]

def OrderShatters : Finset (Finset α) → List α → Prop
  | 𝒜, [] => 𝒜.Nonempty
  | 𝒜, a :: l => (𝒜.nonMemberSubfamily a).OrderShatters l ∧ (𝒜.memberSubfamily a).OrderShatters l
      ∧ ∀ ⦃s : Finset α⦄, s ∈ 𝒜.nonMemberSubfamily a → ∀ ⦃t⦄, t ∈ 𝒜.memberSubfamily a →
        s.filter (a < ·) = t.filter (a < ·)

instance : DecidablePred 𝒜.OrderShatters
  | [] => decidableNonempty
  | a :: l => by unfold OrderShatters; sorry

def orderShatterser (𝒜 : Finset (Finset α)) : Finset (Finset α) :=
  (𝒜.biUnion powerset).filter $ fun s ↦ 𝒜.OrderShatters $ s.sort (· ≤ ·)

end order

end Finset
