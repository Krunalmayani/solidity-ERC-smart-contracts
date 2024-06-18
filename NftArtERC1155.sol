// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftERC1155 is ERC1155, Ownable {   
    string private baseURI;

    // constructor(uint256 _id, uint256 _amount)
    constructor() ERC1155("ipfs://QmcNx1LjytAoRsLXQaqkmz1VgoSdu1nVVcRxhwtupCccuo/{id}.json") {
        _mint(msg.sender,1, 12, "");
        
    }

    function setURI(string memory newuri) public onlyOwner { 
        _setURI(newuri);
    }

    function mint(uint256 id, uint256 amount) public onlyOwner {
        _mint(msg.sender, id, amount, '');
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts) public onlyOwner {
        _mintBatch(msg.sender, ids, amounts, '');
    }
}

