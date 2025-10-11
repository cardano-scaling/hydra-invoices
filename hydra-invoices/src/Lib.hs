module Hydra.Invoice (
  Invoice(..)
  PreImage,
  PaymentId,
  StandardInvoice,
  generatePreImage,
  hashPaymentId,
) where

import Data.Kind (Type)
import System.Random (randomRIO)
import Control.Monad (replicateM)
import Cardano.Api (Address, Value, Hash, ShelleyAddr)
import Crypto.Hash qualified as CH
import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BSL

type Invoice :: Type -> Type -> Type -> Type -> Type -> Type
data Invoice paymentIdType addressType amountType datetimeType = MkInvoice {
  paymentId :: paymentIdType,
  recipient :: addressType,
  amount :: amountType,
  date :: datetimeType
} deriving stock (Eq, Show)

type PreImage :: Type
data PreImage = UnsafePreImage { fromPreImage :: BS.ByteString }

type PaymentId :: Type
data PaymentId = UnsafePaymentId { fromPaymentId :: Hash BS.ByteString }

type StandardInvoice :: Type
type StandardInvoice = Invoice PaymentId (Address ShelleyAddr) Value UTCTime

generatePreImage :: IO PreImage
generatePreImage = UnsafePreImage . BS.pack <$> replicateM 32 (randomRIO (0, 255))

hashPaymentId :: PreImage -> PaymentId
hashPaymentId (UnsafePreImage preimage) = UnsafePaymentId (CH.hashlazy $ BSL.fromStrict preimage))

generateStandardInvoice :: Address ShelleyAddr -> Value -> UTCTime -> IO (StandardInvoice, PreImage)
generateStandardInvoice recipient amount date = do
  preImage <- generatePreImage
  let invoice = MkInvoice {
    paymentId = hashPaymentId preImage,
    receipient,
    amount,
    date
  }
  pure (invoice, preImage)
