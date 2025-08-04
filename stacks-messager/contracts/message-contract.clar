;; Web3-Native Messaging + Notifications Protocol
;; A comprehensive messaging system for dApps and wallets on Stacks

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_MESSAGE (err u101))
(define-constant ERR_MESSAGE_NOT_FOUND (err u102))
(define-constant ERR_INSUFFICIENT_BALANCE (err u103))
(define-constant ERR_INVALID_SUBSCRIPTION (err u104))
(define-constant ERR_USER_NOT_FOUND (err u105))
(define-constant ERR_BLOCKED_USER (err u106))

;; Message fee in microSTX (0.001 STX to prevent spam)
(define-constant MESSAGE_FEE u1000)

;; Data Variables
(define-data-var next-message-id uint u1)
(define-data-var protocol-fee uint u1000)
(define-data-var protocol-enabled bool true)

;; Message Types
(define-constant MSG_TYPE_DIRECT "direct")
(define-constant MSG_TYPE_BROADCAST "broadcast")
(define-constant MSG_TYPE_NOTIFICATION "notification")
(define-constant MSG_TYPE_ALERT "alert")

;; Priority Levels
(define-constant PRIORITY_LOW u1)
(define-constant PRIORITY_NORMAL u2)
(define-constant PRIORITY_HIGH u3)
(define-constant PRIORITY_URGENT u4)

;; Core Message Storage
(define-map messages
  { message-id: uint }
  {
    sender: principal,
    recipient: principal,
    content-hash: (buff 32),
    encrypted-key: (optional (buff 64)),
    message-type: (string-ascii 20),
    priority: uint,
    timestamp: uint,
    block-height: uint,
    expires-at: (optional uint),
    thread-id: (optional uint),
    dapp-origin: (optional principal),
    metadata: (optional (string-utf8 256))
  })

;; User Profiles and Preferences
(define-map user-profiles
  { user: principal }
  {
    display-name: (optional (string-utf8 50)),
    avatar-hash: (optional (buff 32)),
    public-key: (optional (buff 33)),
    created-at: uint,
    message-count: uint,
    last-active: uint,
    reputation-score: uint
  })

(define-map user-preferences
  { user: principal }
  {
    notifications-enabled: bool,
    allow-unknown-senders: bool,
    auto-delete-after: (optional uint),
    priority-threshold: uint,
    max-daily-messages: uint,
    require-payment: bool,
    custom-fee: (optional uint)
  })

;; Subscription Management
(define-map user-subscriptions
  { user: principal, dapp: principal }
  {
    subscribed: bool,
    notification-types: (list 10 (string-ascii 20)),
    created-at: uint,
    last-notification: (optional uint)
  })

;; Blocking System
(define-map blocked-users
  { blocker: principal, blocked: principal }
  { blocked-at: uint })

;; Message Threads
(define-map message-threads
  { thread-id: uint }
  {
    creator: principal,
    participants: (list 50 principal),
    message-count: uint,
    created-at: uint,
    last-message-at: uint,
    thread-name: (optional (string-utf8 100))
  })

;; dApp Registration
(define-map registered-dapps
  { dapp: principal }
  {
    name: (string-utf8 50),
    description: (optional (string-utf8 200)),
    website: (optional (string-utf8 100)),
    icon-hash: (optional (buff 32)),
    verified: bool,
    created-at: uint,
    message-count: uint
  })

;; Message Read Status
(define-map message-read-status
  { message-id: uint, user: principal }
  { read-at: uint })

;; Helper Functions

;; Check if user is blocked
(define-private (is-user-blocked (sender principal) (recipient principal))
  (is-some (map-get? blocked-users { blocker: recipient, blocked: sender })))

;; Get next message ID and increment
(define-private (get-next-message-id)
  (let ((current-id (var-get next-message-id)))
    (var-set next-message-id (+ current-id u1))
    current-id))

;; Validate message type
(define-private (is-valid-message-type (msg-type (string-ascii 20)))
  (or 
    (is-eq msg-type MSG_TYPE_DIRECT)
    (is-eq msg-type MSG_TYPE_BROADCAST)
    (is-eq msg-type MSG_TYPE_NOTIFICATION)
    (is-eq msg-type MSG_TYPE_ALERT)))

