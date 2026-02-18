;; DAO Governance Smart Contract
;; Decentralized voting and proposal system

;; Constants
(define-constant err-not-member (err u600))
(define-constant err-proposal-not-found (err u601))
(define-constant err-already-voted (err u602))
(define-constant err-voting-ended (err u603))
(define-constant err-voting-active (err u604))
(define-constant err-proposal-not-passed (err u605))
(define-constant err-already-executed (err u606))
(define-constant err-invalid-amount (err u607))

;; Data Variables
(define-data-var proposal-counter uint u0)
(define-data-var voting-period uint u144) ;; ~1 day in blocks
(define-data-var quorum-percentage uint u5000) ;; 50% in basis points
(define-data-var total-members uint u0)

;; Data Maps
(define-map members principal { voting-power: uint, joined-at: uint })

(define-map proposals
  { proposal-id: uint }
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    votes-for: uint,
    votes-against: uint,
    end-height: uint,
    executed: bool,
    passed: bool
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, power: uint }
)

;; Read-only functions
(define-read-only (is-member (address principal))
  (is-some (map-get? members address))
)

(define-read-only (get-member-info (address principal))
  (map-get? members address)
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (is-some (map-get? votes { proposal-id: proposal-id, voter: voter }))
)

(define-read-only (calculate-quorum)
  (let
    (
      (total (var-get total-members))
      (percentage (var-get quorum-percentage))
    )
    (/ (* total percentage) u10000)
  )
)

;; Public functions
(define-public (join-dao (voting-power uint))
  (begin
    (asserts! (not (is-member tx-sender)) err-already-voted)
    (asserts! (> voting-power u0) err-invalid-amount)

    ;; Require staking some STX to join
    (try! (stx-transfer? (* voting-power u1000000) tx-sender (as-contract tx-sender)))

    (map-set members tx-sender { voting-power: voting-power, joined-at: block-height })
    (var-set total-members (+ (var-get total-members) u1))
    (ok true)
  )
)

(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 500)))
  (let
    (
      (proposal-id (+ (var-get proposal-counter) u1))
      (end-height (+ block-height (var-get voting-period)))
    )
    (asserts! (is-member tx-sender) err-not-member)

    (map-set proposals
      { proposal-id: proposal-id }
      {
        proposer: tx-sender,
        title: title,
        description: description,
        votes-for: u0,
        votes-against: u0,
        end-height: end-height,
        executed: false,
        passed: false
      }
    )

    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

(define-public (vote (proposal-id uint) (vote-for bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-proposal-not-found))
      (member-info (unwrap! (map-get? members tx-sender) err-not-member))
      (voting-power (get voting-power member-info))
    )
    (asserts! (< block-height (get end-height proposal)) err-voting-ended)
    (asserts! (not (has-voted proposal-id tx-sender)) err-already-voted)

    ;; Record vote
    (map-set votes
      { proposal-id: proposal-id, voter: tx-sender }
      { vote: vote-for, power: voting-power }
    )

    ;; Update proposal vote counts
    (if vote-for
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-for: (+ (get votes-for proposal) voting-power) })
      )
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-against: (+ (get votes-against proposal) voting-power) })
      )
    )

    (ok true)
  )
)

(define-public (finalize-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-proposal-not-found))
      (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
      (quorum (calculate-quorum))
    )
    (asserts! (>= block-height (get end-height proposal)) err-voting-active)
    (asserts! (not (get executed proposal)) err-already-executed)

    (let
      (
        (passed (and
          (>= total-votes quorum)
          (> (get votes-for proposal) (get votes-against proposal))
        ))
      )
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { executed: true, passed: passed })
      )
      (ok passed)
    )
  )
)

(define-public (increase-voting-power (additional-power uint))
  (let
    (
      (member-info (unwrap! (map-get? members tx-sender) err-not-member))
      (current-power (get voting-power member-info))
    )
    (asserts! (> additional-power u0) err-invalid-amount)

    ;; Stake additional STX
    (try! (stx-transfer? (* additional-power u1000000) tx-sender (as-contract tx-sender)))

    (map-set members tx-sender
      (merge member-info { voting-power: (+ current-power additional-power) })
    )
    (ok true)
  )
)

(define-public (set-voting-period (new-period uint))
  (begin
    (asserts! (is-member tx-sender) err-not-member)
    (var-set voting-period new-period)
    (ok true)
  )
)
