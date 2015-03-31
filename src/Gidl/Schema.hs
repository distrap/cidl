
module Gidl.Schema where

import Data.Word
import Data.Hashable
import Gidl.Types
import Gidl.Interface

type MsgId = Word32
data Message = Message String Type
             deriving (Eq, Show)
data Schema = Schema String [(MsgId, Message)]
            deriving (Eq, Show)


producerSchema :: Interface -> Schema
producerSchema ir = Schema "Producer" [(mkMsgId m, m) | m <- messages ]
  where
  messages = concatMap mkMessages (interfaceMethods ir)
  mkMessages (streamname, (StreamMethod _ tr)) =
    [ Message streamname tr ]
  mkMessages (_ , (AttrMethod Write _)) = []
  mkMessages (attrname, (AttrMethod  _ tr)) =
    [ Message (attrname ++ "_val") tr ]

consumerSchema :: Interface -> Schema
consumerSchema ir = Schema "Consumer" [(mkMsgId m, m) | m <- messages ]
  where
  messages = concatMap mkMessages (interfaceMethods ir)

  mkMessages (_, (StreamMethod _ _)) = [] -- XXX eventaully add set rate?
  mkMessages (attrname, (AttrMethod Write tr)) =
    [ Message (attrname ++ "_set") tr ]
  mkMessages (attrname, (AttrMethod Read _)) =
    [ Message (attrname ++ "_get")  (PrimType VoidType) ]
  mkMessages (attrname, (AttrMethod ReadWrite tr)) =
    [ Message (attrname ++ "_set") tr
    , Message (attrname ++ "_get") (PrimType VoidType)
    ]


mkMsgId :: Message -> MsgId
mkMsgId = fromIntegral . hash . show

