;; Token Vault Smart Contract
;; Secure storage and management of fungible tokens

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u1000))
(define-constant err-vault-not-found (err u1001))
(define-constant err-not-vault-owner (err u1002))
(define-constant err-insufficient-balance (err u1003))
(define-constant err-invalid-amount (err u1004))
(define-constant err-vault-locked (err u1005))

;; Fungible Token Definition
(define-fungible-token vault-token)

;; Data Variables
(define-data-var vault-counter uint u0)
(define-data-var total-supply uint u0)

;; Data Maps
(define-map vaults
  { vault-id: uint }
  {
    owner: principal,
    balance: uint,
    locked: bool,
    unlock-height: uint
  }
)

(define-map user-vaults
  { owner: principal, index: uint }
  { vault-id: uint }
)

(define-map user-vault-count
  { owner: principal }
  { count: uint }
)

;; Read-only functions
(define-read-only (get-vault (vault-id uint))
  (map-get? vaults { vault-id: vault-id })
)

(define-read-only (get-user-vault-count (owner principal))
  (default-to u0 (get count (map-get? user-vault-count { owner: owner })))
)

(define-read-only (get-user-vault-id (owner principal) (index uint))
  (map-get? user-vaults { owner: owner, index: index })
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance vault-token account))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply vault-token))
)

(define-read-only (is-vault-unlocked (vault-id uint))
  (match (map-get? vaults { vault-id: vault-id })
    vault (ok (or
      (not (get locked vault))
      (>= block-height (get unlock-height vault))
    ))
    (err err-vault-not-found)
  )
)

;; Public functions
(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-amount)
    (try! (ft-mint? vault-token amount recipient))
    (var-set total-supply (+ (var-get total-supply) amount))
    (ok true)
  )
)

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-vault-owner)
    (asserts! (> amount u0) err-invalid-amount)
    (try! (ft-transfer? vault-token amount sender recipient))
    (ok true)
  )
)

(define-public (create-vault (initial-deposit uint) (locked bool) (unlock-height uint))
  (let
    (
      (vault-id (+ (var-get vault-counter) u1))
      (user-count (get-user-vault-count tx-sender))
    )
    (asserts! (> initial-deposit u0) err-invalid-amount)
    (asserts! (>= (ft-get-balance vault-token tx-sender) initial-deposit) err-insufficient-balance)

    (if locked
      (asserts! (> unlock-height block-height) err-invalid-amount)
      true
    )

    ;; Transfer tokens to contract
    (unwrap! (ft-transfer? vault-token initial-deposit tx-sender (as-contract tx-sender)) err-insufficient-balance)

    ;; Create vault
    (map-set vaults
      { vault-id: vault-id }
      {
        owner: tx-sender,
        balance: initial-deposit,
        locked: locked,
        unlock-height: unlock-height
      }
    )

    ;; Add to user's vault list
    (map-set user-vaults
      { owner: tx-sender, index: user-count }
      { vault-id: vault-id }
    )

    (map-set user-vault-count
      { owner: tx-sender }
      { count: (+ user-count u1) }
    )

    (var-set vault-counter vault-id)
    (ok vault-id)
  )
)

(define-public (deposit-to-vault (vault-id uint) (amount uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-vault-not-found))
    )
    (asserts! (is-eq tx-sender (get owner vault)) err-not-vault-owner)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= (ft-get-balance vault-token tx-sender) amount) err-insufficient-balance)

    ;; Transfer tokens to contract
    (unwrap! (ft-transfer? vault-token amount tx-sender (as-contract tx-sender)) err-insufficient-balance)

    ;; Update vault balance
    (map-set vaults
      { vault-id: vault-id }
      (merge vault { balance: (+ (get balance vault) amount) })
    )

    (ok true)
  )
)

(define-public (withdraw-from-vault (vault-id uint) (amount uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-vault-not-found))
    )
    (asserts! (is-eq tx-sender (get owner vault)) err-not-vault-owner)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= (get balance vault) amount) err-insufficient-balance)

    ;; Check if vault is unlocked
    (if (get locked vault)
      (asserts! (>= block-height (get unlock-height vault)) err-vault-locked)
      true
    )

    ;; Transfer tokens back to owner
    (unwrap! (as-contract (ft-transfer? vault-token amount tx-sender (get owner vault))) err-insufficient-balance)

    ;; Update vault balance
    (map-set vaults
      { vault-id: vault-id }
      (merge vault { balance: (- (get balance vault) amount) })
    )

    (ok true)
  )
)

(define-public (unlock-vault (vault-id uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-vault-not-found))
    )
    (asserts! (is-eq tx-sender (get owner vault)) err-not-vault-owner)
    (asserts! (get locked vault) err-vault-not-found)
    (asserts! (>= block-height (get unlock-height vault)) err-vault-locked)

    (map-set vaults
      { vault-id: vault-id }
      (merge vault { locked: false })
    )

    (ok true)
  )
)

(define-public (extend-lock (vault-id uint) (new-unlock-height uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-vault-not-found))
    )
    (asserts! (is-eq tx-sender (get owner vault)) err-not-vault-owner)
    (asserts! (get locked vault) err-vault-not-found)
    (asserts! (> new-unlock-height (get unlock-height vault)) err-invalid-amount)

    (map-set vaults
      { vault-id: vault-id }
      (merge vault { unlock-height: new-unlock-height })
    )

    (ok true)
  )
)
