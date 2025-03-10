;; Repayment Management Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-amount (err u101))

;; Data Maps
(define-map loan-repayments
  { loan-id: uint }
  { total-amount: uint, repaid-amount: uint, status: (string-ascii 20) })

;; Public Functions
(define-public (initialize-loan (loan-id uint) (total-amount uint))
  (if (is-eq tx-sender contract-owner)
    (begin
      (map-set loan-repayments
        { loan-id: loan-id }
        { total-amount: total-amount, repaid-amount: u0, status: "ACTIVE" })
      (ok true))
    err-not-authorized))

(define-public (make-repayment (loan-id uint) (amount uint))
  (let ((loan (unwrap! (map-get? loan-repayments { loan-id: loan-id }) err-not-authorized)))
    (if (> amount u0)
      (let ((new-repaid-amount (+ (get repaid-amount loan) amount))
            (total-amount (get total-amount loan)))
        (map-set loan-repayments
          { loan-id: loan-id }
          (merge loan
            { repaid-amount: new-repaid-amount,
              status: (if (>= new-repaid-amount total-amount) "PAID" "ACTIVE") }))
        (ok true))
      err-invalid-amount)))

(define-read-only (get-loan-status (loan-id uint))
  (map-get? loan-repayments { loan-id: loan-id }))

;; Admin Functions
(define-public (mark-as-default (loan-id uint))
  (if (is-eq tx-sender contract-owner)
    (let ((loan (unwrap! (map-get? loan-repayments { loan-id: loan-id }) err-not-authorized)))
      (map-set loan-repayments
        { loan-id: loan-id }
        (merge loan { status: "DEFAULT" }))
      (ok true))
    err-not-authorized))

