// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IPairFactory {
    // Errors
    error FEE_TOO_HIGH();
    error IA();
    error INVALID_FEE_SPLIT();
    error NOT_AUTHORIZED();
    error PE();
    error ZA();
    error ZERO_FEE();

    // Events
    event FeeSplitWhenNoGauge(address indexed _caller, bool indexed _status);
    event NewTreasury(address indexed _caller, address indexed _newTreasury);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    event SetFee(uint256 indexed fee);
    event SetFeeRecipient(address indexed pair, address indexed feeRecipient);
    event SetFeeSplit(uint256 indexed _feeSplit);
    event SetPairFee(address indexed pair, uint256 indexed fee);
    event SetPairFeeSplit(address indexed pair, uint256 indexed _feeSplit);
    event SkimStatus(address indexed _pair, bool indexed _status);

    // Constants
    function MAX_FEE() external view returns (uint256);

    // Storage Variables
    function accessHub() external view returns (address);
    function allPairs(uint256) external view returns (address);
    function fee() external view returns (uint256);
    function feeRecipientFactory() external view returns (address);
    function feeSplit() external view returns (uint256);
    function feeSplitWhenNoGauge() external view returns (bool);
    function pairCodeHash() external view returns (bytes32);
    function treasury() external view returns (address);
    function voter() external view returns (address);

    // View/Pure Functions
    function allPairsLength() external view returns (uint256);
    function getPair(address token0, address token1, bool stable) external view returns (address pair);
    function isPair(address pair) external view returns (bool isPair);
    function pairFee(address _pair) external view returns (uint256 feeForPair);
    function skimEnabled(address pair) external view returns (bool skimEnabled);

    // State Modifying Functions
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function setFee(uint256 _fee) external;
    function setFeeRecipient(address _pair, address _feeRecipient) external;
    function setFeeSplit(uint256 _feeSplit) external;
    function setFeeSplitWhenNoGauge(bool status) external;
    function setPairFee(address _pair, uint256 _fee) external;
    function setPairFeeSplit(address _pair, uint256 _feeSplit) external;
    function setSkimEnabled(address _pair, bool _status) external;
    function setTreasury(address _treasury) external;
}