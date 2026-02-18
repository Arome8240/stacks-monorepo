;; Escrow Service Smart Contract
;; Secure peer-to-peer transactions with escrow

;; Constants
(define-constant err-escrow-not-found (err u700))
(define-constant err-not-buyer (err u701))
(define-constant err-not-seller (err u702))
(define-constant err-not-arbiter (err u703))
(define-constant err-already-funded (err u704))
(define-constant err-not-funded (err u705))
(define-constant err-already-completed (err u706))
(define-constant err-invalid-amount (err u707))

;; Data Variables
(define-data-var escrow-counter uint u0)
(define-data-var platform-fee uint u250) ;; 2.5% fee

;; Data Maps
(define-map escrows
  { escrow-id: uint }
  {
    buyer: principal,
    seller: principal,
    arbiter: principal,
    amount: uint,
    funded: bool,
    completed: bool,
    released-to-seller: bool,
    refunded-to-buyer: bool
  }
)

;; Read-only functions
(define-read-only (get-escrow (escrow-id uint))
  (map-get? escrows { escrow-id: escrow-id })
)

(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

(define-read-only (calculate-fee (amount uint))
  (/ (* amount (var-get platform-fee)) u10000)
)

;; Public functions
(define-public (create-escrow (seller principal) (arbiter principal) (amount uint))
  (let
    (
      (escrow-id (+ (var-get escrow-counter) u1))
    )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (not (is-eq tx-sender seller)) err-not-buyer)
    (asserts! (not (is-eq tx-sender arbiter)) err-not-buyer)

    (map-set escrows
      { escrow-id: escrow-id }
      {
        buyer: tx-sender,
        seller: seller,
        arbiter: arbiter,
        amount: amount,
        funded: false,
        completed: false,
        released-to-seller: false,
        refunded-to-buyer: false
      }
    )

    (var-set escrow-counter escrow-id)
    (ok escrow-id)
  )
)

(define-public (fund-escrow (escrow-id uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) err-escrow-not-found))
    )
    (asserts! (is-eq tx-sender (get buyer escrow)) err-not-buyer)
    (asserts! (not (get funded escrow)) err-already-funded)
    (asserts! (>= (stx-get-balance tx-sender) (get amount escrow)) err-invalid-amount)

    ;; Transfer funds to contract
    (try! (stx-transfer? (get amount escrow) tx-sender (as-contract tx-sender)))

    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow { funded: true })
    )

    (ok true)
  )
)

(define-public (release-to-seller (escrow-id uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) err-escrow-not-found))
      (fee (calculate-fee (get amount escrow)))
      (seller-amount (- (get amount escrow) fee))
    )
    (asserts! (is-eq tx-sender (get buyer escrow)) err-not-buyer)
    (asserts! (get funded escrow) err-not-funded)
    (asserts! (not (get completed escrow)) err-already-completed)

    ;; Transfer to seller (minus fee)
    (try! (as-contract (stx-transfer? seller-amount tx-sender (get seller escrow))))

    ;; Transfer fee to contract owner
    (try! (as-contract (stx-transfer? fee tx-sender (get arbiter escrow))))

    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow { completed: true, released-to-seller: true })
    )

    (ok true)
  )
)

(define-public (refund-to-buyer (escrow-id uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) err-escrow-not-found))
    )
    (asserts! (is-eq tx-sender (get seller escrow)) err-not-seller)
    (asserts! (get funded escrow) err-not-funded)
    (asserts! (not (get completed escrow)) err-already-completed)

    ;; Refund to buyer
    (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get buyer escrow))))

    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow { completed: true, refunded-to-buyer: true })
    )

    (ok true)
  )
)

(define-public (arbiter-release (escrow-id uint) (release-to-seller bool))
  (let
    (
      (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) err-escrow-not-found))
      (fee (calculate-fee (get amount escrow)))
    )
    (asserts! (is-eq tx-sender (get arbiter escrow)) err-not-arbiter)
    (asserts! (get funded escrow) err-not-funded)
    (asserts! (not (get completed escrow)) err-already-completed)

    (if release-to-seller
      (let
        (
          (seller-amount (- (get amount escrow) fee))
        )
        ;; Release to seller
        (try! (as-contract (stx-transfer? seller-amount tx-sender (get seller escrow))))
        (try! (as-contract (stx-transfer? fee tx-sender (get arbiter escrow))))

        (map-set escrows
          { escrow-id: escrow-id }
          (merge escrow { completed: true, released-to-seller: true })
        )
      )
      (begin
        ;; Refund to buyer
        (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get buyer escrow))))

        (map-set escrows
          { escrow-id: escrow-id }
          (merge escrow { completed: true, refunded-to-buyer: true })
        )
      )
    )

    (ok true)
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (<= new-fee u1000) err-invalid-amount) ;; Max 10%
    (var-set platform-fee new-fee)
    (ok true)
  )
)
