{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE DeriveFoldable             #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveTraversable          #-}
{-# LANGUAGE DerivingStrategies         #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase                 #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE PatternSynonyms            #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TupleSections              #-}
{-# LANGUAGE TypeApplications           #-}
module Rzk.Free.Syntax.Example.MLTT where

import           Debug.Trace
import           Unsafe.Coerce

import qualified Bound.Scope                               as Scope
import qualified Bound.Var                                 as Bound
import           Control.Applicative
import           Data.Bifunctor.TH
import           Data.Char                                 (chr, isPrint,
                                                            isSpace, ord)
import qualified Data.HashSet                              as HashSet
import           Data.Maybe                                (fromMaybe)
import           Data.String                               (IsString (..))
import qualified Data.Text                                 as Text
import           Data.Text.Prettyprint.Doc                 as Doc
import           Data.Text.Prettyprint.Doc.Render.Terminal (putDoc)
import           System.IO.Unsafe                          (unsafePerformIO)
import           Text.Parser.Expression
import           Text.Parser.Token                         ()
import           Text.Parser.Token.Style                   (emptyIdents)
import           Text.Trifecta                             (IdentifierStyle (..),
                                                            Parser,
                                                            TokenParsing,
                                                            symbol)
import qualified Text.Trifecta                             as Trifecta

import           Rzk.Free.Bound.Name
import           Rzk.Free.Syntax.FreeScoped
import           Rzk.Free.Syntax.FreeScoped.TypeCheck      (TypeCheck,
                                                            TypeError, TypeInfo,
                                                            assignType, nonDep,
                                                            shouldHaveType,
                                                            typeOf,
                                                            typeOfScopedWith,
                                                            typecheckDist,
                                                            typecheckInScope,
                                                            unifyWithExpected',
                                                            untyped)
import qualified Rzk.Free.Syntax.FreeScoped.TypeCheck      as TypeCheck
import           Rzk.Free.Syntax.FreeScoped.Unification2   (HigherOrderUnifiable (..),
                                                            Unifiable (..))
import qualified Rzk.Free.Syntax.FreeScoped.Unification2   as Unification2
import qualified Rzk.Syntax.Var                            as Rzk

-- * Generators

-- | Generating bifunctor for terms in .
data TermF scope term
  -- | Universe is the type of all types: \(\mathcal{U}\)
  = UniverseF

  -- | Type of functions: \(A \to B\)
  | PiF term scope
  -- | Lambda function with an optional argument type: \(\lambda (x : A). t\)
  | LamF (Maybe term) scope
  -- | Application of one term to another: \((t_1) t_2\)
  | AppF term term

  -- | Dependent sum type former \(\sum_{x : A} B(x)\).
  -- The term argument represents type family \(B : A \to \mathcal{U}\).
  | SigmaF term scope
  -- | A (dependent) pair of terms.
  -- @Pair x y@ represents a term of the form \((x, y)\).
  | PairF term term
  -- | Project the first element of a pair: \(\pi_1 p\).
  | FirstF term
  -- | Project the second element of a pair: \(\pi_2 p\).
  | SecondF term

  -- | Identity type former \(x =_A y\) (corresponding to term @IdType a x y@).
  | IdTypeF term term term
  -- | Trivial inhabitant of \(x =_A x\) for any type \(A\) and \(x : A\).
  -- @Refl a x@ corresponds to \(x =_a x\).
  | ReflF (Maybe term) term
  -- | Path induction (for identity types).
  -- For any type \(A\) and \(a : A\), type family
  -- \(C : \prod_{x : A} ((a =_A x) \to \mathcal{U})\)
  -- and \(d : C(a,\mathsf{refl}_a)\)
  -- and \(x : A\)
  -- and \(p : a =_A x\)
  -- we have \(\mathcal{J}(A, a, C, d, x, p) : C(x, p)\).
  | JF term term term term term term

  deriving (Show, Functor, Foldable, Traversable)

-- | Generating bifunctor for typed terms of simply typed lambda calculus.
type TypedTermF = TypeCheck.TypedF TermF

-- ** Useful type synonyms (could be generated by TH)

-- | An untyped/unchecked term of simply typed lambda calculus.
type Term b = TypeCheck.Term TermF b

-- | An untyped/unchecked term of simply typed lambda calculus
-- in one scope layer.
type TermInScope b a = TypeCheck.TermInScope TermF b a

-- | A 'Scope.Scope' with an untyped/unchecked term
-- of simply typed lambda calculus.
type ScopedTerm b = TypeCheck.ScopedTerm TermF b

type TypedTerm b = TypeCheck.TypedTerm TermF b
type TypedTermInScope b a = TypeCheck.TypedTermInScope TermF b a
type ScopedTypedTerm b = TypeCheck.ScopedTypedTerm TermF b

type UTypedTerm b a v = TypeCheck.UTypedTerm TermF b a v
type UTypedTermInScope b a v = TypeCheck.UTypedTermInScope TermF b a v
type UScopedTypedTerm b a v = TypeCheck.UScopedTypedTerm TermF b a v

type Term' = Term Rzk.Var Rzk.Var
type TermInScope' = TermInScope Rzk.Var Rzk.Var
type ScopedTerm' = ScopedTerm Rzk.Var Rzk.Var

type TypedTerm' = TypedTerm Rzk.Var Rzk.Var
type TypedTermInScope' = TypedTermInScope Rzk.Var Rzk.Var
type ScopedTypedTerm' = ScopedTypedTerm Rzk.Var Rzk.Var

type UTypedTerm' = UTypedTerm Rzk.Var Rzk.Var Rzk.Var
type UTypedTermInScope' = UTypedTermInScope Rzk.Var Rzk.Var Rzk.Var
type UScopedTypedTerm' = UScopedTypedTerm Rzk.Var Rzk.Var Rzk.Var

type InScope' = Bound.Var (Name Rzk.Var ())

type UTypedTerm'1 = UTypedTerm Rzk.Var (InScope' Rzk.Var) Rzk.Var
type UTypedTerm'2 = UTypedTerm Rzk.Var (InScope' (InScope' Rzk.Var)) Rzk.Var

type TypeInfo'1 = TypeInfo Rzk.Var UTypedTerm'1 (InScope' Rzk.Var)
type TypeInfo'2 = TypeInfo Rzk.Var UTypedTerm'2 (InScope' (InScope' Rzk.Var))

-- *** For typechecking

type TypeError' = TypeError UTypedTerm'

type TypeInfo' = TypeInfo Rzk.Var UTypedTerm' Rzk.Var
type TypeInfoInScope'
  = TypeInfo Rzk.Var UTypedTermInScope' (Bound.Var (Name Rzk.Var ()) Rzk.Var)

type TypeInfoInScopeIgnored' = TypeCheck.TypeInfoInScopeIgnored' TermF

type TypeCheck' = TypeCheck UTypedTerm' Rzk.Var Rzk.Var
type TypeCheckInScope'
  = TypeCheck UTypedTermInScope' (Bound.Var (Name Rzk.Var ()) Rzk.Var) Rzk.Var

-- ** Pattern synonyms (should be generated with TH)

-- *** Untyped

-- | A variable.
pattern Var :: a -> Term b a
pattern Var x = PureScoped x

-- | Universe type \(\mathcal{U}_i\)
pattern Universe :: Term b a
pattern Universe = FreeScoped UniverseF

-- | A dependent product type (\(\Pi\)-type): \(\prod_{x : A} B(x)).
pattern Pi :: Term b a -> ScopedTerm b a -> Term b a
pattern Pi a b = FreeScoped (PiF a b)

mkFun :: Term b a -> Term b a -> Term b a
mkFun a b = Pi a (Scope.toScope (Bound.F <$> b))

-- | A \(\lambda\)-abstraction.
pattern Lam :: Maybe (Term b a) -> ScopedTerm b a -> Term b a
pattern Lam ty body = FreeScoped (LamF ty body)

-- | An application of one term to another.
pattern App :: Term b a -> Term b a -> Term b a
pattern App t1 t2 = FreeScoped (AppF t1 t2)

pattern Sigma :: Term b a -> ScopedTerm b a -> Term b a
pattern Sigma a b = FreeScoped (SigmaF a b)

mkProdType :: Term b a -> Term b a -> Term b a
mkProdType a b = Sigma a (Scope.toScope (Bound.F <$> b))

pattern Pair :: Term b a -> Term b a -> Term b a
pattern Pair t1 t2 = FreeScoped (PairF t1 t2)

pattern First :: Term b a -> Term b a
pattern First t = FreeScoped (FirstF t)

pattern Second :: Term b a -> Term b a
pattern Second t = FreeScoped (SecondF t)

pattern IdType :: Term b a -> Term b a -> Term b a -> Term b a
pattern IdType t x y = FreeScoped (IdTypeF t x y)

pattern Refl :: Maybe (Term b a) -> Term b a -> Term b a
pattern Refl t x = FreeScoped (ReflF t x)

pattern J
  :: Term b a
  -> Term b a
  -> Term b a
  -> Term b a
  -> Term b a
  -> Term b a
  -> Term b a
pattern J tA a tC d x p = FreeScoped (JF tA a tC d x p)

{-# COMPLETE
   Var, Universe,
   Pi, Lam, App,
   Sigma, Pair, First, Second,
   IdType, Refl, J
   #-}

-- *** Typed

-- | A variable.
pattern VarT :: a -> TypedTerm b a
pattern VarT x = PureScoped x

-- | Universe type \(\mathcal{U}_i\)
pattern UniverseT :: Maybe (TypedTerm b a) -> TypedTerm b a
pattern UniverseT ty = TypeCheck.TypedT ty UniverseF

-- | A dependent product type (\(\Pi\)-type): \(\prod_{x : A} B(x)).
pattern PiT :: Maybe (TypedTerm b a) -> TypedTerm b a -> ScopedTypedTerm b a -> TypedTerm b a
pattern PiT ty a b = TypeCheck.TypedT ty (PiF a b)

mkFunT :: TypedTerm b a -> TypedTerm b a -> TypedTerm b a
mkFunT a b = PiT (Just universeT) a (Scope.toScope (Bound.F <$> b))

-- | A \(\lambda\)-abstraction.
pattern LamT :: Maybe (TypedTerm b a) -> Maybe (TypedTerm b a) -> ScopedTypedTerm b a -> TypedTerm b a
pattern LamT ty argType body = TypeCheck.TypedT ty (LamF argType body)

-- | An application of one term to another.
pattern AppT :: Maybe (TypedTerm b a) -> TypedTerm b a -> TypedTerm b a -> TypedTerm b a
pattern AppT ty t1 t2 = TypeCheck.TypedT ty (AppF t1 t2)

pattern SigmaT :: Maybe (TypedTerm b a) -> TypedTerm b a -> ScopedTypedTerm b a -> TypedTerm b a
pattern SigmaT ty a b = TypeCheck.TypedT ty (SigmaF a b)

pattern PairT :: Maybe (TypedTerm b a) -> TypedTerm b a -> TypedTerm b a -> TypedTerm b a
pattern PairT ty t1 t2 = TypeCheck.TypedT ty (PairF t1 t2)

pattern FirstT :: Maybe (TypedTerm b a) -> TypedTerm b a -> TypedTerm b a
pattern FirstT ty t = TypeCheck.TypedT ty (FirstF t)

pattern SecondT :: Maybe (TypedTerm b a) -> TypedTerm b a -> TypedTerm b a
pattern SecondT ty t = TypeCheck.TypedT ty (SecondF t)

pattern IdTypeT :: Maybe (TypedTerm b a) -> TypedTerm b a -> TypedTerm b a -> TypedTerm b a -> TypedTerm b a
pattern IdTypeT ty t x y = TypeCheck.TypedT ty (IdTypeF t x y)

pattern ReflT :: Maybe (TypedTerm b a) -> Maybe (TypedTerm b a) -> TypedTerm b a -> TypedTerm b a
pattern ReflT ty t x = TypeCheck.TypedT ty (ReflF t x)

pattern JT
  :: Maybe (TypedTerm b a)
  -> TypedTerm b a
  -> TypedTerm b a
  -> TypedTerm b a
  -> TypedTerm b a
  -> TypedTerm b a
  -> TypedTerm b a
  -> TypedTerm b a
pattern JT ty tA a tC d x p = TypeCheck.TypedT ty (JF tA a tC d x p)

{-# COMPLETE
   VarT, UniverseT,
   PiT, LamT, AppT,
   SigmaT, PairT, FirstT, SecondT,
   IdTypeT, ReflT, JT
   #-}

-- ** Smart constructors

-- | Universe (type of types).
--
-- > universeT :: TypedTerm'
-- U : U
universeT :: TypedTerm b a
universeT = TypeCheck.TypedT Nothing UniverseF

-- | Abstract over one variable in a term.
--
-- > lam Nothing "x" (App (Var "f") (Var "x")) :: Term'
-- λx₁ → f x₁
-- > lam Nothing "f" (App (Var "f") (Var "x")) :: Term'
-- λx₁ → x₁ x
-- > lam (Just (Var "A")) "x" (App (Var "f") (Var "x")) :: Term'
-- λ(x₁ : A) → f x₁
-- > lam (Just (Fun (Var "A") (Var "B"))) "f" (App (Var "f") (Var "x")) :: Term'
-- λ(x₁ : A → B) → x₁ x
lam :: Eq a => Maybe (Term a a) -> a -> Term a a -> Term a a
lam ty x body = Lam ty (abstract1Name x body)

-- | Abstract over one variable in a term (without type).
--
-- > lam_ "x" (App (Var "f") (Var "x")) :: Term'
-- λx₁ → f x₁
lam_ :: Eq a => a -> Term a a -> Term a a
lam_ x body = Lam Nothing (abstract1Name x body)

etaJ :: Term b a
etaJ =
  Lam Nothing $ Scope.toScope $
  Lam Nothing $ Scope.toScope $
  Lam Nothing $ Scope.toScope $
  Lam Nothing $ Scope.toScope $
  Lam Nothing $ Scope.toScope $
  Lam Nothing $ Scope.toScope $
    J (Var (Bound.F (Bound.F (Bound.F (Bound.F (Bound.F (Bound.B (Name Nothing ()))))))))
      (Var (Bound.F (Bound.F (Bound.F (Bound.F (Bound.B (Name Nothing ())))))))
      (Var (Bound.F (Bound.F (Bound.F (Bound.B (Name Nothing ()))))))
      (Var (Bound.F (Bound.F (Bound.B (Name Nothing ())))))
      (Var (Bound.F (Bound.B (Name Nothing ()))))
      (Var (Bound.B (Name Nothing ())))

pi_ :: Eq a => a -> Term a a -> Term a a -> Term a a
pi_ x a b = Pi a (abstract1Name x b)

sigma_ :: Eq a => a -> Term a a -> Term a a -> Term a a
sigma_ x a b = Sigma a (abstract1Name x b)

-- ** Evaluation

whnfUntyped :: Term b a -> Term b a
whnfUntyped = untyped . whnf . TypeCheck.pseudoTyped

nfUntyped :: Term b a -> Term b a
nfUntyped = untyped . nf . TypeCheck.pseudoTyped

-- | Evaluate a term to its weak head normal form (WHNF).
whnf :: TypedTerm b a -> TypedTerm b a
whnf = \case
  AppT ty f x ->
    case whnf f of
      LamT _ty _typeOfArg body ->
        whnf (Scope.instantiate1 x body)
      f' -> AppT ty f' x

  FirstT ty t ->
    case whnf t of
      PairT _ty f _s -> whnf f
      t'             -> FirstT ty t'

  SecondT ty t ->
    case whnf t of
      PairT _ty _f s -> whnf s
      t'             -> SecondT ty t'

  JT ty tA a tC d x p ->
    case whnf p of
      ReflT _ _ _ -> whnf d
      p'          -> JT ty tA a tC d x p'

  t@LamT{} -> t
  t@PairT{} -> t
  t@ReflT{} -> t

  t@UniverseT{} -> t
  t@PiT{} -> t
  t@SigmaT{} -> t
  t@IdTypeT{} -> t

  t@VarT{} -> t

nf :: TypedTerm b a -> TypedTerm b a
nf = \case
  AppT ty f x ->
    case whnf f of
      LamT _ty _typeOfArg body ->
        nf (Scope.instantiate1 x body)
      f' -> AppT (nf <$> ty) (nf f') (nf x)

  FirstT ty t ->
    case whnf t of
      PairT _ty f _s -> nf f
      t'             -> FirstT (nf <$> ty) (nf t')

  SecondT ty t ->
    case whnf t of
      PairT _ty _f s -> nf s
      t'             -> SecondT (nf <$> ty) (nf t')

  JT ty tA a tC d x p ->
    case whnf p of
      ReflT _ _ _ -> nf d
      p'          -> JT (nf <$> ty) (nf tA) (nf a) (nf tC) (nf d) (nf x) (nf p')

  LamT ty typeOfArg body -> LamT (nf <$> ty) (nf <$> typeOfArg) (nfScope body)
  PairT ty t1 t2 -> PairT (nf <$> ty) (nf t1) (nf t2)
  ReflT ty a x -> ReflT (nf <$> ty) (nf <$> a) (nf x)

  UniverseT ty -> UniverseT (nf <$> ty)
  PiT ty a b -> PiT (nf <$> ty) (nf a) (nfScope b)
  SigmaT ty a b -> SigmaT (nf <$> ty) (nf a) (nfScope b)
  IdTypeT ty a x y -> IdTypeT (nf <$> ty) (nf a) (nf x) (nf y)

  t@VarT{} -> t
  where
    nfScope = Scope.toScope . nf . Scope.fromScope

-- ** Unification

-- | Should be derived with TH or Generics.
instance Unifiable TermF where
  zipMatch (AppF f1 x1) (AppF f2 x2)
    = Just (AppF (Right (f1, f2)) (Right (x1, x2)))

  zipMatch (LamF argTy1 body1) (LamF argTy2 body2)
    = Just (LamF argTy (Right (body1, body2)))
    where
      argTy =
        case (argTy1, argTy2) of
          (Nothing, _)     -> Left <$> argTy2
          (_, Nothing)     -> Left <$> argTy1
          (Just x, Just y) -> Just (Right (x, y))

  zipMatch (PiF arg1 body1) (PiF arg2 body2)
    = Just (PiF (Right (arg1, arg2)) (Right (body1, body2)))

  zipMatch (SigmaF arg1 body1) (SigmaF arg2 body2)
    = Just (SigmaF (Right (arg1, arg2)) (Right (body1, body2)))
  zipMatch (PairF f1 x1) (PairF f2 x2)
    = Just (PairF (Right (f1, f2)) (Right (x1, x2)))
  zipMatch (FirstF t1) (FirstF t2)
    = Just (FirstF (Right (t1, t2)))
  zipMatch (SecondF t1) (SecondF t2)
    = Just (SecondF (Right (t1, t2)))

  zipMatch (IdTypeF a1 x1 y1) (IdTypeF a2 x2 y2)
    = Just (IdTypeF (Right (a1, a2)) (Right (x1, x2)) (Right (y1, y2)))
  zipMatch (ReflF a1 x1) (ReflF a2 x2)
    = Just (ReflF a (Right (x1, x2)))
    where
      a =
        case (a1, a2) of
          (Nothing, _)     -> Left <$> a2
          (_, Nothing)     -> Left <$> a1
          (Just x, Just y) -> Just (Right (x, y))
  zipMatch (JF tA1 a1 tC1 d1 x1 p1) (JF tA2 a2 tC2 d2 x2 p2)
    = Just (JF (Right (tA1, tA2)) (Right (a1, a2)) (Right (tC1, tC2)) (Right (d1, d2)) (Right (x1, x2)) (Right (p1, p2)))

  zipMatch UniverseF UniverseF = Just UniverseF

  zipMatch PiF{} _ = Nothing
  zipMatch LamF{} _ = Nothing
  zipMatch AppF{} _ = Nothing

  zipMatch SigmaF{} _ = Nothing
  zipMatch PairF{} _ = Nothing
  zipMatch FirstF{} _ = Nothing
  zipMatch SecondF{} _ = Nothing

  zipMatch IdTypeF{} _ = Nothing
  zipMatch ReflF{} _ = Nothing
  zipMatch JF{} _ = Nothing

  zipMatch UniverseF{} _ = Nothing

instance HigherOrderUnifiable TermF where
  appSome _ []     = error "cannot apply to zero arguments"
  appSome f (x:xs) = (AppF f x, xs)

  unAppSome (AppF f x) = Just (f, [x])
  unAppSome _          = Nothing

  abstract = LamF Nothing

unifyTerms
  :: (Eq v, Eq a)
  => [v]
  -> UTypedTerm b a v
  -> UTypedTerm b a v
  -> [([(v, UTypedTerm b a v)], [(UTypedTerm b a v, UTypedTerm b a v)])]
unifyTerms mvars t1 t2 = Unification2.driver mvars whnf (t1, t2)

unifyTerms_
  :: (Eq v, Eq a)
  => [v]
  -> UTypedTerm b a v
  -> UTypedTerm b a v
  -> [(v, UTypedTerm b a v)]
unifyTerms_ mvars t1 t2 = fst (head (unifyTerms mvars t1 t2))

unifyTerms'
  :: UTypedTerm'
  -> UTypedTerm'
  -> [([(Rzk.Var, UTypedTerm')], [(UTypedTerm', UTypedTerm')])]
unifyTerms' = unifyTerms (iterate succ "?")

-- | Unify two typed terms with meta-variables.
unifyTerms'_
  :: UTypedTerm'
  -> UTypedTerm'
  -> [(Rzk.Var, UTypedTerm')]
unifyTerms'_ t1 t2 = fst (head (unifyTerms' t1 t2))


-- ** Typechecking and inference

instance TypeCheck.TypeCheckable TermF where
  inferTypeFor = inferTypeForTermF
  whnfT = whnf
  universeT = TypeCheck.TypedT Nothing UniverseF

instance TypeCheck.HasTypeFamilies TermF where
  piT = PiT (Just universeT)

unsafeTraceCurrentTypeInfo' :: String -> TypeCheck (UTypedTerm b a v) a v ()
unsafeTraceCurrentTypeInfo' tag = do
  info <- TypeCheck.getTypeInfo
  trace ("unsafeTraceCurrentTypeInfo'[" <> tag <> "]: " <> show (unsafeCoerce info :: TypeInfo')) $
    return ()

unsafeTraceCurrentTypeInfoInScope' :: String -> TypeCheck (UTypedTermInScope b a v) (Bound.Var (Name b ()) a) v ()
unsafeTraceCurrentTypeInfoInScope' tag = do
  info <- TypeCheck.getTypeInfo
  trace ("unsafeTraceCurrentTypeInfo'[" <> tag <> "]: " <> show (unsafeCoerce info :: TypeInfoInScope')) $
    return ()

unsafeTraceCurrentTypeInfoInScopeIgnored'
  :: (Eq a, Eq v)
  => String -> TypeCheck (UTypedTermInScope b a v) (Bound.Var (Name b ()) a) v ()
unsafeTraceCurrentTypeInfoInScopeIgnored' tag = do
  info <- TypeCheck.getTypeInfo
  info' <- TypeCheck.ignoreBoundVarInTypeInfo info
  trace ("unsafeTraceCurrentTypeInfo'[" <> tag <> "]: " <> show (unsafeCoerce info' :: TypeInfoInScopeIgnored')) $
    return ()

inferTypeForTermF
  :: (Eq a, Eq v)
  => TermF
        (TypeCheck (UTypedTermInScope b a v) (Bound.Var (Name b ()) a) v
            (UScopedTypedTerm b a v))
        (TypeCheck (UTypedTerm b a v) a v (UTypedTerm b a v))
  -> TypeCheck (UTypedTerm b a v) a v
        (TypedTermF (UScopedTypedTerm b a v) (UTypedTerm b a v))
inferTypeForTermF term = case term of
  UniverseF -> pure (TypeCheck.TypedF UniverseF (Just universeT))
  -- a -> b
  PiF inferA inferB -> do
    a <- inferA
    typeOfA <- a `shouldHaveType` universeT >>= typeOf
    b <- typecheckInScope $ do
      assignType (Bound.B (Name Nothing ())) (fmap Bound.F typeOfA) -- FIXME: unnamed?
      inferB
    typeOfB <- typeOfScopedWith typeOfA b >>= nonDep
    _ <- typeOfB `shouldHaveType` universeT
    pure (TypeCheck.TypedF (PiF a b) (Just universeT))

  LamF minferTypeOfArg inferBody -> do
    typeOfArg <- case minferTypeOfArg of
      Just inferTypeOfArg -> inferTypeOfArg
      Nothing             -> TypeCheck.freshAppliedTypeMetaVar
    typeOfArg' <- typeOfArg `shouldHaveType` universeT
    -- unsafeTraceCurrentTypeInfo' "LamF"
    scopedTypedBody <- typecheckInScope $ do
      assignType (Bound.B (Name Nothing ())) (fmap Bound.F typeOfArg') -- FIXME: unnamed?
      r <- inferBody
      -- unsafeTraceCurrentTypeInfoInScope' "LamF"
      -- unsafeTraceCurrentTypeInfoInScopeIgnored' "IGNORED"
      return r
    -- unsafeTraceCurrentTypeInfo' "LamF"
    typeOfBody <- typeOfScopedWith typeOfArg' scopedTypedBody
    -- unsafeTraceCurrentTypeInfo' "LamF"
    typeOfTypeOfBody <- typeOfScopedWith typeOfArg' typeOfBody >>= nonDep
    -- unsafeTraceCurrentTypeInfo' "LamF"
    _ <- unifyWithExpected' "LamF" typeOfTypeOfBody universeT
    pure $ TypeCheck.TypedF
      (LamF (typeOfArg <$ minferTypeOfArg) scopedTypedBody)
      (Just (PiT (Just universeT) typeOfArg' typeOfBody))

  AppF infer_f infer_x -> do
    f <- infer_f
    x <- infer_x
    TypeCheck.TypedF (AppF f x) . Just <$> do
      typeOf f >>= \case
        PiT _ argType bodyType -> do
          _ <- x `shouldHaveType` argType
          Scope.instantiate1 x bodyType `shouldHaveType` universeT
        t -> do
          typeOf_x <- typeOf x
          bodyType <- fmap (Scope.toScope . fmap TypeCheck.dist') . typecheckInScope . typecheckDist $ do
            assignType (Bound.B (Name Nothing ())) (fmap (TypeCheck.dist . Bound.F) typeOf_x) -- FIXME: unnamed?
            TypeCheck.freshAppliedTypeMetaVar
              -- (map (fmap (TypeCheck.dist . Bound.F)) [f, x]) -- TODO: explain?
          _ <- unifyWithExpected' "AppF" t (PiT (Just universeT) typeOf_x bodyType)
          return (Scope.instantiate1 x bodyType)

  SigmaF inferA inferB -> do
    a <- inferA
    typeOfA <- a `shouldHaveType` universeT >>= typeOf
    b <- typecheckInScope $ do
      assignType (Bound.B (Name Nothing ())) (fmap Bound.F typeOfA) -- FIXME: unnamed?
      inferB
    typeOfB <- typeOfScopedWith typeOfA b >>= nonDep
    _ <- typeOfB `shouldHaveType` universeT
    pure (TypeCheck.TypedF (SigmaF a b) (Just universeT))

  PairF inferFirst inferSecond -> do
    f <- inferFirst
    typeOf_f <- typeOf f

    s <- inferSecond
    typeOf_s   <- typeOf s
    typeOf_s'  <- fmap (Scope.toScope . fmap TypeCheck.dist') . typecheckInScope . typecheckDist $ do
      assignType (Bound.B (Name Nothing ())) (fmap (TypeCheck.dist . Bound.F) typeOf_f) -- FIXME: unnamed?
      TypeCheck.freshAppliedTypeMetaVar
    -- FIXME: do not discard?
    _ <- unifyWithExpected' "PairF" typeOf_s (Scope.instantiate1 f typeOf_s')

    pure (TypeCheck.TypedF
            (PairF f s)
            (Just (SigmaT (Just universeT) typeOf_f typeOf_s')))

  FirstF inferT -> do
    t <- inferT
    typeOf t >>= \case
      SigmaT _ty f _s ->
        pure (TypeCheck.TypedF (FirstF t) (Just f))
      ty -> do
        f <- TypeCheck.freshAppliedTypeMetaVar
        typeOf_f <- typeOf f
        s <- fmap (Scope.toScope . fmap TypeCheck.dist') . typecheckInScope . typecheckDist $ do
          assignType (Bound.B (Name Nothing ())) (fmap (TypeCheck.dist . Bound.F) typeOf_f) -- FIXME: unnamed?
          TypeCheck.freshAppliedTypeMetaVar
        _ <- unifyWithExpected' "FirstF" ty (SigmaT (Just universeT) f s)
        pure (TypeCheck.TypedF (FirstF t) (Just f))

  SecondF inferT -> do
    t <- inferT
    typeOf t >>= \case
      SigmaT _ty f s ->
        pure (TypeCheck.TypedF
                (SecondF t)
                (Just (Scope.instantiate1 (FirstT (Just f) t) s)))
      ty -> do
        f <- TypeCheck.freshAppliedTypeMetaVar
        typeOf_f <- typeOf f
        s <- fmap (Scope.toScope . fmap TypeCheck.dist') . typecheckInScope . typecheckDist $ do
          assignType (Bound.B (Name Nothing ())) (fmap (TypeCheck.dist . Bound.F) typeOf_f) -- FIXME: unnamed?
          TypeCheck.freshAppliedTypeMetaVar
        _ <- unifyWithExpected' "FirstF" ty (SigmaT (Just universeT) f s)
        pure (TypeCheck.TypedF (SecondF t) (Just (Scope.instantiate1 (FirstT (Just f) t) s)))

  IdTypeF inferA inferX inferY -> do
    a <- inferA >>= (`shouldHaveType` universeT)
    x <- inferX >>= (`shouldHaveType` a)
    y <- inferY >>= (`shouldHaveType` a)
    pure (TypeCheck.TypedF (IdTypeF a x y) (Just universeT))

  ReflF minferA inferX -> do
    a <- case minferA of
           Nothing     -> TypeCheck.freshAppliedTypeMetaVar
           Just inferA -> inferA >>= (`shouldHaveType` universeT)
    x <- inferX >>= (`shouldHaveType` a)
    pure (TypeCheck.TypedF (ReflF (a <$ minferA) x) (Just (IdTypeT (Just universeT) a x x)))

  JF infer_A infer_a infer_C infer_d infer_x infer_p -> do
    tA  <- infer_A >>= (`shouldHaveType` universeT)
    a   <- infer_a >>= (`shouldHaveType` tA)
    let typeOf_C = TypeCheck.piT tA . Scope.toScope $
          mkFunT (IdTypeT (Just universeT) (Bound.F <$> tA) (Bound.F <$> a) (VarT (Bound.B (Name Nothing ())))) universeT
    tC  <- do
      tC <- infer_C
      tC `shouldHaveType` typeOf_C
    let typeOf_C_a = mkFunT (IdTypeT (Just universeT) tA a a) universeT
    let typeOf_d = AppT (Just universeT) (AppT (Just typeOf_C_a) tC a) (ReflT (Just (IdTypeT (Just universeT) tA a a)) (Just tA) a)
    d   <- infer_d >>= (`shouldHaveType` typeOf_d )
    x   <- infer_x >>= (`shouldHaveType` tA)
    p   <- infer_p >>= (`shouldHaveType` IdTypeT (Just universeT) tA a x)
    let typeOf_C_x = mkFunT (IdTypeT (Just universeT) tA a x) universeT
    let typeOf_result = AppT (Just universeT) (AppT (Just typeOf_C_x) tC x) p
    return (TypeCheck.TypedF (JF tA a tC d x p) (Just typeOf_result))

execTypeCheck' :: TypeCheck' a -> Either TypeError' a
execTypeCheck' = TypeCheck.execTypeCheck defaultFreshMetaVars

runTypeCheckOnce' :: TypeCheck' a -> Either TypeError' (a, TypeInfo')
runTypeCheckOnce' = TypeCheck.runTypeCheckOnce defaultFreshMetaVars

typecheck' :: Term' -> Term' -> TypeCheck' UTypedTerm'
typecheck' = TypeCheck.typecheckUntyped

infer' :: Term' -> TypeCheck' UTypedTerm'
infer' = TypeCheck.infer

inferScoped' :: ScopedTerm' -> TypeCheck' UScopedTypedTerm'
inferScoped' = TypeCheck.inferScoped

inferInScope' :: TermInScope' -> TypeCheck' UTypedTermInScope'
inferInScope' = fmap (fmap TypeCheck.dist') . typecheckInScope . typecheckDist . TypeCheck.infer

unsafeInfer' :: Term' -> UTypedTerm'
unsafeInfer' = unsafeUnpack . execTypeCheck' . infer'
  where
    unsafeUnpack (Right typedTerm) = typedTerm
    unsafeUnpack _ = error "unsafeInfer': failed to extract term with inferred type"

-- ** Pretty-printing

instance (Pretty n, Pretty b) => Pretty (Name n b) where
  pretty (Name Nothing b)     = pretty b
  pretty (Name (Just name) b) = "<" <> pretty name <> " " <> pretty b <> ">"

instance (Pretty b, Pretty a) => Pretty (Bound.Var b a) where
  pretty (Bound.B b) = "<bound " <> pretty b <> ">"
  pretty (Bound.F x) = "<free " <> pretty x <> ">"

instance IsString a => IsString (Bound.Var b a) where
  fromString = Bound.F . fromString

-- | Uses 'Pretty' instance.
instance (Pretty a, Pretty b, IsString a) => Show (Term b a) where
  show = show . pretty

-- | Uses default names (@x@ with a positive integer subscript) for bound variables:
instance (Pretty a, Pretty b, IsString a) => Pretty (Term b a) where
  pretty = ppTerm defaultFreshVars

defaultFreshVars :: IsString a => [a]
defaultFreshVars = mkDefaultFreshVars "x"

defaultFreshMetaVars :: IsString a => [a]
defaultFreshMetaVars = mkDefaultFreshVars "M"

mkDefaultFreshVars :: IsString a => String -> [a]
mkDefaultFreshVars prefix = [ fromString (prefix <> toIndex i) | i <- [1..] ]
  where
    toIndex n = index
      where
        digitToSub c = chr ((ord c - ord '0') + ord '₀')
        index = map digitToSub (show n)

instance (Pretty a, Pretty b, IsString a) => Show (TypedTerm b a) where
  show = show . ppTermWithType defaultFreshVars

ppTermWithType :: (Pretty a, Pretty b) => [a] -> TypedTerm b a -> Doc ann
ppTermWithType vars t = group $
  case t of
    FreeScoped (TypeCheck.TypedF _term ty) ->
      ppTypedTerm vars t <> nest 2 (line <> ":" <+> group (ppTypedTerm vars (fromMaybe universeT ty)))
    _ -> ppTypedTerm vars t

ppTypedTerm :: (Pretty a, Pretty b) => [a] -> TypedTerm b a -> Doc ann
ppTypedTerm vars = ppTerm vars . untyped

ppType :: (Pretty a, Pretty b) => [a] -> Term b a -> Doc ann
ppType vars = group . ppTerm vars

-- | Pretty-print an untyped term.
ppTerm :: (Pretty a, Pretty b) => [a] -> Term b a -> Doc ann
ppTerm vars = \case
  Var x -> pretty x

  Universe -> "U"

  Pi a b -> ppScopedTerm vars b $ \x b' ->
    if withoutBoundVars b
       then align (ppTermArg vars a <+> "→" <> line <> b')
       else align (parens (pretty x <+> ":" <+> ppType vars a) <+> "→" <> line <> b')
  Lam Nothing body -> ppScopedTerm vars body $ \x body' ->
    "λ" <> pretty x <+> "→" <+> body'
  Lam (Just ty) body -> ppScopedTerm vars body $ \x body' ->
    "λ" <> parens (pretty x <+> ":" <+> ppType vars ty) <+> "→" <+> body'
  App f x -> ppTermFun vars f <+> ppTermArg vars x

  Sigma a b -> ppScopedTerm vars b $ \x b' ->
    if withoutBoundVars b
       then ppTermArg vars a <+> "×" <> line <> b'
       else parens (pretty x <+> ":" <+> ppType vars a) <+> "×" <> line <> b'
  Pair f s -> tupled (map (group . ppTerm vars) [f, s])

  First t  -> ppElimWithArgs vars "π₁" [t]
  Second t -> ppElimWithArgs vars "π₂" [t]

  IdType a x y -> ppTermFun vars x <+> "=_{" <> ppType vars a <> "}" <+> ppTermFun vars y
  Refl Nothing x -> ppElimWithArgs vars "refl" [x]
  Refl (Just a) x -> ppElimWithArgs vars ("refl_{" <> ppType vars a <> "}") [x]

  J tA a tC d x p -> ppElimWithArgs vars "J" [tA, a, tC, d, x, p]
  where
    withoutBoundVars = null . Scope.bindings

ppElimWithArgs :: (Pretty a, Pretty b) => [a] -> Doc ann -> [Term b a] -> Doc ann
ppElimWithArgs vars name args = hsep (name : map (ppTermFun vars) args)

-- | Pretty-print an untyped in a head position.
ppTermFun :: (Pretty a, Pretty b) => [a] -> Term b a -> Doc ann
ppTermFun vars = group . \case
  t@Var{} -> ppTerm vars t
  t@App{} -> ppTerm vars t
  t@First{} -> ppTerm vars t
  t@Second{} -> ppTerm vars t
  t@Pair{} -> ppTerm vars t
  t@Refl{} -> ppTerm vars t
  t@J{} -> ppTerm vars t
  t@Universe{} -> ppTerm vars t

  t@Lam{} -> Doc.parens (ppTerm vars t)
  t@Sigma{} -> Doc.parens (ppTerm vars t)
  t@IdType{} -> Doc.parens (ppTerm vars t)
  t@Pi{} -> Doc.parens (ppTerm vars t)

-- | Pretty-print an untyped in an argument position.
ppTermArg :: (Pretty a, Pretty b) => [a] -> Term b a -> Doc ann
ppTermArg vars = group . \case
  t@Var{} -> ppTerm vars t
  t@Universe{} -> ppTerm vars t
  t@Pair{} -> ppTerm vars t

  t@App{} -> Doc.parens (ppTerm vars t)
  t@First{} -> Doc.parens (ppTerm vars t)
  t@Second{} -> Doc.parens (ppTerm vars t)
  t@Refl{} -> Doc.parens (ppTerm vars t)
  t@J{} -> Doc.parens (ppTerm vars t)
  t@Lam{} -> Doc.parens (ppTerm vars t)
  t@Pi{} -> Doc.parens (ppTerm vars t)
  t@Sigma{} -> Doc.parens (ppTerm vars t)
  t@IdType{} -> Doc.parens (ppTerm vars t)

ppScopedTerm
  :: (Pretty a, Pretty b)
  => [a] -> ScopedTerm b a -> (a -> Doc ann -> Doc ann) -> Doc ann
ppScopedTerm [] _ _            = error "not enough fresh names"
ppScopedTerm (x:xs) t withScope = withScope x (ppTerm xs (Scope.instantiate1 (Var x) t))

-- ** Examples

-- | Each example presents:
--
-- * an untyped term
-- * a typed term (with inferred type)
-- * extra type information (inferred types of free variables, known information about meta-variables, unresolved constraints, etc.)
--
-- @
-- Example #1:
-- fix (λx₁ → λx₂ → if (isZero x₂) then 1 else (x₂ * (x₁ (pred x₂))))
-- fix (λx₁ → λx₂ → if (isZero x₂) then 1 else (x₂ * (x₁ (pred x₂)))) : NAT → NAT
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = [(M₃,U : U),(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₃,NAT : U),(M₁,NAT → ?M₃ : U),(M₂,NAT : U)]
--   , constraints   = []
--   , freshMetaVars = [M₄,M₅,M₆,M₇,M₈,...]
--   }
--
--
-- Example #2:
-- λ(x₁ : (λx₁ → x₁) A) → (λx₂ → x₂) x₁
-- λ(x₁ : (λx₁ → x₁) A) → (λx₂ → x₂) x₁ : (λx₁ → x₁) A → (λx₁ → x₁) A
-- TypeInfo
--   { knownFreeVars = [(A,U : U)]
--   , knownMetaVars = [(M₃,U : U),(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₃,(λx₁ → x₁) A : U),(M₁,U : U),(M₂,?M₁)]
--   , constraints   = []
--   , freshMetaVars = [M₄,M₅,M₆,M₇,M₈,...]
--   }
--
--
-- Example #3:
-- let x₁ = λx₁ → λx₂ → x₂ in let x₂ = λx₂ → λx₃ → λx₄ → x₃ (x₂ x₃ x₄) in x₂ (x₂ x₁)
-- let x₁ = λx₁ → λx₂ → x₂ in let x₂ = λx₂ → λx₃ → λx₄ → x₃ (x₂ x₃ x₄) in x₂ (x₂ x₁) : (?M₇ → ?M₇) → ?M₇ → ?M₇
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = [(M₈,U : U),(M₇,U : U),(M₆,U : U),(M₅,U : U),(M₄,U : U),(M₃,U : U),(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₈,?M₇),(M₅,?M₇),(M₁,?M₇ → ?M₈ : U),(M₂,?M₇),(M₂,?M₅),(M₁,?M₇ → ?M₈ : U),(M₄,?M₇ → ?M₈ : U),(M₆,?M₅ → ?M₇ : U),(M₃,?M₄ → ?M₆ : U)]
--   , constraints   = []
--   , freshMetaVars = [M₉,M₁₀,M₁₁,M₁₂,M₁₃,...]
--   }
--
--
-- Example #4:
-- let x₁ = λx₁ → λx₂ → x₂ in x₁
-- let x₁ = λx₁ → λx₂ → x₂ in x₁ : ?M₁ → ?M₂ → ?M₂
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = [(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₃,M₄,M₅,M₆,M₇,...]
--   }
--
--
-- Example #5:
-- (λx₁ → x₁) (λx₁ → λx₂ → x₂)
-- (λx₁ → x₁) (λx₁ → λx₂ → x₂) : ?M₂ → ?M₃ → ?M₃
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = [(M₃,U : U),(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₁,?M₂ → ?M₃ → ?M₃ : U)]
--   , constraints   = []
--   , freshMetaVars = [M₄,M₅,M₆,M₇,M₈,...]
--   }
--
--
-- Example #6:
-- let x₁ = unit in unit
-- let x₁ = unit in unit : UNIT
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = []
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₁,M₂,M₃,M₄,M₅,...]
--   }
--
--
-- Example #7:
-- let x₁ = unit in x₁
-- let x₁ = unit in x₁ : UNIT
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = []
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₁,M₂,M₃,M₄,M₅,...]
--   }
--
--
-- Example #8:
-- λx₁ → λx₂ → x₁ x₂
-- λx₁ → λx₂ → x₁ x₂ : (?M₂ → ?M₃) → ?M₂ → ?M₃
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = [(M₃,U : U),(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₁,?M₂ → ?M₃ : U)]
--   , constraints   = []
--   , freshMetaVars = [M₄,M₅,M₆,M₇,M₈,...]
--   }
--
--
-- Example #9:
-- λ(x₁ : UNIT → UNIT) → λ(x₂ : UNIT) → x₁ x₂
-- λ(x₁ : UNIT → UNIT) → λ(x₂ : UNIT) → x₁ x₂ : (UNIT → UNIT) → UNIT → UNIT
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = []
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₁,M₂,M₃,M₄,M₅,...]
--   }
--
--
-- Example #10:
-- λ(x₁ : A → B) → λ(x₂ : A) → x₁ x₂
-- λ(x₁ : A → B) → λ(x₂ : A) → x₁ x₂ : (A → B) → A → B
-- TypeInfo
--   { knownFreeVars = [(B,U : U),(A,U : U)]
--   , knownMetaVars = [(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₂,U : U),(M₁,U : U)]
--   , constraints   = []
--   , freshMetaVars = [M₃,M₄,M₅,M₆,M₇,...]
--   }
--
--
-- Example #11:
-- λx₁ → λx₂ → x₂
-- λx₁ → λx₂ → x₂ : ?M₁ → ?M₂ → ?M₂
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = [(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₃,M₄,M₅,M₆,M₇,...]
--   }
--
--
-- Example #12:
-- λx₁ → λx₂ → x₁
-- λx₁ → λx₂ → x₁ : ?M₁ → ?M₂ → ?M₁
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = [(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₃,M₄,M₅,M₆,M₇,...]
--   }
--
--
-- Example #13:
-- λ(x₁ : A → B) → λx₂ → x₁ x₂
-- λ(x₁ : A → B) → λx₂ → x₁ x₂ : (A → B) → A → B
-- TypeInfo
--   { knownFreeVars = [(B,U : U),(A,U : U)]
--   , knownMetaVars = [(M₃,U : U),(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₃,A),(M₂,U : U),(M₁,U : U)]
--   , constraints   = []
--   , freshMetaVars = [M₄,M₅,M₆,M₇,M₈,...]
--   }
--
--
-- Example #14:
-- λx₁ → x₁
-- λx₁ → x₁ : ?M₁ → ?M₁
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = [(M₁,U : U)]
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₂,M₃,M₄,M₅,M₆,...]
--   }
--
--
-- Example #15:
-- λ(x₁ : A) → x₁
-- λ(x₁ : A) → x₁ : A → A
-- TypeInfo
--   { knownFreeVars = [(A,U : U)]
--   , knownMetaVars = [(M₁,U : U)]
--   , knownSubsts   = [(M₁,U : U)]
--   , constraints   = []
--   , freshMetaVars = [M₂,M₃,M₄,M₅,M₆,...]
--   }
--
--
-- Example #16:
-- λ(x₁ : A → B) → x₁
-- λ(x₁ : A → B) → x₁ : (A → B) → A → B
-- TypeInfo
--   { knownFreeVars = [(B,U : U),(A,U : U)]
--   , knownMetaVars = [(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₂,U : U),(M₁,U : U)]
--   , constraints   = []
--   , freshMetaVars = [M₃,M₄,M₅,M₆,M₇,...]
--   }
--
--
-- Example #17:
-- λx₁ → x₁ x₁
-- Type Error: TypeErrorOther "unable to unify ..."
--
-- Example #18:
-- λx₁ → x₁ unit
-- λx₁ → x₁ unit : (UNIT → ?M₂) → ?M₂
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = [(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₁,UNIT → ?M₂ : U)]
--   , constraints   = []
--   , freshMetaVars = [M₃,M₄,M₅,M₆,M₇,...]
--   }
--
--
-- Example #19:
-- A → UNIT
-- A → UNIT : U
-- TypeInfo
--   { knownFreeVars = [(A,U : U)]
--   , knownMetaVars = [(M₁,U : U)]
--   , knownSubsts   = [(M₁,U : U)]
--   , constraints   = []
--   , freshMetaVars = [M₂,M₃,M₄,M₅,M₆,...]
--   }
--
--
-- Example #20:
-- A → B
-- A → B : U
-- TypeInfo
--   { knownFreeVars = [(B,U : U),(A,U : U)]
--   , knownMetaVars = [(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₂,U : U),(M₁,U : U)]
--   , constraints   = []
--   , freshMetaVars = [M₃,M₄,M₅,M₆,M₇,...]
--   }
--
--
-- Example #21:
-- λx₁ → λ(x₂ : UNIT) → x₁ (x₁ x₂)
-- λx₁ → λ(x₂ : UNIT) → x₁ (x₁ x₂) : (UNIT → UNIT) → UNIT → UNIT
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = [(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₂,UNIT : U),(M₁,UNIT → ?M₂ : U)]
--   , constraints   = []
--   , freshMetaVars = [M₃,M₄,M₅,M₆,M₇,...]
--   }
--
--
-- Example #22:
-- unit
-- unit : UNIT
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = []
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₁,M₂,M₃,M₄,M₅,...]
--   }
--
--
-- Example #23:
-- unit unit
-- Type Error: TypeErrorOther "inferTypeForF: application of a non-function"
--
-- Example #24:
-- UNIT
-- UNIT : U
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = []
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₁,M₂,M₃,M₄,M₅,...]
--   }
--
--
-- Example #25:
-- x
-- x
-- TypeInfo
--   { knownFreeVars = [(x,?M₁)]
--   , knownMetaVars = [(M₁,U : U)]
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₂,M₃,M₄,M₅,M₆,...]
--   }
--
--
-- Example #26:
-- f unit
-- f unit : ?M₂
-- TypeInfo
--   { knownFreeVars = [(f,UNIT → ?M₂ : U)]
--   , knownMetaVars = [(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₁,UNIT → ?M₂ : U)]
--   , constraints   = [(?M₂,?M₂)]
--   , freshMetaVars = [M₃,M₄,M₅,M₆,M₇,...]
--   }
--
--
-- Example #27:
-- f (f unit)
-- f (f unit) : UNIT
-- TypeInfo
--   { knownFreeVars = [(f,UNIT → UNIT : U)]
--   , knownMetaVars = [(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₂,UNIT : U),(M₁,UNIT → ?M₂ : U)]
--   , constraints   = []
--   , freshMetaVars = [M₃,M₄,M₅,M₆,M₇,...]
--   }
--
--
-- Example #28:
-- unit → unit
-- Type Error: TypeErrorOther "unable to unify ..."
--
-- Example #29:
-- UNIT → UNIT
-- UNIT → UNIT : U
-- TypeInfo
--   { knownFreeVars = []
--   , knownMetaVars = []
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₁,M₂,M₃,M₄,M₅,...]
--   }
--
--
-- Example #30:
-- x
-- x
-- TypeInfo
--   { knownFreeVars = [(x,?M₁)]
--   , knownMetaVars = [(M₁,U : U)]
--   , knownSubsts   = []
--   , constraints   = []
--   , freshMetaVars = [M₂,M₃,M₄,M₅,M₆,...]
--   }
--
--
-- Example #31:
-- f x
-- f x : ?M₃
-- TypeInfo
--   { knownFreeVars = [(x,?M₂),(f,?M₂ → ?M₃ : U)]
--   , knownMetaVars = [(M₃,U : U),(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₁,?M₂ → ?M₃ : U)]
--   , constraints   = [(?M₂,?M₂),(?M₃,?M₃)]
--   , freshMetaVars = [M₄,M₅,M₆,M₇,M₈,...]
--   }
--
--
-- Example #32:
-- λ(x₁ : unit) → x₁
-- Type Error: TypeErrorOther "unable to unify ..."
--
-- Example #33:
-- λ(x₁ : unit) → y
-- Type Error: TypeErrorOther "unable to unify ..."
--
-- Example #34:
-- λ(x₁ : A) → x₁
-- λ(x₁ : A) → x₁ : A → A
-- TypeInfo
--   { knownFreeVars = [(A,U : U)]
--   , knownMetaVars = [(M₁,U : U)]
--   , knownSubsts   = [(M₁,U : U)]
--   , constraints   = []
--   , freshMetaVars = [M₂,M₃,M₄,M₅,M₆,...]
--   }
--
--
-- Example #35:
-- λ(x₁ : A → B) → x₁
-- λ(x₁ : A → B) → x₁ : (A → B) → A → B
-- TypeInfo
--   { knownFreeVars = [(B,U : U),(A,U : U)]
--   , knownMetaVars = [(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₂,U : U),(M₁,U : U)]
--   , constraints   = []
--   , freshMetaVars = [M₃,M₄,M₅,M₆,M₇,...]
--   }
--
--
-- Example #36:
-- λ(x₁ : (λx₁ → λx₂ → x₁ (x₁ (x₁ (x₁ (x₁ x₂))))) (λx₁ → λx₂ → x₁ (x₁ (x₁ (x₁ (x₁ (x₁ x₂)))))) (λx₁ → x₁) A) → (λx₂ → x₂) x₁
-- λ(x₁ : (λx₁ → λx₂ → x₁ (x₁ (x₁ (x₁ (x₁ x₂))))) (λx₁ → λx₂ → x₁ (x₁ (x₁ (x₁ (x₁ (x₁ x₂)))))) (λx₁ → x₁) A) → (λx₂ → x₂) x₁ : (λx₁ → λx₂ → x₁ (x₁ (x₁ (x₁ (x₁ x₂))))) (λx₁ → λx₂ → x₁ (x₁ (x₁ (x₁ (x₁ (x₁ x₂)))))) (λx₁ → x₁) A → (λx₁ → λx₂ → x₁ (x₁ (x₁ (x₁ (x₁ x₂))))) (λx₁ → λx₂ → x₁ (x₁ (x₁ (x₁ (x₁ (x₁ x₂)))))) (λx₁ → x₁) A
-- TypeInfo
--   { knownFreeVars = [(A,U : U)]
--   , knownMetaVars = [(M₉,U : U),(M₈,U : U),(M₇,U : U),(M₆,U : U),(M₅,U : U),(M₄,U : U),(M₃,U : U),(M₂,U : U),(M₁,U : U)]
--   , knownSubsts   = [(M₉,(λx₁ → λx₂ → x₁ (x₁ (x₁ (x₁ (x₁ x₂))))) (λx₁ → λx₂ → x₁ (x₁ (x₁ (x₁ (x₁ (x₁ x₂)))))) (λx₁ → x₁) A : U),(M₅,U : U),(M₈,?M₅),(M₇,?M₅),(M₇,?M₅),(M₂,?M₅ → ?M₅ : U),(M₂,?M₅ → ?M₅ : U),(M₂,?M₅ → ?M₅ : U),(M₆,?M₅),(M₄,?M₅ → ?M₆ : U),(M₃,?M₂),(M₁,?M₂ → ?M₃ : U)]
--   , constraints   = []
--   , freshMetaVars = [M₁₀,M₁₁,M₁₂,M₁₃,M₁₄,...]
--   }
-- @
examples :: IO ()
examples = mapM_ runExample . zip [1..] $
  [ lam_ "A" (lam_ "x" (Refl Nothing (Var "x")))

  , lam_ "A" (lam (Just (Var "A")) "x" (Refl Nothing (Var "x")))

  , lam_ "A" (lam_ "x" (Refl (Just (Var "A")) (Var "x")))

  , lam (Just (App (lam_ "x" (Var "x")) (Var "A"))) "x" (App (lam_ "y" (Var "y")) (Var "x")) -- ok (fixed)

  , lam Nothing "f" $
      lam Nothing "x" $
        App (Var "f") (Var "x") -- ok (fixed)

  , lam (Just (mkFun (Var "A") (Var "B"))) "f" $
      lam (Just (Var "A")) "x" $
        App (Var "f") (Var "x") -- ok (fixed)

  , lam Nothing "x" $
      lam Nothing "x" $
        Var "x" -- ok

  , lam Nothing "x" $
      lam Nothing "y" $
        Var "x" -- ok (fixed)

  , lam (Just (mkFun (Var "A") (Var "B"))) "f" $
      lam Nothing "x" $
        App (Var "f") (Var "x") -- ok

  , lam Nothing "x" $
      Var "x" -- ok

  , lam (Just (Var "A")) "x" $
      Var "x" -- ok

  , lam (Just (mkFun (Var "A") (Var "B"))) "f" $
      Var "f" -- ok

  , lam Nothing "f" $
      App (Var "f") (Var "f")  -- ok: type error

  , mkFun (Var "A") (Var "B") -- ok (looped because of unsafeCoerce)

  , Var "x"               -- ok-ish

  , Var "x"
  , App (Var "f") (Var "x")
  , lam (Just (Var "A")) "x" (Var "x")
  , lam (Just (mkFun (Var "A") (Var "B"))) "x" (Var "x")

  , lam (Just (App (App (App (ex_nat 5) (ex_nat 6)) (lam_ "x" (Var "x"))) (Var "A"))) "x" (App (lam_ "z" (Var "z")) (Var "x")) -- FIXME: optimize to avoid recomputation of whnf

  ]

