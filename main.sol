// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Imbrium canopy — delayed handoffs and ink-weighted stakes; halts freeze ingress only.

error CobaltMicaImbrium_AccessDenied();
error CobaltMicaImbrium_AmountZero();
error CobaltMicaImbrium_CapBreached(uint256 maxWei);
error CobaltMicaImbrium_CooldownActive(uint256 availableAt);
error CobaltMicaImbrium_Halted();
error CobaltMicaImbrium_RecipientNotOnMatrix(address who);
error CobaltMicaImbrium_TransferFailed();
error CobaltMicaImbrium_MerkleInvalid();
error CobaltMicaImbrium_ClaimAlreadySpent(bytes32 leaf);
error CobaltMicaImbrium_InsufficientCredit();
error CobaltMicaImbrium_HandoffTiming();
error CobaltMicaImbrium_HandoffVacant();
error CobaltMicaImbrium_InkUnderflow();
error CobaltMicaImbrium_InkTimelock(uint256 readyAt);
error CobaltMicaImbrium_BatchLength();
error CobaltMicaImbrium_MemoSinkDenied(address sink);

event CobaltMicaImbrium_Pulse(uint256 indexed nonce, uint256 weiMoved, address indexed sink);
event CobaltMicaImbrium_Deposit(address indexed from, uint256 amount, bytes32 memo);
event CobaltMicaImbrium_SlateTraced(bytes32 indexed a, bytes32 indexed b, address indexed from);
event CobaltMicaImbrium_ConduitSweep(uint256 amount, address indexed conduit);
