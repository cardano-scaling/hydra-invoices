module Main where

import Test.Hspec.Runner (hspec)

import Spec qualified

main :: IO ()
main = hspec Spec.spec