runExample :: (Int, Term') -> IO ()
runExample (n, term) = do
  putStrLn ("Example #" <> show n <> ":")
  -- putStr   "[input term]:          "
  print term
  -- _ <- getLine
  -- putStr   "[with inferred types]: "
  case runTypeCheckOnce' (TypeCheck.infer term) of
    Left err -> putStrLn ("Type Error: " <> show err)
    Right (typedTerm, typeInfo) -> do
      print typedTerm
      print typeInfo
  putStrLn ""
  _ <- getLine
  return ()

runExample_ :: Term' -> IO ()
runExample_ = runExample . (,) 0

-- *** Church numerals

-- |
-- > ex_zero
-- λx₁ → λx₂ → x₂
--
-- > execTypeCheck' (infer' ex_zero)
-- Right λx₁ → λx₂ → x₂ : ?M₁ → ?M₂ → ?M₂
ex_zero :: Term'
ex_zero = lam_ "s" (lam_ "z" (Var "z"))

-- |
-- > ex_nat 3
-- λx₁ → λx₂ → x₁ (x₁ (x₁ x₂))
--
-- > execTypeCheck' (infer' (ex_nat 3))
-- Right λx₁ → λx₂ → x₁ (x₁ (x₁ x₂)) : (?M₂ → ?M₂) → ?M₂ → ?M₂
ex_nat :: Int -> Term'
ex_nat n = lam_ "s" (lam_ "z" (iterate (App (Var "s")) (Var "z") !! n))

