
;; title: CorpBondVault
;; version: 1.0.0
;; summary: Synthetic corporate bond portfolio platform
;; description: Creates synthetic exposure to traditional corporate bond assets through tokenized portfolios

;; traits
(define-trait sip-010-trait
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

;; token definitions
(define-fungible-token cbv-token)

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-portfolio-not-found (err u104))
(define-constant err-portfolio-inactive (err u105))
(define-constant err-price-outdated (err u106))

;; data vars
(define-data-var contract-admin principal contract-owner)
(define-data-var token-name (string-ascii 32) "CorpBondVault Token")
(define-data-var token-symbol (string-ascii 10) "CBV")
(define-data-var token-decimals uint u6)
(define-data-var total-supply uint u0)
(define-data-var platform-fee uint u100) ;; 1% = 100 basis points
(define-data-var min-collateral-ratio uint u12000) ;; 120% = 12000 basis points

;; data maps
(define-map portfolios 
  { portfolio-id: uint }
  {
    name: (string-ascii 64),
    description: (string-ascii 256),
    target-yield: uint,
    risk-rating: uint,
    total-value: uint,
    active: bool,
    created-at: uint
  }
)

(define-map portfolio-prices
  { portfolio-id: uint }
  {
    price: uint,
    last-updated: uint,
    oracle: principal
  }
)

(define-map user-positions
  { user: principal, portfolio-id: uint }
  {
    synthetic-tokens: uint,
    collateral-amount: uint,
    entry-price: uint,
    created-at: uint
  }
)

(define-map authorized-oracles principal bool)

;; public functions

;; SIP-010 Standard Functions
(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq from tx-sender) (is-eq from contract-caller)) err-not-authorized)
    (ft-transfer? cbv-token amount from to)
  )
)

(define-public (get-name)
  (ok (var-get token-name))
)

(define-public (get-symbol)
  (ok (var-get token-symbol))
)

(define-public (get-decimals)
  (ok (var-get token-decimals))
)

(define-public (get-balance (user principal))
  (ok (ft-get-balance cbv-token user))
)

(define-public (get-total-supply)
  (ok (ft-get-supply cbv-token))
)

(define-public (get-token-uri)
  (ok none)
)

;; Administrative Functions
(define-public (set-contract-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) err-owner-only)
    (ok (var-set contract-admin new-admin))
  )
)

(define-public (add-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) err-owner-only)
    (ok (map-set authorized-oracles oracle true))
  )
)

(define-public (remove-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) err-owner-only)
    (ok (map-delete authorized-oracles oracle))
  )
)

;; Portfolio Management
(define-public (create-portfolio 
  (portfolio-id uint)
  (name (string-ascii 64))
  (description (string-ascii 256))
  (target-yield uint)
  (risk-rating uint)
)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) err-owner-only)
    (asserts! (is-none (map-get? portfolios {portfolio-id: portfolio-id})) err-invalid-amount)
    (ok (map-set portfolios {portfolio-id: portfolio-id}
      {
        name: name,
        description: description,
        target-yield: target-yield,
        risk-rating: risk-rating,
        total-value: u0,
        active: true,
        created-at: block-height
      }
    ))
  )
)

(define-public (update-portfolio-price (portfolio-id uint) (new-price uint))
  (begin
    (asserts! (default-to false (map-get? authorized-oracles tx-sender)) err-not-authorized)
    (asserts! (is-some (map-get? portfolios {portfolio-id: portfolio-id})) err-portfolio-not-found)
    (ok (map-set portfolio-prices {portfolio-id: portfolio-id}
      {
        price: new-price,
        last-updated: block-height,
        oracle: tx-sender
      }
    ))
  )
)

(define-public (toggle-portfolio-status (portfolio-id uint))
  (let ((portfolio (unwrap! (map-get? portfolios {portfolio-id: portfolio-id}) err-portfolio-not-found)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) err-owner-only)
    (ok (map-set portfolios {portfolio-id: portfolio-id}
      (merge portfolio {active: (not (get active portfolio))})
    ))
  )
)

