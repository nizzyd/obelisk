{-# LANGUAGE ScopedTypeVariables #-}
module Obelisk.ExecutableConfig (get) where

import Control.Exception (bracket)
import qualified Data.ByteString as BS
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import Foreign.C.String (withCString)
import Foreign.Ptr (nullPtr)
import System.FilePath.Posix ((</>))

import Obelisk.ExecutableConfig.Internal.AssetManager
import Obelisk.ExecutableConfig.Types

get :: forall config. ObeliskConfig config => IO config
get = bracket getAssets freeAssetManager $ \mgrObj -> do
  mgr <- assetManagerFromJava mgrObj
  path <- getConfigPath configPath
  let open = do
        a <- withCString path $ \fn ->
          assetManager_open mgr fn 3
        return $ if unAAsset a == nullPtr
          then Nothing
          else Just a
      close = mapM_ asset_close
  content <- bracket open close $ mapM $ \asset -> do
    b <- asset_getBuffer asset
    l <- asset_getLength asset
    fmap T.decodeUtf8 $ BS.packCStringLen (b, fromIntegral l)
  parseConfig content