-- |
-- > ex_add
-- λx₁ → λx₂ → λx₃ → λx₄ → x₁ x₃ (x₂ x₃ x₄)
--
-- > unsafeInfer' ex_add
-- λx₁ → λx₂ → λx₃ → λx₄ → x₁ x₃ (x₂ x₃ x₄) : (?M₃ → ?M₇ → ?M₈) → (?M₃ → ?M₄ → ?M₇) → ?M₃ → ?M₄ → ?M₈
ex_add :: Term'
ex_add = lam_ "n" (lam_ "m" (lam_ "s" (lam_ "z"
  (App (App (Var "n") (Var "s")) (App (App (Var "m") (Var "s")) (Var "z"))))))

-- |
-- > ex_mul
-- λx₁ → λx₂ → λx₃ → x₁ (x₂ x₃)
-- > unsafeInfer' ex_mul
-- λx₁ → λx₂ → λx₃ → x₁ (x₂ x₃) : (?M₄ → ?M₅) → (?M₃ → ?M₄) → ?M₃ → ?M₅
ex_mul :: Term'
ex_mul = lam_ "n" (lam_ "m" (lam_ "s"
  (App (Var "n") (App (Var "m") (Var "s")))))

-- |
-- > ex_mkPair (Var "x") (Var "y")
-- λx₁ → x₁ x y
ex_mkPair :: Term' -> Term' -> Term'
ex_mkPair t1 t2 = lam_ "_ex_mkPair" (App (App (Var "_ex_mkPair") t1) t2)

