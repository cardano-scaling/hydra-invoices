-- |
-- Module      : Codec.Binary.Bech32.Records
-- Description : Bech32 Tagged Fields
-- Copyright   : IOG 2025
-- License     : Apache
-- Maintainer  : daniel.firth@iohk.io
--
-- A bech32 record follows the following standard adapted from the
-- [Tagged Fields](https://github.com/lightning/bolts/blob/master/11-payment-encoding.md#tagged-fields)
-- section of the BOLT11 spec.
--
-- Each Tagged Field is of the form:
--
-- type (5 bits)
-- data_length (10 bits, big-endian)
-- data (data_length x 5 bits)
--
-- This is deserialised into a `Map` where the key is a single `Word5` and the value is the `Data`.
--
-- Additionally, this module supports encoding and decoding lists and big-endian integers.
module Codec.Binary.Bech32.Records (
  -- * Records
  parseField,
  fieldToWords,
  parseRecord,
  wordsToRecord,
  recordToWords,

  -- * Lists
  parseElement,
  elementToWords,
  parseSequence,
  wordsToSequence,
  sequenceToWords,

  -- * Integers
  parseIntBE,
  wordsToInt,
  intToWords,
) where

import "base" Data.List qualified as List
import "bech32" Codec.Binary.Bech32 (Word5)
import "containers" Data.Map (Map)
import "containers" Data.Map qualified as Map
import "parsec" Text.Parsec qualified as P

-- * Records

-- | Parse a single tagged field into a key-value pair.
parseField :: P.Parsec [Word5] a (Word5, [Word5])
parseField = do
  typeWord <- P.anyToken
  dataWords <- parseElement
  pure (typeWord, dataWords)

-- | Print a key-value pair as a sequence of type (5-bits): data_length (10 bits, big-endian) : data (data_length * 5 bits)
fieldToWords :: Word5 -> [Word5] -> [Word5]
fieldToWords typeWord dataWords = typeWord : elementToWords dataWords

-- | Parse a sequence of tagged fields into a `Map`.
parseRecord :: P.Parsec [Word5] a (Map Word5 [Word5])
parseRecord = Map.fromList <$> P.many parseField

-- | Parse a a sequence of tagged fields into a `Map` and run the parser.
wordsToRecord :: [Word5] -> Either P.ParseError (Map Word5 [Word5])
wordsToRecord = P.runParser parseRecord () "Bech32 Record Parser"

-- | Print a `Map` of key-value pairs into a sequence of tagged fields.
recordToWords :: Map Word5 [Word5] -> [Word5]
recordToWords = concatMap (uncurry fieldToWords) . Map.toList

-- * Lists

-- | Parse a single sequent element (just the `data_length : data` section)
parseElement :: P.Parsec [Word5] a [Word5]
parseElement = do
  len <- parseIntBE 2
  P.count len P.anyToken

-- | Parse many sequence elements into a list.
parseSequence :: P.Parsec [Word5] a [[Word5]]
parseSequence = P.many parseElement

-- | Parse many sequence elements into a list.
wordsToSequence :: [Word5] -> Either P.ParseError [[Word5]]
wordsToSequence = P.runParser parseSequence () "Bech32 Sequence Parser"

-- | Print a single piece of data as a sequence of data_length (10 bits, big-endian) : data (data_length * 5 bits)
elementToWords :: [Word5] -> [Word5]
elementToWords dataWords =
  let len = length dataWords
      hi = len `div` 32
      lo = len `mod` 32
   in toEnum hi : toEnum lo : dataWords

-- | Print a list of data as as a sequence using `elementToWords`.
sequenceToWords :: [[Word5]] -> [Word5]
sequenceToWords = concatMap elementToWords

-- * Integers

-- | Parse a big-endian integer with length n.
parseIntBE :: Int -> P.Parsec [Word5] a Int
parseIntBE len = do
  integerWords <- P.count len P.anyToken
  return $ foldl (\acc w -> acc * 32 + fromEnum w) 0 integerWords

-- | Print a big-endian integer over n bits.
intToWords :: Int -> Int -> [Word5]
intToWords len n
  | n < 0 = error "negative number"
  | otherwise = map toEnum $ reverse padded
 where
  lsbDigits = List.unfoldr (\x -> if x == 0 then Nothing else Just (x `mod` 32, x `div` 32)) n
  truncated = take len lsbDigits
  padded = truncated ++ replicate (len - length truncated) 0

-- | Parse a big-endian integer with length n and run the parser.
wordsToInt :: Int -> [Word5] -> Either P.ParseError Int
wordsToInt len = P.runParser (parseIntBE len) () "Bech32 Integer Parser"
