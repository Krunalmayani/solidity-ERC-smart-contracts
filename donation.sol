// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Charitable is Ownable {
    address payable admin;
    address payable highestDonor;
    address payable  charityAddress;
    uint256 totalDonationAmount;
    uint256 highestDonation;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address payable _charityAddress){
        admin = payable(msg.sender);
        charityAddress =_charityAddress;
    }

    function changeCharityAddress(address payable _address) public onlyOwner returns(bool){
        charityAddress = _address;
        return true;
    }
    function showCharityAddress() public view returns(address) {
        return charityAddress;
    }

    // modifier validateDonationAmount() {
    //     require(msg.value > 0.01 ether && (msg.value <= 2 ether),
    //         "Donation amount has to be from 0.01 ehter to 2 ehter of the total transferred amount");
    //     _;
    // }
    // function donationETH() public validateDonationAmount() payable returns (bool) {
    //     // uint256 actualDeposit = donationAmount;
    //     (bool success,) = charityAddress.call{value: msg.value}("");
    //     require(success, "Failed to send money");
    //     emit Transfer(msg.sender, charityAddress,msg.value);
    //     return true;
    // }

    function donationETH(uint256 donationAmountInPercentage) external payable returns(bool) {
        // uint256 actualDeposit = donationAmount;
        (bool success,) = charityAddress.call{value: msg.value * donationAmountInPercentage / 100}("");
        require(success, "Failed to send money");
        emit Transfer(msg.sender, charityAddress,msg.value * donationAmountInPercentage / 100);
        return true;
    }


    function getBalance() public view returns(uint256){
        return charityAddress.balance;
    }
    
    function sendMoney(address to, uint256 donationAmountInPercentage) payable public {
        address payable receiver = payable(to);
        receiver.transfer(msg.value - msg.value * donationAmountInPercentage / 100);
        charityAddress.transfer(msg.value * donationAmountInPercentage / 100);

    }
}

/*
    charity address: 0x04249371f1becfa3284e59F4D529F51772a25c1a acc 2  02.2989 ETH
    deploy address : 0x769e2B2C27aa3Cf8989c59d9aFea54459188945d acc 123
    trafer from : 0x5b14Cc67C79a4350E75C284e34CC5f3Bc6554c93 acc 1  15.6676 ETH
    trasfer to  : 0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7 acc 3   2.6833 ETH


*/