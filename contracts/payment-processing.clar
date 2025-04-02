;; Payment Processing Contract
;; Manages disbursement of approved claims

;; Data Variables
(define-map payments
  { payment-id: uint }
  {
    claim-id: uint,
    recipient: principal,
    amount: uint,
    status: (string-ascii 20),
    payment-date: uint,
    transaction-hash: (optional (buff 32))
  }
)

(define-data-var next-payment-id uint u1)
(define-data-var contract-balance uint u0)

;; Read-only functions
(define-read-only (get-payment (payment-id uint))
  (map-get? payments { payment-id: payment-id })
)

(define-read-only (get-contract-balance)
  (var-get contract-balance)
)

;; Public functions
(define-public (fund-contract (amount uint))
  (begin
    (var-set contract-balance (+ (var-get contract-balance) amount))
    (ok true)
  )
)

(define-public (process-payment (claim-id uint))
  (let (
    (payment-id (var-get next-payment-id))
    ;; In a real implementation, we would get claim details from the claim contract
    ;; For simplicity, we'll use hardcoded values
    (claim-amount u1000)
    (claimant tx-sender)
  )
    ;; Check if contract has enough balance
    (asserts! (>= (var-get contract-balance) claim-amount) (err u3))

    ;; Create payment record
    (map-set payments
      { payment-id: payment-id }
      {
        claim-id: claim-id,
        recipient: claimant,
        amount: claim-amount,
        status: "PENDING",
        payment-date: u0,
        transaction-hash: none
      }
    )

    ;; Update next payment ID
    (var-set next-payment-id (+ payment-id u1))

    (ok payment-id)
  )
)

(define-public (execute-payment (payment-id uint) (tx-hash (buff 32)))
  (let (
    (payment (unwrap-panic (get-payment payment-id)))
    (payment-amount (get amount payment))
    (recipient (get recipient payment))
  )
    ;; Only authorized payment processors can execute payments
    (asserts! (is-authorized-processor tx-sender) (err u4))

    ;; Check if payment is in PENDING status
    (asserts! (is-eq (get status payment) "PENDING") (err u5))

    ;; Check if contract has enough balance
    (asserts! (>= (var-get contract-balance) payment-amount) (err u3))

    ;; Update contract balance
    (var-set contract-balance (- (var-get contract-balance) payment-amount))

    ;; Update payment record
    (map-set payments
      { payment-id: payment-id }
      (merge payment {
        status: "COMPLETED",
        payment-date: block-height,
        transaction-hash: (some tx-hash)
      })
    )

    ;; In a real implementation, we would update the claim status
    ;; For simplicity, we'll just return success
    (ok true)
  )
)

;; Helper function to check if sender is authorized processor
(define-private (is-authorized-processor (address principal))
  ;; In a real implementation, this would check against a list of authorized processors
  ;; For simplicity, we're just checking if it's the contract owner
  (is-eq address (contract-owner))
)

;; Helper function for contract owner
(define-private (contract-owner)
  (as-contract tx-sender)
)