-- |
-- > ex_fst
-- λx₁ → x₁ (λx₂ → λx₃ → x₂)
-- > unsafeInfer' ex_fst
-- λx₁ → x₁ (λx₂ → λx₃ → x₂) : ((?M₂ → ?M₃ → ?M₂) → ?M₄) → ?M₄
ex_fst :: Term'
ex_fst = lam_ "p" (App (Var "p") (lam_ "f" (lam_ "s" (Var "f"))))

-- |
-- > ex_snd
-- λx₁ → x₁ (λx₂ → λx₃ → x₃)
-- > unsafeInfer' ex_snd
-- λx₁ → x₁ (λx₂ → λx₃ → x₃) : ((?M₂ → ?M₃ → ?M₃) → ?M₄) → ?M₄
ex_snd :: Term'
ex_snd = lam_ "p" (App (Var "p") (lam_ "f" (lam_ "s" (Var "s"))))

-- |
-- > ex_pred
-- λx₁ → (λx₂ → x₂ (λx₃ → λx₄ → x₃)) (x₁ (λx₂ → λx₃ → x₃ ((λx₄ → x₄ (λx₅ → λx₆ → x₆)) x₂) ((λx₄ → λx₅ → λx₆ → λx₇ → x₄ x₆ (x₅ x₆ x₇)) ((λx₄ → x₄ (λx₅ → λx₆ → x₆)) x₂) (λx₄ → λx₅ → x₄ x₅))) (λx₂ → x₂ (λx₃ → λx₄ → x₄) (λx₃ → λx₄ → x₄)))
-- > unsafeInfer' ex_pred
-- λx₁ → (λx₂ → x₂ (λx₃ → λx₄ → x₃)) (x₁ (λx₂ → λx₃ → x₃ ((λx₄ → x₄ (λx₅ → λx₆ → x₆)) x₂) ((λx₄ → λx₅ → λx₆ → λx₇ → x₄ x₆ (x₅ x₆ x₇)) ((λx₄ → x₄ (λx₅ → λx₆ → x₆)) x₂) (λx₄ → λx₅ → x₄ x₅))) (λx₂ → x₂ (λx₃ → λx₄ → x₄) (λx₃ → λx₄ → x₄))) : ((((?M₂₂ → ?M₂₃ → ?M₂₃) → (?M₁₆ → ?M₁₉) → ?M₁₉ → ?M₂₀) → (((?M₁₆ → ?M₁₉) → ?M₁₉ → ?M₂₀) → ((?M₁₆ → ?M₁₉) → ?M₁₆ → ?M₂₀) → ?M₂₈) → ?M₂₈) → (((?M₃₁ → ?M₃₂ → ?M₃₂) → (?M₃₄ → ?M₃₅ → ?M₃₅) → ?M₃₆) → ?M₃₆) → (?M₃ → ?M₄ → ?M₃) → ?M₅) → ?M₅
ex_pred :: Term'
ex_pred = lam_ "n" (App ex_fst (App (App (Var "n") (lam_ "p" (ex_mkPair (App ex_snd (Var "p")) (App (App ex_add (App ex_snd (Var "p"))) (ex_nat 1))))) (ex_mkPair ex_zero ex_zero)))

