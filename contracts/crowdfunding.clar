;; Crowdfunding Smart Contract
;; Create and fund crowdfunding campaigns

;; Constants
(define-constant err-campaign-not-found (err u500))
(define-constant err-campaign-ended (err u501))
(define-constant err-campaign-active (err u502))
(define-constant err-goal-not-reached (err u503))
(define-constant err-goal-reached (err u504))
(define-constant err-not-campaign-owner (err u505))
(define-constant err-invalid-amount (err u506))
(define-constant err-already-claimed (err u507))

;; Data Variables
(define-data-var campaign-counter uint u0)

;; Data Maps
(define-map campaigns
  { campaign-id: uint }
  {
    owner: principal,
    title: (string-ascii 100),
    goal: uint,
    raised: uint,
    end-height: uint,
    claimed: bool
  }
)

(define-map contributions
  { campaign-id: uint, contributor: principal }
  { amount: uint }
)

(define-map campaign-contributors
  { campaign-id: uint, index: uint }
  { contributor: principal }
)

(define-map campaign-contributor-count
  { campaign-id: uint }
  { count: uint }
)

;; Read-only functions
(define-read-only (get-campaign (campaign-id uint))
  (map-get? campaigns { campaign-id: campaign-id })
)

(define-read-only (get-contribution (campaign-id uint) (contributor principal))
  (default-to { amount: u0 } (map-get? contributions { campaign-id: campaign-id, contributor: contributor }))
)

(define-read-only (is-campaign-successful (campaign-id uint))
  (match (map-get? campaigns { campaign-id: campaign-id })
    campaign (ok (and
      (>= (get raised campaign) (get goal campaign))
      (>= block-height (get end-height campaign))
    ))
    (err err-campaign-not-found)
  )
)

(define-read-only (is-campaign-active (campaign-id uint))
  (match (map-get? campaigns { campaign-id: campaign-id })
    campaign (ok (< block-height (get end-height campaign)))
    (err err-campaign-not-found)
  )
)

;; Public functions
(define-public (create-campaign (title (string-ascii 100)) (goal uint) (duration uint))
  (let
    (
      (campaign-id (+ (var-get campaign-counter) u1))
      (end-height (+ block-height duration))
    )
    (asserts! (> goal u0) err-invalid-amount)
    (asserts! (> duration u0) err-invalid-amount)

    (map-set campaigns
      { campaign-id: campaign-id }
      {
        owner: tx-sender,
        title: title,
        goal: goal,
        raised: u0,
        end-height: end-height,
        claimed: false
      }
    )

    (map-set campaign-contributor-count
      { campaign-id: campaign-id }
      { count: u0 }
    )

    (var-set campaign-counter campaign-id)
    (ok campaign-id)
  )
)

(define-public (contribute (campaign-id uint) (amount uint))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) err-campaign-not-found))
      (current-contribution (get amount (get-contribution campaign-id tx-sender)))
      (contributor-count (default-to u0 (get count (map-get? campaign-contributor-count { campaign-id: campaign-id }))))
    )
    (asserts! (< block-height (get end-height campaign)) err-campaign-ended)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= (stx-get-balance tx-sender) amount) err-invalid-amount)

    ;; Transfer STX to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Update contribution
    (map-set contributions
      { campaign-id: campaign-id, contributor: tx-sender }
      { amount: (+ current-contribution amount) }
    )

    ;; Add to contributor list if first contribution
    (if (is-eq current-contribution u0)
      (begin
        (map-set campaign-contributors
          { campaign-id: campaign-id, index: contributor-count }
          { contributor: tx-sender }
        )
        (map-set campaign-contributor-count
          { campaign-id: campaign-id }
          { count: (+ contributor-count u1) }
        )
      )
      true
    )

    ;; Update campaign raised amount
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { raised: (+ (get raised campaign) amount) })
    )

    (ok true)
  )
)

(define-public (claim-funds (campaign-id uint))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) err-campaign-not-found))
    )
    (asserts! (is-eq tx-sender (get owner campaign)) err-not-campaign-owner)
    (asserts! (>= block-height (get end-height campaign)) err-campaign-active)
    (asserts! (>= (get raised campaign) (get goal campaign)) err-goal-not-reached)
    (asserts! (not (get claimed campaign)) err-already-claimed)

    ;; Transfer funds to campaign owner
    (try! (as-contract (stx-transfer? (get raised campaign) tx-sender (get owner campaign))))

    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { claimed: true })
    )

    (ok (get raised campaign))
  )
)

(define-public (refund (campaign-id uint))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) err-campaign-not-found))
      (contribution (get amount (get-contribution campaign-id tx-sender)))
    )
    (asserts! (>= block-height (get end-height campaign)) err-campaign-active)
    (asserts! (< (get raised campaign) (get goal campaign)) err-goal-reached)
    (asserts! (> contribution u0) err-invalid-amount)

    ;; Refund contributor
    (try! (as-contract (stx-transfer? contribution tx-sender tx-sender)))

    ;; Clear contribution
    (map-delete contributions { campaign-id: campaign-id, contributor: tx-sender })

    (ok contribution)
  )
)
