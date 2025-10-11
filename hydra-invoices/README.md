# hydra-invoices

Invoice types and functions for use with Hydra Lightning payments.

An `Invoice` is a request for payment of a certain amount.

You can use the `Hydra.Invoice.StandardInvoice` type for the most common use case - which
uses standard types from `cardano-api` for its fields.
