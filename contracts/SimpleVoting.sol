pragma solidity >=0.4.22 <0.6.0;

contract SimpleVoting {

    struct Proposal {
        string description;
        uint voteCount;
    }
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    address public administrator;
    
    WorkflowStatus public workflowStatus;
    
    mapping(address => Voter) public voters;
    
    Proposal[] public proposals;
    
    uint private winningProposalId;
    
    modifier onlyAdministrator() {
        require(msg.sender == administrator, "the caller of this function must be the administrator");
        _;
    }
    
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, "the caller of this function must be a registered voter");
        _;
    }
    
    modifier onlyDuringVotersRegistration() {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "this function can be called only before proposals registration has started");
        _;
    }

    modifier onlyDuringProposalsRegistration() {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "this function can be called only during proposals registration");
        _;
    }
    
    modifier onlyDuringVotingSession() {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "this function can be called only during voting session has started");
        _;
    }
    
    modifier onlyAfterVotingSession() {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "this function can be called only during voting session has ended");
        _;
    }
    
    modifier onlyBeforeVotesTallied() {
        require(workflowStatus == WorkflowStatus.VotesTallied, "this function can be called only during votes has taillied");
        _;
    }
    
    modifier onlyAfterVotesTallied() {
        require(workflowStatus == WorkflowStatus.VotesTallied, "this function can be called only during votes has taillied");
        _;
    }
    
    event VoterRegisteredEvent (address voterAddress);
    event ProposalsRegistrationStartedEvent ();
    event ProposalsRegistrationEndedEvent ();
    event ProposalRegisteredEvent(uint proposalId);
    event VotingSessionStartedEvent ();
    event VotingSessionEndedEvent ();
    event VotedEvent (address voter, uint proposalId);
    event VotesTalliedEvent ();
    event WorkflowStatusChangeEvent (
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    
    constructor() public {
        administrator = msg.sender;
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }
    
    function registerVoter(address _voterAddress)
        public onlyAdministrator onlyDuringVotersRegistration {
            require(!voters[_voterAddress].isRegistered, "the voter is already registered");
            voters[_voterAddress].isRegistered = true;
            voters[_voterAddress].hasVoted = false;
            voters[_voterAddress].votedProposalId = 0;
            emit VoterRegisteredEvent(_voterAddress);
    }

    function startProposalsRegistration()
        public onlyAdministrator onlyDuringVotersRegistration {
            workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
            emit ProposalsRegistrationStartedEvent();
            emit WorkflowStatusChangeEvent(
            WorkflowStatus.RegisteringVoters, workflowStatus);
    }

    function endProposalsRegistration()
        public onlyAdministrator onlyDuringProposalsRegistration {
            workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
            emit ProposalsRegistrationEndedEvent();
            emit WorkflowStatusChangeEvent(
            WorkflowStatus.ProposalsRegistrationStarted, workflowStatus);
    }
    
    function registerProposal(string memory proposalDescription)
        public onlyRegisteredVoter onlyDuringProposalsRegistration { //#A
            proposals.push(Proposal({ //#B
            description: proposalDescription,
            voteCount: 0
        }));
        emit ProposalRegisteredEvent(proposals.length - 1);
    }
    
    function vote(uint proposalId)
        onlyRegisteredVoter onlyDuringVotingSession public {//#A
            require(!voters[msg.sender].hasVoted, "the caller has already voted");//#B
            voters[msg.sender].hasVoted = true;//#C
            voters[msg.sender].votedProposalId = proposalId;//#C
            proposals[proposalId].voteCount += 1;//#D
        emit VotedEvent(msg.sender, proposalId);
    }
    
    function tallyVotes()
        onlyAdministrator onlyAfterVotingSession onlyBeforeVotesTallied public { //#A
            uint winningVoteCount = 0;
            uint winningProposalIndex = 0;
            for (uint i = 0; i < proposals.length; i++) { //#B
                if (proposals[i].voteCount > winningVoteCount) {
                    winningVoteCount = proposals[i].voteCount;
                    winningProposalIndex = i;//#C
                }
            }
            winningProposalId = winningProposalIndex;//#D
            workflowStatus = WorkflowStatus.VotesTallied;//#E
            emit VotesTalliedEvent();
            emit WorkflowStatusChangeEvent(
            WorkflowStatus.VotingSessionEnded, workflowStatus); //#F
    }
    
    function getProposalsNumber() public view
        returns (uint) {
            return proposals.length;
    }

    function getProposalDescription(uint index) public view
        returns (string memory) {
            return proposals[index].description;
    }
    
    function getWinningProposalId() onlyAfterVotesTallied
        public view
            returns (uint) {
        return winningProposalId;
    }

    function getWinningProposalDescription() onlyAfterVotesTallied
        public view
            returns (string memory) {
        return proposals[winningProposalId].description;
    }

    function getWinningProposaVoteCounts() onlyAfterVotesTallied
        public view
            returns (uint) {
        return proposals[winningProposalId].voteCount;
    }
    
    function isRegisteredVoter(address _voterAddress) public view
            returns (bool) {
        return voters[_voterAddress].isRegistered;
    }
    
    function isAdministrator(address _address) public view
            returns (bool){
        return _address == administrator;
    }
    
    function getWorkflowStatus() public view
            returns (WorkflowStatus) {
        return workflowStatus;
    }

}
