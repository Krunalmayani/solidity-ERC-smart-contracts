// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract autocompounding is KeeperCompatibleInterface {
   
    uint public immutable interval;
    uint public lastTimeStamp;
    string public name = "Auto Compounding Example";
    string public symbol = "ACE";
    uint8 public decimals = 5;
    uint256 _totalSupply = 10000 wei;
    address private admin;
    uint256 _currentBalance = _totalSupply;
    mapping(address => uint256) balances;
    uint256 public ratio = 30;


    constructor(uint updateInterval) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp + 2 minutes;

        balances[msg.sender] = _totalSupply;
        admin = msg.sender;
        balances[0x769e2B2C27aa3Cf8989c59d9aFea54459188945d] =  1000;
    }

    function checkUpkeep(bytes calldata ) external view override returns (bool upkeepNeeded, bytes memory ) {
        // upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }


    function performUpkeep(bytes calldata ) external override {
        if(block.timestamp >= lastTimeStamp &&  balances[msg.sender] > 0 ){
            balances[0x769e2B2C27aa3Cf8989c59d9aFea54459188945d]   += ratio *   balances[0x769e2B2C27aa3Cf8989c59d9aFea54459188945d]/100 ;
            balances[msg.sender] -= balances[0x769e2B2C27aa3Cf8989c59d9aFea54459188945d];
            lastTimeStamp = block.timestamp + 2 minutes;
        }
        // if ((block.timestamp - lastTimeStamp) > interval) {
            // lastTimeStamp = block.timestamp;
        // }
    }

    function showCurrentBalance(address _address) public view returns(uint256){ 
        return balances[_address];
    }
}
/*

pragma solidity ^0.8.7;


import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract Counter is KeeperCompatibleInterface {
 
    uint public counter;

 
    uint public immutable interval;
    uint public lastTimeStamp;

    constructor(uint updateInterval) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;

      counter = 0;
    }

    function checkUpkeep(bytes calldata ) external view override returns (bool upkeepNeeded, bytes memory ) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata ) external override {
      
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;
        }
       
    }
}

*/