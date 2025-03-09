/-
Copyright (c) 2024 Sina Hazratpour. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sina Hazratpour
-/

import Poly.ForMathlib.CategoryTheory.LocallyCartesianClosed.BeckChevalley -- LCCC.BeckChevalley
import Mathlib.CategoryTheory.Functor.TwoSquare


/-!
# Polynomial Functor

-- TODO: there are various `sorry`-carrying proofs in below which require instances of
`ExponentiableMorphism` for various constructions on morphisms. They need to be defined in
`Poly.Exponentiable`.
-/

noncomputable section

namespace CategoryTheory

open CategoryTheory Category Limits Functor Adjunction Over ExponentiableMorphism
  LocallyCartesianClosed

variable {C : Type*} [Category C] [HasPullbacks C]

/-- `P : UvPoly C` is a polynomial functors in a single variable -/
structure UvPoly (E B : C) where
  (p : E ⟶ B)
  (exp : ExponentiableMorphism p := by infer_instance)

attribute [instance] UvPoly.exp

namespace UvPoly

open TwoSquare

variable {C : Type*} [Category C] [HasTerminal C] [HasPullbacks C]

instance : HasBinaryProducts C :=
  hasBinaryProducts_of_hasTerminal_and_pullbacks C

variable {E B : C}

/-- The constant polynomial in many variables: for this we need the initial object -/
def const [HasInitial C] (S : C) : UvPoly (⊥_ C) S := ⟨initial.to S, sorry⟩

def smul [HasBinaryProducts C] (S : C) (P : UvPoly E B) : UvPoly (S ⨯ E) (S ⨯ B) :=
  ⟨prod.map (𝟙 S) P.p, sorry⟩

