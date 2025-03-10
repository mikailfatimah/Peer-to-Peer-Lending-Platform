;; Lender Matching Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-already-matched (err u101))

;; Data Maps
(define-map loan-matches
  { loan-id: uint }
  { lender: (optional principal), status: (string-ascii 20) })

;; Public Functions
(define-public (offer-loan (loan-id uint))
  (let ((match (default-to { lender: none, status: "UNMATCHED" }
                (map-get? loan-matches { loan-id: loan-id }))))
    (if (is-eq (get status match) "UNMATCHED")
      (begin
        (map-set loan-matches
          { loan-id: loan-id }
          { lender: (some tx-sender), status: "MATCHED" })
        (ok true))
      err-already-matched)))

(define-read-only (get-loan-match (loan-id uint))
  (map-get? loan-matches { loan-id: loan-id }))

(define-public (cancel-loan-offer (loan-id uint))
  (let ((match (unwrap! (get-loan-match loan-id) err-not-authorized)))
    (if (is-eq (some tx-sender) (get lender match))
      (begin
        (map-set loan-matches
          { loan-id: loan-id }
          { lender: none, status: "UNMATCHED" })
        (ok true))
      err-not-authorized)))

;; Admin Functions
(define-public (finalize-match (loan-id uint))
  (if (is-eq tx-sender contract-owner)
    (let ((match (unwrap! (get-loan-match loan-id) err-not-authorized)))
      (map-set loan-matches
        { loan-id: loan-id }
        (merge match { status: "FINALIZED" }))
      (ok true))
    err-not-authorized))

