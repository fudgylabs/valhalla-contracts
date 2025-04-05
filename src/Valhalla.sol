// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./lib/SafeMath8.sol";
import "./owner/Operator.sol";
import "./interfaces/IOracle.sol";

contract Valhalla is ERC20Burnable, Operator {
    using SafeMath8 for uint8;
    using SafeMath for uint256;

    uint256 public constant INITIAL_DAOFUND_DISTRIBUTION = 1000 ether; // 1000 VAL
    uint256 public constant GENESIS_DISTRIBUTION = 714000 ether; // 714k VAL for genesis pool

    bool public rewardsDistributed = false;

    // Address of the Oracle
    address public valhallaOracle;

    /**
     * @notice Constructs the VAL ERC-20 contract.
     */
    constructor() ERC20("VAL", "VAL") {
        // Mints 200 VAL to contract creator for initial pool setup

        _mint(msg.sender, 200 ether);
    }

    function _getValhallaPrice() internal view returns (uint256 _valhallaPrice) {
        try IOracle(valhallaOracle).consult(address(this), 1e18) returns (uint256 _price) {
            return uint256(_price);
        } catch {
            revert("Valhalla: failed to fetch VAL price from Oracle");
        }
    }

    function setValhallaOracle(address _valhallaOracle) public onlyOperator {
        require(_valhallaOracle != address(0), "oracle address cannot be 0 address");
        valhallaOracle = _valhallaOracle;
    }

    /**
     * @notice Operator mints VAL to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of VAL to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @notice distribute to reward pool (only once)
     */
    function distributeReward(
        address _daoFund,
        address _genesis
    ) external onlyOperator {
        require(_daoFund != address(0), "!_treasury");
        require(_genesis != address(0), "!_genesis");
        require(!rewardsDistributed, "only can distribute once");
        rewardsDistributed = true;
        _mint(_daoFund, INITIAL_DAOFUND_DISTRIBUTION);
        _mint(_genesis, GENESIS_DISTRIBUTION);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}