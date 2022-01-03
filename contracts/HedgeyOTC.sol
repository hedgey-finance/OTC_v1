
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


contract FuturesNFT is ERC721, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable public weth;
    string private baseURI;

    struct Future {
        uint amount;
        address asset;
        uint expiry;
    }

    mapping(uint => Future) public futures; //maps the NFT ID to the Future

    constructor(address payable _weth, string memory uri) ERC721("Futures", "F") {
        weth = _weth;
        baseURI = uri;
    }

    //function strictly for weth handling
    receive() external payable {}

    //new minting function for the owner

    function createFuture(address holder, uint _amount, address _asset, uint _expiry) onlyOwner external returns (uint) {
        _tokenIds.increment();
        uint newItemId = _tokenIds.current();
        _safeMint(holder, newItemId);
        //creates a future struct mapped to the minted NFT
        require(_amount > 0 && _asset != address(0) && _expiry > block.timestamp);
        futures[newItemId] = Future(_amount, _asset, _expiry);
        emit FutureCreated(newItemId, _amount, _asset, _expiry);
        return newItemId;
    }

    

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateBaseURI(string memory uri) onlyOwner external {
        baseURI = uri;
    }
    

    function redeemFuture(uint _id) external {
        (uint _amount, address _asset, uint _expiry) = _redeemFuture(payable(msg.sender), _id);
        emit FutureRedeemed(_id, _amount, _asset, _expiry);
    }


    function _redeemFuture(address payable holder, uint _id) internal returns (uint _amount, address _asset, uint _expiry) {
        require(ownerOf(_id) == holder);
        Future storage future = futures[_id];
        require(future.expiry < block.timestamp && future.amount > 0);
        //delivers the vested tokens to the vester
        withdraw(future.asset, holder, future.amount);
        _amount = future.amount;
        _asset = future.asset;
        _expiry = future.expiry;
        delete futures[_id];
        _burn(_id);
    }

    function withdraw(address _token, address payable to, uint _total) internal {
        if (_token == weth) {
            IWETH(weth).withdraw(_total);
            to.transfer(_total);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), to, _total);
        }
    }

    event FutureCreated(uint _i, uint _amount, address _asset, uint _expiry);
    event FutureRedeemed(uint _i, uint _amount, address _asset, uint _expiry);
}
