;; Humble Brag Optimization Service
;; Converts obvious flexes into subtly relatable struggles that still showcase success

;; Constants
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_INVALID_CONTENT (err u402))
(define-constant ERR_CONTENT_NOT_FOUND (err u403))
(define-constant ERR_INVALID_RELATABILITY (err u404))
(define-constant ERR_ALREADY_OPTIMIZED (err u405))

;; Data Maps
(define-map content-optimizations uint {
    creator: principal,
    original-content: (string-ascii 500),
    optimized-content: (string-ascii 500),
    success-category: (string-ascii 50),
    relatability-template: (string-ascii 50),
    relatability-score: uint,
    engagement-prediction: uint,
    authenticity-balance: uint,
    is-published: bool,
    optimization-timestamp: uint,
    feedback-score: uint
})

(define-map user-profiles principal {
    total-optimizations: uint,
    average-engagement: uint,
    preferred-template: (string-ascii 50),
    success-focus: (string-ascii 50),
    authenticity-level: uint,
    subscription-tier: uint
})

(define-map content-analytics (string-ascii 50) {
    usage-count: uint,
    average-engagement: uint,
    success-rate: uint
})

(define-map engagement-tracking uint {
    likes: uint,
    comments: uint,
    shares: uint,
    saves: uint,
    total-engagement: uint
})

;; Data Variables
(define-data-var content-counter uint u0)
(define-data-var total-optimizations uint u0)
(define-data-var platform-revenue uint u0)
(define-data-var optimization-fee uint u100)

;; Private Functions
(define-private (calculate-relatability-score (success-category (string-ascii 50)) 
                                            (template (string-ascii 50))
                                            (original-length uint))
    (let (
        (category-score (if (is-eq success-category "career") u80
                        (if (is-eq success-category "wealth") u75
                        (if (is-eq success-category "travel") u90
                        (if (is-eq success-category "lifestyle") u92 u70)))))
        (template-score (if (is-eq template "struggle-narrative") u95
                        (if (is-eq template "accidental-mention") u88
                        (if (is-eq template "humble-question") u92
                        (if (is-eq template "grateful-surprise") u89 u70)))))
        (length-factor (if (< original-length u100) u10 
                       (if (< original-length u200) u5 u0)))
        (randomness (mod block-height u15))
    )
    (+ category-score (+ template-score (+ length-factor randomness)))
    )
)

(define-private (predict-engagement (relatability-score uint) (category (string-ascii 50)))
    (let (
        (base-engagement (* relatability-score u2))
        (category-multiplier (if (or (is-eq category "travel") (is-eq category "lifestyle")) u15 u10))
        (viral-potential (if (> relatability-score u180) u50 u0))
    )
    (+ base-engagement (+ category-multiplier viral-potential))
    )
)

(define-private (validate-success-category (category (string-ascii 50)))
    (or (is-eq category "career")
        (or (is-eq category "wealth")
            (or (is-eq category "travel")
                (or (is-eq category "relationships")
                    (or (is-eq category "health")
                        (or (is-eq category "education")
                            (or (is-eq category "achievements")
                                (or (is-eq category "lifestyle")
                                    (or (is-eq category "social")
                                        (is-eq category "creative"))))))))))
)

(define-private (validate-template (template (string-ascii 50)))
    (or (is-eq template "struggle-narrative")
        (or (is-eq template "accidental-mention")
            (or (is-eq template "humble-question")
                (or (is-eq template "grateful-surprise")
                    (or (is-eq template "learning-journey")
                        (or (is-eq template "community-focus")
                            (or (is-eq template "behind-scenes")
                                (or (is-eq template "vulnerability-share")
                                    (or (is-eq template "mentor-credit")
                                        (is-eq template "failure-contrast"))))))))))
)

