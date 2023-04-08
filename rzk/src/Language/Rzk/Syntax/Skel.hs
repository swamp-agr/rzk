-- File generated by the BNF Converter (bnfc 2.9.4.1).

-- Templates for pattern matching on abstract syntax

{-# OPTIONS_GHC -fno-warn-unused-matches #-}

module Language.Rzk.Syntax.Skel where

import Prelude (($), Either(..), String, (++), Show, show)
import qualified Language.Rzk.Syntax.Abs

type Err = Either String
type Result = Err String

failure :: Show a => a -> Result
failure x = Left $ "Undefined case: " ++ show x

transVarIdent :: Language.Rzk.Syntax.Abs.VarIdent -> Result
transVarIdent x = case x of
  Language.Rzk.Syntax.Abs.VarIdent string -> failure x

transHoleIdent :: Language.Rzk.Syntax.Abs.HoleIdent -> Result
transHoleIdent x = case x of
  Language.Rzk.Syntax.Abs.HoleIdent string -> failure x

transModule :: Language.Rzk.Syntax.Abs.Module -> Result
transModule x = case x of
  Language.Rzk.Syntax.Abs.Module languagedecl commands -> failure x

transLanguageDecl :: Language.Rzk.Syntax.Abs.LanguageDecl -> Result
transLanguageDecl x = case x of
  Language.Rzk.Syntax.Abs.LanguageDecl language -> failure x

transLanguage :: Language.Rzk.Syntax.Abs.Language -> Result
transLanguage x = case x of
  Language.Rzk.Syntax.Abs.Rzk1 -> failure x
  Language.Rzk.Syntax.Abs.Rzk2 -> failure x

transCommand :: Language.Rzk.Syntax.Abs.Command -> Result
transCommand x = case x of
  Language.Rzk.Syntax.Abs.CommandDefine varident term1 term2 -> failure x

transPattern :: Language.Rzk.Syntax.Abs.Pattern -> Result
transPattern x = case x of
  Language.Rzk.Syntax.Abs.PatternWildcard -> failure x
  Language.Rzk.Syntax.Abs.PatternVar varident -> failure x
  Language.Rzk.Syntax.Abs.PatternPair pattern_1 pattern_2 -> failure x

transParam :: Language.Rzk.Syntax.Abs.Param -> Result
transParam x = case x of
  Language.Rzk.Syntax.Abs.ParamPattern pattern_ -> failure x
  Language.Rzk.Syntax.Abs.ParamPatternType pattern_ term -> failure x
  Language.Rzk.Syntax.Abs.ParamPatternShape pattern_ term1 term2 -> failure x

transParamDecl :: Language.Rzk.Syntax.Abs.ParamDecl -> Result
transParamDecl x = case x of
  Language.Rzk.Syntax.Abs.ParamType term -> failure x
  Language.Rzk.Syntax.Abs.ParamWildcardType term -> failure x
  Language.Rzk.Syntax.Abs.ParamVarType varident term -> failure x
  Language.Rzk.Syntax.Abs.ParamVarShape pattern_ term1 term2 -> failure x

transRestriction :: Language.Rzk.Syntax.Abs.Restriction -> Result
transRestriction x = case x of
  Language.Rzk.Syntax.Abs.Restriction term1 term2 -> failure x

transTerm :: Language.Rzk.Syntax.Abs.Term -> Result
transTerm x = case x of
  Language.Rzk.Syntax.Abs.Universe -> failure x
  Language.Rzk.Syntax.Abs.UniverseCube -> failure x
  Language.Rzk.Syntax.Abs.UniverseTope -> failure x
  Language.Rzk.Syntax.Abs.CubeUnit -> failure x
  Language.Rzk.Syntax.Abs.CubeUnitStar -> failure x
  Language.Rzk.Syntax.Abs.Cube2 -> failure x
  Language.Rzk.Syntax.Abs.Cube2_0 -> failure x
  Language.Rzk.Syntax.Abs.Cube2_1 -> failure x
  Language.Rzk.Syntax.Abs.CubeProduct term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TopeTop -> failure x
  Language.Rzk.Syntax.Abs.TopeBottom -> failure x
  Language.Rzk.Syntax.Abs.TopeEQ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TopeLEQ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TopeAnd term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TopeOr term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.RecBottom -> failure x
  Language.Rzk.Syntax.Abs.RecOr restrictions -> failure x
  Language.Rzk.Syntax.Abs.TypeFun paramdecl term -> failure x
  Language.Rzk.Syntax.Abs.TypeSigma pattern_ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TypeId term1 term2 term3 -> failure x
  Language.Rzk.Syntax.Abs.TypeIdSimple term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TypeRestricted term restriction -> failure x
  Language.Rzk.Syntax.Abs.App term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.Lambda params term -> failure x
  Language.Rzk.Syntax.Abs.Pair term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.First term -> failure x
  Language.Rzk.Syntax.Abs.Second term -> failure x
  Language.Rzk.Syntax.Abs.Refl -> failure x
  Language.Rzk.Syntax.Abs.ReflTerm term -> failure x
  Language.Rzk.Syntax.Abs.ReflTermType term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.IdJ term1 term2 term3 term4 term5 term6 -> failure x
  Language.Rzk.Syntax.Abs.Hole holeident -> failure x
  Language.Rzk.Syntax.Abs.Var varident -> failure x
  Language.Rzk.Syntax.Abs.TypeAsc term1 term2 -> failure x
