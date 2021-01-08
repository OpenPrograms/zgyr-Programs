# moonlink
A OpenComputers wireless mesh network with shortest path bridging.

By default, routes are updated every 30 seconds (TIMER_INTERVAL in moonlink.lua), and you can use the `ping` function to quickly update information from nearby nodes.

## Installation
oppm install moonlink

## Functions
* `connect([port: number])` connects to the moonlink network and registers message listener.
* `disconnect()` disconnects from the moonlink network.
* `send(address: string, ...)` tries to send a message `...` to `address`.
* `ping()` sends the ping message to neighbors.
* `list():table` returns a list of all available network nodes.

## Events
* `moonlink_message(receiver_addr: string, ...)` received message from the moonlink network.
