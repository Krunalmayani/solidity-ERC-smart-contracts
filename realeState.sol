// SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract realeState {

    struct RealeState {
        string description;
        uint256 amount;
        address payable recipient;
        bool isSell;
   }

    address public  owner;
    mapping(uint256 => RealeState) public addRealeState;
    uint256 public numRequests;
    

    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor(){
        owner= msg.sender;
    }

    modifier onlyOwner(){
        require(owner == msg.sender,"You are not owner");
        _;
    }

    function createRealState(
        string memory _description,
        address payable _recipient,
        uint256 _amount

     ) public  {
         require(_amount > 0);
        RealeState storage newRealeState = addRealeState[numRequests];
        numRequests++;
        newRealeState.amount = _amount;
        newRealeState.description = _description;
        newRealeState.recipient = _recipient;
    }

    function makePayment(uint256 _requestNo) public payable returns(bool) {
        RealeState storage thisRealeState= addRealeState[_requestNo];
        require(msg.value >= thisRealeState.amount ,"Amount is less then realestate amount");
        require(thisRealeState.isSell == false);
        uint256 _brokerageAmount = msg.value/100;
        thisRealeState.recipient.transfer(msg.value - _brokerageAmount);
        thisRealeState.recipient =payable(msg.sender); 
        thisRealeState.isSell =true; 
        _brokerage(_brokerageAmount);

        emit Transfer(msg.sender, thisRealeState.recipient, msg.value - _brokerageAmount);
        return true;
    }

    function _brokerage(uint256 _amount) private {
        require(_amount>0);
        address payable ownerAddress = payable(owner);
        ownerAddress.transfer(_amount);
        emit Transfer(msg.sender, ownerAddress, _amount);
    }

    function updateRealestateInfo(uint256 _requestNo,uint256 _newAmount,bool _isSell) public {
        RealeState storage thisRealeState= addRealeState[_requestNo];
        require(msg.sender == thisRealeState.recipient,"You are not real estate owner" );
        thisRealeState.amount = _newAmount;
        thisRealeState.isSell = _isSell;
    }
    
}