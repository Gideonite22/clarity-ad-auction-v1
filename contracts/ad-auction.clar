;; Ad Auction Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-auction-ended (err u101))
(define-constant err-bid-too-low (err u102))
(define-constant err-no-auction (err u103))
(define-constant err-not-winner (err u104))

;; Data Variables
(define-data-var current-auction-id uint u0)
(define-data-var min-bid uint u1000)

;; Data Maps
(define-map auctions
    uint
    {
        ad-space: (string-ascii 256),
        highest-bid: uint,
        highest-bidder: principal,
        end-block: uint,
        claimed: bool
    }
)

;; Create new auction
(define-public (create-auction (ad-space (string-ascii 256)) (duration uint))
    (let (
        (auction-id (var-get current-auction-id))
        (end-block (+ block-height duration))
    )
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set auctions auction-id {
                ad-space: ad-space,
                highest-bid: (var-get min-bid),
                highest-bidder: contract-owner,
                end-block: end-block,
                claimed: false
            })
            (var-set current-auction-id (+ auction-id u1))
            (ok auction-id)
        )
        err-owner-only
    ))
)

;; Place bid
(define-public (place-bid (auction-id uint) (bid uint))
    (let (
        (auction (unwrap! (map-get? auctions auction-id) err-no-auction))
        (end-block (get end-block auction))
        (current-highest (get highest-bid auction))
    )
    (asserts! (< block-height end-block) err-auction-ended)
    (asserts! (> bid current-highest) err-bid-too-low)
    (begin
        (map-set auctions auction-id 
            (merge auction {
                highest-bid: bid,
                highest-bidder: tx-sender
            })
        )
        (ok bid)
    ))
)

;; Claim ad space
(define-public (claim-ad-space (auction-id uint))
    (let (
        (auction (unwrap! (map-get? auctions auction-id) err-no-auction))
        (end-block (get end-block auction))
        (winner (get highest-bidder auction))
    )
    (asserts! (>= block-height end-block) err-auction-ended)
    (asserts! (is-eq tx-sender winner) err-not-winner)
    (begin
        (map-set auctions auction-id 
            (merge auction {
                claimed: true
            })
        )
        (ok true)
    ))
)

;; Read only functions
(define-read-only (get-auction-details (auction-id uint))
    (ok (map-get? auctions auction-id))
)

(define-read-only (get-current-auction-id)
    (ok (var-get current-auction-id))
)

(define-read-only (get-min-bid)
    (ok (var-get min-bid))
)