-- | \(\eta\)-expanded J path eliminator:
--
-- >>> unsafeInfer' ex_J
-- λx₁ → λx₂ → λx₃ → λx₄ → λx₅ → λx₆ → J x₁ x₂ x₃ x₄ x₅ x₆
-- : (x₁ : U) → (x₂ : x₁) → (x₃ : (x₃ : x₁) → (x₂ =_{x₁} x₃) → U) → (x₃ x₂ (refl_{x₁} x₂)) → (x₅ : x₁) → (x₆ : x₂ =_{x₁} x₅) → x₃ x₅ x₆
ex_J :: Term'
ex_J =
  lam_ "A" $ lam_ "a" $ lam_ "C" $ lam_ "d" $ lam_ "x" $ lam_ "p" $
    J (Var "A") (Var "a") (Var "C") (Var "d") (Var "x") (Var "p")

-- | An example proof of symmetry for path type:
--
-- >>> unsafeInfer' ex_pathinv
-- λx₁ → λx₂ → λx₃ → λx₄ → J x₁ x₂ (λx₅ → λx₆ → x₅ =_{x₁} x₂) refl x₂ x₃ x₄
-- : (x₁ : U) → (x₂ : x₁) → (x₃ : x₁) → (x₂ =_{x₁} x₃) → x₃ =_{x₁} x₂
ex_pathinv :: Term'
ex_pathinv =
  lam_ "A" $
    lam_ "x" $
    lam_ "y" $
      lam_ "p" $
        J (Var "A")
          (Var "x")
          (lam_ "z" $
            lam_ "q" $
              IdType (Var "A") (Var "z") (Var "x"))
          (Refl Nothing (Var "x"))
          (Var "y")
          (Var "p")

