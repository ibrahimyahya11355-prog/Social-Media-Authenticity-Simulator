;; Spontaneous Moment Scheduler
;; Plans unplanned adventures with optimal lighting and backup outfit options

;; Constants
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_INVALID_ADVENTURE (err u402))
(define-constant ERR_INVALID_LIGHTING (err u403))
(define-constant ERR_ADVENTURE_NOT_FOUND (err u405))
(define-constant ERR_INVALID_OUTFIT (err u406))

;; Data Maps
(define-map adventures uint {
    creator: principal,
    adventure-type: (string-ascii 50),
    lighting-condition: (string-ascii 50),
    primary-outfit: (string-ascii 100),
    backup-outfits: (list 5 (string-ascii 100)),
    location: (string-ascii 200),
    scheduled-time: uint,
    authenticity-score: uint,
    is-executed: bool,
    photographer: (optional principal)
})

(define-map user-adventures principal (list 50 uint))
(define-map outfit-combinations (string-ascii 150) uint)
(define-map location-popularity (string-ascii 200) uint)

;; Data Variables
(define-data-var adventure-counter uint u0)
(define-data-var total-authenticity-points uint u0)

;; Private Functions
(define-private (calculate-authenticity-score (adventure-type (string-ascii 50)) 
                                            (lighting (string-ascii 50)))
    (let (
        (base-score (if (is-eq adventure-type "coffee-run") u85
                    (if (is-eq adventure-type "beach-walk") u92
                    (if (is-eq adventure-type "workout-session") u78
                    (if (is-eq adventure-type "sunset-photography") u90 u70)))))
        (lighting-bonus (if (is-eq lighting "golden-hour") u98
                        (if (is-eq lighting "blue-hour") u95
                        (if (is-eq lighting "overcast") u75 u60))))
        (randomness (mod block-height u20))
    )
    (+ base-score (+ lighting-bonus randomness))
    )
)

(define-private (validate-adventure-type (adventure-type (string-ascii 50)))
    (or (is-eq adventure-type "coffee-run")
        (or (is-eq adventure-type "beach-walk")
            (or (is-eq adventure-type "workout-session")
                (is-eq adventure-type "sunset-photography"))))
)

(define-private (validate-lighting-condition (lighting (string-ascii 50)))
    (or (is-eq lighting "golden-hour")
        (or (is-eq lighting "blue-hour")
            (or (is-eq lighting "overcast")
                (is-eq lighting "bright-sun"))))
)

;; Public Functions
(define-public (schedule-adventure 
    (adventure-type (string-ascii 50))
    (lighting-condition (string-ascii 50))
    (primary-outfit (string-ascii 100))
    (backup-outfits (list 5 (string-ascii 100)))
    (location (string-ascii 200))
    (scheduled-time uint)
    (photographer (optional principal)))
    (let (
        (adventure-id (+ (var-get adventure-counter) u1))
        (authenticity-score (calculate-authenticity-score adventure-type lighting-condition))
    )
    (asserts! (validate-adventure-type adventure-type) ERR_INVALID_ADVENTURE)
    (asserts! (validate-lighting-condition lighting-condition) ERR_INVALID_LIGHTING)
    (asserts! (> (len primary-outfit) u0) ERR_INVALID_OUTFIT)
    (asserts! (> scheduled-time block-height) (err u407))
    
    (map-set adventures adventure-id {
        creator: tx-sender,
        adventure-type: adventure-type,
        lighting-condition: lighting-condition,
        primary-outfit: primary-outfit,
        backup-outfits: backup-outfits,
        location: location,
        scheduled-time: scheduled-time,
        authenticity-score: authenticity-score,
        is-executed: false,
        photographer: photographer
    })
    
    (var-set adventure-counter adventure-id)
    (var-set total-authenticity-points (+ (var-get total-authenticity-points) authenticity-score))
    
    (ok adventure-id)
    )
)

(define-public (execute-adventure (adventure-id uint))
    (let (
        (adventure-data (unwrap! (map-get? adventures adventure-id) ERR_ADVENTURE_NOT_FOUND))
    )
    (asserts! (is-eq (get creator adventure-data) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (not (get is-executed adventure-data)) (err u408))
    (asserts! (<= (get scheduled-time adventure-data) block-height) (err u409))
    
    (map-set adventures adventure-id (merge adventure-data { is-executed: true }))
    (ok true)
    )
)

(define-public (update-outfit (adventure-id uint) (new-primary-outfit (string-ascii 100)))
    (let (
        (adventure-data (unwrap! (map-get? adventures adventure-id) ERR_ADVENTURE_NOT_FOUND))
    )
    (asserts! (is-eq (get creator adventure-data) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (not (get is-executed adventure-data)) (err u408))
    (asserts! (> (len new-primary-outfit) u0) ERR_INVALID_OUTFIT)
    
    (map-set adventures adventure-id 
        (merge adventure-data { primary-outfit: new-primary-outfit }))
    (ok true)
    )
)

;; Read-only functions
(define-read-only (get-adventure (adventure-id uint))
    (map-get? adventures adventure-id)
)

(define-read-only (get-user-adventures (user principal))
    (map-get? user-adventures user)
)

(define-read-only (get-adventure-counter)
    (var-get adventure-counter)
)

(define-read-only (get-total-authenticity-points)
    (var-get total-authenticity-points)
)

(define-read-only (get-location-popularity (location (string-ascii 200)))
    (default-to u0 (map-get? location-popularity location))
)

(define-read-only (calculate-optimal-timing (adventure-type (string-ascii 50)))
    (if (or (is-eq adventure-type "sunset-photography") (is-eq adventure-type "beach-walk"))
        (+ block-height u144)
        (+ block-height u72)
    )
)