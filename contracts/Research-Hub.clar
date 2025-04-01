;; Academic Research Hub
;; A blockchain platform for secure academic research publication management
;; Author: ResearchDAO

;; Storage Structures
(define-map scholar-publications
  { manuscript-id: uint }
  {
    manuscript-name: (string-ascii 80),
    author: principal,
    file-size: uint,
    publication-date: uint,
    abstract: (string-ascii 256),
    categories: (list 8 (string-ascii 40))
  }
)

(define-map reader-access
  { manuscript-id: uint, reader: principal }
  { access-granted: bool }
)

;; State Variables
(define-data-var manuscripts-count uint u0)

;; Constants for Admin Control
(define-constant ADMIN_PRINCIPAL tx-sender)

;; Error Code Constants
(define-constant ERR_NOT_AUTHORIZED (err u305))
(define-constant ERR_INVALID_MANUSCRIPT_DATA (err u303))
(define-constant ERR_FILE_SIZE_LIMITS (err u304))
(define-constant ERR_DUPLICATE_MANUSCRIPT (err u302))
(define-constant ERR_MANUSCRIPT_NOT_FOUND (err u301))
(define-constant ERR_ADMIN_ONLY (err u300))

;; Validation Helper Functions
(define-private (check-category-length (category (string-ascii 40)))
  (and 
    (> (len category) u0)
    (< (len category) u41)
  )
)
(define-private (verify-categories (category-list (list 8 (string-ascii 40))))
  (and
    (> (len category-list) u0)
    (<= (len category-list) u8)
    (is-eq (len (filter check-category-length category-list)) (len category-list))
  )
)

;; Helper Functions
(define-private (manuscript-registered (manuscript-id uint))
  (is-some (map-get? scholar-publications { manuscript-id: manuscript-id }))
)

(define-private (is-manuscript-author (manuscript-id uint) (author principal))
  (match (map-get? scholar-publications { manuscript-id: manuscript-id })
    manuscript-data (is-eq (get author manuscript-data) author)
    false
  )
)

(define-private (get-file-size (manuscript-id uint))
  (default-to u0 
    (get file-size 
      (map-get? scholar-publications { manuscript-id: manuscript-id })
    )
  )
)

;; Public Functions for Manuscript Management

;; Submit a new academic manuscript to the repository
(define-public (submit-manuscript (manuscript-name (string-ascii 80)) (file-size uint) (abstract (string-ascii 256)) (categories (list 8 (string-ascii 40))))
  (let
    (
      (next-id (+ (var-get manuscripts-count) u1))
    )
    ;; Input validation
    (asserts! (> (len manuscript-name) u0) ERR_INVALID_MANUSCRIPT_DATA)
    (asserts! (< (len manuscript-name) u81) ERR_INVALID_MANUSCRIPT_DATA)
    (asserts! (> file-size u0) ERR_FILE_SIZE_LIMITS)
    (asserts! (< file-size u2000000000) ERR_FILE_SIZE_LIMITS)
    (asserts! (> (len abstract) u0) ERR_INVALID_MANUSCRIPT_DATA)
    (asserts! (< (len abstract) u257) ERR_INVALID_MANUSCRIPT_DATA)
    (asserts! (verify-categories categories) ERR_INVALID_MANUSCRIPT_DATA)

    ;; Register the manuscript
    (map-insert scholar-publications
      { manuscript-id: next-id }
      {
        manuscript-name: manuscript-name,
        author: tx-sender,
        file-size: file-size,
        publication-date: block-height,
        abstract: abstract,
        categories: categories
      }
    )

    ;; Grant author access to their own manuscript
    (map-insert reader-access
      { manuscript-id: next-id, reader: tx-sender }
      { access-granted: true }
    )

    ;; Update total count and return the new ID
    (var-set manuscripts-count next-id)
    (ok next-id)
  )
)

;; Delete a manuscript from the repository
(define-public (withdraw-manuscript (manuscript-id uint))
  (let
    (
      (manuscript-record (unwrap! (map-get? scholar-publications { manuscript-id: manuscript-id }) ERR_MANUSCRIPT_NOT_FOUND))
    )
    ;; Verify manuscript exists and sender is authorized
    (asserts! (manuscript-registered manuscript-id) ERR_MANUSCRIPT_NOT_FOUND)
    (asserts! (is-eq (get author manuscript-record) tx-sender) ERR_NOT_AUTHORIZED)

    ;; Remove the manuscript
    (map-delete scholar-publications { manuscript-id: manuscript-id })
    (ok true)
  )
)

;; Update manuscript metadata
(define-public (update-manuscript (manuscript-id uint) (new-manuscript-name (string-ascii 80)) (new-file-size uint) (new-abstract (string-ascii 256)) (new-categories (list 8 (string-ascii 40))))
  (let
    (
      (manuscript-record (unwrap! (map-get? scholar-publications { manuscript-id: manuscript-id }) ERR_MANUSCRIPT_NOT_FOUND))
    )
    ;; Verify manuscript exists and sender is authorized
    (asserts! (manuscript-registered manuscript-id) ERR_MANUSCRIPT_NOT_FOUND)
    (asserts! (is-eq (get author manuscript-record) tx-sender) ERR_NOT_AUTHORIZED)

    ;; Validate input data
    (asserts! (> (len new-manuscript-name) u0) ERR_INVALID_MANUSCRIPT_DATA)
    (asserts! (< (len new-manuscript-name) u81) ERR_INVALID_MANUSCRIPT_DATA)
    (asserts! (> new-file-size u0) ERR_FILE_SIZE_LIMITS)
    (asserts! (< new-file-size u2000000000) ERR_FILE_SIZE_LIMITS)
    (asserts! (> (len new-abstract) u0) ERR_INVALID_MANUSCRIPT_DATA)
    (asserts! (< (len new-abstract) u257) ERR_INVALID_MANUSCRIPT_DATA)
    (asserts! (verify-categories new-categories) ERR_INVALID_MANUSCRIPT_DATA)

    ;; Update the manuscript record
    (map-set scholar-publications
      { manuscript-id: manuscript-id }
      (merge manuscript-record { 
        manuscript-name: new-manuscript-name, 
        file-size: new-file-size, 
        abstract: new-abstract, 
        categories: new-categories 
      })
    )
    (ok true)
  )
)

;; Transfer manuscript ownership to another researcher
(define-public (transfer-authorship (manuscript-id uint) (new-author principal))
  (let
    (
      (manuscript-record (unwrap! (map-get? scholar-publications { manuscript-id: manuscript-id }) ERR_MANUSCRIPT_NOT_FOUND))
    )
    ;; Verify manuscript exists and sender is authorized
    (asserts! (manuscript-registered manuscript-id) ERR_MANUSCRIPT_NOT_FOUND)
    (asserts! (is-eq (get author manuscript-record) tx-sender) ERR_NOT_AUTHORIZED)

    ;; Update the manuscript owner
    (map-set scholar-publications
      { manuscript-id: manuscript-id }
      (merge manuscript-record { author: new-author })
    )
    (ok true)
  )
)
