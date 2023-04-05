{-# LANGUAGE LambdaCase #-}
module Language.Rzk.Syntax (
  module Language.Rzk.Syntax.Abs,

  parseModule,
  parseModuleFile,
  parseTerm,
  printTree,
) where

import Language.Rzk.Syntax.Abs
import Language.Rzk.Syntax.Print (printTree)

import Language.Rzk.Syntax.Lex (tokens)
import Language.Rzk.Syntax.Par (pModule, pTerm)
import Language.Rzk.Syntax.Layout (resolveLayout)

parseModule :: String -> Either String Module
parseModule = pModule . resolveLayout True . tokens

parseModuleFile :: FilePath -> IO (Either String Module)
parseModuleFile path = do
  parseModule <$> readFile path

parseTerm :: String -> Either String Term
parseTerm = pTerm . tokens