;; Public Functions
(define-public (optimize-content 
    (original-content (string-ascii 500))
    (success-category (string-ascii 50))
    (relatability-template (string-ascii 50))
    (target-relatability-level uint))
    (let (
        (content-id (+ (var-get content-counter) u1))
        (relatability-score (calculate-relatability-score success-category relatability-template (len original-content)))
        (engagement-prediction (predict-engagement relatability-score success-category))
        (authenticity-balance (- u100 (/ relatability-score u2)))
        (optimized-text (concat "Optimized: " original-content))
    )
    (asserts! (> (len original-content) u0) ERR_INVALID_CONTENT)
    (asserts! (validate-success-category success-category) (err u407))
    (asserts! (validate-template relatability-template) (err u408))
    (asserts! (and (>= target-relatability-level u1) (<= target-relatability-level u10)) ERR_INVALID_RELATABILITY)
    
    (map-set content-optimizations content-id {
        creator: tx-sender,
        original-content: original-content,
        optimized-content: optimized-text,
        success-category: success-category,
        relatability-template: relatability-template,
        relatability-score: relatability-score,
        engagement-prediction: engagement-prediction,
        authenticity-balance: authenticity-balance,
        is-published: false,
        optimization-timestamp: block-height,
        feedback-score: u0
    })
    
    (var-set content-counter content-id)
    (var-set total-optimizations (+ (var-get total-optimizations) u1))
    
    (ok content-id)
    )
)

(define-public (publish-optimized-content (content-id uint))
    (let (
        (content-data (unwrap! (map-get? content-optimizations content-id) ERR_CONTENT_NOT_FOUND))
    )
    (asserts! (is-eq (get creator content-data) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (not (get is-published content-data)) ERR_ALREADY_OPTIMIZED)
    
    (map-set content-optimizations content-id (merge content-data { is-published: true }))
    (ok true)
    )
)

(define-public (rate-optimization (content-id uint) (feedback-score uint))
    (let (
        (content-data (unwrap! (map-get? content-optimizations content-id) ERR_CONTENT_NOT_FOUND))
    )
    (asserts! (get is-published content-data) (err u409))
    (asserts! (and (>= feedback-score u1) (<= feedback-score u10)) (err u410))
    
    (map-set content-optimizations content-id 
        (merge content-data { feedback-score: feedback-score }))
    (ok true)
    )
)

(define-public (update-engagement-metrics (content-id uint) 
                                        (likes uint) 
                                        (comments uint) 
                                        (shares uint) 
                                        (saves uint))
    (let (
        (content-data (unwrap! (map-get? content-optimizations content-id) ERR_CONTENT_NOT_FOUND))
        (total-engagement (+ likes (+ comments (+ shares saves))))
    )
    (asserts! (is-eq (get creator content-data) tx-sender) ERR_UNAUTHORIZED)
    
    (map-set engagement-tracking content-id {
        likes: likes,
        comments: comments,
        shares: shares,
        saves: saves,
        total-engagement: total-engagement
    })
    (ok total-engagement)
    )
)

;; Read-only Functions
(define-read-only (get-content-optimization (content-id uint))
    (map-get? content-optimizations content-id)
)

(define-read-only (get-user-profile (user principal))
    (map-get? user-profiles user)
)

(define-read-only (get-content-counter)
    (var-get content-counter)
)

(define-read-only (get-total-optimizations)
    (var-get total-optimizations)
)

(define-read-only (get-template-analytics (template (string-ascii 50)))
    (map-get? content-analytics template)
)

(define-read-only (get-engagement-metrics (content-id uint))
    (map-get? engagement-tracking content-id)
)

(define-read-only (calculate-authenticity-balance (relatability-score uint))
    (if (> relatability-score u180) u20
        (if (> relatability-score u150) u40
            (if (> relatability-score u120) u60
                (if (> relatability-score u90) u80 u100))))
)

(define-read-only (estimate-virality-potential (engagement-prediction uint) (category (string-ascii 50)))
    (let (
        (base-viral (if (> engagement-prediction u300) u80 u20))
        (category-boost (if (or (is-eq category "travel") (is-eq category "lifestyle")) u20 u0))
    )
    (+ base-viral category-boost)
    )
)

(define-read-only (get-optimization-fee)
    (var-get optimization-fee)
)

(define-read-only (get-platform-revenue)
    (var-get platform-revenue)
)