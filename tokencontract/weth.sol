pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Weth is ERC20 {
    mapping(address => uint256) private _balances;
    constructor() ERC20("WETH", "WETH") {}

    receive() external payable {}

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
    }

    function withDraw(uint wad) public {
        require(_balances[msg.sender] >= wad);
        _balances[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
    }
}
