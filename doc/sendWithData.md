[ERC777](https://eips.ethereum.org/EIPS/eip-777) defines a new way to interact with a token contract while remaining backward compatible with [ERC-20](https://eips.ethereum.org/EIPS/eip-20). It takes advantage of [ERC-1820](https://eips.ethereum.org/EIPS/eip-1820) to find out whether and where to notify contracts and regular addresses when they receive tokens as well as to allow compatibility with already-deployed contracts.

Instead of `ERC20.transfer()` a new method is added, `send`. The `tokensReceived` hook notifies of any increment of the balance (send and mint) for a given recipient. Any address (regular or contract) wishing to be notified of token credits to their address MAY register the address of a contract implementing the `ERC777TokensRecipient` interface.

An operator is an address which is allowed to send and burn tokens on behalf of some holder. The token MAY define default operators. A default operator is an implicitly authorized operator for all holders. 

---

The issues with ERC777 are that:
- Overly engineered. Too much work to set up and interact with.
- Added protection against spam tokens can be circumvented
- Token fallback concept can be abused because caller is the ERC777 token contract, so there is no way to verify who was the original msg.sender
- Gas intensive

It is now deprecated in OpenZeppelin's repository.

It is vulnerable to both DoS and reentrancy attacks. This led to situations such as the imBTC hack through Uniswap for a loss of $25 million.

Consensys Diligence reported:
> Every ERC-777 token should have a callback to the spender before the balances are changed and to the recipient after. That allows everyone to make malicious reentrancy to an exchange contract with ERC-777 token.

---

[ERC1363](https://eips.ethereum.org/EIPS/eip-1363) defines a token interface for ERC-20 tokens that supports executing recipient code after `transfer` or `transferFrom`, or spender code after `approve`.

`transferAndCall` and `transferFromAndCall` will call an `onTransferReceived` on a ERC1363Receiver contract.

`approveAndCall` will call an `onApprovalReceived` on a ERC1363Spender contract.


---

Take away: When designing an application that interacts with arbitrary ERC20 tokens, don’t assume transfer and transferFrom are non-reentrant.