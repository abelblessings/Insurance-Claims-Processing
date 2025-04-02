;; Policy Management Contract
;; Records insurance terms and coverage

;; Data Variables
(define-map policies
  { policy-id: uint }
  {
    owner: principal,
    premium: uint,
    coverage-amount: uint,
    coverage-type: (string-ascii 20),
    start-date: uint,
    end-date: uint,
    active: bool
  }
)

(define-data-var next-policy-id uint u1)

;; Read-only functions
(define-read-only (get-policy (policy-id uint))
  (map-get? policies { policy-id: policy-id })
)

(define-read-only (get-policy-owner (policy-id uint))
  (get owner (unwrap-panic (get-policy policy-id)))
)

(define-read-only (is-policy-active (policy-id uint))
  (default-to false (get active (get-policy policy-id)))
)

;; Public functions
(define-public (create-policy
    (premium uint)
    (coverage-amount uint)
    (coverage-type (string-ascii 20))
    (start-date uint)
    (end-date uint))
  (let ((policy-id (var-get next-policy-id)))
    (asserts! (> coverage-amount u0) (err u1))
    (asserts! (> end-date start-date) (err u2))

    (map-set policies
      { policy-id: policy-id }
      {
        owner: tx-sender,
        premium: premium,
        coverage-amount: coverage-amount,
        coverage-type: coverage-type,
        start-date: start-date,
        end-date: end-date,
        active: true
      }
    )

    (var-set next-policy-id (+ policy-id u1))
    (ok policy-id)
  )
)

(define-public (deactivate-policy (policy-id uint))
  (let ((policy (unwrap-panic (get-policy policy-id))))
    (asserts! (is-eq tx-sender (get owner policy)) (err u3))

    (map-set policies
      { policy-id: policy-id }
      (merge policy { active: false })
    )

    (ok true)
  )
)

(define-public (update-coverage (policy-id uint) (new-coverage-amount uint))
  (let ((policy (unwrap-panic (get-policy policy-id))))
    (asserts! (is-eq tx-sender (get owner policy)) (err u3))
    (asserts! (get active policy) (err u4))
    (asserts! (> new-coverage-amount u0) (err u1))

    (map-set policies
      { policy-id: policy-id }
      (merge policy { coverage-amount: new-coverage-amount })
    )

    (ok true)
  )
)
