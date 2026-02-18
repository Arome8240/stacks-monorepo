;; Multi-Signature Wallet Smart Contract
;; Requires multiple signatures to execute transactions

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-not-signer (err u401))
(define-constant err-already-signed (err u402))
(define-constant err-tx-not-found (err u403))
(define-constant err-already-executed (err u404))
(define-constant err-insufficient-signatures (err u405))
(define-constant err-invalid-threshold (err u406))

;; Data Variables
(define-data-var required-signatures uint u2)
(define-data-var transaction-counter uint u0)

;; Data Maps
(define-map signers principal bool)
(define-map signer-count { dummy: bool } { count: uint })

(define-map transactions
  { tx-id: uint }
  {
    to: principal,
    amount: uint,
    executed: bool,
    signature-count: uint,
    created-by: principal
  }
)

(define-map transaction-signatures
  { tx-id: uint, signer: principal }
  { signed: bool }
)

;; Initialize contract with owner as first signer
(map-set signers contract-owner true)
(map-set signer-count { dummy: true } { count: u1 })

;; Read-only functions
(define-read-only (is-signer (address principal))
  (default-to false (map-get? signers address))
)

(define-read-only (get-required-signatures)
  (var-get required-signatures)
)

(define-read-only (get-transaction (tx-id uint))
  (map-get? transactions { tx-id: tx-id })
)

(define-read-only (has-signed (tx-id uint) (signer principal))
  (default-to false (get signed (map-get? transaction-signatures { tx-id: tx-id, signer: signer })))
)

(define-read-only (get-signer-count)
  (default-to u0 (get count (map-get? signer-count { dummy: true })))
)

;; Public functions
(define-public (add-signer (new-signer principal))
  (let
    (
      (current-count (get-signer-count))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (is-signer new-signer)) err-already-signed)

    (map-set signers new-signer true)
    (map-set signer-count { dummy: true } { count: (+ current-count u1) })
    (ok true)
  )
)

(define-public (remove-signer (signer principal))
  (let
    (
      (current-count (get-signer-count))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-signer signer) err-not-signer)
    (asserts! (> current-count (var-get required-signatures)) err-invalid-threshold)

    (map-delete signers signer)
    (map-set signer-count { dummy: true } { count: (- current-count u1) })
    (ok true)
  )
)

(define-public (set-required-signatures (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-threshold u0) err-invalid-threshold)
    (asserts! (<= new-threshold (get-signer-count)) err-invalid-threshold)
    (var-set required-signatures new-threshold)
    (ok true)
  )
)

(define-public (submit-transaction (to principal) (amount uint))
  (let
    (
      (tx-id (+ (var-get transaction-counter) u1))
    )
    (asserts! (is-signer tx-sender) err-not-signer)

    (map-set transactions
      { tx-id: tx-id }
      {
        to: to,
        amount: amount,
        executed: false,
        signature-count: u1,
        created-by: tx-sender
      }
    )

    (map-set transaction-signatures
      { tx-id: tx-id, signer: tx-sender }
      { signed: true }
    )

    (var-set transaction-counter tx-id)
    (ok tx-id)
  )
)

(define-public (sign-transaction (tx-id uint))
  (let
    (
      (tx (unwrap! (map-get? transactions { tx-id: tx-id }) err-tx-not-found))
    )
    (asserts! (is-signer tx-sender) err-not-signer)
    (asserts! (not (get executed tx)) err-already-executed)
    (asserts! (not (has-signed tx-id tx-sender)) err-already-signed)

    (map-set transaction-signatures
      { tx-id: tx-id, signer: tx-sender }
      { signed: true }
    )

    (map-set transactions
      { tx-id: tx-id }
      (merge tx { signature-count: (+ (get signature-count tx) u1) })
    )

    (ok true)
  )
)

(define-public (execute-transaction (tx-id uint))
  (let
    (
      (tx (unwrap! (map-get? transactions { tx-id: tx-id }) err-tx-not-found))
    )
    (asserts! (is-signer tx-sender) err-not-signer)
    (asserts! (not (get executed tx)) err-already-executed)
    (asserts! (>= (get signature-count tx) (var-get required-signatures)) err-insufficient-signatures)

    ;; Execute the transaction
    (unwrap! (as-contract (stx-transfer? (get amount tx) tx-sender (get to tx))) err-insufficient-signatures)

    (map-set transactions
      { tx-id: tx-id }
      (merge tx { executed: true })
    )

    (ok true)
  )
)

(define-public (deposit (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok true)
  )
)
