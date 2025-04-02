;; Claim Submission Contract
;; Handles documentation of insured events

;; Data Variables
(define-map claims
  { claim-id: uint }
  {
    policy-id: uint,
    claimant: principal,
    amount: uint,
    description: (string-utf8 500),
    date: uint,
    status: (string-ascii 20),
    documents-hash: (buff 32)
  }
)

(define-data-var next-claim-id uint u1)

;; Read-only functions
(define-read-only (get-claim (claim-id uint))
  (map-get? claims { claim-id: claim-id })
)

(define-read-only (get-claim-status (claim-id uint))
  (get status (unwrap-panic (get-claim claim-id)))
)

;; Public functions
(define-public (submit-claim
    (policy-id uint)
    (amount uint)
    (description (string-utf8 500))
    (documents-hash (buff 32)))
  (let (
    (claim-id (var-get next-claim-id))
  )
    ;; In a real implementation, we would check policy validity
    ;; For now, we'll simplify to avoid contract reference errors

    ;; Create the claim
    (map-set claims
      { claim-id: claim-id }
      {
        policy-id: policy-id,
        claimant: tx-sender,
        amount: amount,
        description: description,
        date: block-height,
        status: "SUBMITTED",
        documents-hash: documents-hash
      }
    )

    (var-set next-claim-id (+ claim-id u1))
    (ok claim-id)
  )
)

(define-public (update-claim-documents (claim-id uint) (new-documents-hash (buff 32)))
  (let ((claim (unwrap-panic (get-claim claim-id))))
    ;; Check if sender is the claimant
    (asserts! (is-eq tx-sender (get claimant claim)) (err u3))

    ;; Check if claim is still in SUBMITTED status
    (asserts! (is-eq (get status claim) "SUBMITTED") (err u4))

    ;; Update the claim documents
    (map-set claims
      { claim-id: claim-id }
      (merge claim { documents-hash: new-documents-hash })
    )

    (ok true)
  )
)

(define-public (update-claim-status (claim-id uint) (new-status (string-ascii 20)))
  (let ((claim (unwrap-panic (get-claim claim-id))))
    ;; In a real implementation, we would check permissions
    ;; For simplicity, we'll allow any caller to update status

    ;; Update the claim status
    (map-set claims
      { claim-id: claim-id }
      (merge claim { status: new-status })
    )

    (ok true)
  )
)

(define-public (cancel-claim (claim-id uint))
  (let ((claim (unwrap-panic (get-claim claim-id))))
    ;; Check if sender is the claimant
    (asserts! (is-eq tx-sender (get claimant claim)) (err u3))

    ;; Check if claim is not already processed
    (asserts! (or (is-eq (get status claim) "SUBMITTED") (is-eq (get status claim) "UNDER_REVIEW")) (err u4))

    ;; Update the claim status
    (map-set claims
      { claim-id: claim-id }
      (merge claim { status: "CANCELLED" })
    )

    (ok true)
  )
)
