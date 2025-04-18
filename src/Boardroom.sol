// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./lib/Babylonian.sol";
import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IMasonry.sol";
import "./owner/Operator.sol";

contract Boardroom is ContractGuard, Operator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant PERIOD = 6 hours;
    uint256 public constant BASIS_DIVISOR = 100000; // 100%

    /* ========== STATE VARIABLES ========== */

    // flags
    bool public initialized = false;

    // epoch
    uint256 public startTime;
    uint256 public epoch = 0;
    uint256 public epochSupplyContractionLeft = 0;

    //=================================================================// exclusions from total supply
    address[] public excludedFromTotalSupply = [
        address(0x79717Ca0fC65fCfaf02457d65a4F2ed5E3b69B22) // Ragnarok
    ];

    // core components
    address public valhalla;
    address public vbond;
    address public vshare;

    address public masonry;
    address public valhallaOracle;

    // price
    uint256 public valhallaPriceOne;
    uint256 public valhallaPriceCeiling;

    uint256 public seigniorageSaved;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDebtRatioPercent;

    // 14 first epochs (0.5 week) with 4.5% expansion regardless of VAL price
    uint256 public bootstrapEpochs;
    uint256 public bootstrapSupplyExpansionPercent;

    /* =================== Added variables =================== */
    uint256 public previousEpochValhallaPrice;
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate;  // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt; // print extra VAL during debt phase

    address public daoFund;
    uint256 public daoFundSharedPercent;

    //=================================================//

    address public devFund;
    uint256 public devFundSharedPercent;
    address public teamFund;
    uint256 public teamFundSharedPercent;

    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(address indexed from, uint256 valhallaAmount, uint256 bondAmount);
    event BoughtBonds(address indexed from, uint256 valhallaAmount, uint256 bondAmount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event MasonryFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);
    event TeamFundFunded(uint256 timestamp, uint256 seigniorage);

    /* =================== Modifier =================== */

    modifier checkCondition {
        require(block.timestamp >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch {
        require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
        epochSupplyContractionLeft = (getValhallaPrice() > valhallaPriceCeiling) ? 0 : getValhallaCirculatingSupply().mul(maxSupplyContractionPercent).div(BASIS_DIVISOR);
    }

    modifier checkOperator {
        require(
                IBasisAsset(valhalla).operator() == address(this) &&
                IBasisAsset(vbond).operator() == address(this) &&
                IBasisAsset(vshare).operator() == address(this) &&
                Operator(masonry).operator() == address(this),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getValhallaPrice() public view returns (uint256 valhallaPrice) {
        try IOracle(valhallaOracle).consult(valhalla, 1e18) returns (uint256 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult VAL price from the oracle");
        }
    }

    function getValhallaUpdatedPrice() public view returns (uint256 _valhallaPrice) {
        try IOracle(valhallaOracle).twap(valhalla, 1e18) returns (uint256 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult VAL price from the oracle");
        }
    }

    // budget
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function getBurnableValhallaLeft() public view returns (uint256 _burnableValhallaLeft) {
        uint256 _valhallaPrice = getValhallaPrice();
        if (_valhallaPrice <= valhallaPriceOne) {
            uint256 _valhallaSupply = getValhallaCirculatingSupply();
            uint256 _bondMaxSupply = _valhallaSupply.mul(maxDebtRatioPercent).div(BASIS_DIVISOR);
            uint256 _bondSupply = IERC20(vbond).totalSupply();
            if (_bondMaxSupply > _bondSupply) {
                uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint256 _maxBurnableValhalla = _maxMintableBond.mul(_valhallaPrice).div(1e18);
                _burnableValhallaLeft = Math.min(epochSupplyContractionLeft, _maxBurnableValhalla);
            }
        }
    }

    function getRedeemableBonds() public view returns (uint256 _redeemableBonds) {
        uint256 _valhallaPrice = getValhallaPrice();
        if (_valhallaPrice > valhallaPriceCeiling) {
            uint256 _totalValhalla = IERC20(valhalla).balanceOf(address(this));
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalValhalla.mul(1e18).div(_rate);
            }
        }
    }

    function getBondDiscountRate() public view returns (uint256 _rate) {
        uint256 _valhallaPrice = getValhallaPrice();
        if (_valhallaPrice <= valhallaPriceOne) {
            if (discountPercent == 0) {
                // no discount
                _rate = valhallaPriceOne;
            } else {
                uint256 _bondAmount = valhallaPriceOne.mul(1e18).div(_valhallaPrice); // to burn 1 VAL
                uint256 _discountAmount = _bondAmount.sub(valhallaPriceOne).mul(discountPercent).div(BASIS_DIVISOR);
                _rate = valhallaPriceOne.add(_discountAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getBondPremiumRate() public view returns (uint256 _rate) {
        uint256 _valhallaPrice = getValhallaPrice();
        if (_valhallaPrice > valhallaPriceCeiling) {
            uint256 _valhallaPricePremiumThreshold = valhallaPriceOne.mul(premiumThreshold).div(100);
            if (_valhallaPrice >= _valhallaPricePremiumThreshold) {
                //Price > 1.10
                uint256 _premiumAmount = _valhallaPrice.sub(valhallaPriceOne).mul(premiumPercent).div(BASIS_DIVISOR);
                _rate = valhallaPriceOne.add(_premiumAmount);
                if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
                    _rate = maxPremiumRate;
                }
            } else {
                // no premium bonus
                _rate = valhallaPriceOne;
            }
        }
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _valhalla,
        address _vbond,
        address _vshare,
        address _valhallaOracle,
        address _masonry,
        uint256 _startTime
    ) public notInitialized onlyOperator {
        valhalla = _valhalla;
        vbond = _vbond;
        vshare = _vshare;
        valhallaOracle = _valhallaOracle;
        masonry = _masonry;
        startTime = _startTime;

        valhallaPriceOne = 10 ** 18;
        // valhallaPriceCeiling = 1000300000000000000; // 1.003 as its stable pool
        valhallaPriceCeiling = valhallaPriceOne.mul(101).div(100); // even if its stable we aim to get 1.01

        // Dynamic max expansion percent
        supplyTiers = [0 ether, 600000 ether, 750000 ether, 1000000 ether, 1200000 ether, 1500000 ether, 2000000 ether];
        maxExpansionTiers = [110, 90, 80, 70, 60, 50, 20]; // 0.11%, 0.09%, 0.08%, 0.07%, 0.06%, 0.05%, 0.02%

        maxSupplyExpansionPercent = 150; // 0.15%

        bondDepletionFloorPercent = 100000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 35000; // At least 35% of expansion reserved for masonry
        maxSupplyContractionPercent = 10000; // Upto 10.0% supply for contraction (to burn VAL and mint vbond)
        maxDebtRatioPercent = 35000; // Upto 35% supply of vbond to purchase

        premiumThreshold = 1100;
        premiumPercent = 70000;

        // First 12 epochs with 1.5% expansion
        bootstrapEpochs = 12;
        bootstrapSupplyExpansionPercent = 150; // 0.15%

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(valhalla).balanceOf(address(this));

        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        transferOperator(_operator);
    }

    function renounceOperator() external onlyOperator {
        _renounceOperator();
    }

    function setMasonry(address _masonry) external onlyOperator {
        masonry = _masonry;
    }

    function setValhallaOracle(address _valhallaOracle) external onlyOperator {
        valhallaOracle = _valhallaOracle;
    }

    function setValhallaPriceCeiling(uint256 _valhallaPriceCeiling) external onlyOperator {
        require(_valhallaPriceCeiling >= valhallaPriceOne && _valhallaPriceCeiling <= valhallaPriceOne.mul(120).div(100), "out of range"); // [$1.0, $1.2]
        valhallaPriceCeiling = _valhallaPriceCeiling;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent) external onlyOperator {
        require(_maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 10000, "_maxSupplyExpansionPercent: out of range"); // [0.01%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }
    // =================== ALTER THE NUMBERS IN LOGIC!!!! =================== //
    function setSupplyTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 7, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1]);
        }
        if (_index < 6) {
            require(_value < supplyTiers[_index + 1]);
        }
        supplyTiers[_index] = _value;
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 7, "Index has to be lower than count of tiers");
        require(_value >= 10 && _value <= 10000, "_value: out of range"); // [0.01%, 10%]
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent) external onlyOperator {
        require(_bondDepletionFloorPercent >= 500 && _bondDepletionFloorPercent <= BASIS_DIVISOR, "out of range"); // [0.5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxSupplyContractionPercent(uint256 _maxSupplyContractionPercent) external onlyOperator {
        require(_maxSupplyContractionPercent >= 100 && _maxSupplyContractionPercent <= 15000, "out of range"); // [0.1%, 15%]
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent) external onlyOperator {
        require(_maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= BASIS_DIVISOR, "out of range"); // [1%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 120, "_bootstrapEpochs: out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 10000, "_bootstrapSupplyExpansionPercent: out of range"); // [0.1%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }
    //======================================================================
    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent,
        address _teamFund,
        uint256 _teamFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 15000, "out of range");
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 3500, "out of range");
        require(_teamFund != address(0), "zero");
        require(_teamFundSharedPercent <= 5500, "out of range");

        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;
        teamFund = _teamFund;
        teamFundSharedPercent = _teamFundSharedPercent;
    }

    function setMaxDiscountRate(uint256 _maxDiscountRate) external onlyOperator {
        require(_maxDiscountRate <= 200000, "_maxDiscountRate is over 200%");
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
        require(_maxPremiumRate <= 200000, "_maxPremiumRate is over 200%");
        maxPremiumRate = _maxPremiumRate;
    }

    function setDiscountPercent(uint256 _discountPercent) external onlyOperator {
        require(_discountPercent <= 200000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumThreshold(uint256 _premiumThreshold) external onlyOperator {
        require(_premiumThreshold >= valhallaPriceCeiling, "_premiumThreshold exceeds valhallaPriceCeiling");
        require(_premiumThreshold <= 1500, "_premiumThreshold is higher than 1.5");
        premiumThreshold = _premiumThreshold;
    }

    function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 200000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt) external onlyOperator {
        require(_mintingFactorForPayingDebt >= BASIS_DIVISOR && _mintingFactorForPayingDebt <= 200000, "_mintingFactorForPayingDebt: out of range"); // [100%, 200%]
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateValhallaPrice() internal {
        try IOracle(valhallaOracle).update() {} catch {}
    }

    function getValhallaCirculatingSupply() public view returns (uint256) {
        IERC20 valhallaErc20 = IERC20(valhalla);
        uint256 totalSupply = valhallaErc20.totalSupply();
        uint256 balanceExcluded = 0;
        for (uint8 entryId = 0; entryId < excludedFromTotalSupply.length; ++entryId) {
            balanceExcluded = balanceExcluded.add(valhallaErc20.balanceOf(excludedFromTotalSupply[entryId]));
        }
        return totalSupply.sub(balanceExcluded);
    }

    function buyBonds(uint256 _valhallaAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_valhallaAmount > 0, "Treasury: cannot purchase bonds with zero amount");

        uint256 valhallaPrice = getValhallaPrice();
        require(valhallaPrice == targetPrice, "Treasury: VAL price moved");
        require(
        valhallaPrice <valhallaPriceOne, // price < $1
            "Treasury:valhallaPrice not eligible for bond purchase"
        );

        require(_valhallaAmount <= epochSupplyContractionLeft, "Treasury: not enough bond left to purchase");

        uint256 _rate = getBondDiscountRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _bondAmount = _valhallaAmount.mul(_rate).div(1e18);
        uint256 valhallaSupply = getValhallaCirculatingSupply();
        uint256 newBondSupply = IERC20(vbond).totalSupply().add(_bondAmount);
        require(newBondSupply <= valhallaSupply.mul(maxDebtRatioPercent).div(BASIS_DIVISOR), "over max debt ratio");

        IBasisAsset(valhalla).burnFrom(msg.sender, _valhallaAmount);
        IBasisAsset(vbond).mint(msg.sender, _bondAmount);

        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_valhallaAmount);
        _updateValhallaPrice();

        emit BoughtBonds(msg.sender, _valhallaAmount, _bondAmount);
    }

    function redeemBonds(uint256 _bondAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_bondAmount > 0, "Treasury: cannot redeem bonds with zero amount");

        uint256 valhallaPrice = getValhallaPrice();
        require(valhallaPrice == targetPrice, "Treasury: VAL price moved");
        require(
            valhallaPrice > valhallaPriceCeiling, // price > $1.01
            "Treasury: valhallaPrice not eligible for bond purchase"
        );

        uint256 _rate = getBondPremiumRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _valhallaAmount = _bondAmount.mul(_rate).div(1e18);
        require(IERC20(valhalla).balanceOf(address(this)) >= _valhallaAmount, "Treasury: treasury has no more budget");

        seigniorageSaved = seigniorageSaved.sub(Math.min(seigniorageSaved, _valhallaAmount));

        IBasisAsset(vbond).burnFrom(msg.sender, _bondAmount);
        IERC20(valhalla).safeTransfer(msg.sender, _valhallaAmount);

        _updateValhallaPrice();

        emit RedeemedBonds(msg.sender, _valhallaAmount, _bondAmount);
    }

    function _sendToMasonry(uint256 _amount) internal {
        IBasisAsset(valhalla).mint(address(this), _amount);

        uint256 _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(BASIS_DIVISOR);
            IERC20(valhalla).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);
        }

        uint256 _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(BASIS_DIVISOR);
            IERC20(valhalla).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(block.timestamp, _devFundSharedAmount);
        }

        uint256 _teamFundSharedAmount = 0;
        if (teamFundSharedPercent > 0) {
            _teamFundSharedAmount = _amount.mul(teamFundSharedPercent).div(BASIS_DIVISOR);
            IERC20(valhalla).transfer(teamFund, _teamFundSharedAmount);
            emit TeamFundFunded(block.timestamp, _teamFundSharedAmount);
        }

        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount).sub(_teamFundSharedAmount);

        IERC20(valhalla).safeApprove(masonry, 0);
        IERC20(valhalla).safeApprove(masonry, _amount);
        IMasonry(masonry).allocateSeigniorage(_amount);
        emit MasonryFunded(block.timestamp, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint256 _valhallaSupply) internal returns (uint256) {
        for (uint8 tierId = 6; tierId >= 0; --tierId) {
            if (_valhallaSupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updateValhallaPrice();
        previousEpochValhallaPrice = getValhallaPrice();
        uint256 valhallaSupply = getValhallaCirculatingSupply().sub(seigniorageSaved);
        if (epoch < bootstrapEpochs) {
            // 14 first epochs with 6% expansion
            _sendToMasonry(valhallaSupply.mul(bootstrapSupplyExpansionPercent).div(BASIS_DIVISOR));
        } else {
            if (previousEpochValhallaPrice > valhallaPriceCeiling) {
                // Expansion ($VAL Price > 1 $FTM): there is some seigniorage to be allocated
                uint256 bondSupply = IERC20(vbond).totalSupply();
                uint256 _percentage = previousEpochValhallaPrice.sub(valhallaPriceOne);
                uint256 _savedForBond;
                uint256 _savedForMasonry;
                uint256 _mse = _calculateMaxSupplyExpansionPercent(valhallaSupply).mul(1e13);
                if (_percentage > _mse) {
                    _percentage = _mse;
                }
                if (seigniorageSaved >= bondSupply.mul(bondDepletionFloorPercent).div(BASIS_DIVISOR)) {
                    // saved enough to pay debt, mint as usual rate
                    _savedForMasonry = valhallaSupply.mul(_percentage).div(1e18);
                } else {
                    // have not saved enough to pay debt, mint more
                    uint256 _seigniorage = valhallaSupply.mul(_percentage).div(1e18);
                    _savedForMasonry = _seigniorage.mul(seigniorageExpansionFloorPercent).div(BASIS_DIVISOR);
                    _savedForBond = _seigniorage.sub(_savedForMasonry);
                    if (mintingFactorForPayingDebt > 0) {
                        _savedForBond = _savedForBond.mul(mintingFactorForPayingDebt).div(BASIS_DIVISOR);
                    }
                }
                if (_savedForMasonry > 0) {
                    _sendToMasonry(_savedForMasonry);
                }
                if (_savedForBond > 0) {
                    seigniorageSaved = seigniorageSaved.add(_savedForBond);
                    IBasisAsset(valhalla).mint(address(this), _savedForBond);
                    emit TreasuryFunded(block.timestamp, _savedForBond);
                }
            }
        }
    }
    //===================================================================================================================================

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(valhalla), "valhalla");
        require(address(_token) != address(vbond), "bond");
        require(address(_token) != address(vshare), "share");
        _token.safeTransfer(_to, _amount);
    }

    function masonrySetOperator(address _operator) external onlyOperator {
        IMasonry(masonry).setOperator(_operator);
    }

    function masonrySetLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        IMasonry(masonry).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
    }

    function masonryAllocateSeigniorage(uint256 amount) external onlyOperator {
        IMasonry(masonry).allocateSeigniorage(amount);
    }

    function masonryGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IMasonry(masonry).governanceRecoverUnsupported(_token, _amount, _to);
    }
}