;; Lottery System Smart Contract
;; A decentralized lottery system where users can buy tickets and winners are selected

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-lottery-not-active (err u101))
(define-constant err-lottery-active (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-no-participants (err u104))
(define-constant err-already-drawn (err u105))

;; Data Variables
(define-data-var lottery-active bool false)
(define-data-var ticket-price uint u1000000) ;; 1 STX in microSTX
(define-data-var lottery-round uint u0)
(define-data-var total-pool uint u0)
(define-data-var winner principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Data Maps
(define-map participants { round: uint, participant: principal } { tickets: uint })
(define-map round-winners { round: uint } { winner: principal, prize: uint })
(define-map participant-list { round: uint, index: uint } { participant: principal })
(define-map round-participant-count { round: uint } { count: uint })

;; Read-only functions
(define-read-only (get-lottery-status)
  {
    active: (var-get lottery-active),
    round: (var-get lottery-round),
    ticket-price: (var-get ticket-price),
    total-pool: (var-get total-pool)
  }
)

(define-read-only (get-participant-tickets (round uint) (participant principal))
  (default-to { tickets: u0 } (map-get? participants { round: round, participant: participant }))
)

(define-read-only (get-round-winner (round uint))
  (map-get? round-winners { round: round })
)

;; Public functions
(define-public (start-lottery)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (var-get lottery-active)) err-lottery-active)
    (var-set lottery-active true)
    (var-set lottery-round (+ (var-get lottery-round) u1))
    (var-set total-pool u0)
    (ok true)
  )
)

(define-public (buy-ticket)
  (let
    (
      (current-round (var-get lottery-round))
      (price (var-get ticket-price))
      (current-tickets (get tickets (get-participant-tickets current-round tx-sender)))
      (participant-count (default-to u0 (get count (map-get? round-participant-count { round: current-round }))))
    )
    (asserts! (var-get lottery-active) err-lottery-not-active)
    (asserts! (>= (stx-get-balance tx-sender) price) err-insufficient-payment)

    ;; Transfer STX to contract
    (try! (stx-transfer? price tx-sender (as-contract tx-sender)))

    ;; Update participant tickets
    (map-set participants
      { round: current-round, participant: tx-sender }
      { tickets: (+ current-tickets u1) }
    )

    ;; Add to participant list if first ticket
    (if (is-eq current-tickets u0)
      (begin
        (map-set participant-list
          { round: current-round, index: participant-count }
          { participant: tx-sender }
        )
        (map-set round-participant-count
          { round: current-round }
          { count: (+ participant-count u1) }
        )
      )
      true
    )

    ;; Update total pool
    (var-set total-pool (+ (var-get total-pool) price))
    (ok true)
  )
)

(define-public (draw-winner)
  (let
    (
      (current-round (var-get lottery-round))
      (pool (var-get total-pool))
      (participant-count (default-to u0 (get count (map-get? round-participant-count { round: current-round }))))
      (random-index (mod (+ (unwrap-panic (get-block-info? vrf-seed block-height)) current-round) participant-count))
      (winner-data (map-get? participant-list { round: current-round, index: random-index }))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (var-get lottery-active) err-lottery-not-active)
    (asserts! (> participant-count u0) err-no-participants)

    (let
      (
        (winner-principal (get participant (unwrap-panic winner-data)))
      )
      ;; Transfer prize to winner (90% of pool, 10% stays as fee)
      (let
        (
          (prize (/ (* pool u90) u100))
        )
        (try! (as-contract (stx-transfer? prize tx-sender winner-principal)))

        ;; Record winner
        (map-set round-winners
          { round: current-round }
          { winner: winner-principal, prize: prize }
        )

        ;; End lottery
        (var-set lottery-active false)
        (var-set total-pool u0)
        (var-set winner winner-principal)
        (ok winner-principal)
      )
    )
  )
)

(define-public (set-ticket-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (var-get lottery-active)) err-lottery-active)
    (var-set ticket-price new-price)
    (ok true)
  )
)

(define-public (withdraw-fees)
  (let
    (
      (balance (stx-get-balance (as-contract tx-sender)))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (var-get lottery-active)) err-lottery-active)
    (try! (as-contract (stx-transfer? balance tx-sender contract-owner)))
    (ok balance)
  )
)
