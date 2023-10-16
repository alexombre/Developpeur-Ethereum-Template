// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    
    struct Proposal {
        string description;
        uint voteCount;
    }
    
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    WorkflowStatus public workflowStatus;
    uint public winningProposalId;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);
    
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, "Only registered voters can call this function");
        _;
    }

    function registerVoter(address _voterAddress) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Cannot register voters at this stage");
        voters[_voterAddress].isRegistered = true;
        emit VoterRegistered(_voterAddress);
    }

    function startProposalRegistration() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Cannot start proposal registration at this stage");
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }
    
    function endProposalRegistration() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Cannot end proposal registration at this stage");
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }
    
    function submitProposal(string calldata _description) external onlyRegisteredVoter {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Cannot submit proposals at this stage");
        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposals.length - 1);
    }
    
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "Cannot start voting session at this stage");
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function vote(uint _proposalId) external onlyRegisteredVoter {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "Cannot vote at this stage");
        require(!voters[msg.sender].hasVoted, "You have already voted");

        proposals[_proposalId].voteCount += 1;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        
        emit Voted(msg.sender, _proposalId);
    }

    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "Cannot end voting session at this stage");
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    function tallyVotes() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Cannot tally votes at this stage");
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
    
    function getWinner() external view returns(string memory) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "Votes are not tallied yet");
        return proposals[winningProposalId].description;
    }
}
