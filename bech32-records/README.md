# bech32-records

Encodes and decodes "tagged fields" represented as `Word5`s from the [bech32](https://hackage.haskell.org/package/bech32)
library.

This is the expected format for extra metadata in the [BOLT11](https://github.com/lightning/bolts/blob/master/11-payment-encoding.md#tagged-fields) spec.

A bech32 record follows the following standard adapted from the
[Tagged Fields](https://github.com/lightning/bolts/blob/master/11-payment-encoding.md#tagged-fields)
section of the BOLT11 spec.

Each Tagged Field is of the form:

type (5 bits)
data_length (10 bits, big-endian)
data (data_length x 5 bits)

This is deserialised into a `Map` where the key is a single `Word5` and the value is the `data`.
