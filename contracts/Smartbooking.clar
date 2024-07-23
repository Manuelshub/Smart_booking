;; title: Smartbooking
;; version: 1.0.0
;; summary: Smart contract for event ticket booking
;; description: Allows creation of events, ticket purchases, and ticket transfers

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-sold-out (err u102))
(define-constant err-already-purchased (err u103))
(define-constant err-transfer-failed (err u104))
(define-constant err-outside-sale-period (err u105))
(define-constant err-self-transfer (err u106))
(define-constant err-invalid-name (err u107))
(define-constant err-invalid-price (err u108))
(define-constant err-invalid-ticket-count (err u109))

;; Define data variables
(define-data-var event-name (string-utf8 50) u"")
(define-data-var ticket-price uint u0)
(define-data-var total-tickets uint u0)
(define-data-var tickets-sold uint u0)

;; Define data maps
(define-map tickets principal uint)

;; Private function (admin only)
(define-private (create-event-internal (name (string-utf8 50)) (price uint) (num-tickets uint))
    (begin
        (var-set event-name name)
        (var-set ticket-price price)
        (var-set total-tickets num-tickets)
        (var-set tickets-sold u0)
        (ok true)))

;; Public functions

;; Create a new event (admin only)
(define-public (create-event (name (string-utf8 50)) (price uint) (num-tickets uint))
    (begin
        ;; Check if the caller is the contract owner
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
        ;; Validate inputs
        (asserts! (> (len name) u0) err-invalid-name)
        (asserts! (and (> price u0) (<= price u1000000000)) err-invalid-price)
        (asserts! (and (> num-tickets u0) (<= num-tickets u1000000)) err-invalid-ticket-count)
    
        ;; Call the internal function with validated inputs
        (create-event-internal name price num-tickets)))

;; Purchase a ticket
(define-public (buy-ticket)
  (let ((buyer tx-sender))
    (asserts! (< (var-get tickets-sold) (var-get total-tickets)) err-sold-out)
    (asserts! (is-none (map-get? tickets buyer)) err-already-purchased)
    (try! (stx-transfer? (var-get ticket-price) buyer contract-owner))
    (map-set tickets buyer (+ (var-get tickets-sold) u1))
    (var-set tickets-sold (+ (var-get tickets-sold) u1))
    (ok true)))

;; Transfer a ticket to another address
(define-public (transfer-ticket (to principal))
    (let ((ticket-owner tx-sender))
        (match (map-get? tickets ticket-owner) 
            ticket-id
                (if (is-eq to ticket-owner)
                    (err err-self-transfer) 
                    (begin
                        (map-delete tickets ticket-owner)
                        (map-set tickets to ticket-id)
                        (ok true)))
            (err err-not-found))))

;; Read-only fuctions

;; Get ticket information for a specific owner
(define-read-only (get-ticket-info (owner principal))
    (ok (map-get? tickets owner)))

;; get general event information
(define-read-only (get-event-info)
    (ok {
        name: (var-get event-name),
        price: (var-get ticket-price),
        total: (var-get total-tickets),
        sold: (var-get tickets-sold),
        available: (- (var-get total-tickets) (var-get tickets-sold))
    }))

;; Check if an address owns ticket
(define-read-only (check-ticket (owner principal))
    (is-some (map-get? tickets owner)))