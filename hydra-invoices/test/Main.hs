module Main (main) where

import Test.Hydra.InvoiceSpec (tests)
import Test.Tasty (defaultMain)

main :: IO ()
main = defaultMain tests
