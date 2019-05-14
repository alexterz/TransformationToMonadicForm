module Syntax where

type Name = String

data Expr
  = Lam Name Expr
  | App Expr Expr
  | Let [Dclr] Expr --uses Parsing sequences
  | Var Name
  | Lit Lit
  | Op Binop Expr Expr
  deriving (Eq,Show)
   

data Dclr 
  = Assign Name Expr
  deriving (Eq,Show)

data Lit
  = LInt Int
  | LBool Bool
  deriving (Show, Eq, Ord)

data Binop = Add | Sub | Mul | Eql
  deriving (Eq, Ord, Show)