/-- The product of two polynomials in a single variable. -/
def prod {E' B'} (P : UvPoly E B) (Q : UvPoly E' B') [HasBinaryCoproducts C]:
    UvPoly ((E ⨯ B') ⨿ (B ⨯ E')) (B ⨯ B') where
  p := coprod.desc (prod.map P.p (𝟙 B')) (prod.map (𝟙 B) Q.p)
  exp := sorry -- perhaps we need extra assumptions on `C` to prove this, e.g. `C` is lextensive?

/-- For a category `C` with binary products, `P.functor : C ⥤ C` is the functor associated
to a single variable polynomial `P : UvPoly E B`. -/
def functor [HasBinaryProducts C] (P : UvPoly E B) : C ⥤ C :=
  Over.star E ⋙ pushforward P.p ⋙ forget B

/-- The evaluation function of a polynomial `P` at an object `X`. -/
def apply (P : UvPoly E B) : C → C := (P.functor).obj

@[inherit_doc]
infix:90 " @ " => UvPoly.apply

/-- The fstProjection morphism from `∑ b : B, X ^ (E b)` to `B` again. -/
def fstProj (P : UvPoly E B) (X : C) : P @ X ⟶ B :=
  ((Over.star E ⋙ pushforward P.p).obj X).hom

@[simp, reassoc (attr := simp)]
lemma map_fstProj {X Y : C} (P : UvPoly E B) (f : X ⟶ Y) :
    P.functor.map f ≫ P.fstProj Y = P.fstProj X := by
  simp [fstProj, functor]

/-- The natural transformation `Q.functor ⟶ P.functor ` induced by a triangle `ρ : P.p ⟶ Q.p`
is obtained by pasting the following 2-cells
```
              Q.p
C --- >  C/F ----> C/B -----> C
|         |          |        |
|   ↙     | ρ*  ≅    |   =    |
|         v          v        |
C --- >  C/E ---->  C/B ----> C
              P.p
```
-/
def verticalNatTrans {F : C} (P : UvPoly E B) (Q : UvPoly F B) (ρ : E ⟶ F) (h : P.p = ρ ≫ Q.p) :
    Q.functor ⟶ P.functor := by
  unfold functor
  have sq : CommSq ρ P.p Q.p (𝟙 _) := by simp [h]
  let cellLeft := (Over.starPullbackIsoStar ρ).hom
  let cellMid := (pushforwardBeckChevalleySquare ρ P.p Q.p (𝟙 _) sq)
  let cellLeftMidPasted := TwoSquare.whiskerRight (cellLeft ≫ₕ cellMid) (Over.pullbackId).inv
  simpa using (cellLeftMidPasted ≫ₕ (vId (forget B)))

variable (B)

/-- The identity polynomial functor in single variable. -/
@[simps!]
def id : UvPoly B B := ⟨𝟙 B, by infer_instance⟩

/-- Evaluating the identity polynomial at an object `X` is isomorphic to `B × X`. -/
def id_apply (X : C) : (id B) @ X ≅ B ⨯ X where
  hom := 𝟙 (B ⨯ X)
  inv := 𝟙 (B ⨯ X)

variable {B}

/-- A morphism from a polynomial `P` to a polynomial `Q` is a pair of morphisms `e : E ⟶ E'`
and `b : B ⟶ B'` such that the diagram
```
      E -- P.p ->  B
      ^            |
   ρ  |            |
      |     ψ      |
      Pb --------> B
      |            |
   φ  |            | δ
      v            v
      F -- Q.p ->  D
```
is a pullback square. -/
structure Hom {F D : C} (P : UvPoly E B) (Q : UvPoly F D) where
  Pb : C
  δ : B ⟶ D
  φ : Pb ⟶ F
  ψ : Pb ⟶ B
  ρ : Pb ⟶ E
  is_pb : IsPullback ψ φ δ Q.p
  w : ρ ≫ P.p = ψ

namespace Hom

open IsPullback

/-- The identity morphism in the category of polynomials. -/
def id (P : UvPoly E B) : Hom P P := ⟨E, 𝟙 B, 𝟙 _ , P.p , 𝟙 _, IsPullback.of_id_snd, by simp⟩

-- def vertCartExchange

/-- The composition of morphisms in the category of polynomials. -/
def comp {E B F D N M : C} {P : UvPoly E B} {Q : UvPoly F D} {R : UvPoly N M}
    (f : Hom P Q) (g : Hom Q R) : Hom P R := sorry

end Hom

/-- Bundling up the the polynomials over different bases to form the underlying type of the
category of polynomials. -/
structure Total (C : Type*) [Category C] [HasPullbacks C] where
  (E B : C)
  (poly : UvPoly E B)

def Total.of (P : UvPoly E B) : Total C := ⟨E, B, P⟩

end UvPoly

open UvPoly

/-- The category of polynomial functors in a single variable. -/
instance : Category (UvPoly.Total C) where
  Hom P Q := UvPoly.Hom P.poly Q.poly
  id P := UvPoly.Hom.id P.poly
  comp := UvPoly.Hom.comp
  id_comp := by
    simp [UvPoly.Hom.id, UvPoly.Hom.comp]
    sorry
  comp_id := by
    simp [UvPoly.Hom.id, UvPoly.Hom.comp]
    sorry
  assoc := by
    simp [UvPoly.Hom.comp]

def Total.ofHom {E' B' : C} (P : UvPoly E B) (Q : UvPoly E' B') (α : P.Hom Q) :
    Total.of P ⟶ Total.of Q := sorry

namespace UvPoly

variable {C : Type*} [Category C] [HasTerminal C] [HasPullbacks C]

instance : SMul C (Total C) where
  smul S P := Total.of (smul S P.poly)

/-- Scaling a polynomial `P` by an object `S` is isomorphic to the product of `const S` and the
polynomial `P`. -/
@[simps!]
def smul_eq_prod_const [HasBinaryCoproducts C] [HasInitial C] (S : C) (P : Total C) :
    S • P ≅ Total.of ((const S).prod P.poly) where
      hom := sorry
      inv := sorry
      hom_inv_id := sorry
      inv_hom_id := sorry

variable {E B : C}

-- used to be called `polyPair`
def polyPair {Γ X : C} (P : UvPoly E B) (be : Γ ⟶ P @ X) :
    Σ b : Γ ⟶ B, pullback b P.p ⟶ X :=
  let b := be ≫ P.fstProj X
  let be' : Over.mk b ⟶ (Over.star E ⋙ pushforward P.p).obj X := Over.homMk be
  let be'' := (P.exp.adj.homEquiv _ _).symm be'
  let be''' : pullback b P.p ⟶ E ⨯ X := be''.left
  ⟨b, be''' ≫ prod.snd⟩

-- used to be called `pairPoly`
def pairPoly {Γ X : C} (P : UvPoly E B) (b : Γ ⟶ B) (e : pullback b P.p ⟶ X) :
    Γ ⟶ P @ X :=
  let pbE := (Over.pullback P.p).obj (Over.mk b)
  let eE : pbE ⟶ (Over.star E).obj X := (Over.forgetAdjStar E).homEquiv _ _ e
  (P.exp.adj.homEquiv _ _ eE).left

/-! ## Generic pullback -/

/--
The UP of polynomial functors is mediated by a "generic pullback".
```
     X
     ^
  ev |
     |
   genPb -----fst-------> E
     | ┘                  |
 snd |                    | P.p
     v                    v
  P @ X ----------------> B
          P.fstProj X
```
-/
def genericPullback (P : UvPoly E B) (X : C) : C :=
  Comma.left <| (Over.pullback P.p).obj ((Over.star E ⋙ pushforward P.p).obj X)

lemma genericPullback_def (P : UvPoly E B) (X : C) :
    genericPullback P X = pullback (P.fstProj X) P.p := by
  rfl

namespace genericPullback

def fst (P : UvPoly E B) (X : C) : P.genericPullback X ⟶ P @ X :=
  pullback.fst (P.fstProj X) P.p

def ev (P : UvPoly E B) (X : C) : P.genericPullback X ⟶ X := by
  let ε :=


-- u₂ previously
def ev (P : UvPoly E B) (X : C) : P.genericPullback X ⟶ X :=
  have : P.fstProj X = (P.polyPair <| 𝟙 <| P.functor.obj X).fst :=
    by simp [polyPair]
  (pullback.congrHom this rfl).hom ≫ (P.polyPair <| 𝟙 <| P.functor.obj X).snd

/-- The second component of `polyPair` is a comparison map of pullbacks composed with `genPb.u₂`. -/
theorem genPb.polyPair_snd_eq_comp_u₂' {Γ X : C} (P : UvPoly E B) (be : Γ ⟶ P.functor.obj X) :
    (P.polyPair be).snd = pullback.map (P.polyPair be).fst P.p (P.fstProj X) P.p be (𝟙 _) (𝟙 _) (by simp [polyPair]) (by simp) ≫
                          u₂ P X := by
  simp only [polyPair, u₂, homEquiv_counit, comp_left, ← assoc]
  congr 2
  aesop_cat

/-- Universal property of the polynomial functor. -/
@[simps]
def equiv (P : UvPoly E B) (Γ : C) (X : C) :
    (Γ ⟶ P.functor.obj X) ≃ (b : Γ ⟶ B) × (pullback b P.p ⟶ X) where
  toFun := P.polyPair
  invFun := fun ⟨b, e⟩ => P.pairPoly b e
  left_inv be := by
    simp_rw [polyPair, pairPoly, ← forgetAdjStar.homEquiv_symm]
    simp
  right_inv := by
    intro ⟨b, e⟩
    dsimp [polyPair, pairPoly]
    have := Over.forgetAdjStar.homEquiv (X := (pullback P.p).obj (Over.mk b)) (f := e)
    simp at this
    rw [this]
    set pairHat := P.exp.adj.homEquiv _ _ _
    congr! with h
    · simpa [-w] using pairHat.w
    · -- We deal with HEq/dependency by precomposing with an iso
      let i : Over.mk (pairHat.left ≫ P.fstProj X) ≅ Over.mk b :=
        Over.isoMk (Iso.refl _) (by simp [h])
      rw [
        show homMk _ _ = i.hom ≫ pairHat by ext; simp [i],
        show _ ≫ prod.snd = (pullback.congrHom h rfl).hom ≫ e by (
          simp only [pullback_obj_left,
          mk_left, mk_hom, star_obj_left, pullback_obj_hom, const_obj_obj, BinaryFan.mk_pt,
          BinaryFan.π_app_left, BinaryFan.mk_fst, id_eq, homEquiv_unit, id_obj, comp_obj,
          homEquiv_counit, map_comp, assoc, counit_naturality, left_triangle_components_assoc,
          comp_left, pullback_map_left, eqToHom_left, eqToHom_refl, homMk_left, prod.comp_lift,
          limit.lift_π, eq_mpr_eq_cast, PullbackCone.mk_pt, PullbackCone.mk_π_app, comp_id,
          BinaryFan.π_app_right, BinaryFan.mk_snd, pullback.congrHom_hom, pairHat]
          congr 1
          ext <;> simp [i])
      ]
      generalize (hasPullbackHorizPaste .. : HasPullback (pairHat.left ≫ P.fstProj X) P.p) = pf
      generalize pairHat.left ≫ _ = x at h pf
      cases h
      simp [pullback.congrHom]

/-- `UvPoly.equiv` is natural in `Γ`. -/
lemma equiv_naturality_left {Δ Γ : C} (σ : Δ ⟶ Γ) (P : UvPoly E B) (X : C) (be : Γ ⟶ P.functor.obj X) :
    equiv P Δ X (σ ≫ be) = let ⟨b, e⟩ := equiv P Γ X be
                           ⟨σ ≫ b, pullback.lift (pullback.fst .. ≫ σ) (pullback.snd ..)
                                     (assoc (obj := C) .. ▸ pullback.condition) ≫ e⟩ := by
  dsimp
  congr! with h
  . simp [polyPair, pairPoly]
  . set g := _ ≫ (P.polyPair be).snd
    rw [(_ : (P.polyPair (σ ≫ be)).snd = (pullback.congrHom h rfl).hom ≫ g)]
    · generalize (P.polyPair (σ ≫ be)).fst = x at h
      cases h
      simp
    · simp only [polyPair, comp_obj, homEquiv_counit, id_obj, comp_left, pullback_obj_left,
      mk_left, mk_hom, star_obj_left, pullback_map_left, homMk_left, pullback.congrHom_hom, ←
      assoc, g]
      congr 2
      ext <;> simp

/-- `UvPoly.equiv` is natural in `X`. -/
lemma equiv_naturality_right {Γ X Y : C}
    (P : UvPoly E B) (be : Γ ⟶ P.functor.obj X) (f : X ⟶ Y) :
    equiv P Γ Y (be ≫ P.functor.map f) =
      let ⟨b, e⟩ := equiv P Γ X be
      ⟨b, e ≫ f⟩ := by
  dsimp
  congr! 1 with h
  . simp [polyPair]
  . set g := (P.polyPair be).snd ≫ f
    rw [(_ : (P.polyPair (be ≫ P.functor.map f)).snd = (pullback.congrHom h rfl).hom ≫ g)]
    · generalize (P.polyPair (be ≫ P.functor.map f)).fst = x at h
      cases h
      simp
    · dsimp only [polyPair, g]
      rw [homMk_comp (f_comp := by simp [fstProj, functor]) (g_comp := by simp [functor])]
      simp only [UvPoly.functor, Functor.comp_map, forget_map, left_homMk,
        homEquiv_naturality_right_symm, comp_left, assoc]
      rw [show ((pullback E).map f).left ≫ prod.snd = prod.snd ≫ f by simp]
      simp only [← assoc]
      congr 2
      simp only [comp_obj, forget_obj, star_obj_left, homEquiv_counit, id_obj, comp_left,
        pullback_obj_left, mk_left, mk_hom, pullback_map_left, Over.homMk_left,
        pullback.congrHom_hom, ← assoc]
      congr 1
      ext <;> simp

def foo [HasBinaryProducts C] {P Q : UvPoly.Total C} (f : P ⟶ Q) :
    (Over.map P.poly.p) ⋙ (Over.map f.b) ≅ (Over.map f.e) ⋙ (Over.map Q.poly.p) :=
  mapSquareIso _ _ _ _ (f.is_pullback.w)

def bar [HasBinaryProducts C] {P Q : UvPoly.Total C} (f : P ⟶ Q) :
    (pullback f.e) ⋙ (Σ_ P.poly.p) ≅ (Σ_ Q.poly.p) ⋙ (pullback f.b) := by
  set l := pullbackBeckChevalleyNatTrans P.poly.p f.b f.e Q.poly.p (f.is_pullback.w)
  have : IsIso l :=
    (pullbackBeckChevalleyNatTrans_of_IsPullback_is_iso P.poly.p f.b f.e Q.poly.p f.is_pullback)
  exact asIso l

def bar' [HasBinaryProducts C] {P Q : UvPoly.Total C} (f : P ⟶ Q) :
    (pullback P.poly.p) ⋙ (Σ_ f.e) ≅ (Σ_ f.b) ⋙ (pullback Q.poly.p) := by
  sorry

/-- A map of polynomials induces a natural transformation between their associated functors. -/
def naturality [HasBinaryProducts C] {P Q : UvPoly.Total C} (f : P ⟶ Q) :
    P.poly.functor ⟶ Q.poly.functor := by
  sorry

/-- The domain of the composition of two polynomials. See `UvPoly.comp`. -/
def compDom {E B D A : C} (P : UvPoly E B) (Q : UvPoly D A) :=
  pullback Q.p (genPb.u₂ P A)

/-- The codomain of the composition of two polynomials. See `UvPoly.comp`. -/
def compCod {E B D A : C} (P : UvPoly E B) (_ : UvPoly D A) :=
  P.functor.obj A

@[simps!]
def comp [HasPullbacks C] [HasTerminal C]
    {E B D A : C} (P : UvPoly E B) (Q : UvPoly D A) : UvPoly (compDom P Q) (compCod P Q) :=
   {
     p :=  (pullback.snd Q.p (genPb.u₂ P A)) ≫ (genPb.fst P A)
     exp := by sorry
   }

/-- The associated functor of the composition of two polynomials is isomorphic to the composition of the associated functors. -/
def compFunctorIso [HasPullbacks C] [HasTerminal C]
    {E B D C : C} (P : UvPoly E B) (Q : UvPoly D C) :
    P.functor ⋙ Q.functor ≅ (comp P Q).functor := by
  sorry

end UvPoly

end CategoryTheory

end
