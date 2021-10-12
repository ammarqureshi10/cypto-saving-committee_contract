//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.0;

interface CommitteeSystemInterface {
    function createNewCommittee(uint256 _minimumDeposit, uint256 _totalParticipants) external returns(bool);
    function joinCommittee(uint256 _committeeNo) external payable returns(bool);
    function selectWinner(uint256 _committeeNo) external returns(address);
}

contract CommitteeSystem is CommitteeSystemInterface{
    // state
    
    //committee Detail
    struct CommitteeInfo {
        uint256 minimumDeposit;
        uint256 MaxParticipants;
        uint256 expectedTotal; 
        uint256 currentTotal; 
        address[] participants;
    }
    mapping(uint256 => CommitteeInfo) private committeeCreator; // committeeInfo by committeeNo
    
    uint256 public committeeNo;
    
    event Withdrawal(address to,uint256 amount);
    event NewCommitteeCreated(uint256 committeeNo, uint256 minimumDeposit, uint256 totalParticipants);
    event Participated(address by);
    
    function createNewCommittee(uint256 _minimumDeposit, uint256 _MaxParticipants) external override returns(bool){
        require(_minimumDeposit > 0, "minimumDeposit should be greater than 0");
        committeeNo ++;
        
        // set minimumDeposit against committeeNo
        committeeCreator[committeeNo].minimumDeposit = _minimumDeposit;
        // committee max participants
        committeeCreator[committeeNo].MaxParticipants = _MaxParticipants;
        // each participant get expectedTotal amount
        uint256 sumAmount = _minimumDeposit * _MaxParticipants; //100*5=500
        committeeCreator[committeeNo].expectedTotal = sumAmount;
        
        emit NewCommitteeCreated(committeeNo, _minimumDeposit, _MaxParticipants);
        return true;
    }
    
    function joinCommittee(uint256 _committeeNo) external override payable returns(bool){
        // committee should exist
        require(committeeCreator[_committeeNo].minimumDeposit > 0, "committee not found");
        
        // should not housefull
        require(committeeCreator[_committeeNo].participants.length + 1 <= committeeCreator[_committeeNo].MaxParticipants, "full");
        
        // user should send exact minimumDeposit
        require(msg.value == committeeCreator[_committeeNo].minimumDeposit, "depositValue should be correct");
        
        // add user to participants list
        committeeCreator[_committeeNo].participants.push(msg.sender);
        
        committeeCreator[_committeeNo].currentTotal += msg.value;
        
        emit Participated(msg.sender);
        return true;
    }
    
    // committee winner
    function selectWinner(uint256 _committeeNo) external override returns(address){
        //committee should exist
        require(committeeCreator[_committeeNo].minimumDeposit > 0, "committee not found");
        
        // all participants should deposit before selection
        require(committeeCreator[_committeeNo].currentTotal == committeeCreator[_committeeNo].expectedTotal, "all participants should deposit first");
        
        // contract-balance check
        require(committeeCreator[_committeeNo].expectedTotal <= address(this).balance, "selectWinner: contract not have sufficient amount");
        
        address[] storage arr = committeeCreator[_committeeNo].participants;
        
        //choosing winner
        address committeeWinner = arr[randomNumber(committeeCreator[_committeeNo].MaxParticipants)];
        
        // give sum-amount to committeeWinner
        withdraw(committeeWinner, committeeCreator[_committeeNo].expectedTotal);
        
        return committeeWinner;
    }
    
    function committeeDetail(uint256 _committeeNo) external view returns(uint256 minimumDeposit,
        
        uint256 MaxParticipants,
        uint256 expectedTotal,
        uint256 currentTotal,
        address[] memory participants){
            
        //committee should exist
        require(committeeCreator[_committeeNo].minimumDeposit > 0, "committee not found");
        
        return (committeeCreator[_committeeNo].minimumDeposit,committeeCreator[_committeeNo].MaxParticipants, committeeCreator[_committeeNo].expectedTotal,committeeCreator[_committeeNo].currentTotal ,committeeCreator[_committeeNo].participants);
    }
    
    function contractBalance() external view returns(uint256){
        return address(this).balance;
    }
    
    // internal functions
    function randomNumber(uint256 _totalParticipants) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(now,msg.sender))) % _totalParticipants;
    }
    function withdraw(address  _account, uint256 _amount) internal {
        payable(_account).transfer(_amount);
        emit Withdrawal(_account, _amount);
    }
}