-- | An example proof of transitivity for path type:
--
-- >>> unsafeInfer' ex_pathtrans
-- λx₁ → λx₂ → λx₃ → λx₄ → λx₅ → λx₆ → J x₁ x₃ (λx₇ → λx₈ → x₂ =_{x₁} x₇) x₅ x₄ x₆
-- : (x₁ : U) → (x₂ : x₁) → (x₃ : x₁) → (x₄ : x₁) → (x₂ =_{x₁} x₃) → (x₃ =_{x₁} x₄) → x₂ =_{x₁} x₄
ex_pathtrans :: Term'
ex_pathtrans =
  lam_ "A" $
    lam_ "x" $
    lam_ "y" $
    lam_ "z" $
      lam_ "p" $
      lam_ "q" $
        J (Var "A")
          (Var "y")
          (lam_ "w" $
            lam_ "s" $
              IdType (Var "A") (Var "x") (Var "w"))
          (Var "p")
          (Var "z")
          (Var "q")

-- * Parsing

pOperatorTable :: (TokenParsing m, Monad m) => OperatorTable m Term'
pOperatorTable =
  [ [ Infix (pure App) AssocLeft ]
  , [ Infix (IdType <$ symbol "=_{" <*> pTerm <* symbol "}") AssocNone]
  , [ Infix (mkProdType <$ symbol "*") AssocRight ]
  , [ Infix (mkFun <$ symbol "->") AssocRight ]
  ]

