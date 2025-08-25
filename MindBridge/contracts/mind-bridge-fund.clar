;; Mind Bridge Fund - Mental Health Support Fund Smart Contract
;; A decentralized fund supporting mental health initiatives and individual assistance

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))
(define-constant ERR_INVALID_AMOUNT (err u403))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u404))
(define-constant ERR_VOTING_CLOSED (err u405))
(define-constant ERR_ALREADY_VOTED (err u406))
(define-constant ERR_PROPOSAL_NOT_ACTIVE (err u407))
(define-constant VOTING_PERIOD u1008) ;; ~1 week in blocks
(define-constant MIN_PROPOSAL_AMOUNT u1000)
(define-constant MAX_PROPOSAL_AMOUNT u50000)

;; Data structures
(define-map fund-proposals
  { proposal-id: uint }
  {
    applicant: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    amount: uint,
    category: (string-ascii 50),
    votes-for: uint,
    votes-against: uint,
    created-at: uint,
    status: (string-ascii 20),
    is-active: bool
  }
)

(define-map voter-records
  { proposal-id: uint, voter: principal }
  { vote: bool, voted-at: uint }
)

(define-map contributor-profiles
  { contributor: principal }
  {
    total-donated: uint,
    total-votes: uint,
    reputation: uint,
    joined-at: uint
  }
)

(define-map fund-recipients
  { recipient: principal }
  {
    total-received: uint,
    proposals-funded: uint,
    last-funded: uint
  }
)

;; Data variables
(define-data-var total-fund-balance uint u0)
(define-data-var next-proposal-id uint u1)
(define-data-var total-proposals uint u0)
(define-data-var total-funded uint u0)

;; Helper functions
(define-private (is-valid-voter (voter principal))
  (let ((contributor (map-get? contributor-profiles { contributor: voter })))
    (match contributor
      some-profile (> (get total-donated some-profile) u0)
      false
    )
  )
)

(define-private (calculate-voting-power (voter principal))
  (let ((contributor (default-to 
    { total-donated: u0, total-votes: u0, reputation: u1, joined-at: u0 }
    (map-get? contributor-profiles { contributor: voter }))))
    (+ u1 (/ (get total-donated contributor) u1000))
  )
)

(define-private (has-voted (proposal-id uint) (voter principal))
  (is-some (map-get? voter-records { proposal-id: proposal-id, voter: voter }))
)

(define-private (is-voting-open (proposal-id uint))
  (let ((proposal (unwrap! (map-get? fund-proposals { proposal-id: proposal-id }) false)))
    (and 
      (get is-active proposal)
      (< (- block-height (get created-at proposal)) VOTING_PERIOD)
      (is-eq (get status proposal) "pending")
    )
  )
)

;; Public functions
(define-public (donate-to-fund (amount uint))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Update contributor profile
    (let ((current-profile (default-to 
      { total-donated: u0, total-votes: u0, reputation: u1, joined-at: block-height }
      (map-get? contributor-profiles { contributor: tx-sender }))))
      
      (map-set contributor-profiles
        { contributor: tx-sender }
        (merge current-profile { 
          total-donated: (+ (get total-donated current-profile) amount),
          reputation: (+ (get reputation current-profile) u1)
        })
      )
    )
    
    ;; Update total fund balance
    (var-set total-fund-balance (+ (var-get total-fund-balance) amount))
    (ok true)
  )
)

