;; NFT Marketplace Smart Contract
;; A decentralized marketplace for buying and selling NFTs

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-token-owner (err u201))
(define-constant err-listing-not-found (err u202))
(define-constant err-insufficient-payment (err u203))
(define-constant err-already-listed (err u204))
(define-constant err-invalid-price (err u205))

;; Data Variables
(define-data-var platform-fee-percentage uint u250) ;; 2.5% fee (250 basis points)
(define-data-var listing-counter uint u0)

;; NFT Definition
(define-non-fungible-token marketplace-nft uint)

;; Data Maps
(define-map listings
  { listing-id: uint }
  {
    token-id: uint,
    seller: principal,
    price: uint,
    active: bool
  }
)

(define-map token-listings { token-id: uint } { listing-id: uint })

;; Read-only functions
(define-read-only (get-listing (listing-id uint))
  (map-get? listings { listing-id: listing-id })
)

(define-read-only (get-token-listing (token-id uint))
  (match (map-get? token-listings { token-id: token-id })
    listing-data (map-get? listings { listing-id: (get listing-id listing-data) })
    none
  )
)

(define-read-only (get-platform-fee)
  (var-get platform-fee-percentage)
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? marketplace-nft token-id))
)

(define-read-only (calculate-fees (price uint))
  (let
    (
      (fee-percentage (var-get platform-fee-percentage))
      (platform-fee (/ (* price fee-percentage) u10000))
      (seller-proceeds (- price platform-fee))
    )
    {
      platform-fee: platform-fee,
      seller-proceeds: seller-proceeds
    }
  )
)

;; Public functions
(define-public (mint-nft (recipient principal))
  (let
    (
      (token-id (+ (var-get listing-counter) u1))
    )
    (try! (nft-mint? marketplace-nft token-id recipient))
    (var-set listing-counter token-id)
    (ok token-id)
  )
)

(define-public (transfer-nft (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (try! (nft-transfer? marketplace-nft token-id sender recipient))
    (ok true)
  )
)

(define-public (list-nft (token-id uint) (price uint))
  (let
    (
      (listing-id (+ (var-get listing-counter) u1))
      (token-owner (unwrap! (nft-get-owner? marketplace-nft token-id) err-not-token-owner))
    )
    (asserts! (is-eq tx-sender token-owner) err-not-token-owner)
    (asserts! (> price u0) err-invalid-price)
    (asserts! (is-none (map-get? token-listings { token-id: token-id })) err-already-listed)

    ;; Create listing
    (map-set listings
      { listing-id: listing-id }
      {
        token-id: token-id,
        seller: tx-sender,
        price: price,
        active: true
      }
    )

    (map-set token-listings { token-id: token-id } { listing-id: listing-id })
    (var-set listing-counter listing-id)
    (ok listing-id)
  )
)

(define-public (update-listing-price (listing-id uint) (new-price uint))
  (let
    (
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-listing-not-found))
    )
    (asserts! (is-eq tx-sender (get seller listing)) err-not-token-owner)
    (asserts! (get active listing) err-listing-not-found)
    (asserts! (> new-price u0) err-invalid-price)

    (map-set listings
      { listing-id: listing-id }
      (merge listing { price: new-price })
    )
    (ok true)
  )
)

(define-public (cancel-listing (listing-id uint))
  (let
    (
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-listing-not-found))
    )
    (asserts! (is-eq tx-sender (get seller listing)) err-not-token-owner)
    (asserts! (get active listing) err-listing-not-found)

    (map-set listings
      { listing-id: listing-id }
      (merge listing { active: false })
    )

    (map-delete token-listings { token-id: (get token-id listing) })
    (ok true)
  )
)

(define-public (buy-nft (listing-id uint))
  (let
    (
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-listing-not-found))
      (price (get price listing))
      (seller (get seller listing))
      (token-id (get token-id listing))
      (fees (calculate-fees price))
    )
    (asserts! (get active listing) err-listing-not-found)
    (asserts! (>= (stx-get-balance tx-sender) price) err-insufficient-payment)

    ;; Transfer payment to seller
    (try! (stx-transfer? (get seller-proceeds fees) tx-sender seller))

    ;; Transfer platform fee
    (try! (stx-transfer? (get platform-fee fees) tx-sender contract-owner))

    ;; Transfer NFT to buyer
    (try! (nft-transfer? marketplace-nft token-id seller tx-sender))

    ;; Mark listing as inactive
    (map-set listings
      { listing-id: listing-id }
      (merge listing { active: false })
    )

    (map-delete token-listings { token-id: token-id })
    (ok true)
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u1000) err-invalid-price) ;; Max 10% fee
    (var-set platform-fee-percentage new-fee)
    (ok true)
  )
)
