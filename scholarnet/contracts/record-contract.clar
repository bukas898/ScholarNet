;; Academic Research Network Contract
;; A platform for researchers to share publications, peer reviews, and academic credentials

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-RESEARCHER-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-ENDORSED (err u102))
(define-constant ERR-INVALID-PRIVACY-LEVEL (err u103))
(define-constant ERR-CREDENTIAL-NOT-FOUND (err u104))

;; Privacy levels
(define-constant PRIVACY-PUBLIC u0)
(define-constant PRIVACY-ACADEMIC-NETWORK u1)
(define-constant PRIVACY-PRIVATE u2)

;; Data structures
(define-map researcher-profiles
  principal
  {
    researcher-name: (string-ascii 50),
    bio: (string-ascii 500),
    institution: (string-ascii 200),
    privacy-level: uint,
    joined-at: uint,
    is-verified: bool
  })

(define-map publication-records
  { researcher: principal, publication-id: uint }
  {
    title: (string-ascii 100),
    journal: (string-ascii 100),
    publication-date: uint,
    doi: (optional uint),
    abstract: (string-ascii 500),
    privacy-level: uint
  })

(define-map academic-credentials
  { researcher: principal, credential-id: uint }
  {
    degree: (string-ascii 100),
    institution: (string-ascii 100),
    graduation-date: uint,
    field-of-study: (optional uint),
    verification-url: (string-ascii 200),
    privacy-level: uint,
    is-verified: bool
  })

(define-map peer-reviews
  { reviewer: principal, reviewee: principal, expertise: (string-ascii 50) }
  {
    feedback: (string-ascii 200),
    timestamp: uint,
    is-public: bool
  })

(define-map academic-connections
  { researcher1: principal, researcher2: principal }
  {
    status: (string-ascii 20), ;; "pending", "accepted", "blocked"
    initiated-by: principal,
    timestamp: uint
  })

