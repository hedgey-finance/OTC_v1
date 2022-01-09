
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


interface Decimals {
    function decimals() external view returns (uint256);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IFuturesNFT {
    function createFuture(address vester, uint _amount, address _asset, uint _expiry) external returns (uint);
    function transferOwnership(address newOwner) external;
    function updateBaseURI(string memory uri) external;
}


contract HedgeyOTC is ReentrancyGuard {
    using SafeERC20 for IERC20;


    uint public fee;
    address payable public collector;
    address payable public weth;
    uint public d = 0;
    address public futureContract;

    constructor(uint _fee, address payable _collector, address payable _weth, address _fc) {
        fee = _fee;
        collector = _collector;
        weth = _weth;
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
        if (_token == weth) {
            
            if (!Address.isContract(to)) {
                to.transfer(_amt);
            } else {
                // we want to deliver WETH from ETH here for better handling at contract
                IWETH(weth).deposit{value: _amt}();
                assert(IWETH(weth).transfer(to, _amt));
            }
        } else {
            SafeERC20.safeTransferFrom(IERC20(_token), from, to, _amt);         
        }
    }

    function transferPymtWithFee(address _token, address from, address payable to, uint _total) internal {
        uint _fee = (_total * fee) / (1e4);
        uint _amt = _total - _fee;
        if (_token == weth) {
            require(msg.value == _total, "transfer issue: wrong amount of eth sent");
        }
        transferPymt(_token, from, to, _amt); //transfer the stub to recipient
        if (_fee > 0) transferPymt(_token, from, collector, _fee); //transfer fee to fee collector
    }

    function withdraw(address _token, address payable to, uint _total) internal {
        if (_token == weth) {
            IWETH(weth).withdraw(_total);
            to.transfer(_total);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), to, _total);
        }
    }

    //admin function to update the fee amount
    function changeFee(uint _fee) external {
        require(msg.sender == collector);
        fee = _fee;
    }

    function changeCollector(address payable _collector) external {
        require(msg.sender == collector);
        collector = _collector;
    }

    function changeFutureContract(address _fc) external {
        require(msg.sender == collector);
        futureContract = _fc;
    }

    function transferFC_Owner(address newOwner) external {
        require(msg.sender == collector);
        IFuturesNFT(futureContract).transferOwnership(newOwner);
    }

    function setNewURI(string memory uri) external {
        require(msg.sender == collector);
        IFuturesNFT(futureContract).updateBaseURI(uri);
    }

    //functions create deal
    //buy tokens
    //close / cancel

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
        //pull in tokens
        if (_token == weth) {
            require(msg.value == amount, "wrong msg.value");
            IWETH(weth).deposit{value: amount}();
            assert(IWETH(weth).transfer(address(this), amount));
        } else {
            require(IERC20(_token).balanceOf(msg.sender) >= amount);
            SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, address(this), amount);
        }
        
        deals[d++] = Deal(payable(msg.sender), _token, _paymentCurrency, amount, min, _price, _maturity, _unlockDate, true, payable(_buyer));
        emit NewDeal(d - 1, msg.sender, _token, _paymentCurrency, amount, min, _price, _maturity, _unlockDate, true, _buyer);
    }

    

    function close(uint _d) external nonReentrant {
        Deal storage deal = deals[_d];
        require(msg.sender == deal.seller, "not the seller");
        require(deal.remainingAmount > 0, "all tokens sold");
        require(deal.open, "already closed");
        //send back the remainder to the seller
        if (deal.token == weth) {
            IWETH(weth).withdraw(deal.remainingAmount);
            payable(msg.sender).transfer(deal.remainingAmount);
        } else {
            SafeERC20.safeTransfer(IERC20(deal.token), msg.sender, deal.remainingAmount);
        }
        deal.remainingAmount = 0;
        deal.open = false;
        emit DealClosed(_d);
    }

    function buy(uint _d, uint amount) payable external nonReentrant {
        Deal storage deal = deals[_d];
        require(msg.sender != deal.seller);
        require(deal.open && deal.maturity >= block.timestamp, "deal closed");
        require(msg.sender == deal.buyer || deal.buyer == address(0x0), "not allowed to buy");
        require((amount >= deal.minimumPurchase || amount == deal.remainingAmount) && deal.remainingAmount >= amount, "not enough");
        uint decimals = Decimals(deal.token).decimals();
        uint purchase = (amount * deal.price) / (10 ** decimals);
        uint balanceCheck = (deal.paymentCurrency == weth) ? msg.value : IERC20(deal.paymentCurrency).balanceOf(msg.sender);
        require(balanceCheck >= purchase);
        transferPymtWithFee(deal.paymentCurrency, msg.sender, deal.seller, purchase);
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
        require(_unlockDate > block.timestamp);
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
