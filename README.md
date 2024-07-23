# Event Ticket Booking Smart Contract

## Overview

This Project implements a simple event ticket booking system using a smart contract written in Clarity, designed for the Stacks blockchain. The contract allows event organizers to create events and sell tickets while attendees can purchase tickets securely.

## Features

- Create events with customizable name, ticket price, and total number of tickets.
- Purchase tickets using cryptocurrency (STX)
- Track ticket sales and availability
- Prevent double-booking and overselling
- Retrieve event and ticket information

## Smart Contract Functions

### Admin Functions

- `create-event`: Allows the contract owner to create a new event

### Public Functions

- `buy-ticket`: Enables users to purchase a ticket for the event
- `get-ticket-info`: Retrieves ticket information for a specific owner
- `get-event-info`: Retrieves general information about the event

## Usage

1. Deploy the smart contract to the Stacks blockchain
2. Use the `create-event` functions to set up your event (contract owner only)
3. Attendees can use the `buy-ticket` function to purchase tickets
4. Use `get-ticket-info` and `get-event-info` to retrieve relevant information