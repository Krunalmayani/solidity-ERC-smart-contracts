// SPDX-License-Identifier: MIT;

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract crowdFunding is Ownable {

    mapping(address => uint256) public contributors;

    uint256 public target;
    uint256 public deadLine;
    uint256 public noOfContributors;
    uint256 public raisedAmount;
    uint256 public minimumContribution;

    constructor(uint256 _target,uint256 _deadLine){
        target = _target;
        deadLine = block.timestamp + _deadLine;
        minimumContribution = 100 wei;
    }

    function sendEther() public payable {
        require(block.timestamp < deadLine ,"your deadline has passed");
        require(msg.value>= minimumContribution,"Minimum Contribution is not met");
        
        if(contributors[msg.sender] ==0){
            noOfContributors += 1;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    function refund() public  {
        require(block.timestamp > deadLine && raisedAmount < target,"You are not eligible" );
        require( contributors[msg.sender] > 0);
        address payable User = payable(msg.sender);
        User.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    struct Request {
        uint256 amount;
        bool completed;
        uint256 noOfVoters;
        string description;
        address payable recipient;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Request) public requests;
    uint256 public numRequests;

    function createNewRequests(
        string memory _description,
        address payable _recipient,
        uint256 _amount
    )
    public onlyOwner{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient =_recipient;
        newRequest.completed = false;
        newRequest.amount = _amount; 
        newRequest.noOfVoters = 0;
    }

    function makePayment(uint256 _requestNo) public onlyOwner {
        require(raisedAmount >= target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false,"The Request has been completed");
        require(thisRequest.noOfVoters == noOfContributors/2,"Majority does not support");
        thisRequest.recipient.transfer(thisRequest.amount);
        thisRequest.completed = true;
    }

    function voteRequests(uint256 _requestNo) public {
        require(contributors[msg.sender] > 0 ,"You must be contributor");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] ==false ,"You have already voted");
        thisRequest.voters[msg.sender] =true;
        thisRequest.noOfVoters++;
    }
}

/*
    0) deploy contract with target amout and deadline time 
    1) create new requests
        e.g;
            desc = charity
            reci = charity address
            amount = 1000 wei
    2) send ether from other 3 or 4 address more then 100
    3) refund donate ehter if deadline finish and raised amount is less then targate amount
    4) vode request
        add requests any number 
    5) Make Payment
        raised amount is more then target amount and 50% vote then owner can make payment s
*/