(define-public (submit-proposal (title (string-ascii 100)) 
                               (description (string-ascii 500))
                               (amount uint)
                               (category (string-ascii 50)))
  (let ((proposal-id (var-get next-proposal-id)))
    (asserts! (and (>= amount MIN_PROPOSAL_AMOUNT) (<= amount MAX_PROPOSAL_AMOUNT)) ERR_INVALID_AMOUNT)
    (asserts! (<= amount (var-get total-fund-balance)) ERR_INSUFFICIENT_FUNDS)
    
    (map-set fund-proposals
      { proposal-id: proposal-id }
      {
        applicant: tx-sender,
        title: title,
        description: description,
        amount: amount,
        category: category,
        votes-for: u0,
        votes-against: u0,
        created-at: block-height,
        status: "pending",
        is-active: true
      }
    )
    
    (var-set next-proposal-id (+ proposal-id u1))
    (var-set total-proposals (+ (var-get total-proposals) u1))
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (support bool))
  (let (
    (proposal (unwrap! (map-get? fund-proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
    (voting-power (calculate-voting-power tx-sender))
  )
    (asserts! (is-voting-open proposal-id) ERR_VOTING_CLOSED)
    (asserts! (is-valid-voter tx-sender) ERR_UNAUTHORIZED)
    (asserts! (not (has-voted proposal-id tx-sender)) ERR_ALREADY_VOTED)
    
    ;; Record vote
    (map-set voter-records
      { proposal-id: proposal-id, voter: tx-sender }
      { vote: support, voted-at: block-height }
    )
    
    ;; Update proposal vote counts
    (let ((updated-proposal 
      (if support
        (merge proposal { votes-for: (+ (get votes-for proposal) voting-power) })
        (merge proposal { votes-against: (+ (get votes-against proposal) voting-power) })
      )))
      
      (map-set fund-proposals { proposal-id: proposal-id } updated-proposal)
    )
    
    ;; Update voter profile
    (let ((voter-profile (default-to 
      { total-donated: u0, total-votes: u0, reputation: u1, joined-at: block-height }
      (map-get? contributor-profiles { contributor: tx-sender }))))
      
      (map-set contributor-profiles
        { contributor: tx-sender }
        (merge voter-profile { 
          total-votes: (+ (get total-votes voter-profile) u1),
          reputation: (+ (get reputation voter-profile) u1)
        })
      )
    )
    
    (ok true)
  )
)

(define-public (finalize-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? fund-proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
    (asserts! (get is-active proposal) ERR_PROPOSAL_NOT_ACTIVE)
    (asserts! (not (is-voting-open proposal-id)) ERR_VOTING_CLOSED)
    
    (let (
      (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
      (approval-rate (if (> total-votes u0) (/ (* (get votes-for proposal) u100) total-votes) u0))
      (is-approved (and (> total-votes u10) (>= approval-rate u60)))
    )
      
      (if is-approved
        (begin
          ;; Approve and fund proposal
          (map-set fund-proposals
            { proposal-id: proposal-id }
            (merge proposal { status: "approved", is-active: false })
          )
          
          ;; Update recipient record
          (let ((recipient-record (default-to 
            { total-received: u0, proposals-funded: u0, last-funded: u0 }
            (map-get? fund-recipients { recipient: (get applicant proposal) }))))
            
            (map-set fund-recipients
              { recipient: (get applicant proposal) }
              {
                total-received: (+ (get total-received recipient-record) (get amount proposal)),
                proposals-funded: (+ (get proposals-funded recipient-record) u1),
                last-funded: block-height
              }
            )
          )
          
          ;; Update fund balance
          (var-set total-fund-balance (- (var-get total-fund-balance) (get amount proposal)))
          (var-set total-funded (+ (var-get total-funded) (get amount proposal)))
          (ok "approved")
        )
        (begin
          ;; Reject proposal
          (map-set fund-proposals
            { proposal-id: proposal-id }
            (merge proposal { status: "rejected", is-active: false })
          )
          (ok "rejected")
        )
      )
    )
  )
)

(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= amount (var-get total-fund-balance)) ERR_INSUFFICIENT_FUNDS)
    (var-set total-fund-balance (- (var-get total-fund-balance) amount))
    (ok amount)
  )
)

;; Read-only functions
(define-read-only (get-fund-balance)
  (var-get total-fund-balance)
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? fund-proposals { proposal-id: proposal-id })
)

(define-read-only (get-contributor-profile (contributor principal))
  (map-get? contributor-profiles { contributor: contributor })
)

(define-read-only (get-recipient-record (recipient principal))
  (map-get? fund-recipients { recipient: recipient })
)

(define-read-only (get-fund-stats)
  (ok {
    total-balance: (var-get total-fund-balance),
    total-proposals: (var-get total-proposals),
    total-funded: (var-get total-funded),
    next-proposal-id: (var-get next-proposal-id)
  })
)

(define-read-only (get-vote-record (proposal-id uint) (voter principal))
  (map-get? voter-records { proposal-id: proposal-id, voter: voter })
)