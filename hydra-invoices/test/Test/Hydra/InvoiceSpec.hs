module Test.Hydra.InvoiceSpec where

import Cardano.Binary (toCBOR, fromCBOR, serialize, decodeFull)
import Cardano.Api qualified as C
import Hydra.Invoice
import Hedgehog (tripping, forAll, (===), Property, Gen, property, GenT, MonadGen)
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Test.Gen.Cardano.Api.Typed (genAddressShelley, genValueForTxOut)
import Data.Time (UTCTime(UTCTime), fromGregorian, secondsToDiffTime)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.Hedgehog (testProperty)

genUTCTime :: MonadGen m => m UTCTime
genUTCTime = do
  year <- Gen.integral (Range.linear 1900 2100)
  month <- Gen.integral (Range.linear 1 12)
  day <- Gen.integral (Range.linear 1 28)
  let utcDay = fromGregorian year month day
  seconds <- Gen.integral (Range.linear 0 86399)
  let utcDayTime = secondsToDiffTime seconds
  pure $ UTCTime utcDay utcDayTime

genInvoiceData :: Gen (C.Address C.ShelleyAddr, C.Value, UTCTime)
genInvoiceData = do
  address <- genAddressShelley
  value <- genValueForTxOut (C.shelleyBasedEra @C.ConwayEra)
  time <- genUTCTime
  pure (address, value, time)

prop_roundtrip_standard_invoice :: Property
prop_roundtrip_standard_invoice = property $ do
  (address, value, time) <- forAll genInvoiceData
  (inv, _) <- C.liftIO $ generateStandardInvoice address value time
  tripping inv serialize decodeFull

tests :: TestTree
tests = do
  testGroup "Hydra.Invoice"
    [ testProperty "roundtrip standard invoice" prop_roundtrip_standard_invoice
    ]
