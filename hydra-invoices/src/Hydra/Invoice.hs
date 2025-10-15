module Hydra.Invoice (
  Invoice (..),
  PreImage (..),
  PaymentId (..),
  StandardInvoice,
  generatePreImage,
  hashPaymentId,
  generateStandardInvoice,
) where

import Cardano.Api (Address, ShelleyAddr, Value)
import Cardano.Crypto.Hash qualified as Crypto
import Control.Monad (replicateM)
import Data.ByteString qualified as BS
import Data.Kind (Type)
import Data.Time (UTCTime)
import System.Random (randomRIO)

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
  deriving stock (Show, Eq)

type StandardInvoice :: Type
type StandardInvoice = Invoice PaymentId (Address ShelleyAddr) Value UTCTime

generatePreImage :: IO PreImage
generatePreImage = UnsafePreImage . BS.pack <$> replicateM 32 (randomRIO (0, 255))

hashPaymentId :: PreImage -> PaymentId
hashPaymentId (UnsafePreImage preimage) =
  UnsafePaymentId $ Crypto.hashWith id preimage

generateStandardInvoice :: Address ShelleyAddr -> Value -> UTCTime -> IO (StandardInvoice, PreImage)
generateStandardInvoice recipient amount date = do
  preImage <- generatePreImage
  let invoice =
        MkInvoice
          { paymentId = hashPaymentId preImage
          , recipient
          , amount
          , date
          }
  pure (invoice, preImage)
