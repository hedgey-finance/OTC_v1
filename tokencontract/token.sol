pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract Token is ERC20 {
    constructor(uint initialSupply) ERC20("Token", "TK") {
        _mint(msg.sender, initialSupply);
    }

    function mintToOwner (uint amount) public {
        _mint(msg.sender, amount);
    }
}
