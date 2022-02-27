// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract HedgeyHoglets is ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private baseURI;
    uint8 private ownerSet = 0;

    struct Future {
        uint amount;
        address asset;
        uint expiry;
    }

    mapping(uint => Future) public futures; //maps the NFT ID to the Future

    constructor(string memory uri) ERC721("HedgeyHoglets", "HDHG") {
        baseURI = uri;
    }

    //function strictly for weth handling
    receive() external payable {}


    function transferOwnership(address newOwner) public override onlyOwner {
        require(ownerSet == 0, "owner already set");
        ownerSet = 1;
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    //new minting function for the owner

    function createFuture(address holder, uint _amount, address _asset, uint _expiry) onlyOwner external returns (uint) {
        _tokenIds.increment();
        uint newItemId = _tokenIds.current();
        _safeMint(holder, newItemId);
        //creates a future struct mapped to the minted NFT
        require(_amount > 0 && _asset != address(0) && _expiry > block.timestamp);
        futures[newItemId] = Future(_amount, _asset, _expiry);
        emit FutureCreated(newItemId, holder, _amount, _asset, _expiry);
        return newItemId;
    }

    

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateBaseURI(string memory uri) onlyOwner external {
        baseURI = uri;
    }
    

    function redeemFuture(uint _id) external returns (bool) {
        _redeemFuture(payable(msg.sender), _id);
        return true;
    }


    function _redeemFuture(address payable holder, uint _id) internal {
        require(ownerOf(_id) == holder, "you are not the owner");
        Future storage future = futures[_id];
        require(future.expiry < block.timestamp && future.amount > 0,"not unlock time yet");
        //delivers the vested tokens to the vester
        emit FutureRedeemed(_id, holder, future.amount, future.asset, future.expiry);
        SafeERC20.safeTransfer(IERC20(future.asset), holder, future.amount);
        delete futures[_id];
        _burn(_id);
    }


    event FutureCreated(uint _i, address _holder, uint _amount, address _asset, uint _expiry);
    event FutureRedeemed(uint _i, address _holder, uint _amount, address _asset, uint _expiry);
}