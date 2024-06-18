// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract VotingSystem {
    struct VoterDetalis {
        string name;
    }

    mapping(uint256 => VoterDetalis) public voterDetails;
    mapping(address => bool) public alreadyVote;
    uint256 public noOfVoter;

    struct CandidateDetails {
        uint id;
        string name;
        uint voteCount;
    }
    uint256 public noOFCandidate;
    mapping (uint256=>CandidateDetails) public candidateDetails;

    address voteingOfficer;
    bool isVotingStart;

    constructor(address _address){
        voteingOfficer = _address;
        addNewVoter("last 1");
        addNewVoter("last 2");
        addNewVoter("last 3");
        addNewVoter("last 4");
        addNewVoter("last 5");
        addNewVoter("last 6");
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    modifier onlyOfficer(){
        require(msg.sender == voteingOfficer,"You are not voting officer");
        _;
    }

    function addNewVoter( string memory _name) public onlyOfficer {
        VoterDetalis storage newVoter = voterDetails[noOfVoter];
        noOfVoter++;
        newVoter.name = _name;
    }

    function addCandidate(string memory _name) public onlyOfficer {
        CandidateDetails storage newCandidate = candidateDetails[noOFCandidate];
        newCandidate.id = noOFCandidate;
        newCandidate.name = _name;
        noOFCandidate++;
    }

    function startVoting() public onlyOfficer returns(bool) {
        isVotingStart = true;
        return true;
    }
    
    function stopVoting() public onlyOfficer returns(bool){
        isVotingStart = false;
        return true;
    }


    function vote(uint256 _candidateId) public {
        require(isVotingStart == true ,"voting booth is not open"); 
        require(voteingOfficer != msg.sender,"You are not voter");
        require(alreadyVote[msg.sender] == false,"Already voted");
        require(_candidateId >= 0 && _candidateId <= noOFCandidate-1,"candidate not found");

        alreadyVote[msg.sender]= true;
        candidateDetails[_candidateId].voteCount++;
        emit votedEvent(_candidateId);
    }

    event votedEvent(uint indexed id);

}

/*
0xdD870fA1b7C4700F2BD7f44238821C26f7392148 last 1
0x583031D1113aD414F02576BD6afaBfb302140225 last 2
0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB last 3
0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C last 4
0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c last 5
0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC last 6
*/