;; Counters for unique IDs
(define-data-var publication-id-counter uint u0)
(define-data-var credential-id-counter uint u0)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Researcher profile management functions
(define-public (create-researcher-profile (researcher-name (string-ascii 50)) (bio (string-ascii 500)) (institution (string-ascii 200)) (privacy-level uint))
  (begin
    (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
    (ok (map-set researcher-profiles tx-sender {
      researcher-name: researcher-name,
      bio: bio,
      institution: institution,
      privacy-level: privacy-level,
      joined-at: block-height,
      is-verified: false
    }))))

(define-public (update-researcher-profile (researcher-name (string-ascii 50)) (bio (string-ascii 500)) (institution (string-ascii 200)) (privacy-level uint))
  (begin
    (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
    (asserts! (is-some (map-get? researcher-profiles tx-sender)) ERR-RESEARCHER-NOT-FOUND)
    (ok (map-set researcher-profiles tx-sender {
      researcher-name: researcher-name,
      bio: bio,
      institution: institution,
      privacy-level: privacy-level,
      joined-at: (default-to block-height (get joined-at (map-get? researcher-profiles tx-sender))),
      is-verified: (default-to false (get is-verified (map-get? researcher-profiles tx-sender)))
    }))))

;; Publication record functions
(define-public (add-publication-record (title (string-ascii 100)) (journal (string-ascii 100)) (publication-date uint) (doi (optional uint)) (abstract (string-ascii 500)) (privacy-level uint))
  (let ((publication-id (+ (var-get publication-id-counter) u1)))
    (begin
      (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
      (asserts! (is-some (map-get? researcher-profiles tx-sender)) ERR-RESEARCHER-NOT-FOUND)
      (var-set publication-id-counter publication-id)
      (ok (map-set publication-records { researcher: tx-sender, publication-id: publication-id } {
        title: title,
        journal: journal,
        publication-date: publication-date,
        doi: doi,
        abstract: abstract,
        privacy-level: privacy-level
      })))))

;; Academic credential functions
(define-public (add-academic-credential (degree (string-ascii 100)) (institution (string-ascii 100)) (graduation-date uint) (field-of-study (optional uint)) (verification-url (string-ascii 200)) (privacy-level uint))
  (let ((credential-id (+ (var-get credential-id-counter) u1)))
    (begin
      (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
      (asserts! (is-some (map-get? researcher-profiles tx-sender)) ERR-RESEARCHER-NOT-FOUND)
      (var-set credential-id-counter credential-id)
      (ok (map-set academic-credentials { researcher: tx-sender, credential-id: credential-id } {
        degree: degree,
        institution: institution,
        graduation-date: graduation-date,
        field-of-study: field-of-study,
        verification-url: verification-url,
        privacy-level: privacy-level,
        is-verified: false
      })))))

(define-public (verify-academic-credential (researcher principal) (credential-id uint))
  (let ((credential (map-get? academic-credentials { researcher: researcher, credential-id: credential-id })))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
      (asserts! (is-some credential) ERR-CREDENTIAL-NOT-FOUND)
      (ok (map-set academic-credentials { researcher: researcher, credential-id: credential-id }
        (merge (unwrap-panic credential) { is-verified: true }))))))

;; Peer review functions
(define-public (endorse-research-expertise (reviewee principal) (expertise (string-ascii 50)) (feedback (string-ascii 200)) (is-public bool))
  (begin
    (asserts! (is-some (map-get? researcher-profiles tx-sender)) ERR-RESEARCHER-NOT-FOUND)
    (asserts! (is-some (map-get? researcher-profiles reviewee)) ERR-RESEARCHER-NOT-FOUND)
    (asserts! (is-none (map-get? peer-reviews { reviewer: tx-sender, reviewee: reviewee, expertise: expertise })) ERR-ALREADY-ENDORSED)
    (ok (map-set peer-reviews { reviewer: tx-sender, reviewee: reviewee, expertise: expertise } {
      feedback: feedback,
      timestamp: block-height,
      is-public: is-public
    }))))

;; Academic connection functions
(define-public (send-collaboration-request (to-researcher principal))
  (begin
    (asserts! (is-some (map-get? researcher-profiles tx-sender)) ERR-RESEARCHER-NOT-FOUND)
    (asserts! (is-some (map-get? researcher-profiles to-researcher)) ERR-RESEARCHER-NOT-FOUND)
    (ok (map-set academic-connections { researcher1: tx-sender, researcher2: to-researcher } {
      status: "pending",
      initiated-by: tx-sender,
      timestamp: block-height
    }))))

(define-public (accept-collaboration-request (from-researcher principal))
  (let ((connection (map-get? academic-connections { researcher1: from-researcher, researcher2: tx-sender })))
    (begin
      (asserts! (is-some connection) ERR-RESEARCHER-NOT-FOUND)
      (asserts! (is-eq (get status (unwrap-panic connection)) "pending") ERR-NOT-AUTHORIZED)
      (ok (map-set academic-connections { researcher1: from-researcher, researcher2: tx-sender }
        (merge (unwrap-panic connection) { status: "accepted" }))))))

;; Read-only functions with privacy controls
(define-read-only (get-researcher-profile (researcher principal))
  (let ((profile (map-get? researcher-profiles researcher)))
    (if (is-some profile)
      (let ((profile-data (unwrap-panic profile)))
        (if (or (is-eq (get privacy-level profile-data) PRIVACY-PUBLIC)
                (is-eq researcher tx-sender)
                (is-academic-connected researcher tx-sender))
          profile
          none))
      none)))

(define-read-only (get-publication-record (researcher principal) (publication-id uint))
  (let ((publication (map-get? publication-records { researcher: researcher, publication-id: publication-id })))
    (if (is-some publication)
      (let ((publication-data (unwrap-panic publication)))
        (if (can-view-research-data researcher (get privacy-level publication-data))
          publication
          none))
      none)))

(define-read-only (get-academic-credential (researcher principal) (credential-id uint))
  (let ((credential (map-get? academic-credentials { researcher: researcher, credential-id: credential-id })))
    (if (is-some credential)
      (let ((credential-data (unwrap-panic credential)))
        (if (can-view-research-data researcher (get privacy-level credential-data))
          credential
          none))
      none)))

(define-read-only (get-peer-review (reviewer principal) (reviewee principal) (expertise (string-ascii 50)))
  (let ((review (map-get? peer-reviews { reviewer: reviewer, reviewee: reviewee, expertise: expertise })))
    (if (is-some review)
      (let ((review-data (unwrap-panic review)))
        (if (or (get is-public review-data)
                (is-eq reviewee tx-sender)
                (is-academic-connected reviewee tx-sender))
          review
          none))
      none)))

;; Helper functions
(define-read-only (is-academic-connected (researcher1 principal) (researcher2 principal))
  (or (is-eq (get status (default-to { status: "none", initiated-by: researcher1, timestamp: u0 } 
                          (map-get? academic-connections { researcher1: researcher1, researcher2: researcher2 }))) "accepted")
      (is-eq (get status (default-to { status: "none", initiated-by: researcher2, timestamp: u0 } 
                          (map-get? academic-connections { researcher1: researcher2, researcher2: researcher1 }))) "accepted")))

(define-read-only (can-view-research-data (data-owner principal) (privacy-level uint))
  (or (is-eq privacy-level PRIVACY-PUBLIC)
      (is-eq data-owner tx-sender)
      (and (is-eq privacy-level PRIVACY-ACADEMIC-NETWORK) (is-academic-connected data-owner tx-sender))))

;; Admin functions
(define-public (verify-researcher-profile (researcher principal))
  (let ((profile (map-get? researcher-profiles researcher)))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
      (asserts! (is-some profile) ERR-RESEARCHER-NOT-FOUND)
      (ok (map-set researcher-profiles researcher
        (merge (unwrap-panic profile) { is-verified: true }))))))

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner new-owner))))