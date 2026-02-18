;; Oracle Feed Smart Contract
;; Provides external data feeds to smart contracts

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u800))
(define-constant err-not-oracle (err u801))
(define-constant err-feed-not-found (err u802))
(define-constant err-stale-data (err u803))
(define-constant err-invalid-data (err u804))

;; Data Variables
(define-data-var feed-counter uint u0)
(define-data-var staleness-threshold uint u144) ;; ~1 day in blocks

;; Data Maps
(define-map oracles principal bool)

(define-map price-feeds
  { feed-id: uint }
  {
    name: (string-ascii 50),
    price: uint,
    last-update: uint,
    oracle: principal
  }
)

(define-map feed-names
  { name: (string-ascii 50) }
  { feed-id: uint }
)

;; Initialize owner as oracle
(map-set oracles contract-owner true)

;; Read-only functions
(define-read-only (is-oracle (address principal))
  (default-to false (map-get? oracles address))
)

(define-read-only (get-price-feed (feed-id uint))
  (map-get? price-feeds { feed-id: feed-id })
)

(define-read-only (get-price-by-name (name (string-ascii 50)))
  (match (map-get? feed-names { name: name })
    feed-data (map-get? price-feeds { feed-id: (get feed-id feed-data) })
    none
  )
)

(define-read-only (is-data-fresh (feed-id uint))
  (match (map-get? price-feeds { feed-id: feed-id })
    feed (ok (<= (- burn-block-height (get last-update feed)) (var-get staleness-threshold)))
    (err err-feed-not-found)
  )
)

(define-read-only (get-latest-price (feed-id uint))
  (let
    (
      (feed (unwrap! (map-get? price-feeds { feed-id: feed-id }) err-feed-not-found))
    )
    (asserts! (<= (- burn-block-height (get last-update feed)) (var-get staleness-threshold)) err-stale-data)
    (ok (get price feed))
  )
)

;; Public functions
(define-public (add-oracle (new-oracle principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set oracles new-oracle true)
    (ok true)
  )
)

(define-public (remove-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-delete oracles oracle)
    (ok true)
  )
)

(define-public (create-feed (name (string-ascii 50)) (initial-price uint))
  (let
    (
      (feed-id (+ (var-get feed-counter) u1))
    )
    (asserts! (is-oracle tx-sender) err-not-oracle)
    (asserts! (> initial-price u0) err-invalid-data)

    (map-set price-feeds
      { feed-id: feed-id }
      {
        name: name,
        price: initial-price,
        last-update: burn-block-height,
        oracle: tx-sender
      }
    )

    (map-set feed-names { name: name } { feed-id: feed-id })
    (var-set feed-counter feed-id)
    (ok feed-id)
  )
)

(define-public (update-price (feed-id uint) (new-price uint))
  (let
    (
      (feed (unwrap! (map-get? price-feeds { feed-id: feed-id }) err-feed-not-found))
    )
    (asserts! (is-oracle tx-sender) err-not-oracle)
    (asserts! (> new-price u0) err-invalid-data)

    (map-set price-feeds
      { feed-id: feed-id }
      (merge feed {
        price: new-price,
        last-update: burn-block-height,
        oracle: tx-sender
      })
    )

    (ok true)
  )
)

(define-public (update-price-by-name (name (string-ascii 50)) (new-price uint))
  (let
    (
      (feed-data (unwrap! (map-get? feed-names { name: name }) err-feed-not-found))
      (feed-id (get feed-id feed-data))
    )
    (try! (update-price feed-id new-price))
    (ok feed-id)
  )
)

(define-public (set-staleness-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set staleness-threshold new-threshold)
    (ok true)
  )
)