;; Public Functions

;; Initialize user profile
(define-public (initialize-profile (display-name (optional (string-utf8 50))) 
                                 (avatar-hash (optional (buff 32)))
                                 (public-key (optional (buff 33))))
  (let ((user tx-sender)
        (current-block block-height))
    (map-set user-profiles
      { user: user }
      {
        display-name: display-name,
        avatar-hash: avatar-hash,
        public-key: public-key,
        created-at: current-block,
        message-count: u0,
        last-active: current-block,
        reputation-score: u100
      })
    ;; Set default preferences
    (map-set user-preferences
      { user: user }
      {
        notifications-enabled: true,
        allow-unknown-senders: true,
        auto-delete-after: none,
        priority-threshold: PRIORITY_NORMAL,
        max-daily-messages: u100,
        require-payment: false,
        custom-fee: none
      })
    (ok true)))

;; Send a message
(define-public (send-message (recipient principal)
                           (content-hash (buff 32))
                           (encrypted-key (optional (buff 64)))
                           (message-type (string-ascii 20))
                           (priority uint)
                           (expires-at (optional uint))
                           (thread-id (optional uint))
                           (metadata (optional (string-utf8 256))))
  (let ((sender tx-sender)
        (message-id (get-next-message-id))
        (current-block block-height)
        (fee (var-get protocol-fee)))
    
    ;; Validate inputs
    (asserts! (var-get protocol-enabled) ERR_NOT_AUTHORIZED)
    (asserts! (is-valid-message-type message-type) ERR_INVALID_MESSAGE)
    (asserts! (<= priority PRIORITY_URGENT) ERR_INVALID_MESSAGE)
    (asserts! (not (is-user-blocked sender recipient)) ERR_BLOCKED_USER)
    
    ;; Check if payment required and collect fee
    (if (> fee u0)
      (try! (stx-transfer? fee sender CONTRACT_OWNER))
      true)
    
    ;; Store the message
    (map-set messages
      { message-id: message-id }
      {
        sender: sender,
        recipient: recipient,
        content-hash: content-hash,
        encrypted-key: encrypted-key,
        message-type: message-type,
        priority: priority,
        timestamp: block-height,
        block-height: current-block,
        expires-at: expires-at,
        thread-id: thread-id,
        dapp-origin: (some tx-sender),
        metadata: metadata
      })
    
    ;; Update sender's message count
    (map-set user-profiles
      { user: sender }
      (merge (default-to 
        {
          display-name: none,
          avatar-hash: none,
          public-key: none,
          created-at: current-block,
          message-count: u0,
          last-active: current-block,
          reputation-score: u100
        }
        (map-get? user-profiles { user: sender }))
        { message-count: (+ (get message-count (default-to { message-count: u0 } (map-get? user-profiles { user: sender }))) u1),
          last-active: current-block }))
    
    ;; Emit event for indexing
    (print {
      event: "message-sent",
      message-id: message-id,
      sender: sender,
      recipient: recipient,
      message-type: message-type,
      priority: priority,
      timestamp: block-height
    })
    
    (ok message-id)))

;; Subscribe to dApp notifications
(define-public (subscribe-to-dapp (dapp principal) 
                                (notification-types (list 10 (string-ascii 20))))
  (let ((user tx-sender)
        (current-block block-height))
    
    ;; Verify dApp is registered
    (asserts! (is-some (map-get? registered-dapps { dapp: dapp })) ERR_INVALID_SUBSCRIPTION)
    
    (map-set user-subscriptions
      { user: user, dapp: dapp }
      {
        subscribed: true,
        notification-types: notification-types,
        created-at: current-block,
        last-notification: none
      })
    
    (print {
      event: "dapp-subscribed",
      user: user,
      dapp: dapp,
      notification-types: notification-types
    })
    
    (ok true)))

;; Unsubscribe from dApp
(define-public (unsubscribe-from-dapp (dapp principal))
  (let ((user tx-sender))
    (map-delete user-subscriptions { user: user, dapp: dapp })
    
    (print {
      event: "dapp-unsubscribed",
      user: user,
      dapp: dapp
    })
    
    (ok true)))

