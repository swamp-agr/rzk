-- File generated by the BNF Converter (bnfc 2.9.5).

{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE PatternSynonyms #-}

-- | The abstract syntax of language Syntax.

module Language.Rzk.Syntax.Abs where

import Prelude (String)
import qualified Prelude as C
  ( Eq, Ord, Show, Read
  , Functor, Foldable, Traversable
  , Int, Maybe(..)
  )
import qualified Data.String

import qualified Data.Data    as C (Data, Typeable)
import qualified GHC.Generics as C (Generic)

type Module = Module' BNFC'Position
data Module' a = Module a (LanguageDecl' a) [Command' a]
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type HoleIdent = HoleIdent' BNFC'Position
data HoleIdent' a = HoleIdent a HoleIdentToken
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type VarIdent = VarIdent' BNFC'Position
data VarIdent' a = VarIdent a VarIdentToken
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type LanguageDecl = LanguageDecl' BNFC'Position
data LanguageDecl' a = LanguageDecl a (Language' a)
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type Language = Language' BNFC'Position
data Language' a = Rzk1 a
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type Command = Command' BNFC'Position
data Command' a
    = CommandSetOption a String String
    | CommandUnsetOption a String
    | CommandCheck a (Term' a) (Term' a)
    | CommandCompute a (Term' a)
    | CommandComputeWHNF a (Term' a)
    | CommandComputeNF a (Term' a)
    | CommandPostulate a (VarIdent' a) (DeclUsedVars' a) [Param' a] (Term' a)
    | CommandAssume a [VarIdent' a] (Term' a)
    | CommandSection a (SectionName' a)
    | CommandSectionEnd a (SectionName' a)
    | CommandDefine a (VarIdent' a) (DeclUsedVars' a) [Param' a] (Term' a) (Term' a)
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type DeclUsedVars = DeclUsedVars' BNFC'Position
data DeclUsedVars' a = DeclUsedVars a [VarIdent' a]
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type SectionName = SectionName' BNFC'Position
data SectionName' a
    = NoSectionName a | SomeSectionName a (VarIdent' a)
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type Pattern = Pattern' BNFC'Position
data Pattern' a
    = PatternUnit a
    | PatternVar a (VarIdent' a)
    | PatternPair a (Pattern' a) (Pattern' a)
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type Param = Param' BNFC'Position
data Param' a
    = ParamPattern a (Pattern' a)
    | ParamPatternType a [Pattern' a] (Term' a)
    | ParamPatternShape a [Pattern' a] (Term' a) (Term' a)
    | ParamPatternShapeDeprecated a (Pattern' a) (Term' a) (Term' a)
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type ParamDecl = ParamDecl' BNFC'Position
data ParamDecl' a
    = ParamType a (Term' a)
    | ParamTermType a (Term' a) (Term' a)
    | ParamTermShape a (Term' a) (Term' a) (Term' a)
    | ParamTermTypeDeprecated a (Pattern' a) (Term' a)
    | ParamVarShapeDeprecated a (Pattern' a) (Term' a) (Term' a)
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type SigmaParam = SigmaParam' BNFC'Position
data SigmaParam' a = SigmaParam a (Pattern' a) (Term' a)
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type Restriction = Restriction' BNFC'Position
data Restriction' a
    = Restriction a (Term' a) (Term' a)
    | ASCII_Restriction a (Term' a) (Term' a)
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

type Term = Term' BNFC'Position
data Term' a
    = Universe a
    | UniverseCube a
    | UniverseTope a
    | CubeUnit a
    | CubeUnitStar a
    | Cube2 a
    | Cube2_0 a
    | Cube2_1 a
    | CubeProduct a (Term' a) (Term' a)
    | TopeTop a
    | TopeBottom a
    | TopeEQ a (Term' a) (Term' a)
    | TopeLEQ a (Term' a) (Term' a)
    | TopeAnd a (Term' a) (Term' a)
    | TopeOr a (Term' a) (Term' a)
    | RecBottom a
    | RecOr a [Restriction' a]
    | RecOrDeprecated a (Term' a) (Term' a) (Term' a) (Term' a)
    | TypeFun a (ParamDecl' a) (Term' a)
    | TypeSigma a (Pattern' a) (Term' a) (Term' a)
    | TypeSigmaNested a (SigmaParam' a) [SigmaParam' a] (Term' a)
    | TypeUnit a
    | TypeId a (Term' a) (Term' a) (Term' a)
    | TypeIdSimple a (Term' a) (Term' a)
    | TypeRestricted a (Term' a) [Restriction' a]
    | TypeExtensionDeprecated a (ParamDecl' a) (Term' a)
    | App a (Term' a) (Term' a)
    | Lambda a [Param' a] (Term' a)
    | Pair a (Term' a) (Term' a)
    | First a (Term' a)
    | Second a (Term' a)
    | Unit a
    | Refl a
    | ReflTerm a (Term' a)
    | ReflTermType a (Term' a) (Term' a)
    | IdJ a (Term' a) (Term' a) (Term' a) (Term' a) (Term' a) (Term' a)
    | Hole a (HoleIdent' a)
    | Var a (VarIdent' a)
    | TypeAsc a (Term' a) (Term' a)
    | ASCII_CubeUnitStar a
    | ASCII_Cube2_0 a
    | ASCII_Cube2_1 a
    | ASCII_TopeTop a
    | ASCII_TopeBottom a
    | ASCII_TopeEQ a (Term' a) (Term' a)
    | ASCII_TopeLEQ a (Term' a) (Term' a)
    | ASCII_TopeAnd a (Term' a) (Term' a)
    | ASCII_TopeOr a (Term' a) (Term' a)
    | ASCII_TypeFun a (ParamDecl' a) (Term' a)
    | ASCII_TypeSigma a (Pattern' a) (Term' a) (Term' a)
    | ASCII_Lambda a [Param' a] (Term' a)
    | ASCII_TypeExtensionDeprecated a (ParamDecl' a) (Term' a)
    | ASCII_First a (Term' a)
    | ASCII_Second a (Term' a)
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Functor, C.Foldable, C.Traversable, C.Data, C.Typeable, C.Generic)

commandPostulateNoParams :: a -> VarIdent' a -> DeclUsedVars' a -> Term' a -> Command' a
commandPostulateNoParams = \ _a x vars ty -> CommandPostulate _a x vars [] ty

commandVariable :: a -> VarIdent' a -> Term' a -> Command' a
commandVariable = \ _a name term -> CommandAssume _a [name] term

commandVariables :: a -> [VarIdent' a] -> Term' a -> Command' a
commandVariables = \ _a names term -> CommandAssume _a names term

commandDefineNoParams :: a -> VarIdent' a -> DeclUsedVars' a -> Term' a -> Term' a -> Command' a
commandDefineNoParams = \ _a x vars ty term -> CommandDefine _a x vars [] ty term

commandDef :: a -> VarIdent' a -> DeclUsedVars' a -> [Param' a] -> Term' a -> Term' a -> Command' a
commandDef = \ _a x vars params ty term -> CommandDefine _a x vars params ty term

commandDefNoParams :: a -> VarIdent' a -> DeclUsedVars' a -> Term' a -> Term' a -> Command' a
commandDefNoParams = \ _a x vars ty term -> CommandDefine _a x vars [] ty term

noDeclUsedVars :: a -> DeclUsedVars' a
noDeclUsedVars = \ _a -> DeclUsedVars _a []

paramVarShapeDeprecated :: a -> Pattern' a -> Term' a -> Term' a -> ParamDecl' a
paramVarShapeDeprecated = \ _a pat cube tope -> ParamVarShapeDeprecated _a pat cube tope

ascii_CubeProduct :: a -> Term' a -> Term' a -> Term' a
ascii_CubeProduct = \ _a l r -> CubeProduct _a l r

unicode_TypeSigmaAlt :: a -> Pattern' a -> Term' a -> Term' a -> Term' a
unicode_TypeSigmaAlt = \ _a pat fst snd -> TypeSigma _a pat fst snd

newtype VarIdentToken = VarIdentToken String
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Data, C.Typeable, C.Generic, Data.String.IsString)

newtype HoleIdentToken = HoleIdentToken String
  deriving (C.Eq, C.Ord, C.Show, C.Read, C.Data, C.Typeable, C.Generic, Data.String.IsString)

-- | Start position (line, column) of something.

type BNFC'Position = C.Maybe (C.Int, C.Int)

pattern BNFC'NoPosition :: BNFC'Position
pattern BNFC'NoPosition = C.Nothing

pattern BNFC'Position :: C.Int -> C.Int -> BNFC'Position
pattern BNFC'Position line col = C.Just (line, col)

-- | Get the start position of something.

class HasPosition a where
  hasPosition :: a -> BNFC'Position

instance HasPosition Module where
  hasPosition = \case
    Module p _ _ -> p

instance HasPosition HoleIdent where
  hasPosition = \case
    HoleIdent p _ -> p

instance HasPosition VarIdent where
  hasPosition = \case
    VarIdent p _ -> p

instance HasPosition LanguageDecl where
  hasPosition = \case
    LanguageDecl p _ -> p

instance HasPosition Language where
  hasPosition = \case
    Rzk1 p -> p

instance HasPosition Command where
  hasPosition = \case
    CommandSetOption p _ _ -> p
    CommandUnsetOption p _ -> p
    CommandCheck p _ _ -> p
    CommandCompute p _ -> p
    CommandComputeWHNF p _ -> p
    CommandComputeNF p _ -> p
    CommandPostulate p _ _ _ _ -> p
    CommandAssume p _ _ -> p
    CommandSection p _ -> p
    CommandSectionEnd p _ -> p
    CommandDefine p _ _ _ _ _ -> p

instance HasPosition DeclUsedVars where
  hasPosition = \case
    DeclUsedVars p _ -> p

instance HasPosition SectionName where
  hasPosition = \case
    NoSectionName p -> p
    SomeSectionName p _ -> p

instance HasPosition Pattern where
  hasPosition = \case
    PatternUnit p -> p
    PatternVar p _ -> p
    PatternPair p _ _ -> p

instance HasPosition Param where
  hasPosition = \case
    ParamPattern p _ -> p
    ParamPatternType p _ _ -> p
    ParamPatternShape p _ _ _ -> p
    ParamPatternShapeDeprecated p _ _ _ -> p

instance HasPosition ParamDecl where
  hasPosition = \case
    ParamType p _ -> p
    ParamTermType p _ _ -> p
    ParamTermShape p _ _ _ -> p
    ParamTermTypeDeprecated p _ _ -> p
    ParamVarShapeDeprecated p _ _ _ -> p

instance HasPosition SigmaParam where
  hasPosition = \case
    SigmaParam p _ _ -> p

instance HasPosition Restriction where
  hasPosition = \case
    Restriction p _ _ -> p
    ASCII_Restriction p _ _ -> p

instance HasPosition Term where
  hasPosition = \case
    Universe p -> p
    UniverseCube p -> p
    UniverseTope p -> p
    CubeUnit p -> p
    CubeUnitStar p -> p
    Cube2 p -> p
    Cube2_0 p -> p
    Cube2_1 p -> p
    CubeProduct p _ _ -> p
    TopeTop p -> p
    TopeBottom p -> p
    TopeEQ p _ _ -> p
    TopeLEQ p _ _ -> p
    TopeAnd p _ _ -> p
    TopeOr p _ _ -> p
    RecBottom p -> p
    RecOr p _ -> p
    RecOrDeprecated p _ _ _ _ -> p
    TypeFun p _ _ -> p
    TypeSigma p _ _ _ -> p
    TypeSigmaNested p _ _ _ -> p
    TypeUnit p -> p
    TypeId p _ _ _ -> p
    TypeIdSimple p _ _ -> p
    TypeRestricted p _ _ -> p
    TypeExtensionDeprecated p _ _ -> p
    App p _ _ -> p
    Lambda p _ _ -> p
    Pair p _ _ -> p
    First p _ -> p
    Second p _ -> p
    Unit p -> p
    Refl p -> p
    ReflTerm p _ -> p
    ReflTermType p _ _ -> p
    IdJ p _ _ _ _ _ _ -> p
    Hole p _ -> p
    Var p _ -> p
    TypeAsc p _ _ -> p
    ASCII_CubeUnitStar p -> p
    ASCII_Cube2_0 p -> p
    ASCII_Cube2_1 p -> p
    ASCII_TopeTop p -> p
    ASCII_TopeBottom p -> p
    ASCII_TopeEQ p _ _ -> p
    ASCII_TopeLEQ p _ _ -> p
    ASCII_TopeAnd p _ _ -> p
    ASCII_TopeOr p _ _ -> p
    ASCII_TypeFun p _ _ -> p
    ASCII_TypeSigma p _ _ _ -> p
    ASCII_Lambda p _ _ -> p
    ASCII_TypeExtensionDeprecated p _ _ -> p
    ASCII_First p _ -> p
    ASCII_Second p _ -> p

