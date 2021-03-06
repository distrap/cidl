{-# LANGUAGE TemplateHaskell #-}

module Cidl.Types.AST where

import Lens.Family2.TH

type Identifier = String
type Length = Integer
type TypeName = String
data TypeEnv
  = TypeEnv [(TypeName, Type)]
  deriving (Eq, Show)

data Perm
  = Read
  | Write
  | ReadWrite
  | Const
  | Reserved
  deriving (Eq, Show)

readable :: Perm -> Bool
readable Read = True
readable ReadWrite = True
readable Const = True
readable _ = False

writable :: Perm -> Bool
writable Write = True
writable ReadWrite = True
writable _ = False

data InitVal
  = NoInit
  | NumInit Integer
  | NumInitOffset Integer
--  | StrInit String
  deriving (Eq, Show)

emptyTypeEnv :: TypeEnv
emptyTypeEnv = TypeEnv []

data Entry = Entry
  { _name :: String
  , _typ :: Type
  , _initial :: InitVal
  , _access :: Perm
  , _verbose :: Maybe String
  , _pdoMappable :: Bool
  , _isRPDO :: Bool
  , _isTPDO :: Bool
  , _isPDOMap :: Bool
  , _index :: Integer
  }
  deriving (Eq, Show)

data Type
  = RecordType String [Entry] -- RecordType in CANOpen terminology
  | ArrayType String Length Type
  | VarArrayType Type
  | PrimType PrimType
  deriving (Eq, Show)

data PrimType
  = Newtype  String PrimType
  | EnumType String Bits [(Identifier, Integer)]
  | AtomType Atom
  deriving (Eq, Show)

data Atom
  = AtomInt Bits
  | AtomWord Bits
  | AtomFloat
  | AtomDouble
  deriving (Eq, Show)

data Bits
  = Bits8
  | Bits16
  | Bits32
  | Bits64
  deriving (Eq, Show)

isRecord :: Type -> Bool
isRecord (RecordType _ _) = True
isRecord _ = False

isArray :: Type -> Bool
isArray (ArrayType _ _ _) = True
isArray _ = False

isVarArray :: Type -> Bool
isVarArray (VarArrayType _) = True
isVarArray _ = False

isComplex :: Type -> Bool
isComplex x = isRecord x || isArray x || isVarArray x

$(makeLenses ''Entry)