pTerm :: (TokenParsing m, Monad m) => m Term'
pTerm = buildExpressionParser pOperatorTable pNotAppTerm

pNotAppTerm :: (TokenParsing m, Monad m) => m Term'
pNotAppTerm = Trifecta.choice
  [ Trifecta.try pPi
  , Trifecta.try pSigma
  , Trifecta.try pPair
  , pNotPiSigmaTerm
  ]

pNotPiSigmaTerm :: (TokenParsing m, Monad m) => m Term'
pNotPiSigmaTerm = Trifecta.choice
  [ Universe <$ symbol "U"
  , First <$  (symbol "first" <|> symbol "π₁")
          <*> Trifecta.parens pTerm
  , Second <$  (symbol "second" <|> symbol "π₂")
          <*> Trifecta.parens pTerm
  , Refl <$ symbol "refl_{"
         <*> (Just <$> pTerm)
         <* symbol "}"
         <*> Trifecta.parens pTerm
  , Refl Nothing
         <$ symbol "refl"
         <*> Trifecta.parens pTerm
  , symbol "J" *> Trifecta.parens
      (J <$> pTerm <* Trifecta.comma
         <*> pTerm <* Trifecta.comma
         <*> pTerm <* Trifecta.comma
         <*> pTerm <* Trifecta.comma
         <*> pTerm <* Trifecta.comma
         <*> pTerm )
  -- , lam_ "x" (First (Var "x")) <$ (symbol "first" <|> symbol "π₁")
  -- , lam_ "x" (Second (Var "x")) <$ (symbol "second" <|> symbol "π₂")
  -- , (\ty -> lam_ "x" (Refl (Just ty) (Var "x")))
  --    <$ symbol "refl_{" <*> pTerm <* symbol "}"
  -- , lam_ "x" (Refl Nothing (Var "x"))
  --    <$ symbol "refl"
  -- , etaJ <$ symbol "J"
  , pVar
  , pLam
  , Trifecta.parens pTerm
  ]

