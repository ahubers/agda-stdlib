------------------------------------------------------------------------
-- The Agda standard library
--
-- An effectful view of Vec
------------------------------------------------------------------------

{-# OPTIONS --without-K --safe #-}

module Data.Vec.Effectful {a n} where

open import Data.Fin.Base using (Fin)
open import Data.Vec.Base as Vec hiding (_⊛_)
open import Data.Vec.Properties
open import Effect.Applicative using (RawApplicative)
open import Effect.Applicative.Indexed using (Morphism)
open import Effect.Functor as Fun using (RawFunctor)
open import Effect.Monad using (RawMonad)
import Function.Identity.Effectful as Id
open import Function hiding (Morphism)

------------------------------------------------------------------------
-- Functor and applicative

functor : RawFunctor (λ (A : Set a) → Vec A n)
functor = record
  { _<$>_ = map
  }

applicative : RawApplicative (λ (A : Set a) → Vec A n)
applicative = record
  { pure = replicate
  ; _⊛_  = Vec._⊛_
  }

monad : RawMonad (λ (A : Set a) → Vec A n)
monad = record
  { return = replicate
  ; _>>=_ = DiagonalBind._>>=_
  }

------------------------------------------------------------------------
-- Get access to other monadic functions

module TraversableA {f F} (App : RawApplicative {f} F) where

  open RawApplicative App

  sequenceA : ∀ {A n} → Vec (F A) n → F (Vec A n)
  sequenceA []       = pure []
  sequenceA (x ∷ xs) = _∷_ <$> x ⊛ sequenceA xs

  mapA : ∀ {a} {A : Set a} {B n} → (A → F B) → Vec A n → F (Vec B n)
  mapA f = sequenceA ∘ map f

  forA : ∀ {a} {A : Set a} {B n} → Vec A n → (A → F B) → F (Vec B n)
  forA = flip mapA

module TraversableM {m M} (Mon : RawMonad {m} M) where

  open RawMonad Mon

  open TraversableA rawIApplicative public
    renaming
    ( sequenceA to sequenceM
    ; mapA      to mapM
    ; forA      to forM
    )

------------------------------------------------------------------------
-- Other

-- lookup is a functor morphism from Vec to Identity.

lookup-functor-morphism : (i : Fin n) → Fun.Morphism functor Id.functor
lookup-functor-morphism i = record
  { op     = flip lookup i
  ; op-<$> = lookup-map i
  }

-- lookup is an applicative functor morphism.

lookup-morphism : (i : Fin n) → Morphism applicative Id.applicative
lookup-morphism i = record
  { op      = flip lookup i
  ; op-pure = lookup-replicate i
  ; op-⊛    = lookup-⊛ i
  }
