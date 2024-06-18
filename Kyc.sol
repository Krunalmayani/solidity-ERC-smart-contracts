// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract KYC {

    struct Bank {
        string name;
        address etherAddress;
        uint rating;
        uint KYC_count;
        string regNumber;
    }

    Bank[] allBanks;
    uint noOfBank =0;
    address admin;

    constructor(){
        admin = msg.sender;
        addBank("HDFC",0xdD870fA1b7C4700F2BD7f44238821C26f7392148,"001");
        addBank("IDFC",0x583031D1113aD414F02576BD6afaBfb302140225,"002");
        addBank("DBS",0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB,"003");
        addBank("KOTAK",0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,"004");
    }
    modifier onlyAdmin(){
        require(admin == msg.sender,"only Admin access..");
        _;
    }

    function addBank(
        string memory bankName, 
        address bankAddress, 
        string memory bankRegistrationNumber
        ) public onlyAdmin returns(bool) {
        allBanks.push(Bank({
            name:bankName,
            etherAddress:bankAddress,
            rating:0,
            KYC_count:0,
            regNumber:bankRegistrationNumber}));
        return true;
    }

    function getBankDetails(address _bankAddress) public view returns(
        string memory name,
        address etherAddress,
        uint rating,
        uint KYC_count,
        string memory regNumber){
        for(uint i=0;i< allBanks.length;i++){
            if(allBanks[i].etherAddress == _bankAddress){
                name = allBanks[i].name;
                etherAddress = allBanks[i].etherAddress;
                rating = allBanks[i].rating;
                KYC_count = allBanks[i].KYC_count;
                regNumber = allBanks[i].regNumber;
            }
        }
   }

}





/*
admin-0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

HDFC-0xdD870fA1b7C4700F2BD7f44238821C26f7392148

IDFC-0x583031D1113aD414F02576BD6afaBfb302140225

DBS-0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB

KOTAK-0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C

*/