# Changelog for hydra-invoices

## 0.0.4.0

* Add missing `Eq` and `Show` instances to `PaymentId`.

## 0.0.3.0

* Change hashing algorithm from `SHA256` to `Blake2b_256`.

## 0.0.2.0

* Use `Value` instead of `TxOutValue` in `StandardInvoice`

## 0.0.1.0

* Initial commit of `hydra-invoices`.
* Add `Invoice` type with parameterisable fields.
* Add `StandardInvoice` type with typical field types for use with `cardano-api`.
* Add `generateStandardInvoice` function.
