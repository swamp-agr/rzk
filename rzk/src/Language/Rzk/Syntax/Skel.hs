-- File generated by the BNF Converter (bnfc 2.9.5).

-- Templates for pattern matching on abstract syntax

{-# OPTIONS_GHC -fno-warn-unused-matches #-}

module Language.Rzk.Syntax.Skel where

import Prelude (($), Either(..), String, (++), Show, show)
import qualified Language.Rzk.Syntax.Abs

type Err = Either String
type Result = Err String

failure :: Show a => a -> Result
failure x = Left $ "Undefined case: " ++ show x

transVarIdentToken :: Language.Rzk.Syntax.Abs.VarIdentToken -> Result
transVarIdentToken x = case x of
  Language.Rzk.Syntax.Abs.VarIdentToken string -> failure x

transHoleIdentToken :: Language.Rzk.Syntax.Abs.HoleIdentToken -> Result
transHoleIdentToken x = case x of
  Language.Rzk.Syntax.Abs.HoleIdentToken string -> failure x

transModule :: Show a => Language.Rzk.Syntax.Abs.Module' a -> Result
transModule x = case x of
  Language.Rzk.Syntax.Abs.Module _ languagedecl commands -> failure x

transHoleIdent :: Show a => Language.Rzk.Syntax.Abs.HoleIdent' a -> Result
transHoleIdent x = case x of
  Language.Rzk.Syntax.Abs.HoleIdent _ holeidenttoken -> failure x

transVarIdent :: Show a => Language.Rzk.Syntax.Abs.VarIdent' a -> Result
transVarIdent x = case x of
  Language.Rzk.Syntax.Abs.VarIdent _ varidenttoken -> failure x

transLanguageDecl :: Show a => Language.Rzk.Syntax.Abs.LanguageDecl' a -> Result
transLanguageDecl x = case x of
  Language.Rzk.Syntax.Abs.LanguageDecl _ language -> failure x

transLanguage :: Show a => Language.Rzk.Syntax.Abs.Language' a -> Result
transLanguage x = case x of
  Language.Rzk.Syntax.Abs.Rzk1 _ -> failure x

transCommand :: Show a => Language.Rzk.Syntax.Abs.Command' a -> Result
transCommand x = case x of
  Language.Rzk.Syntax.Abs.CommandSetOption _ string1 string2 -> failure x
  Language.Rzk.Syntax.Abs.CommandUnsetOption _ string -> failure x
  Language.Rzk.Syntax.Abs.CommandCheck _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.CommandCompute _ term -> failure x
  Language.Rzk.Syntax.Abs.CommandComputeWHNF _ term -> failure x
  Language.Rzk.Syntax.Abs.CommandComputeNF _ term -> failure x
  Language.Rzk.Syntax.Abs.CommandPostulate _ varident declusedvars params term -> failure x
  Language.Rzk.Syntax.Abs.CommandAssume _ varidents term -> failure x
  Language.Rzk.Syntax.Abs.CommandSection _ sectionname -> failure x
  Language.Rzk.Syntax.Abs.CommandSectionEnd _ sectionname -> failure x
  Language.Rzk.Syntax.Abs.CommandDefine _ varident declusedvars params term1 term2 -> failure x

transDeclUsedVars :: Show a => Language.Rzk.Syntax.Abs.DeclUsedVars' a -> Result
transDeclUsedVars x = case x of
  Language.Rzk.Syntax.Abs.DeclUsedVars _ varidents -> failure x

transSectionName :: Show a => Language.Rzk.Syntax.Abs.SectionName' a -> Result
transSectionName x = case x of
  Language.Rzk.Syntax.Abs.NoSectionName _ -> failure x
  Language.Rzk.Syntax.Abs.SomeSectionName _ varident -> failure x

transPattern :: Show a => Language.Rzk.Syntax.Abs.Pattern' a -> Result
transPattern x = case x of
  Language.Rzk.Syntax.Abs.PatternUnit _ -> failure x
  Language.Rzk.Syntax.Abs.PatternVar _ varident -> failure x
  Language.Rzk.Syntax.Abs.PatternPair _ pattern_1 pattern_2 -> failure x
  Language.Rzk.Syntax.Abs.PatternTuple _ pattern_1 pattern_2 patterns -> failure x

transParam :: Show a => Language.Rzk.Syntax.Abs.Param' a -> Result
transParam x = case x of
  Language.Rzk.Syntax.Abs.ParamPattern _ pattern_ -> failure x
  Language.Rzk.Syntax.Abs.ParamPatternType _ patterns term -> failure x
  Language.Rzk.Syntax.Abs.ParamPatternShape _ patterns term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.ParamPatternShapeDeprecated _ pattern_ term1 term2 -> failure x

transParamDecl :: Show a => Language.Rzk.Syntax.Abs.ParamDecl' a -> Result
transParamDecl x = case x of
  Language.Rzk.Syntax.Abs.ParamType _ term -> failure x
  Language.Rzk.Syntax.Abs.ParamTermType _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.ParamTermShape _ term1 term2 term3 -> failure x
  Language.Rzk.Syntax.Abs.ParamTermTypeDeprecated _ pattern_ term -> failure x
  Language.Rzk.Syntax.Abs.ParamVarShapeDeprecated _ pattern_ term1 term2 -> failure x

transSigmaParam :: Show a => Language.Rzk.Syntax.Abs.SigmaParam' a -> Result
transSigmaParam x = case x of
  Language.Rzk.Syntax.Abs.SigmaParam _ pattern_ term -> failure x

transRestriction :: Show a => Language.Rzk.Syntax.Abs.Restriction' a -> Result
transRestriction x = case x of
  Language.Rzk.Syntax.Abs.Restriction _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.ASCII_Restriction _ term1 term2 -> failure x

transTerm :: Show a => Language.Rzk.Syntax.Abs.Term' a -> Result
transTerm x = case x of
  Language.Rzk.Syntax.Abs.Universe _ -> failure x
  Language.Rzk.Syntax.Abs.UniverseCube _ -> failure x
  Language.Rzk.Syntax.Abs.UniverseTope _ -> failure x
  Language.Rzk.Syntax.Abs.CubeUnit _ -> failure x
  Language.Rzk.Syntax.Abs.CubeUnitStar _ -> failure x
  Language.Rzk.Syntax.Abs.Cube2 _ -> failure x
  Language.Rzk.Syntax.Abs.Cube2_0 _ -> failure x
  Language.Rzk.Syntax.Abs.Cube2_1 _ -> failure x
  Language.Rzk.Syntax.Abs.CubeProduct _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TopeTop _ -> failure x
  Language.Rzk.Syntax.Abs.TopeBottom _ -> failure x
  Language.Rzk.Syntax.Abs.TopeEQ _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TopeLEQ _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TopeAnd _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TopeOr _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.RecBottom _ -> failure x
  Language.Rzk.Syntax.Abs.RecOr _ restrictions -> failure x
  Language.Rzk.Syntax.Abs.RecOrDeprecated _ term1 term2 term3 term4 -> failure x
  Language.Rzk.Syntax.Abs.TypeFun _ paramdecl term -> failure x
  Language.Rzk.Syntax.Abs.TypeSigma _ pattern_ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TypeSigmaTuple _ sigmaparam sigmaparams term -> failure x
  Language.Rzk.Syntax.Abs.TypeUnit _ -> failure x
  Language.Rzk.Syntax.Abs.TypeId _ term1 term2 term3 -> failure x
  Language.Rzk.Syntax.Abs.TypeIdSimple _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.TypeRestricted _ term restrictions -> failure x
  Language.Rzk.Syntax.Abs.TypeExtensionDeprecated _ paramdecl term -> failure x
  Language.Rzk.Syntax.Abs.App _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.Lambda _ params term -> failure x
  Language.Rzk.Syntax.Abs.Pair _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.Tuple _ term1 term2 terms -> failure x
  Language.Rzk.Syntax.Abs.First _ term -> failure x
  Language.Rzk.Syntax.Abs.Second _ term -> failure x
  Language.Rzk.Syntax.Abs.Unit _ -> failure x
  Language.Rzk.Syntax.Abs.Refl _ -> failure x
  Language.Rzk.Syntax.Abs.ReflTerm _ term -> failure x
  Language.Rzk.Syntax.Abs.ReflTermType _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.IdJ _ term1 term2 term3 term4 term5 term6 -> failure x
  Language.Rzk.Syntax.Abs.Hole _ holeident -> failure x
  Language.Rzk.Syntax.Abs.Var _ varident -> failure x
  Language.Rzk.Syntax.Abs.TypeAsc _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.ASCII_CubeUnitStar _ -> failure x
  Language.Rzk.Syntax.Abs.ASCII_Cube2_0 _ -> failure x
  Language.Rzk.Syntax.Abs.ASCII_Cube2_1 _ -> failure x
  Language.Rzk.Syntax.Abs.ASCII_TopeTop _ -> failure x
  Language.Rzk.Syntax.Abs.ASCII_TopeBottom _ -> failure x
  Language.Rzk.Syntax.Abs.ASCII_TopeEQ _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.ASCII_TopeLEQ _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.ASCII_TopeAnd _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.ASCII_TopeOr _ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.ASCII_TypeFun _ paramdecl term -> failure x
  Language.Rzk.Syntax.Abs.ASCII_TypeSigma _ pattern_ term1 term2 -> failure x
  Language.Rzk.Syntax.Abs.ASCII_TypeSigmaTuple _ sigmaparam sigmaparams term -> failure x
  Language.Rzk.Syntax.Abs.ASCII_Lambda _ params term -> failure x
  Language.Rzk.Syntax.Abs.ASCII_TypeExtensionDeprecated _ paramdecl term -> failure x
  Language.Rzk.Syntax.Abs.ASCII_First _ term -> failure x
  Language.Rzk.Syntax.Abs.ASCII_Second _ term -> failure x