;; Synthetic Asset Functions
(define-public (mint-synthetic (portfolio-id uint) (amount uint) (collateral uint))
  (let (
    (portfolio (unwrap! (map-get? portfolios {portfolio-id: portfolio-id}) err-portfolio-not-found))
    (price-data (unwrap! (map-get? portfolio-prices {portfolio-id: portfolio-id}) err-price-outdated))
    (current-price (get price price-data))
    (required-collateral (/ (* amount current-price (var-get min-collateral-ratio)) u10000))
    (user-position (default-to 
      {synthetic-tokens: u0, collateral-amount: u0, entry-price: u0, created-at: u0}
      (map-get? user-positions {user: tx-sender, portfolio-id: portfolio-id})
    ))
  )
    (asserts! (get active portfolio) err-portfolio-inactive)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= collateral required-collateral) err-insufficient-balance)
    (asserts! (< (- block-height (get last-updated price-data)) u144) err-price-outdated) ;; Price must be < 24 hours old
    
    ;; Transfer collateral from user
    (try! (stx-transfer? collateral tx-sender (as-contract tx-sender)))
    
    ;; Mint synthetic tokens
    (try! (ft-mint? cbv-token amount tx-sender))
    
    ;; Update user position
    (map-set user-positions {user: tx-sender, portfolio-id: portfolio-id}
      {
        synthetic-tokens: (+ (get synthetic-tokens user-position) amount),
        collateral-amount: (+ (get collateral-amount user-position) collateral),
        entry-price: current-price,
        created-at: (if (is-eq (get created-at user-position) u0) block-height (get created-at user-position))
      }
    )
    
    ;; Update total supply
    (var-set total-supply (+ (var-get total-supply) amount))
    
    (ok amount)
  )
)

(define-public (burn-synthetic (portfolio-id uint) (amount uint))
  (let (
    (portfolio (unwrap! (map-get? portfolios {portfolio-id: portfolio-id}) err-portfolio-not-found))
    (price-data (unwrap! (map-get? portfolio-prices {portfolio-id: portfolio-id}) err-price-outdated))
    (current-price (get price price-data))
    (user-position (unwrap! (map-get? user-positions {user: tx-sender, portfolio-id: portfolio-id}) err-insufficient-balance))
    (synthetic-tokens (get synthetic-tokens user-position))
    (collateral-amount (get collateral-amount user-position))
    (collateral-to-return (/ (* amount collateral-amount) synthetic-tokens))
    (fee-amount (/ (* collateral-to-return (var-get platform-fee)) u10000))
    (net-collateral (- collateral-to-return fee-amount))
  )
    (asserts! (get active portfolio) err-portfolio-inactive)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= synthetic-tokens amount) err-insufficient-balance)
    (asserts! (< (- block-height (get last-updated price-data)) u144) err-price-outdated)
    
    ;; Burn synthetic tokens
    (try! (ft-burn? cbv-token amount tx-sender))
    
    ;; Return collateral to user (minus fee)
    (try! (as-contract (stx-transfer? net-collateral tx-sender tx-sender)))
    
    ;; Update user position
    (if (is-eq synthetic-tokens amount)
      ;; If burning all tokens, remove position
      (map-delete user-positions {user: tx-sender, portfolio-id: portfolio-id})
      ;; Otherwise, update position
      (map-set user-positions {user: tx-sender, portfolio-id: portfolio-id}
        (merge user-position {
          synthetic-tokens: (- synthetic-tokens amount),
          collateral-amount: (- collateral-amount collateral-to-return)
        })
      )
    )
    
    ;; Update total supply
    (var-set total-supply (- (var-get total-supply) amount))
    
    (ok net-collateral)
  )
)

;; read only functions
(define-read-only (get-portfolio (portfolio-id uint))
  (map-get? portfolios {portfolio-id: portfolio-id})
)

(define-read-only (get-portfolio-price (portfolio-id uint))
  (map-get? portfolio-prices {portfolio-id: portfolio-id})
)

(define-read-only (get-user-position (user principal) (portfolio-id uint))
  (map-get? user-positions {user: user, portfolio-id: portfolio-id})
)

(define-read-only (get-contract-admin)
  (var-get contract-admin)
)

(define-read-only (is-authorized-oracle (oracle principal))
  (default-to false (map-get? authorized-oracles oracle))
)

(define-read-only (calculate-collateral-ratio (user principal) (portfolio-id uint))
  (let (
    (position (map-get? user-positions {user: user, portfolio-id: portfolio-id}))
    (price-data (map-get? portfolio-prices {portfolio-id: portfolio-id}))
  )
    (match position
      user-pos
        (match price-data
          price-info
            (let (
              (synthetic-value (* (get synthetic-tokens user-pos) (get price price-info)))
              (collateral (get collateral-amount user-pos))
            )
              (if (> synthetic-value u0)
                (some (/ (* collateral u10000) synthetic-value))
                none
              )
            )
          none
        )
      none
    )
  )
)

(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

(define-read-only (get-min-collateral-ratio)
  (var-get min-collateral-ratio)
)

;; private functions
(define-private (is-owner)
  (is-eq tx-sender (var-get contract-admin))
)
