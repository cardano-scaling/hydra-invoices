{-# OPTIONS_GHC -Wno-missed-specialisations #-}

module Test.Codec.Binary.Bech32.RecordsSpec (
  tests,
) where

import "base" Control.Monad (replicateM)
import "bech32" Codec.Binary.Bech32 (Word5)
import "bech32-records" Codec.Binary.Bech32.Records qualified as Bech32
import "containers" Data.Map (Map)
import "containers" Data.Map qualified as Map
import "hedgehog" Hedgehog (Gen, Property, Range, forAll, property, tripping)
import "hedgehog" Hedgehog.Gen qualified as Gen
import "hedgehog" Hedgehog.Range qualified as Range
import "tasty" Test.Tasty (TestTree, testGroup)
import "tasty-hedgehog" Test.Tasty.Hedgehog (testProperty)

genList :: Range Int -> Gen [[Word5]]
genList r = do
  numLists <- Gen.int r
  replicateM numLists (Gen.list r genWord5)

genRecord :: Range Int -> Gen (Map Word5 [Word5])
genRecord r = do
  numFields <- Gen.int r
  allKeys <- Gen.shuffle [minBound .. maxBound :: Word5]
  let keys = take numFields allKeys
  values <- traverse (\_ -> Gen.list r genWord5) keys
  pure $ Map.fromList (zip keys values)

genWord5 :: Gen Word5
genWord5 = Gen.enumBounded

prop_roundtrip_int :: Property
prop_roundtrip_int = property $ do
  xs <- forAll $ Gen.int $ Range.linear 0 maxBound
  tripping xs (Bech32.intToWords 16) (Bech32.wordsToInt 16)

prop_roundtrip_list :: Property
prop_roundtrip_list = property $ do
  xs <- forAll $ genList $ Range.linear 0 100
  tripping xs Bech32.sequenceToWords Bech32.wordsToSequence

prop_roundtrip_record :: Property
prop_roundtrip_record = property $ do
  xs <- forAll $ genRecord $ Range.linear 0 100
  tripping xs Bech32.recordToWords Bech32.wordsToRecord

tests :: TestTree
tests = do
  testGroup
    "Codec.Binary.Bech32.Records"
    [ testProperty "roundtrip int encoding" prop_roundtrip_int
    , testProperty "roundtrip list encoding" prop_roundtrip_list
    , testProperty "roundtrip record encoding" prop_roundtrip_record
    ]
