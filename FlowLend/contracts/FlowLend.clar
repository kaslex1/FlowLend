;; FlowLend - Collateralized Payment Streaming Protocol
;; A decentralized lending platform on Stacks blockchain enabling secure STX payment streams

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-LOAN-NOT-FOUND (err u102))
(define-constant ERR-LOAN-ALREADY-ACTIVE (err u103))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u104))
(define-constant ERR-LOAN-NOT-ACTIVE (err u105))
(define-constant ERR-LOAN-LIQUIDATED (err u106))
(define-constant ERR-INVALID-AMOUNT (err u107))
(define-constant ERR-PAYMENT-TOO-SMALL (err u108))
(define-constant ERR-NO-LIQUIDATION-NEEDED (err u109))

;; Constants
(define-constant DAILY-BLOCKS u144) ;; Approximate number of blocks per day
(define-constant LATE-PAYMENT-FEE-RATE u10) ;; 10% fee rate for late payments
(define-constant LIQUIDATION-THRESHOLD u130) ;; 130% minimum collateral ratio before liquidation

;; Loan status constants
(define-constant LOAN-PENDING "PENDING")
(define-constant LOAN-ACTIVE "ACTIVE")
(define-constant LOAN-COMPLETED "COMPLETED")
(define-constant LOAN-LIQUIDATED "LIQUIDATED")
(define-constant LOAN-DEFAULTED "DEFAULTED")

;; Data variables
(define-data-var min-collateral-ratio uint u150) ;; 150% collateral ratio
(define-data-var protocol-admin principal tx-sender)

;; Loan data structure
(define-map payment-loans
    {loan-id: uint}
    {
        borrower: principal,
        lender: (optional principal),
        loan-amount: uint,
        collateral-amount: uint,
        interest-rate: uint,
        loan-duration: uint,
        start-block: uint,
        last-payment-block: uint,
        payment-interval: uint,
        payment-amount: uint,
        remaining-balance: uint,
        loan-status: (string-ascii 20)
    }
)

;; Payment schedule tracking
(define-map payment-schedules
    {loan-id: uint}
    {
        next-payment-block: uint,
        missed-payments: uint,
        total-late-fees: uint
    }
)

;; Protocol state variables
(define-data-var next-loan-id uint u1)
(define-data-var total-locked-collateral uint u0)

;; Read-only functions
(define-read-only (get-loan (loan-id uint))
    (map-get? payment-loans {loan-id: loan-id})
)

(define-read-only (get-payment-schedule (loan-id uint))
    (map-get? payment-schedules {loan-id: loan-id})
)

(define-read-only (get-collateral-ratio (collateral uint) (loan-amount uint))
    (let
        (
            (ratio (* (/ collateral loan-amount) u100))
        )
        ratio
    )
)

(define-read-only (get-current-collateral-ratio (loan-id uint))
    (let
        (
            (loan (unwrap! (get-loan loan-id) u0))
            (ratio (get-collateral-ratio (get collateral-amount loan) (get remaining-balance loan)))
        )
        ratio
    )
)

(define-read-only (check-liquidation-needed (loan-id uint))
    (let
        (
            (current-ratio (get-current-collateral-ratio loan-id))
        )
        (< current-ratio LIQUIDATION-THRESHOLD)
    )
)

;; Private functions
(define-private (calculate-late-fee (payment-amount uint))
    (/ (* payment-amount LATE-PAYMENT-FEE-RATE) u100)
)

(define-private (update-payment-schedule (loan-id uint) (start-block uint) (payment-interval uint))
    (begin
        (map-set payment-schedules
            {loan-id: loan-id}
            {
                next-payment-block: (+ start-block payment-interval),
                missed-payments: u0,
                total-late-fees: u0
            }
        )
        true
    )
)

