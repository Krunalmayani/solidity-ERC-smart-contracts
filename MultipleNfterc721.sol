/**
multiple nft mint 

e.g. =
    change nft url 
    ipfs link
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NftArtERC721 is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    
    string public baseURI;
    uint256 public MINT_PRICE = 0.05 ether;
    uint public MAX_SUPPLY = 1000;


    constructor(string memory _cid) ERC721("NftArt", "NFT") {

        // baseURI = "ipfs://QmcNx1LjytAoRsLXQaqkmz1VgoSdu1nVVcRxhwtupCccuo/";
        baseURI = string(abi.encodePacked("ipfs://",_cid,"/"));
        _tokenIdCounter.increment();
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner() {
        require(address(this).balance > 0, "Balance is zero");
        payable(owner()).transfer(address(this).balance);
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI,_tokenIdCounter.current().toString(),".json")): "";
    }

    function checkURL() public view returns(string memory){
        return baseURI;
    }



    function safeMint(address to,uint256 noOfNft,bool isMax) public onlyOwner {

        // require(totalSupply() < MAX_SUPPLY, "Can't mint anymore tokens.");
        // require(msg.value >= MINT_PRICE, "Not enough ether sent.");
        if(isMax){
             for(uint256 i = 1; i<= noOfNft ; i++){
                uint256 tokenId = _tokenIdCounter.current();
                _mint(to, tokenId);
                _tokenIdCounter.increment();
            }
        }else{
                uint256 tokenId = _tokenIdCounter.current();
                _mint(to, tokenId);
                _tokenIdCounter.increment();
        }
       
    }


    function updateBaseUrl(string memory _cid) external onlyOwner returns(bool){
       baseURI = string(abi.encodePacked("ipfs://",_cid,"/"));
        return true;
    }
}   

/**
    Note::

    owner: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        - deployed contract
        - can only call the `onlyOwner` modifier functions
    address 2: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        - mint 1 NFT
    address 3: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
        - address 2 will transfer NFT #1 to address 3 (recipient)

*/