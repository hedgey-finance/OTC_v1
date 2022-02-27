// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface IFuturesNFT {
    function createFuture(address vester, uint _amount, address _asset, uint _expiry) external returns (uint);
}


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface Decimals {
    function decimals() external view returns (uint256);
}


contract HedgeyOTC is ReentrancyGuard {
    using SafeERC20 for IERC20;


    uint public d = 0;
    address public futureContract;

    constructor(address _fc) {
        futureContract = _fc;
    }

    struct Deal {
        address payable seller;
        address token;
        address paymentCurrency;
        uint remainingAmount;
        uint minimumPurchase;
        uint price;
        uint maturity;
        uint unlockDate;
        bool open;
        address payable buyer;
    }

    mapping (uint => Deal) public deals;


    receive() external payable {}

    function transferPymt(address _token, address from, address payable to, uint _amt) internal {
        SafeERC20.safeTransferFrom(IERC20(_token), from, to, _amt);         
    }


    function withdraw(address _token, address payable to, uint _total) internal {
        SafeERC20.safeTransfer(IERC20(_token), to, _total);
    }

    

    function create(
        address _token,
        address _paymentCurrency,
        uint amount,
        uint min,
        uint _price,
        uint _maturity,
        uint _unlockDate,
        address payable _buyer
    ) payable external {
        require(_maturity > block.timestamp);
        require(amount >= min, "min error");
        require((min * _price) / (10 ** Decimals(_paymentCurrency).decimals()) > 0, "minimum too small");
        uint currentBalance = IERC20(_token).balanceOf(address(this));
        //pull in tokens
        require(IERC20(_token).balanceOf(msg.sender) >= amount);
        SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, address(this), amount);
        uint postBalance = IERC20(_token).balanceOf(address(this));
        assert(postBalance - currentBalance == amount);
        deals[d++] = Deal(payable(msg.sender), _token, _paymentCurrency, amount, min, _price, _maturity, _unlockDate, true, payable(_buyer));
        emit NewDeal(d - 1, msg.sender, _token, _paymentCurrency, amount, min, _price, _maturity, _unlockDate, true, _buyer);
    }

    

    function close(uint _d) external nonReentrant {
        Deal storage deal = deals[_d];
        require(msg.sender == deal.seller, "not the seller");
        require(deal.remainingAmount > 0, "all tokens sold");
        require(deal.open, "already closed");
        //send back the remainder to the seller
        SafeERC20.safeTransfer(IERC20(deal.token), msg.sender, deal.remainingAmount);
        deal.remainingAmount = 0;
        deal.open = false;
        emit DealClosed(_d);
    }

    function buy(uint _d, uint amount) payable external nonReentrant {
        Deal storage deal = deals[_d];
        require(msg.sender != deal.seller, "youre the seller");
        require(deal.open && deal.maturity >= block.timestamp, "deal closed");
        require(msg.sender == deal.buyer || deal.buyer == address(0x0), "not allowed to buy");
        require((amount >= deal.minimumPurchase || amount == deal.remainingAmount) && deal.remainingAmount >= amount, "not enough");
        uint decimals = Decimals(deal.token).decimals();
        uint purchase = (amount * deal.price) / (10 ** decimals);
        uint balanceCheck = IERC20(deal.paymentCurrency).balanceOf(msg.sender);
        require(balanceCheck >= purchase, "not enough to purchase");
        transferPymt(deal.paymentCurrency, msg.sender, deal.seller, purchase);
        if (deal.unlockDate > block.timestamp) {
            //creates a futures contract
            lockTokens(payable(msg.sender), deal.token, amount, deal.unlockDate);
        } else {
            withdraw(deal.token, payable(msg.sender), amount);
        }
        
        deal.remainingAmount -= amount;
        if (deal.remainingAmount == 0) deal.open = false;
        emit TokensBought(_d, amount, deal.remainingAmount);
    }

    function lockTokens(address payable _owner, address _token, uint _amount, uint _unlockDate) internal {
        require(_unlockDate > block.timestamp, "no need to lock up");
        uint currentBalance = IERC20(_token).balanceOf(futureContract);
        //physically creates the future and mints an NFT
        IFuturesNFT(futureContract).createFuture(_owner, _amount, _token, _unlockDate);
        //now we have to physically send the tokens to the NFT contract as escrow
        SafeERC20.safeTransfer(IERC20(_token), futureContract, _amount);
        uint postBalance = IERC20(_token).balanceOf(futureContract);
        //check to make sure the entire balance of the funds have arrived in escrow at the NFT contract
        assert(postBalance - currentBalance == _amount);
        emit FutureCreated(_owner, _token, _unlockDate, _amount);

    }

    

    event NewDeal(uint _d, address _seller, address _token, address _paymentCurrency, uint _remainingAmount, uint _minimumPurchase, uint _price, uint _maturity, uint _unlockDate, bool open, address _buyer);
    event TokensBought(uint _d, uint _amount, uint _remainingAmount);
    event DealClosed(uint _d);
    event FutureCreated(address _owner, address _token, uint _unlockDate, uint _amount);
    
}