;; Public functions
(define-public (create-loan-request (amount uint) (collateral uint) (interest-rate uint) (duration uint) (payment-interval uint))
    (let
        (
            (loan-id (var-get next-loan-id))
            (collateral-ratio (get-collateral-ratio collateral amount))
            (payment-amount (/ (+ amount (* amount interest-rate)) duration))
        )
        (asserts! (>= collateral-ratio (var-get min-collateral-ratio)) ERR-INSUFFICIENT-COLLATERAL)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (try! (stx-transfer? collateral tx-sender (as-contract tx-sender)))
        
        (var-set total-locked-collateral (+ (var-get total-locked-collateral) collateral))
        
        (map-set payment-loans
            {loan-id: loan-id}
            {
                borrower: tx-sender,
                lender: none,
                loan-amount: amount,
                collateral-amount: collateral,
                interest-rate: interest-rate,
                loan-duration: duration,
                start-block: u0,
                last-payment-block: u0,
                payment-interval: payment-interval,
                payment-amount: payment-amount,
                remaining-balance: amount,
                loan-status: LOAN-PENDING
            }
        )
        (var-set next-loan-id (+ loan-id u1))
        (ok loan-id)
    )
)

(define-public (fund-loan (loan-id uint))
    (let
        (
            (loan (unwrap! (get-loan loan-id) ERR-LOAN-NOT-FOUND))
            (amount (get loan-amount loan))
        )
        (asserts! (is-eq (get loan-status loan) LOAN-PENDING) ERR-LOAN-ALREADY-ACTIVE)
        (try! (stx-transfer? amount tx-sender (get borrower loan)))
        
        (map-set payment-loans
            {loan-id: loan-id}
            (merge loan {
                lender: (some tx-sender),
                start-block: block-height,
                last-payment-block: block-height,
                loan-status: LOAN-ACTIVE
            })
        )
        
        (asserts! (update-payment-schedule loan-id block-height (get payment-interval loan)) ERR-LOAN-NOT-FOUND)
        
        (ok true)
    )
)

(define-public (make-payment (loan-id uint))
    (let
        (
            (loan (unwrap! (get-loan loan-id) ERR-LOAN-NOT-FOUND))
            (schedule (unwrap! (get-payment-schedule loan-id) ERR-LOAN-NOT-FOUND))
            (payment-amount (get payment-amount loan))
            (lender (unwrap! (get lender loan) ERR-LOAN-NOT-FOUND))
            (late-fee (if (>= block-height (get next-payment-block schedule))
                        (calculate-late-fee payment-amount)
                        u0))
            (total-payment (+ payment-amount late-fee))
        )
        (asserts! (is-eq (get loan-status loan) LOAN-ACTIVE) ERR-LOAN-NOT-ACTIVE)
        (asserts! (is-eq (get borrower loan) tx-sender) ERR-UNAUTHORIZED)
        
        (try! (stx-transfer? total-payment tx-sender lender))
        
        (map-set payment-loans
            {loan-id: loan-id}
            (merge loan {
                last-payment-block: block-height,
                remaining-balance: (- (get remaining-balance loan) payment-amount)
            })
        )
        
        (map-set payment-schedules
            {loan-id: loan-id}
            (merge schedule {
                next-payment-block: (+ block-height (get payment-interval loan)),
                total-late-fees: (+ (get total-late-fees schedule) late-fee)
            })
        )
        
        (ok true)
    )
)

(define-public (liquidate-loan (loan-id uint))
    (let
        (
            (loan (unwrap! (get-loan loan-id) ERR-LOAN-NOT-FOUND))
            (schedule (unwrap! (get-payment-schedule loan-id) ERR-LOAN-NOT-FOUND))
            (lender (unwrap! (get lender loan) ERR-LOAN-NOT-FOUND))
            (needs-liquidation (check-liquidation-needed loan-id))
        )
        (asserts! needs-liquidation ERR-NO-LIQUIDATION-NEEDED)
        
        (as-contract
            (try! (stx-transfer? (get collateral-amount loan) lender tx-sender))
        )
        
        (var-set total-locked-collateral (- (var-get total-locked-collateral) (get collateral-amount loan)))
        
        (map-set payment-loans
            {loan-id: loan-id}
            (merge loan {
                loan-status: LOAN-LIQUIDATED
            })
        )
        
        (ok true)
    )
)

;; Admin functions
(define-public (set-min-collateral-ratio (new-ratio uint))
    (begin
        (asserts! (is-eq tx-sender (var-get protocol-admin)) ERR-UNAUTHORIZED)
        (var-set min-collateral-ratio new-ratio)
        (ok true)
    )
)

(define-public (transfer-admin (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get protocol-admin)) ERR-UNAUTHORIZED)
        (var-set protocol-admin new-admin)
        (ok true)
    )
)