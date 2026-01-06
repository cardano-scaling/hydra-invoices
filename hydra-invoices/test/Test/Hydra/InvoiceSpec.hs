module Test.Hydra.InvoiceSpec (
  tests,
)
where

import "base" Control.Monad (guard)
import "cardano-api" Cardano.Api qualified as C
import "cardano-api" Cardano.Api.Ledger qualified as L
import "cardano-api" Cardano.Api.Tx qualified as A
import "cardano-api" Test.Gen.Cardano.Api.Typed qualified as Gen
import "hedgehog" Hedgehog (Gen, MonadGen, Property, forAll, property, tripping)
import "hedgehog" Hedgehog.Gen qualified as Gen
import "hedgehog" Hedgehog.Range qualified as Range
import "hydra-invoices" Hydra.Invoice qualified as H
import "tasty" Test.Tasty (TestTree, testGroup)
import "tasty-hedgehog" Test.Tasty.Hedgehog (testProperty)
import "text" Data.Text qualified as Text
import "time" Data.Time (UTCTime (UTCTime), fromGregorian, secondsToDiffTime)

genLedgerValue ::
  C.MaryEraOnwards era -> Gen C.AssetId -> Gen C.Quantity -> Gen (L.Value (C.ShelleyLedgerEra era))
genLedgerValue w genAId genQuant =
  C.toLedgerValue w <$> Gen.genValue genAId genQuant

-- | Generate a 'Value' suitable for usage in a transaction output, i.e. any
-- asset ID and a positive quantity.
genLedgerValueForTxOut :: C.ShelleyBasedEra era -> Gen (L.Value (C.ShelleyLedgerEra era))
genLedgerValueForTxOut sbe = do
  -- Generate at least one positive ADA, without it Value in TxOut makes no sense
  -- and will fail deserialization starting with ConwayEra
  ada <- A.mkAdaValue sbe . L.Coin <$> Gen.integral (Range.constant 1 2)

  -- Generate a potentially empty list with multi assets
  C.caseShelleyToAllegraOrMaryEraOnwards
    (const (pure ada))
    ( \w -> do
        v <- Gen.list (Range.constant 0 3) $ genLedgerValue w Gen.genAssetId Gen.genPositiveQuantity
        pure $ ada <> mconcat v
    )
    sbe

-- | Generate a 'Value' suitable for use in a transaction output, with non-zero ADA,
-- any asset IDs and with positive quantities
genValueForTxOut :: C.ShelleyBasedEra era -> Gen C.Value
genValueForTxOut w = C.fromLedgerValue w <$> genLedgerValueForTxOut w

genUTCTime :: MonadGen m => m UTCTime
genUTCTime = do
  year <- Gen.integral (Range.linear 1900 2100)
  month <- Gen.integral (Range.linear 1 12)
  day <- Gen.integral (Range.linear 1 28)
  let utcDay = fromGregorian year month day
  seconds <- Gen.integral (Range.linear 0 86399)
  let utcDayTime = secondsToDiffTime seconds
  pure $ UTCTime utcDay utcDayTime

genInvoiceData :: C.ShelleyBasedEra era -> Gen (C.Address C.ShelleyAddr, C.Value, UTCTime)
genInvoiceData sbe = do
  address <- Gen.genAddressShelley
  value <- genValueForTxOut sbe
  time <- genUTCTime
  pure (address, value, time)

prop_roundtrip_address :: Property
prop_roundtrip_address = property $ do
  address <- forAll Gen.genAddressShelley
  tripping address H.shelleyAddrToWords H.wordsToShelleyAddr

prop_roundtrip_paymentId :: Property
prop_roundtrip_paymentId = property $ do
  (paymentId, _) <- C.liftIO H.generatePaymentId
  tripping paymentId H.paymentIdToWords H.wordsToPaymentId

prop_roundtrip_utcTime :: Property
prop_roundtrip_utcTime = property $ do
  address <- forAll genUTCTime
  tripping address H.utcTimeToWords H.wordsToUtcTime

prop_roundtrip_value :: Property
prop_roundtrip_value = property $ do
  value <- forAll $ Gen.genValueForTxOut $ C.shelleyBasedEra @C.ConwayEra
  tripping value H.valueToWords H.wordsToValue

prop_roundtrip_standard_invoice_fields :: Property
prop_roundtrip_standard_invoice_fields = property $ do
  (address, value, time) <- forAll (genInvoiceData $ C.shelleyBasedEra @C.ConwayEra)
  (inv, _) <- C.liftIO $ H.generateStandardInvoice address value time
  tripping inv H.standardInvoiceToRecord H.recordToStandardInvoice

prop_roundtrip_standard_invoice_bech32 :: Property
prop_roundtrip_standard_invoice_bech32 = property $ do
  (address, value, time) <- forAll (genInvoiceData $ C.shelleyBasedEra @C.ConwayEra)
  (inv, _) <- C.liftIO $ H.generateStandardInvoice address value time
  guard $ Text.length (H.encodeStandardInvoice inv) < 1024
  tripping inv H.encodeStandardInvoice H.decodeStandardInvoice

tests :: TestTree
tests = do
  testGroup
    "Hydra.Invoice"
    [ testProperty "roundtrip shelley address" prop_roundtrip_address
    , testProperty "roundtrip payment id" prop_roundtrip_paymentId
    , testProperty "roundtrip utc time" prop_roundtrip_utcTime
    , testProperty "roundtrip value" prop_roundtrip_value
    , testProperty "roundtrip standard invoice fields" prop_roundtrip_standard_invoice_fields
    , testProperty "roundtrip standard invoice bech32" prop_roundtrip_standard_invoice_bech32
    ]
