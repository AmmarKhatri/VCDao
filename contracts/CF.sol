// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrowdFund {
    // event Launch(
    //     uint id,
    //     address indexed creator,
    //     uint goal,
    //     uint32 startAt,
    //     uint32 endAt
    // );
    // event Cancel(uint id);
    // event Pledge(uint indexed id, address indexed caller, uint amount);
    // event Unpledge(uint indexed id, address indexed caller, uint amount);
    // event Claim(uint id);
    // event Refund(uint id, address indexed caller, uint amount);

    // struct Campaign {
    //     address creator;
    //     uint goal;
    //     uint pledged;
    //     uint32 startAt;
    //     uint32 endAt;
    //     bool claimed;
    // }

    //  uint public count;
    // // Mapping from id to Campaign
    // mapping(uint => Campaign) public campaigns;
    // // Mapping from campaign id => pledger => amount pledged
    // mapping(uint => mapping(address => uint)) public pledgedAmount;
    // constructor(address _token) {
    //     token = IERC20(_token);
    // }
    address public owner;
    uint public goal;
    uint256 public startAt;
    uint256 public endAt;
    bool public launched;
    uint256 public raisedAmnt;
    uint public AssignedTokensToAddress;
    IERC20 public immutable token;

    event Launch(
         address creator,
         uint goal,
         uint32 startAt,
         uint32 endAt
    );
    event Pledge(address indexed caller, uint amount);
    event Unpledge(address indexed caller, uint amount);
    event ClaimFunds(address indexed caller, uint amount);
    event ClaimTokens(address indexed caller, uint amount);
    mapping(address => uint) public addressToAmntFunded;
    constructor(address _token){
        launched = false;
        token = IERC20(_token);
    }
    function launch(uint _goal, uint32 _startAt, uint32 _endAt, uint32 duration) external {
        require(launched == false, "Contract is already launched");
        require(startAt >= block.timestamp, "start at < now");
        require(endAt >= _startAt, "end at < start at");
        require(endAt <= block.timestamp + 24*3600*duration, "end at > max duration");
        emit Launch(owner, _goal, _startAt, _endAt);
    }

    function pledge(uint _amount) payable external {
        require(block.timestamp >= startAt, "not started");
        require(block.timestamp <= endAt, "ended");
        raisedAmnt += _amount;
        addressToAmntFunded[msg.sender] += _amount;
        (bool callSuccess, ) = payable(address(this)).call{value: _amount}("");
        require(callSuccess, "Not enough funds");
        emit Pledge(msg.sender, _amount);
    }

    function unpledge(uint _amount) payable external {
        require(block.timestamp >= startAt, "not started");
        require(block.timestamp <= endAt, "ended");
        require(_amount <= addressToAmntFunded[msg.sender], "Extracting more than pledged");
        raisedAmnt -= _amount;
        addressToAmntFunded[msg.sender] -= _amount;
        (bool callSuccess, ) = payable(msg.sender).call{value: _amount}("");
        require(callSuccess, "Could not withdraw pledged funds");
        emit Unpledge(msg.sender, _amount);
    }

    function claimtokens() external {
        require(block.timestamp > endAt, "not ended");
        require(raisedAmnt < goal, "pledged >= goal");
        require(addressToAmntFunded[msg.sender] > 0, "No amount pledged");
        uint bal = addressToAmntFunded[msg.sender] /raisedAmnt * AssignedTokensToAddress;
        addressToAmntFunded[msg.sender] = 0;
        //this function requires that the contract address contains
        // the required amount
        token.transfer(msg.sender, bal);
        emit ClaimTokens(msg.sender, bal);
    }
    //only owner is able to claim the tokens
    function claimFunds() external {
        require(msg.sender == owner, "Only owner can call this contract");
        require(raisedAmnt >= goal, "Goal was still not reached");
        uint bal = address(this).balance;
        (bool callSuccess, ) = payable(owner).call{value: bal}("");
        require(callSuccess, "No coins to withdraw");
        emit ClaimFunds(msg.sender, bal);
    }
}