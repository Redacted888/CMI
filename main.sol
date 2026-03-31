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
event CobaltMicaImbrium_HaltSet(bool on);
event CobaltMicaImbrium_MerkleRoot(bytes32 indexed root, uint256 indexed epoch);
event CobaltMicaImbrium_GulfClaim(address indexed claimant, uint256 amount, bytes32 leaf);
event CobaltMicaImbrium_CreditSet(address indexed holder, uint256 amount);
event CobaltMicaImbrium_SuccessorProposed(address indexed fromWarden, address indexed pending, uint256 unlocks);
event CobaltMicaImbrium_SuccessorCleared(address indexed fromWarden);
event CobaltMicaImbrium_WardenAdvanced(address indexed previous, address indexed next);
event CobaltMicaImbrium_InkMoved(address indexed who, int256 delta, uint256 newBalance);
event CobaltMicaImbrium_Imprint(bytes32 indexed digest);
event CobaltMicaImbrium_BatchImprint(uint256 indexed count, bytes32 head, bytes32 tail);
event CobaltMicaImbrium_MemoPulse(address indexed sink, uint256 amount, bytes32 outer, bytes32 inner);

contract CobaltMicaGlyphFjordImbrium {
    address public immutable conduit;

    address internal constant TRIPLEX_ALPHA = 0x13579246801357924680135792468013579246801357924680;
    address internal constant TRIPLEX_BETA = 0x24680135792468013579246801357924680135792468013579;
    address internal constant TRIPLEX_GAMMA = 0x97531864209753186420975318642097531864209753186420;

    bytes32 public immutable imbriumSalt;

    address public chamberWarden;
    uint256 public immutable genesisEpoch;
    uint256 public pulseNonce;
    uint256 public lastPulseAt;
    bool public halted;