;; Block a user
(define-public (block-user (user-to-block principal))
  (let ((blocker tx-sender)
        (current-block block-height))
    
    (asserts! (not (is-eq blocker user-to-block)) ERR_INVALID_MESSAGE)
    
    (map-set blocked-users
      { blocker: blocker, blocked: user-to-block }
      { blocked-at: current-block })
    
    (print {
      event: "user-blocked",
      blocker: blocker,
      blocked: user-to-block
    })
    
    (ok true)))

;; Unblock a user
(define-public (unblock-user (user-to-unblock principal))
  (let ((blocker tx-sender))
    (map-delete blocked-users { blocker: blocker, blocked: user-to-unblock })
    
    (print {
      event: "user-unblocked",
      blocker: blocker,
      unblocked: user-to-unblock
    })
    
    (ok true)))

;; Mark message as read
(define-public (mark-message-read (message-id uint))
  (let ((user tx-sender)
        (current-block block-height))
    
    ;; Verify message exists and user is recipient
    (match (map-get? messages { message-id: message-id })
      message-data 
        (begin
          (asserts! (is-eq user (get recipient message-data)) ERR_NOT_AUTHORIZED)
          (map-set message-read-status
            { message-id: message-id, user: user }
            { read-at: current-block })
          (ok true))
      ERR_MESSAGE_NOT_FOUND)))

;; Register dApp
(define-public (register-dapp (name (string-utf8 50))
                            (description (optional (string-utf8 200)))
                            (website (optional (string-utf8 100)))
                            (icon-hash (optional (buff 32))))
  (let ((dapp tx-sender)
        (current-block block-height))
    
    (map-set registered-dapps
      { dapp: dapp }
      {
        name: name,
        description: description,
        website: website,
        icon-hash: icon-hash,
        verified: false,
        created-at: current-block,
        message-count: u0
      })
    
    (print {
      event: "dapp-registered",
      dapp: dapp,
      name: name
    })
    
    (ok true)))

;; Update user preferences
(define-public (update-preferences (notifications-enabled bool)
                                 (allow-unknown-senders bool)
                                 (auto-delete-after (optional uint))
                                 (priority-threshold uint)
                                 (max-daily-messages uint)
                                 (require-payment bool)
                                 (custom-fee (optional uint)))
  (let ((user tx-sender))
    
    (map-set user-preferences
      { user: user }
      {
        notifications-enabled: notifications-enabled,
        allow-unknown-senders: allow-unknown-senders,
        auto-delete-after: auto-delete-after,
        priority-threshold: priority-threshold,
        max-daily-messages: max-daily-messages,
        require-payment: require-payment,
        custom-fee: custom-fee
      })
    
    (ok true)))

;; Read-only functions

;; Get message details
(define-read-only (get-message (message-id uint))
  (map-get? messages { message-id: message-id }))

;; Get user profile
(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user }))

;; Get user preferences
(define-read-only (get-user-preferences (user principal))
  (map-get? user-preferences { user: user }))

;; Check subscription status
(define-read-only (get-subscription (user principal) (dapp principal))
  (map-get? user-subscriptions { user: user, dapp: dapp }))

;; Check if message is read
(define-read-only (is-message-read (message-id uint) (user principal))
  (is-some (map-get? message-read-status { message-id: message-id, user: user })))

;; Get dApp info
(define-read-only (get-dapp-info (dapp principal))
  (map-get? registered-dapps { dapp: dapp }))

;; Check if user is blocked
(define-read-only (is-blocked (blocker principal) (blocked principal))
  (is-some (map-get? blocked-users { blocker: blocker, blocked: blocked })))

;; Admin functions (only contract owner)

;; Update protocol fee
(define-public (set-protocol-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set protocol-fee new-fee)
    (ok true)))

;; Enable/disable protocol
(define-public (set-protocol-enabled (enabled bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set protocol-enabled enabled)
    (ok true)))

;; Verify dApp
(define-public (verify-dapp (dapp principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (match (map-get? registered-dapps { dapp: dapp })
      dapp-data
        (begin
          (map-set registered-dapps
            { dapp: dapp }
            (merge dapp-data { verified: true }))
          (ok true))
      ERR_INVALID_SUBSCRIPTION)))

;; Withdraw collected fees
(define-public (withdraw-fees (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (stx-transfer? amount (as-contract tx-sender) recipient)))