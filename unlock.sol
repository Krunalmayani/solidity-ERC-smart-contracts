// SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    // function transfer(address recipient, uint256 amount) external returns (bool);

    // function allowance(address owner, address spender) external view returns (uint256);
    // function approve(address spender, uint256 amount) external returns (bool);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Basic is IERC20 {

    string public name = "Solidity by Example";
    string public symbol = "MKETHNew";
    uint8 public decimals = 5;
    address admin;
    uint256 unlockDate  =  1648615389000;

    

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ =10000 wei;
   constructor() {
    balances[0x04249371f1becfa3284e59F4D529F51772a25c1a] =totalSupply_ * 70/100;
    balances[0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7] = totalSupply_* 30/100 ;

    admin = msg.sender;
    }

    function unlockWallet() public  returns (string memory) {

        if(block.timestamp >= unlockDate){
            unlockDate =block.timestamp + 5 minutes;
            balances[0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7] -=  balances[0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7]* 10/100 ;
           return "successfully transfer";
        }else {
            return "Time is not complete";
        }
      
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }



    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }


    modifier onlyOwner{
        require(msg.sender == admin,"Only admin can run this function");
        _;
    }

     function mint(uint256 _qty) external {
        balances[msg.sender]+=_qty;
        totalSupply_ +=_qty;
        emit Transfer(address(0), msg.sender, _qty);
    }
    
  

   
} 