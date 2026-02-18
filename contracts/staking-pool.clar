;; Staking Pool Smart Contract
;; Stake STX tokens and earn rewards

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-insufficient-balance (err u900))
(define-constant err-no-stake (err u901))
(define-constant err-insufficient-rewards (err u902))
(define-constant err-owner-only (err u903))
(define-constant err-invalid-amount (err u904))

;; Data Variables
(define-data-var total-staked uint u0)
(define-data-var reward-rate uint u100) ;; 1% per epoch (100 basis points)
(define-data-var total-rewards-distributed uint u0)

;; Data Maps
(define-map stakes
  { staker: principal }
  {
    amount: uint,
    start-height: uint,
    last-claim-height: uint
  }
)

(define-map staker-list
  { index: uint }
  { staker: principal }
)

(define-map staker-count
  { dummy: bool }
  { count: uint }
)

;; Initialize
(map-set staker-count { dummy: true } { count: u0 })

;; Read-only functions
(define-read-only (get-stake (staker principal))
  (map-get? stakes { staker: staker })
)

(define-read-only (get-total-staked)
  (var-get total-staked)
)

(define-read-only (get-reward-rate)
  (var-get reward-rate)
)

(define-read-only (calculate-rewards (staker principal))
  (match (map-get? stakes { staker: staker })
    stake-info
      (let
        (
          (blocks-staked (- block-height (get last-claim-height stake-info)))
          (stake-amount (get amount stake-info))
          (rewards (/ (* (* stake-amount (var-get reward-rate)) blocks-staked) u1000000))
        )
        (ok rewards)
      )
    (err err-no-stake)
  )
)

;; Public functions
(define-public (stake (amount uint))
  (let
    (
      (existing-stake (map-get? stakes { staker: tx-sender }))
      (staker-idx (default-to u0 (get count (map-get? staker-count { dummy: true }))))
    )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= (stx-get-balance tx-sender) amount) err-insufficient-balance)

    ;; Transfer STX to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    (match existing-stake
      stake-info
        ;; Update existing stake
        (map-set stakes
          { staker: tx-sender }
          {
            amount: (+ (get amount stake-info) amount),
            start-height: (get start-height stake-info),
            last-claim-height: block-height
          }
        )
      ;; Create new stake
      (begin
        (map-set stakes
          { staker: tx-sender }
          {
            amount: amount,
            start-height: block-height,
            last-claim-height: block-height
          }
        )
        (map-set staker-list { index: staker-idx } { staker: tx-sender })
        (map-set staker-count { dummy: true } { count: (+ staker-idx u1) })
      )
    )

    (var-set total-staked (+ (var-get total-staked) amount))
    (ok true)
  )
)

(define-public (unstake (amount uint))
  (let
    (
      (stake-info (unwrap! (map-get? stakes { staker: tx-sender }) err-no-stake))
    )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= (get amount stake-info) amount) err-insufficient-balance)

    ;; Claim rewards first
    (try! (claim-rewards))

    ;; Transfer STX back to staker
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))

    (let
      (
        (new-amount (- (get amount stake-info) amount))
      )
      (if (is-eq new-amount u0)
        (map-delete stakes { staker: tx-sender })
        (map-set stakes
          { staker: tx-sender }
          (merge stake-info { amount: new-amount })
        )
      )
    )

    (var-set total-staked (- (var-get total-staked) amount))
    (ok true)
  )
)

(define-public (claim-rewards)
  (let
    (
      (stake-info (unwrap! (map-get? stakes { staker: tx-sender }) err-no-stake))
      (rewards (unwrap! (calculate-rewards tx-sender) err-no-stake))
    )
    (asserts! (> rewards u0) err-invalid-amount)

    ;; Transfer rewards
    (try! (as-contract (stx-transfer? rewards tx-sender tx-sender)))

    ;; Update last claim height
    (map-set stakes
      { staker: tx-sender }
      (merge stake-info { last-claim-height: block-height })
    )

    (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) rewards))
    (ok rewards)
  )
)

(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-rate u10000) err-invalid-amount) ;; Max 100%
    (var-set reward-rate new-rate)
    (ok true)
  )
)

(define-public (fund-rewards (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok true)
  )
)

(define-public (emergency-withdraw)
  (let
    (
      (balance (stx-get-balance (as-contract tx-sender)))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (as-contract (stx-transfer? balance tx-sender contract-owner)))
    (ok balance)
  )
)
