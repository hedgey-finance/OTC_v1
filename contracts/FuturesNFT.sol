// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


/**
* @notice Interface used to handle Wrapped Ether when withdrawing from the contract to an NFT owner
*/
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


/**
* @title An NFT representation of ownership of time locked tokens
* @notice The time locked tokens are redeemable by the owner of the NFT
* @notice The NFT is basic ERC721 with an ownable usage to ensure only a single owner call mint new NFTs
* @notice it uses the Enumerable extension to allow for easy lookup to pull balances of one account for multiple NFTs
*/
contract HedgeyHoglets is ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable public weth;
    string private baseURI;
    /// @dev ownerSet is a variable set to 0 ensuring that the owner of this contract can only be changed once
    /// @dev after the contract is deployed by a wallet, the ownership is transferred to the OTC contract
    /// @dev the OTC contract cannot change ownership using this variable check
    uint8 private ownerSet = 0;


    /// @dev the Future is the storage in a struct of the tokens that are time locked
    /// @dev the Future contains the information about the amount of tokens, the underlying token address (asset), and the date in which they are unlocked
    struct Future {
        uint amount;
        address asset;
        uint expiry;
    }

    /// @dev this maping maps the same uint from Counters that is used to mint an NFT to the Future struct
    mapping(uint => Future) public futures;

    constructor(address payable _weth, string memory uri) ERC721("HedgeyHoglets", "HDHG") {
        weth = _weth;
        baseURI = uri;
    }

    receive() external payable {}


    /// @dev The function for transferring ownership one time only to the OTC contract
    /// @dev the OTC contract cannot transfer ownership again for security
    /// @notice the new OTC owner address 
    function transferOwnership(address newOwner) public override onlyOwner {
        require(ownerSet == 0, "HNEC01: Owner already set");
        ownerSet = 1;
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    /**
     * @notice The external function creates a Future position
     * @dev A Future position is the combination of an NFT and a Future struct with the same index uint storing both information separately but with the same index
     * @dev the OTC contract as the owner is only allowed to call this function to ensure integrity of the minting process
     * @param holder is the buyer and minter of the NFT
     * @param _amount is the amount with full decimals of the tokens being locked into the future
     * @param _asset is the address of the tokens that are being delivered to this contract to be held and locked
     * @param _expiry is the date in UTC in which the tokens can become redeemed - evaluated based on the block.timestamp
    */
    function createFuture(address holder, uint _amount, address _asset, uint _expiry) onlyOwner external returns (uint) {
        _tokenIds.increment();
        uint newItemId = _tokenIds.current();
        /// @dev record the NFT miting with the newItemID coming from Counters library
        _safeMint(holder, newItemId);
        /// @dev require that the amount is not 0, address is not the 0 address, and that the expiration date is actually beyond today
        require(_amount > 0 && _asset != address(0) && _expiry > block.timestamp, "HEC02: NFT Minting Error");
        /// @dev using the same newItemID we generate a Future struct recording the token address (asset), the amount of tokens (amount), and time it can be unlocked (_expiry)
        futures[newItemId] = Future(_amount, _asset, _expiry);
        emit FutureCreated(newItemId, holder, _amount, _asset, _expiry);
        return newItemId;
    }

    
    /// @dev internal function used by the standard ER721 function tokenURI to retrieve the baseURI privately held to visualize and get the metadata
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @dev onlyOwner function to set the base URI after the contract has been launched
    /// @dev there is no actual on-chain functions that require this URI to be anything beyond a blank string ("")
    /// @dev there are no vulnerabilities should this be changed as it is for astetic purposes only 
    function updateBaseURI(string memory uri) onlyOwner external {
        baseURI = uri;
    }
    
    /// @notice this is the external function that actually redeems an NFT futures position
    /// @dev this function calls the _redeemFuture(...) internal function which handles the requirements and checks
    function redeemFuture(uint _id) external returns (bool) {
        _redeemFuture(payable(msg.sender), _id);
        return true;
    }

    /** 
     * @notice This internal function, called by redeemFuture to physically burn the NFT and distribute the locked tokens to its owner
     * @dev this function does five things: 1) Checks to ensure only the owner of the NFT can call this function
     * @dev 2) it checks that the tokens can actually be unlocked based on the time from the expiration
     * @dev 3) it burns the NFT - removing it from storage entirely
     * @dev 4) it also deletes the futures struct from storage so that nothing can be redeemed from that storage index again
     * @dev 5) it withdraws the tokens that have been locked - delivering them to the current owner of the NFT
    */ 
    function _redeemFuture(address payable holder, uint _id) internal {
        require(ownerOf(_id) == holder, "HNEC03: Only the NFT Owner");
        Future storage future = futures[_id];
        require(future.expiry < block.timestamp && future.amount > 0,"HNEC04: Tokens are still locked");
        //delivers the vested tokens to the vester
        emit FutureRedeemed(_id, holder, future.amount, future.asset, future.expiry);
        _withdraw(future.asset, holder, future.amount);
        delete futures[_id];
        _burn(_id);
    }

    /// @dev internal function used to withdraw locked tokens and send them to an address
    /// @dev this contract stores WETH instead of ETH to represent ETH
    /// @dev which means that if we are delivering ETH back out, we will convert the WETH first and then transfer the ETH to the recipiient
    /// @dev if the tokens are not WETH, then we simply safely transfer them back out to the address
    function _withdraw(address _token, address payable to, uint _amt) internal {
        if (_token == weth) {
            IWETH(weth).withdraw(_amt);
            to.transfer(_amt);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), to, _amt);
        }
    }


    ///@notice Events when a new NFT (future) is created and one with a Future is redeemed (burned)
    event FutureCreated(uint _i, address _holder, uint _amount, address _asset, uint _expiry);
    event FutureRedeemed(uint _i, address _holder, uint _amount, address _asset, uint _expiry);
}
