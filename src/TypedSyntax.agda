module TypedSyntax where

open import Agda.Builtin.List
open import Agda.Builtin.String
open import Agda.Builtin.Nat

open import Agda.Builtin.Bool
open import Agda.Builtin.Int   public using () renaming (Int to Integer)
open import Agda.Builtin.Float public using () renaming (Float to Double)

open import Data.Product hiding (Σ)

open import Javalette.AST using (Type) renaming (Ident to Id)
open Type public

variable
  A B : Set

variable
  xs : List A
  ys : List (List A)
  x y : A

infix 1 _∈_
data _∈_ (e : A)  : List A → Set where
  zero : e ∈ e ∷ xs
  suc  : e ∈ xs → e ∈ x ∷ xs
  
infix 1 _∉_
data _∉_ (e : A)  : List A → Set where
  -- notIn : {!!} → e ∉ xs -- TODO not in

data _∈'_ (e : A) : List (List A) → Set where
  zero : e ∈  xs → e ∈' (xs ∷ ys)
  suc  : e ∈' ys → e ∈' (xs ∷ ys)


SymbolTab : Set
SymbolTab = List (Id × ((List Type) × Type))

Block : Set
Block = List (Id × Type)

Ctx : Set
Ctx = List Block

--------------------------------------------------------------------------------
-- Basic defs

data Void : Set where


toSet : Type → Set
toSet bool = Bool
toSet int = Integer
toSet doub = Double
toSet void = Void
toSet (fun t ts) = Void -- toFun t ts
  where
    toFun : Type → List Type → Set
    toFun x [] = toSet x
    toFun x (x₁ ∷ xs) = toSet x₁ → toFun x xs

data LogicOp  : Set where && ||     : LogicOp
data EqOp     : Set where == !=     : EqOp
data OrdOp    : Set where < <= > >= : OrdOp
data ArithOp  : Set where + - * /   : ArithOp


data Eq : (T : Type) → Set where
  EqInt : Eq int
  EqBool : Eq bool
  EqDouble : Eq doub

data Ord : (T : Type) → Set where
  OrdInt : Ord int
  OrdDouble : Ord doub

data Num : (T : Type) → Set where
  NumInt : Num int
  NumDouble : Num doub

-- LIFTED TypeD List
infixr 5 _:+_
data TList (e : Type → Set) : (As : List Type) → Set where
  NIL  : TList e []
  _:+_ : ∀ {A AS} → e A → TList e AS → TList e (A ∷ AS)

-- data Op (const : C a) (a : A) (b : B) where


variable
  T t : Type
  ts  : List Type
  Δ Δ₁ Δ₂ : Block
  Γ Γ' : Ctx
  Σ : SymbolTab

--------------------------------------------------------------------------------
-- EXPRESSIONS AND STATEMENTS

data Exp (Γ : Ctx) : Type → Set where
  EValue : toSet T  → Exp Γ T
  EId    : (id : Id) → (id , T) ∈' Γ → Exp Γ T
  EAPP   : (id : Id) → TList (Exp Γ) ts → (id , (ts , T)) ∈ Σ → Exp Γ T
  EArith : Num T   → Exp Γ T → ArithOp → Exp Γ T → Exp Γ T
  EMod   : Exp Γ int → Exp Γ int → Exp Γ int
  EOrd   : { Ord T } → Exp Γ T → OrdOp → Exp Γ T → Exp Γ bool
  EEq    : { Eq T } → Exp Γ T → EqOp  → Exp Γ T → Exp Γ bool
  ELogic : Exp Γ bool → LogicOp → Exp Γ bool → Exp Γ bool
  ENeg   : Num T → Exp Γ T → Exp Γ T
  ENot   : Exp Γ bool → Exp Γ bool


mutual
  data Stm (T : Type) : (Γ : Ctx) → (Γ' : Ctx) → Set  where
       SExp    : {X : Type} → Exp Γ X → Stm T Γ Γ
       SDecl   : (t : Type) → (id : Id) → (id , t) ∉ Δ → Stm T (Δ ∷ Γ) (((id , t) ∷ Δ) ∷ Γ)
       SAss    : (id : Id) → (e : Exp Γ t) → (id , t) ∈' Γ → Stm T Γ Γ
       SWhile  : Exp Γ bool  → Stms T ([] ∷ Γ) (Δ ∷ Γ)  → Stm T Γ Γ
       SBlock  : Stms T ([] ∷ Γ) (Δ ∷ Γ) → Stm T Γ Γ
       SIfElse : Exp Γ bool → Stms T ([] ∷ Γ) (Δ₁ ∷ Γ) → Stms T ([] ∷ Γ) (Δ₂ ∷ Γ)  → Stm T Γ Γ
       SReturn : Exp Γ T  → Stm T Γ Γ

  data Stms (T : Type) (Γ : Ctx) : (Γ' : Ctx) → Set where
    SEmpty : Stms T Γ Γ
    SStms  : {Γ' Γ'' : Ctx} → Stm T Γ Γ' → Stms T Γ' Γ'' → Stms T Γ Γ''


record Def (Γ : Ctx) (T : Type) : Set  where
  constructor Fun
  field
    funId  : Id
    body   : ∀ {Γ'} → Stm T Γ Γ'

data SomeDef : Set where
  someDef : {Γ : Ctx} → {a : Type} → Def Γ a → SomeDef

record Program : Set where
  field
    main : Def [] int
    defs : List SomeDef
