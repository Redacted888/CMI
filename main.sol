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
    uint256 public merkleEpoch;
    bytes32 public activeMerkleRoot;

    address public pendingWarden;
    uint256 public wardenUnlocks;

    mapping(bytes32 => bool) public spentClaim;
    mapping(address => uint256) public kiteCredit;
    mapping(address => uint256) public inkStake;
    mapping(address => uint256) public inkLastShift;

    uint256 public constant PULSE_COOLDOWN = 6 hours;
    uint256 public constant DRIP_CAP = 88 ether;
    uint256 public constant CONDUIT_BURST = 500 ether;
    uint256 public constant HANDOFF_DELAY = 48 hours;
    uint256 public constant INK_COOLDOWN = 24 hours;

    bool private _entrancyLocked;

    modifier onlyWarden() {
        if (msg.sender != chamberWarden) revert CobaltMicaImbrium_AccessDenied();
        _;
    }

    modifier whenNotHalted() {
        if (halted) revert CobaltMicaImbrium_Halted();
        _;
    }

    modifier nonReentrant() {
        if (_entrancyLocked) revert CobaltMicaImbrium_AccessDenied();
        _entrancyLocked = true;
        _;
        _entrancyLocked = false;
    }

    constructor(address warden_, address conduit_) {
        if (warden_ == address(0) || conduit_ == address(0)) revert CobaltMicaImbrium_AccessDenied();
        chamberWarden = warden_;
        conduit = conduit_;
        genesisEpoch = block.timestamp;
        imbriumSalt = keccak256(abi.encodePacked("cobalt-mica-imbrium", block.chainid, warden_, conduit_));
    }

    receive() external payable whenNotHalted {
        emit CobaltMicaImbrium_Deposit(msg.sender, msg.value, bytes32(0));
    }

    function depositWithMemo(bytes32 memo) external payable whenNotHalted {
        if (msg.value == 0) revert CobaltMicaImbrium_AmountZero();
        emit CobaltMicaImbrium_Deposit(msg.sender, msg.value, memo);
    }

    function proposeSuccessor(address next) external onlyWarden {
        if (next == address(0) || next == chamberWarden) revert CobaltMicaImbrium_AccessDenied();
        pendingWarden = next;
        wardenUnlocks = block.timestamp + HANDOFF_DELAY;
        emit CobaltMicaImbrium_SuccessorProposed(chamberWarden, next, wardenUnlocks);
    }

    function clearSuccessor() external onlyWarden {
        pendingWarden = address(0);
        wardenUnlocks = 0;
        emit CobaltMicaImbrium_SuccessorCleared(chamberWarden);
    }

    function acceptSuccessor() external {
        if (pendingWarden == address(0)) revert CobaltMicaImbrium_HandoffVacant();
        if (msg.sender != pendingWarden) revert CobaltMicaImbrium_AccessDenied();
        if (block.timestamp < wardenUnlocks) revert CobaltMicaImbrium_HandoffTiming();

        address prev = chamberWarden;
        chamberWarden = pendingWarden;
        pendingWarden = address(0);
        wardenUnlocks = 0;

        emit CobaltMicaImbrium_WardenAdvanced(prev, chamberWarden);
    }
