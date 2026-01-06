{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}

module Hydra.Invoice (
  Invoice (..),
  PreImage (..),
  PaymentId (..),
  StandardInvoice,
  generatePreImage,
  hashPaymentId,
  generatePaymentId,
  generateStandardInvoice,
  decodeStandardInvoice,
  encodeStandardInvoice,
  shelleyAddrToWords,
  wordsToShelleyAddr,
  paymentIdToWords,
  wordsToPaymentId,
  utcTimeToWords,
  wordsToUtcTime,
  valueToWords,
  wordsToValue,
  recordToStandardInvoice,
  standardInvoiceToRecord,
) where

import "base" Control.Monad (replicateM, (<=<))
import "base" Data.Kind (Type)
import "base" GHC.Generics (Generic)
import "bech32" Codec.Binary.Bech32 (Word5)
import "bech32" Codec.Binary.Bech32 qualified as Bech32
import "bech32" Codec.Binary.Bech32.Internal qualified as Bech32
import "bech32-records" Codec.Binary.Bech32.Records qualified as Bech32
import "bech32-th" Codec.Binary.Bech32.TH qualified as Bech32
import "bytestring" Data.ByteString qualified as BS
import "bytestring" Data.ByteString.Char8 qualified as Char8
import "cardano-api" Cardano.Api qualified as C
import "cardano-crypto-class" Cardano.Crypto.Hash qualified as Crypto
import "cardano-ledger-mary" Cardano.Ledger.Mary.Value ()
import "containers" Data.Map (Map)
import "containers" Data.Map qualified as Map
import "extra" Data.Either.Extra (eitherToMaybe, mapLeft, maybeToEither)
import "parsec" Text.Parsec qualified as P
import "random" System.Random (randomRIO)
import "text" Data.Text (Text)
import "text" Data.Text.Encoding qualified as Text
import "time" Data.Time (UTCTime, defaultTimeLocale, formatTime, parseTimeM)

type Invoice :: Type -> Type -> Type -> Type -> Type
data Invoice paymentIdType addressType amountType datetimeType = MkInvoice
  { paymentId :: paymentIdType
  , recipient :: addressType
  , amount :: amountType
  , date :: datetimeType
  }
  deriving stock (Eq, Show)

type PreImage :: Type
newtype PreImage = UnsafePreImage {fromPreImage :: BS.ByteString}
  deriving stock (Show, Eq)

type PaymentId :: Type
newtype PaymentId = UnsafePaymentId {fromPaymentId :: Crypto.Hash Crypto.Blake2b_256 BS.ByteString}
  deriving stock (Show, Eq, Generic)

type StandardInvoice :: Type
type StandardInvoice = Invoice PaymentId (C.Address C.ShelleyAddr) C.Value UTCTime

generatePreImage :: IO PreImage
generatePreImage = UnsafePreImage . BS.pack <$> replicateM 32 (randomRIO (0, 255))

hashPaymentId :: PreImage -> PaymentId
hashPaymentId (UnsafePreImage preimage) =
  UnsafePaymentId $ Crypto.hashWith id preimage

generatePaymentId :: IO (PaymentId, PreImage)
generatePaymentId = do
  x <- generatePreImage
  pure (hashPaymentId x, x)

generateStandardInvoice :: C.Address C.ShelleyAddr -> C.Value -> UTCTime -> IO (StandardInvoice, PreImage)
generateStandardInvoice recipient amount date = do
  (paymentId, preImage) <- generatePaymentId
  let invoice =
        MkInvoice
          { paymentId
          , recipient
          , amount
          , date
          }
  pure (invoice, preImage)

(.=) :: a -> b -> (a, b)
(.=) a b = (a, b)

standardInvoiceToRecord :: StandardInvoice -> Map Word5 [Word5]
standardInvoiceToRecord (MkInvoice{..}) =
  Map.fromList
    [ toEnum 1 .= paymentIdToWords paymentId
    , toEnum 19 .= shelleyAddrToWords recipient
    , toEnum 29 .= valueToWords amount
    , toEnum 11 .= utcTimeToWords date
    ]

shelleyAddrToWords :: C.Address C.ShelleyAddr -> [Word5]
shelleyAddrToWords = Bech32.toBase32 . BS.unpack . C.serialiseToRawBytes

wordsToShelleyAddr :: [Word5] -> Maybe (C.Address C.ShelleyAddr)
wordsToShelleyAddr = eitherToMaybe . C.deserialiseFromRawBytes (C.AsAddress C.AsShelleyAddr) . BS.pack <=< Bech32.toBase256

paymentIdToWords :: PaymentId -> [Word5]
paymentIdToWords = Bech32.toBase32 . BS.unpack . Crypto.hashToBytes . fromPaymentId

wordsToPaymentId :: [Word5] -> Maybe PaymentId
wordsToPaymentId = fmap UnsafePaymentId . Crypto.hashFromBytes . BS.pack <=< Bech32.toBase256

valueToWords :: C.Value -> [Word5]
valueToWords = Bech32.toBase32 . BS.unpack . Text.encodeUtf8 . C.renderValue

wordsToValue :: [Word5] -> Maybe C.Value
wordsToValue = eitherToMaybe . P.parse C.parseUTxOValue "" . Text.decodeUtf8 . BS.pack <=< Bech32.toBase256

utcTimeToWords :: UTCTime -> [Word5]
utcTimeToWords = Bech32.toBase32 . BS.unpack . Char8.pack . formatTime defaultTimeLocale "%Y-%m-%d %H:%M:%S"

wordsToUtcTime :: [Word5] -> Maybe UTCTime
wordsToUtcTime = parseTimeM False defaultTimeLocale "%Y-%m-%d %H:%M:%S" . Char8.unpack . BS.pack <=< Bech32.toBase256

recordToStandardInvoice :: Map Word5 [Word5] -> Maybe StandardInvoice
recordToStandardInvoice xs = do
  paymentIdWords <- Map.lookup (toEnum 1) xs
  recipientWords <- Map.lookup (toEnum 19) xs
  amountWords <- Map.lookup (toEnum 29) xs
  dateWords <- Map.lookup (toEnum 11) xs

  recipient <- wordsToShelleyAddr recipientWords
  paymentId <- wordsToPaymentId paymentIdWords
  amount <- wordsToValue amountWords
  date <- wordsToUtcTime dateWords

  pure $ MkInvoice{..}

type StandardInvoiceDecodingError :: Type
data StandardInvoiceDecodingError
  = Bech32DecodeLenientError Bech32.DecodingError
  | Bech32WordsToRecordError P.ParseError
  | StandardInvoiceFieldDecodingError
  deriving stock (Show, Eq)

decodeStandardInvoice :: Text -> Either StandardInvoiceDecodingError StandardInvoice
decodeStandardInvoice x = do
  (_, dataPart) <- mapLeft Bech32DecodeLenientError $ Bech32.decodeLenient x
  a <- mapLeft Bech32WordsToRecordError $ Bech32.wordsToRecord $ Bech32.dataPartToWords dataPart
  maybeToEither StandardInvoiceFieldDecodingError $ recordToStandardInvoice a

humanReadableHydraPrefix :: Bech32.HumanReadablePart
humanReadableHydraPrefix = [Bech32.humanReadablePart|"hln"|]

encodeStandardInvoice :: StandardInvoice -> Text
encodeStandardInvoice x =
  let dataPart = Bech32.dataPartFromWords $ Bech32.recordToWords $ standardInvoiceToRecord x
   in Bech32.encodeLenient humanReadableHydraPrefix dataPart
