;; Time-Locked Vault Smart Contract
;; Allows users to lock STX tokens until a specific block height

;; Constants
(define-constant err-vault-not-found (err u300))
(define-constant err-not-vault-owner (err u301))
(define-constant err-vault-locked (err u302))
(define-constant err-insufficient-balance (err u303))
(define-constant err-invalid-unlock-height (err u304))

;; Data Variables
(define-data-var vault-counter uint u0)

;; Data Maps
(define-map vaults
  { vault-id: uint }
  {
    owner: principal,
    amount: uint,
    unlock-height: uint,
    withdrawn: bool
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

(define-read-only (is-unlocked (vault-id uint))
  (match (map-get? vaults { vault-id: vault-id })
    vault (ok (>= block-height (get unlock-height vault)))
    (err err-vault-not-found)
  )
)

;; Public functions
(define-public (create-vault (amount uint) (unlock-height uint))
  (let
    (
      (vault-id (+ (var-get vault-counter) u1))
      (user-count (get-user-vault-count tx-sender))
    )
    (asserts! (> amount u0) err-insufficient-balance)
    (asserts! (> unlock-height block-height) err-invalid-unlock-height)
    (asserts! (>= (stx-get-balance tx-sender) amount) err-insufficient-balance)

    ;; Transfer STX to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Create vault
    (map-set vaults
      { vault-id: vault-id }
      {
        owner: tx-sender,
        amount: amount,
        unlock-height: unlock-height,
        withdrawn: false
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

(define-public (withdraw (vault-id uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-vault-not-found))
    )
    (asserts! (is-eq tx-sender (get owner vault)) err-not-vault-owner)
    (asserts! (not (get withdrawn vault)) err-vault-not-found)
    (asserts! (>= block-height (get unlock-height vault)) err-vault-locked)

    ;; Transfer STX back to owner
    (try! (as-contract (stx-transfer? (get amount vault) tx-sender (get owner vault))))

    ;; Mark as withdrawn
    (map-set vaults
      { vault-id: vault-id }
      (merge vault { withdrawn: true })
    )

    (ok (get amount vault))
  )
)

(define-public (extend-lock (vault-id uint) (new-unlock-height uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-vault-not-found))
    )
    (asserts! (is-eq tx-sender (get owner vault)) err-not-vault-owner)
    (asserts! (not (get withdrawn vault)) err-vault-not-found)
    (asserts! (> new-unlock-height (get unlock-height vault)) err-invalid-unlock-height)

    (map-set vaults
      { vault-id: vault-id }
      (merge vault { unlock-height: new-unlock-height })
    )

    (ok true)
  )
)

(define-public (add-to-vault (vault-id uint) (additional-amount uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-vault-not-found))
    )
    (asserts! (is-eq tx-sender (get owner vault)) err-not-vault-owner)
    (asserts! (not (get withdrawn vault)) err-vault-not-found)
    (asserts! (> additional-amount u0) err-insufficient-balance)
    (asserts! (>= (stx-get-balance tx-sender) additional-amount) err-insufficient-balance)

    ;; Transfer additional STX to contract
    (try! (stx-transfer? additional-amount tx-sender (as-contract tx-sender)))

    ;; Update vault amount
    (map-set vaults
      { vault-id: vault-id }
      (merge vault { amount: (+ (get amount vault) additional-amount) })
    )

    (ok true)
  )
)
