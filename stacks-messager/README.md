# Web3-Native Messaging + Notifications Protocol

A comprehensive decentralized messaging system built on the Stacks blockchain, enabling secure communication between dApps, wallets, and users with built-in spam protection and notification management.

## Overview

This protocol provides a complete messaging infrastructure for Web3 applications, featuring encrypted messaging, user preferences, subscription management, and anti-spam mechanisms. Built as a Clarity smart contract, it leverages the security and decentralization of the Stacks blockchain.

## Key Features

### 🔐 Secure Messaging
- **Encrypted Communications**: Support for encrypted messages with optional key exchange
- **Multiple Message Types**: Direct messages, broadcasts, notifications, and alerts
- **Priority System**: Four-tier priority levels (Low, Normal, High, Urgent)
- **Message Expiration**: Optional time-based message expiration
- **Thread Support**: Organize messages into conversation threads

### 👤 User Management
- **Customizable Profiles**: Display names, avatars, and public keys
- **Privacy Controls**: Block/unblock users, control message preferences
- **Reputation System**: Built-in reputation scoring
- **Flexible Preferences**: Configure notification settings, payment requirements, and daily limits

### 📱 dApp Integration
- **dApp Registration**: Official dApp verification system
- **Subscription Management**: Users can subscribe/unsubscribe to dApp notifications
- **Notification Types**: Granular control over notification categories
- **Origin Tracking**: Track message sources for transparency

### 🛡️ Anti-Spam Protection
- **Message Fees**: Configurable fees to prevent spam (default: 0.001 STX)
- **Rate Limiting**: User-defined daily message limits
- **Blocking System**: Comprehensive user blocking functionality
- **Payment Requirements**: Optional payment gates for messages

## Message Types

| Type | Description | Use Case |
|------|-------------|----------|
| `direct` | One-to-one private messages | Personal communication |
| `broadcast` | One-to-many messages | Announcements, updates |
| `notification` | System/dApp notifications | App alerts, reminders |
| `alert` | High-priority urgent messages | Security alerts, warnings |

## Priority Levels

- **Low (1)**: Non-critical messages
- **Normal (2)**: Standard communications
- **High (3)**: Important messages requiring attention
- **Urgent (4)**: Critical alerts requiring immediate action

## Core Functions

### User Operations

#### Initialize Profile
```clarity
(initialize-profile (display-name (optional (string-utf8 50))) 
                   (avatar-hash (optional (buff 32)))
                   (public-key (optional (buff 33))))
```
Set up your user profile with display name, avatar, and encryption key.

#### Send Message
```clarity
(send-message (recipient principal)
             (content-hash (buff 32))
             (encrypted-key (optional (buff 64)))
             (message-type (string-ascii 20))
             (priority uint)
             (expires-at (optional uint))
             (thread-id (optional uint))
             (metadata (optional (string-utf8 256))))
```
Send encrypted messages with full metadata support.

#### Update Preferences
```clarity
(update-preferences (notifications-enabled bool)
                   (allow-unknown-senders bool)
                   (auto-delete-after (optional uint))
                   (priority-threshold uint)
                   (max-daily-messages uint)
                   (require-payment bool)
                   (custom-fee (optional uint)))
```
Configure your messaging preferences and privacy settings.

### Subscription Management

#### Subscribe to dApp
```clarity
(subscribe-to-dapp (dapp principal) 
                  (notification-types (list 10 (string-ascii 20))))
```

#### Unsubscribe from dApp
```clarity
(unsubscribe-from-dapp (dapp principal))
```

### Privacy Controls

#### Block/Unblock Users
```clarity
(block-user (user-to-block principal))
(unblock-user (user-to-unblock principal))
```

### Read-Only Functions

- `get-message(message-id)` - Retrieve message details
- `get-user-profile(user)` - Get user profile information
- `get-user-preferences(user)` - Get user preference settings
- `get-subscription(user, dapp)` - Check subscription status
- `is-message-read(message-id, user)` - Check read status
- `get-dapp-info(dapp)` - Get dApp registration details
- `is-blocked(blocker, blocked)` - Check blocking status

## dApp Integration

### Registration Process

1. **Register Your dApp**
```clarity
(register-dapp (name (string-utf8 50))
              (description (optional (string-utf8 200)))
              (website (optional (string-utf8 100)))
              (icon-hash (optional (buff 32))))
```

2. **Get Verified** (requires admin approval)
3. **Start Sending Notifications** to subscribed users

### Best Practices for dApps

- **Register Early**: Register your dApp before sending notifications
- **Respect User Preferences**: Check user notification settings
- **Use Appropriate Priority**: Don't abuse high-priority notifications
- **Provide Clear Descriptions**: Help users understand your notification types

## Fee Structure

- **Default Message Fee**: 0.001 STX (1000 microSTX)
- **Purpose**: Prevent spam and network abuse
- **Configurable**: Protocol owner can adjust fees
- **User Override**: Users can set custom fees for receiving messages

## Technical Specifications

### Data Storage

- **Messages**: Content hash, metadata, encryption keys
- **User Profiles**: Display info, preferences, reputation
- **Subscriptions**: dApp notification preferences
- **Threads**: Conversation organization
- **Read Status**: Message read tracking

### Security Features

- **Access Control**: Function-level permissions
- **Input Validation**: Comprehensive parameter checking
- **Spam Prevention**: Multiple anti-spam mechanisms
- **Privacy Protection**: User blocking and preference controls

## Getting Started

### For Users

1. **Initialize Your Profile**
   ```clarity
   (contract-call? .messaging-protocol initialize-profile 
     (some u"Your Name") none none)
   ```

2. **Set Your Preferences**
   ```clarity
   (contract-call? .messaging-protocol update-preferences 
     true true none u2 u100 false none)
   ```

3. **Start Messaging**!

### For dApp Developers

1. **Register Your dApp**
2. **Implement notification logic in your dApp**
3. **Respect user subscription preferences**
4. **Monitor your message delivery and user feedback**

## Events and Indexing

The contract emits structured events for:
- `message-sent`: New message notifications
- `dapp-subscribed`/`dapp-unsubscribed`: Subscription changes
- `user-blocked`/`user-unblocked`: Privacy control updates
- `dapp-registered`: New dApp registrations

These events enable efficient indexing and real-time notification systems.

## Admin Functions

Contract administrators can:
- Set protocol fees
- Enable/disable the protocol
- Verify dApps
- Withdraw collected fees

## Future Enhancements

- **Message Threading**: Enhanced conversation management
- **File Attachments**: Support for larger content types
- **Group Messaging**: Multi-participant conversations
- **Message Reactions**: Emoji reactions and responses
- **Advanced Encryption**: Enhanced privacy features

## Contributing

This is an open protocol designed for community use and enhancement. Contributions, suggestions, and integrations are welcome.

## Security Considerations

- Always verify message authenticity
- Use proper encryption for sensitive content
- Regularly update your security preferences
- Report suspicious activity to protocol administrators
