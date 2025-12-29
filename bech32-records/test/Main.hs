module Main (main) where

import Test.Codec.Binary.Bech32.RecordsSpec (tests)
import Test.Tasty (defaultMain)

main :: IO ()
main = defaultMain tests
