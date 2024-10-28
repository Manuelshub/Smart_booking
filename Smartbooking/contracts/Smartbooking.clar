;; title: Smartbooking
;; version: 1.0.0
;; summary: Smart contract for event ticket booking
;; description: Allows creation of events, ticket purchases, ticket transfers and so much more.

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
        (ok "Event successfully created!")))

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
    (ok u"Ticket succesfully purchased!")))

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
                        (ok u"Ticket succesfully transferred!")))
            (err err-not-found))))


;; Get ticket information for a specific owner
(define-public (get-ticket-info (owner principal))
    (let ((ticket-id (map-get? tickets owner)))
        (ok (tuple (owner (var-get ticket-price))))
))
;; Read-only fuctions

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

;; Refund a ticket
(define-public (refund-ticket (buyer principal))
    ;; Ensure the buyer is valid (basic check since principal is already a secure type)
    (if (is-eq buyer tx-sender)  ;; Ensure that the buyer is the same as the transaction sender
        (let 
            (
                ;; Fetch the ticket price from the tickets map
                (maybe-refund-amount (map-get? tickets buyer))
            )
            ;; Check if the ticket exists and unwrap the result safely
            (match maybe-refund-amount
                refund-amount
                ;; Proceed with the refund logic if the ticket is found
                (begin
                    ;; Transfer the ticket price back to the buyer and check the result
                    (unwrap! (stx-transfer? refund-amount tx-sender buyer) (err "Transfer failed"))

                    ;; Optionally, delete the ticket from the map to mark it as refunded
                    (map-delete tickets buyer)

                    ;; Return success
                    (ok true)
                )
                ;; If the ticket is not found, return an error
                (err "No ticket found for this buyer")
            )
        )
        ;; If the buyer isn't the same as the tx-sender, return an error
        (err "Invalid buyer principal")
    )
)

;; Private function to update the refunded status of a ticket
(define-private (update-ticket-refunded-status (owner principal))
    ;; Logic to mark the ticket as refunded, e.g., updating a map or flag
    (ok true) ;; Placeholder logic for now
)

;; Cancel Event
(define-public (event-cancel (event-id uint))
    ;; Step 1: Fetch the event details
    (let ((maybe-event (map-get? events event-id)))
        (match maybe-event
            event
            ;; Proceed if the event exists
            (let ((organizer (get event-organizer event)))
                ;; Step 2: Check if the caller is the organizer
                (if (is-eq tx-sender organizer)
                    (begin
                        ;; Step 3: Loop through ticket holders to refund
                        ;; Assuming ticket holders are stored in the tickets map
                        (let ((ticket-holders (map-keys tickets)))
                            (map
                                (lambda (buyer)
                                    (let ((maybe-refund-amount (map-get? tickets buyer)))
                                        ;; Check if theres a ticket for the buyer
                                        (match maybe-refund-amount
                                            refund-amount
                                            (begin
                                                ;; Process the refund transfer
                                                (unwrap! (stx-transfer? refund-amount tx-sender buyer) (err "Transfer failed"))

                                                ;; Delete the ticket from the map after refunding
                                                (asserts! (map-delete tickets buyer) (err "Failed to delete ticket"))
                                            )
                                            (err "No ticket found for buyer")
                                        )
                                    )
                                )
                                ticket-holders
                            )
                        )

                        ;; Step 4: Cancel the event by setting its status
                        (map-set events event-id {event-status: "cancelled"})

                        ;; Confirm the cancellation
                        (ok true)
                    )
                    (err "Only the organizer can cancel the event")
                )
            )
            (err "Event not found")
        )
    )
)
