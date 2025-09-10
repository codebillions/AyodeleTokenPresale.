// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMintableToken {
    function mint(address to, uint256 amount) external;
}

contract AyodeleTokenPresale is ReentrancyGuard, Ownable {
    IMintableToken public token;
    address payable public wallet;
    uint256 public rate;
    uint256 public weiRaised;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public openingTime;
    uint256 public closingTime;
    bool public finalized;

    mapping(address => uint256) public contributions;
    mapping(address => bool) public whitelist;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Finalized(bool success);
    event RefundClaimed(address indexed beneficiary, uint256 amount);
    event Whitelisted(address indexed account, bool whitelisted);

    modifier onlyWhileOpen() {
        require(block.timestamp >= openingTime && block.timestamp <= closingTime && !finalized, "Presale: not open");
        _;
    }

    constructor(
        address tokenAddress_,
        address payable wallet_,
        uint256 rate_,
        uint256 softCapWei_,
        uint256 hardCapWei_,
        uint256 openingTime_,
        uint256 closingTime_
    ) {
        require(tokenAddress_ != address(0), "token is zero");
        require(wallet_ != address(0), "wallet is zero");
        require(rate_ > 0, "rate 0");
        require(openingTime_ < closingTime_, "opening >= closing");
        require(softCapWei_ <= hardCapWei_, "soft > hard");

        token = IMintableToken(tokenAddress_);
        wallet = wallet_;
        rate = rate_;
        softCap = softCapWei_;
        hardCap = hardCapWei_;
        openingTime = openingTime_;
        closingTime = closingTime_;
    }

    receive() external payable {
        buyTokens(msg.sender);
    }

    function addToWhitelist(address account) external onlyOwner {
        whitelist[account] = true;
        emit Whitelisted(account, true);
    }

    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
        emit Whitelisted(account, false);
    }

    function buyTokens(address beneficiary) public payable nonReentrant onlyWhileOpen {
        require(beneficiary != address(0), "beneficiary zero");
        require(msg.value > 0, "zero contribution");
        require(whitelist[beneficiary], "not whitelisted");
        require(weiRaised + msg.value <= hardCap, "hard cap reached");

        uint256 weiAmount = msg.value;
        uint256 tokens = _getTokenAmount(weiAmount);

        weiRaised += weiAmount;
        contributions[beneficiary] += weiAmount;

        token.mint(beneficiary, tokens);

        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        if (weiRaised >= hardCap) {
            closingTime = block.timestamp;
        }
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return (weiAmount * rate) / 1 ether;
    }

    function finalize() external onlyOwner {
        require(!finalized, "already finalized");
        require(block.timestamp > closingTime, "not closed yet");
        finalized = true;

        if (weiRaised >= softCap) {
            (bool sent, ) = wallet.call{value: address(this).balance}("");
            require(sent, "failed to send funds");
            emit Finalized(true);
        } else {
            emit Finalized(false);
        }
    }

    function claimRefund() external nonReentrant {
        require(finalized, "not finalized");
        require(weiRaised < softCap, "soft cap met");
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "no contribution");

        contributions[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "refund failed");
        emit RefundClaimed(msg.sender, amount);
    }

    function hasClosed() external view returns (bool) {
        return block.timestamp > closingTime || weiRaised >= hardCap;
    }
}