pPi :: (TokenParsing m, Monad m) => m Term'
pPi = Trifecta.parens arg <* symbol "->" <*> pTerm
  where
    arg = pi_ <$> pIdent <* symbol ":" <*> pTerm

pSigma :: (TokenParsing m, Monad m) => m Term'
pSigma = Trifecta.parens arg <* (symbol "*" <|> symbol "×") <*> pTerm
  where
    arg = pi_ <$> pIdent <* symbol ":" <*> pTerm

pPair :: (TokenParsing m, Monad m) => m Term'
pPair = Trifecta.parens $
  Pair <$> pTerm <* Trifecta.comma <*> pTerm

--   = UniverseF
--
--   -- | Type of functions: \(A \to B\)
--   | PiF term scope
--   -- | Lambda function with an optional argument type: \(\lambda (x : A). t\)
--   | LamF (Maybe term) scope
--   -- | Application of one term to another: \((t_1) t_2\)
--   | AppF term term
--
--   -- | Dependent sum type former \(\sum_{x : A} B(x)\).
--   -- The term argument represents type family \(B : A \to \mathcal{U}\).
--   | SigmaF term scope
--   -- | A (dependent) pair of terms.
--   -- @Pair x y@ represents a term of the form \((x, y)\).
--   | PairF term term
--   -- | Project the first element of a pair: \(\pi_1 p\).
--   | FirstF term
--   -- | Project the second element of a pair: \(\pi_2 p\).
--   | SecondF term
--
--   -- | Identity type former \(x =_A y\) (corresponding to term @IdType a x y@).
--   | IdTypeF term term term
--   -- | Trivial inhabitant of \(x =_A x\) for any type \(A\) and \(x : A\).
--   -- @Refl a x@ corresponds to \(x =_a x\).
--   | ReflF (Maybe term) term
--   -- | Path induction (for identity types).
--   -- For any type \(A\) and \(a : A\), type family
--   -- \(C : \prod_{x : A} ((a =_A x) \to \mathcal{U})\)
--   -- and \(d : C(a,\mathsf{refl}_a)\)
--   -- and \(x : A\)
--   -- and \(p : a =_A x\)
--   -- we have \(\mathcal{J}(A, a, C, d, x, p) : C(x, p)\).
--   | JF term term term term term term

pVar :: (TokenParsing m, Monad m) => m Term'
pVar = Var <$> pIdent

pIdent :: (TokenParsing m, Monad m) => m Rzk.Var
pIdent = Rzk.Var . Text.pack <$> Trifecta.ident pIdentStyle

pIdentStyle :: (TokenParsing m, Monad m) => IdentifierStyle m
pIdentStyle = (emptyIdents @Parser)
  { _styleStart     = Trifecta.satisfy isIdentChar
  , _styleLetter    = Trifecta.satisfy isIdentChar
  , _styleReserved  = HashSet.fromList [ "λ", "\\", "→", "->"
                                       , "let", "in"
                                       , "fix"
                                       , "UNIT", "unit"
                                       , "NAT"
                                       , "BOOL", "false", "true"
                                       , "if", "then", "else"
                                       , "=_{", "}"
                                       , "--", ":=", ":" ]
  }

pLam :: (TokenParsing m, Monad m) => m Term'
pLam = do
  _ <- symbol "λ" <|> symbol "\\"
  (x, ty) <- Trifecta.choice
    [ (,Nothing) <$> pIdent
    , Trifecta.parens $
        (,) <$> pIdent <* symbol ":" <*> (Just <$> pTerm)
    ]
  _ <- symbol "->" <|> symbol "→"
  t <- pTerm
  return (Lam ty (abstract1Name x t))

-- ** Char predicates

isIdentChar :: Char -> Bool
isIdentChar c = isPrint c && not (isSpace c) && not (isDelim c)

isDelim :: Char -> Bool
isDelim c = c `elem` ("()[]{}=,\\λ→#" :: String)

-- * Orphan 'IsString' instances

instance IsString Term' where
  fromString = unsafeParseTerm

unsafeParseTerm :: String -> Term'
unsafeParseTerm = unsafeParseString pTerm

unsafeParseString :: Parser a -> String -> a
unsafeParseString parser input =
  case Trifecta.parseString parser mempty input of
    Trifecta.Success x       -> x
    Trifecta.Failure errInfo -> unsafePerformIO $ do
      putDoc (Trifecta._errDoc errInfo <> "\n")
      error "Parser error while attempting unsafeParseString"

deriveBifunctor ''TermF
deriveBifoldable ''TermF
deriveBitraversable ''TermF
