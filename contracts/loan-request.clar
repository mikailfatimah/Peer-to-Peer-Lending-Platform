;; Loan Request Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-amount (err u101))
(define-constant err-invalid-term (err u102))

;; Data Maps
(define-map loan-requests
  { id: uint }
  { borrower: principal, amount: uint, term: uint, status: (string-ascii 20) })

(define-data-var next-loan-id uint u1)

;; Public Functions
(define-public (create-loan-request (amount uint) (term uint))
  (let ((loan-id (var-get next-loan-id)))
    (if (and (> amount u0) (> term u0))
      (begin
        (map-set loan-requests
          { id: loan-id }
          { borrower: tx-sender, amount: amount, term: term, status: "PENDING" })
        (var-set next-loan-id (+ loan-id u1))
        (ok loan-id))
      err-invalid-amount)))

(define-read-only (get-loan-request (id uint))
  (map-get? loan-requests { id: id }))

(define-public (cancel-loan-request (id uint))
  (let ((request (unwrap! (get-loan-request id) err-not-authorized)))
    (if (is-eq (get borrower request) tx-sender)
      (begin
        (map-set loan-requests
          { id: id }
          (merge request { status: "CANCELLED" }))
        (ok true))
      err-not-authorized)))

;; Admin Functions
(define-public (update-loan-status (id uint) (new-status (string-ascii 20)))
  (if (is-eq tx-sender contract-owner)
    (let ((request (unwrap! (get-loan-request id) err-not-authorized)))
      (map-set loan-requests
        { id: id }
        (merge request { status: new-status }))
      (ok true))
    err-not-authorized))

