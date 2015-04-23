module Gidl.Backend.Tower where

import Data.List (intercalate)

import Ivory.Artifact
import Ivory.Artifact.Template

import qualified Paths_gidl as P

import Gidl.Interface
import Gidl.Schema
import Gidl.Backend.Cabal
import Gidl.Backend.Ivory (dotwords, ivorySources)
import Gidl.Backend.Ivory.Schema (ifModuleName)
import Gidl.Backend.Tower.Schema
import Gidl.Backend.Tower.Server

towerBackend :: [Interface] -> String -> String -> [Artifact]
towerBackend iis pkgname namespace_raw =
  [ cabalFileArtifact cf
  , makefile
  , defaultconf
  , artifactPath "tests" (codegenTest iis namespace)
  ] ++ map (artifactPath "src") sources
  where
  namespace = dotwords namespace_raw

  sources = isources ++ [ attrModule (namespace ++ ["Tower"]) ] ++ tsources

  tsources = towerSources iis (namespace ++ ["Tower"])

  isources = ivorySources iis (namespace ++ ["Ivory"])

  cf = (defaultCabalFile pkgname cabalmods deps) { executables = [ cg_exe ] }
  cabalmods = map (filePathToPackage . artifactFileName) sources
  deps = words "ivory ivory-stdlib ivory-serialize tower"
  cg_exe = defaultCabalExe (pkgname ++ "-gen") "CodeGen.hs"
            (deps ++ (words "tower-config tower-freertos-stm32") ++ [pkgname])


towerSources :: [Interface] -> [String] -> [Artifact]
towerSources iis namespace = towerInterfaces
  where
  towerInterfaces = concat
    [ [ schemaModule    ifnamespace i (producerSchema i)
      , schemaModule    ifnamespace i (consumerSchema i)
      , serverModule    ifnamespace i
      , umbrellaModule  ifnamespace i
      ]
    | i <- iis ]
  ifnamespace = namespace ++ ["Interface"]

makefile :: Artifact
makefile = artifactCabalFile P.getDataDir "support/tower/Makefile"

defaultconf :: Artifact
defaultconf = artifactCabalFile P.getDataDir "support/tower/default.conf"

codegenTest :: [Interface] -> [String] -> Artifact
codegenTest iis modulepath =
  artifactCabalFileTemplate P.getDataDir fname
    [("module_path",intercalate "." modulepath)
    ,("imports", intercalate "\n"
                  [ "import "
                    ++ interfaceImport (ifModuleName i) "Producer"
                    ++ "\n"
                    ++ "import "
                    ++ interfaceImport (ifModuleName i) "Consumer"
                  | i <- iis
                  ])
    ,("app_body", intercalate "\n  " (concat [ interfaceTest i | i <- iis ]))
    ]
  where
  fname = "support/tower/CodeGen.hs.template"
  interfaceImport i j = intercalate "." (modulepath ++ ["Tower", "Interface", i, j])

  interfaceTest :: Interface -> [String]
  interfaceTest i = [ schemaTest (producerSchema i)
                    , schemaTest (consumerSchema i)
                    ]
    where
    schemaTest :: Schema -> String
    schemaTest (Schema _ []) = []
    schemaTest (Schema schemaName _)
      =  (inputFuncName ((ifModuleName i) ++ schemaName))
      ++ " (snd c) >>= \\i -> "
      ++ (outputFuncName ((ifModuleName i) ++ schemaName))
      ++ " i >>= \\(_ :: ChanOutput (Array 80 (Stored Uint8))) -> return ()"


attrModule :: [String] -> Artifact
attrModule modulepath =
  artifactPath (intercalate "/" modulepath) $
  artifactCabalFileTemplate P.getDataDir fname
    [("module_path", intercalate "." modulepath )]
  where
  fname = "support/tower/Attr.hs.template"
