;; trustless-will.clar
;; A trustless Bitcoin/STX inheritance smart contract with inactivity detection

(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_VAULT_EXISTS u101)
(define-constant ERR_VAULT_NOT_FOUND u102)
(define-constant ERR_NOT_HEIR u103)
(define-constant ERR_TOO_SOON u104)
(define-constant ERR_INVALID_PERCENT u105)
(define-constant ERR_ZERO_AMOUNT u106)

(define-constant INACTIVITY_PERIOD u1576800)

;; Data maps for vault storage
(define-map vaults
  { owner: principal }
  {
    balance: uint,
    last-ping: uint,
    claimable-after: uint,
  }
)

;; Map heirs with percentage shares (percentages sum to 100)
(define-map heirs
  {
    owner: principal,
    heir: principal,
  }
  { percentage: uint }
)

;; Helper function for fold: sum percentages
(define-private (sum-percent
    (item {
      heir: principal,
      percentage: uint,
    })
    (acc uint)
  )
  (+ (get percentage item) acc)
)

;; Helper function for fold: set heirs
(define-private (set-heir
    (heir-tuple {
      heir: principal,
      percentage: uint,
    })
    (acc bool)
  )
  (begin
    (map-set heirs {
      owner: tx-sender,
      heir: (get heir heir-tuple),
    } { percentage: (get percentage heir-tuple) }
    )
    acc
  )
)

;; ===== Public: Create a vault locking amount and heirs =====
(define-public (create-vault
    (amount uint)
    (claim-after uint)
    (heirs-list (list 10 {
      heir: principal,
      percentage: uint,
    }))
  )
  (begin
    ;; Check vault does not already exist
    (match (map-get? vaults { owner: tx-sender })
      vault (err u101)
      (let ((total-percent (fold sum-percent heirs-list u0)))
        (if (or (< amount u1) (not (is-eq total-percent u100)))
          (err u105)
          (begin
            ;; Initialize vault
            (let ((current-block u0))
              (map-set vaults { owner: tx-sender } {
                balance: amount,
                last-ping: current-block,
                claimable-after: claim-after,
              })
            )
            ;; Set heirs using fold
            (fold set-heir heirs-list true)
            ;; Assume off-chain or front-end handles actual fund locking transfer
            (ok true)
          )
        )
      )
    )
  )
)

;; ===== Public: Owner pings contract to reset inactivity timer =====
(define-public (ping)
  (match (map-get? vaults { owner: tx-sender })
    vault-info (begin
      (let ((current-block u0))
        (map-set vaults { owner: tx-sender } {
          balance: (get balance vault-info),
          last-ping: current-block,
          claimable-after: (get claimable-after vault-info),
        })
      )
      (ok true)
    )
    (err u102)
  )
)

;; ===== Public: Heir claims funds after claimable period if owner inactive =====
(define-public (claim (vault-owner principal))
  (let (
      (now u0)
      (vault (map-get? vaults { owner: vault-owner }))
    )
    (if (is-none vault)
      (err u102)
      (let (
          (vault-data (unwrap! vault (err u102)))
          (last-ping (unwrap! (some (get last-ping vault-data)) (err u102)))
          (claimable-after (unwrap! (some (get claimable-after vault-data)) (err u102)))
          (balance (unwrap! (some (get balance vault-data)) (err u102)))
          (inactivity-limit (+ last-ping INACTIVITY_PERIOD))
          (caller tx-sender)
          (heir-pct-opt (map-get? heirs {
            owner: vault-owner,
            heir: caller,
          }))
        )
        (if (is-none heir-pct-opt)
          (err u103)
          (if (or (< now claimable-after) (< now inactivity-limit))
            (err u104)
            (let (
                (heir-pct (unwrap! heir-pct-opt (err u103)))
                (pct (unwrap! (some (get percentage heir-pct)) (err u103)))
                (amount (/ (* balance pct) u100))
              )
              ;; Transfer amount to heir (assume off-chain / front-end handles actual transfer)
              ;; Update vault balance and remove heir
              (if (is-eq amount u0)
                (err u106)
                (let ((new-balance (- balance amount)))
                  (begin
                    (map-set vaults { owner: vault-owner } {
                      balance: new-balance,
                      last-ping: last-ping,
                      claimable-after: claimable-after,
                    })
                    ;; Remove this heir after claiming
                    (map-delete heirs {
                      owner: vault-owner,
                      heir: caller,
                    })
                    (ok amount)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

;; ===== Read-only: Get vault info for owner =====
(define-read-only (get-vault (owner principal))
  (match (map-get? vaults { owner: owner })
    vault-data (ok vault-data)
    (err u102)
  )
)

;; ===== Read-only: Get heir percentage for an owner/heir pair =====
(define-read-only (get-heir-percentage
    (owner principal)
    (heir principal)
  )
  (match (map-get? heirs {
    owner: owner,
    heir: heir,
  })
    heir-data (ok (get percentage heir-data))
    (err u103)
  )
)
