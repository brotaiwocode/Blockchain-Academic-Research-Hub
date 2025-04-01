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
