# Lottery System Contract

## Overview

The Lottery System contract provides a decentralized lottery mechanism where users can purchase tickets and winners are selected randomly using Stacks VRF (Verifiable Random Function).

## Features

- **Ticket Purchase**: Users can buy lottery tickets with STX
- **Random Selection**: Winners are selected using blockchain VRF for fairness
- **Prize Distribution**: Automatic distribution of 90% of pool to winner
- **Owner Controls**: Contract owner can start lotteries and set ticket prices

## Functions

### Public Functions

#### `start-lottery`

Starts a new lottery round.

- **Access**: Owner only
- **Returns**: `(ok true)` on success

#### `buy-ticket`

Purchase a lottery ticket for the current round.

- **Cost**: Configured ticket price (default 1 STX)
- **Returns**: `(ok true)` on success

#### `draw-winner`

Selects and pays out the winner.

- **Access**: Owner only
- **Requirements**: At least one participant
- **Returns**: Winner's principal

#### `set-ticket-price (new-price uint)`

Updates the ticket price.

- **Access**: Owner only
- **Requirements**: Lottery must not be active
- **Returns**: `(ok true)` on success

#### `withdraw-fees`

Withdraws accumulated fees (10% of each lottery).

- **Access**: Owner only
- **Requirements**: Lottery must not be active
- **Returns**: Amount withdrawn

### Read-Only Functions

#### `get-lottery-status`

Returns current lottery status including:

- Active status
- Current round
- Ticket price
- Total pool

#### `get-participant-tickets (round uint) (participant principal)`

Returns number of tickets owned by a participant in a specific round.

#### `get-round-winner (round uint)`

Returns winner information for a completed round.

## Usage Example

```clarity
;; Start a new lottery
(contract-call? .lottery-system start-lottery)

;; Buy a ticket
(contract-call? .lottery-system buy-ticket)

;; Draw winner (owner only)
(contract-call? .lottery-system draw-winner)
```

## Security Considerations

- Uses VRF for random number generation
- 10% platform fee prevents abuse
- Owner-only administrative functions
- Proper access controls on all functions
