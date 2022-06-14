// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    
    /// The function cannot be called at the current state.
    error InvalidState();   
    
    // La personne n'est pas dans la whiteList
    error NotInWhiteList();

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    
    struct Proposal {
        string description;
        uint voteCount;
        address voterAddress;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    // Status courant
    WorkflowStatus public state;

    // Proposition gagnante
    uint winningProposalId;

    // Comptabilisation effectuée
    bool winnerChecked;

    // Whitelist des voters
    mapping(address=> bool) whitelist;
    
    // Mapping des voters
    mapping(address=> uint) voters;

    // Tableau des voters
    Voter[] public votersArray;
    
    // Tableau des adresses des voters, pour pouvoir reinitialiser le vote et ne pas toucher à la structure Voter
    // Serait plus pertinent d'ajouter un champ address au Voter, mais comme on ne peut pas modifier cette structure.
    address[] votersAddressArray;

    // Tableau des propositions
    Proposal[] public proposalsArray;

    // Event Ajout White liste
    event VoterRegistered(address voterAddress); 

    // Event pour indiquer le changement de Status
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    // Event pour indiquer l'enregistrement de la proposition
    event ProposalRegistered(uint proposalId);

    // Event pour indiquer le vote
    event Voted (address voter, uint proposalId);

    constructor() {
        // le owner est automatiquement en whiteList
        authorize(msg.sender);
    }
       
    // Vérification si on est sur le bon Status
    modifier inState(WorkflowStatus _state) {
        if (state != _state)
            revert InvalidState();
        _;
    }
    
    // Verification que le sender est bien en whiteList
    modifier inWhitelist() {
        if (whitelist[msg.sender] == false )
            revert NotInWhiteList();
        _;
    }

    /*
    *  Ajout d'un électeur à la WhiteList
    *   - seulement si on est en RegisteringVoters
    *   - uniquement pour le owner
    */
    function authorize(address _address) public onlyOwner inState(WorkflowStatus.RegisteringVoters) {

        // require(state == WorkflowStatus.RegisteringVoters, "Not in RegisteringVoters");
        require (whitelist[_address] == false , "already registred");

        // Ajout à la whiteList
        whitelist[_address] = true;

        // Ajout au tableau des voters et du mapping voters
        votersArray.push(Voter(true, false, 0));
        votersAddressArray.push(_address);
        voters[_address] = votersArray.length - 1;

        // Event pour indiquer l'ajout à la whitelist
        emit VoterRegistered(_address);
    }

    /*
    *  Ajout d'une proposition
    *   - seulement si on est en ProposalsRegistrationStarted
    *   - uniquement pour les personnes en whiteList
    *   - on n'accepte pas les propositions vides
    */
    function registerProposal(string calldata _description) external inState(WorkflowStatus.ProposalsRegistrationStarted) inWhitelist() {

        // La description ne peut pas être vide
        require(bytes(_description).length > 0 , "the proposal is empty");
        
        // Enregistrement de la proposition
        proposalsArray.push(Proposal(_description, 0, msg.sender));

        // Event pour indiquer l'enregistrement de la proposition
        emit ProposalRegistered(proposalsArray.length -1);
    }

    /*
    *  Récupération des proposals
    */    
    function getProposals() public view returns (Proposal[] memory){
        return proposalsArray;
    }

    /*
    *  Récupération des voters
    */    
    function getVoters() public view returns (Voter[] memory){
        return votersArray;
    }

    /*
    *  Vote pour une proposition
    *   - seulement si on est en VotingSessionStarted
    *   - uniquement pour les personnes en whiteList
    *   - uniquement si la proposition existe
    *   - uniquement si la personne n'a pas déjà voté
    *   - uniquement si la personne est enregistrée
    */
    function votingForProposal(uint _proposalId) external inState(WorkflowStatus.VotingSessionStarted) inWhitelist() {
        require(_proposalId < proposalsArray.length, "proposal not exist");
        require(votersArray[voters[msg.sender]].isRegistered == true, "not registered");
        require(votersArray[voters[msg.sender]].hasVoted == false, "already voted");

        // On enregistre le vote 
        votersArray[voters[msg.sender]].votedProposalId = _proposalId;
        votersArray[voters[msg.sender]].hasVoted = true;

        // On comptabilise le vote
        proposalsArray[_proposalId].voteCount += 1;

        // Event pour indiquer le vote
        emit Voted (msg.sender, _proposalId);
    }

    /*
    *  Comptabilisation des votes
    *   - seulement si on est en VotingSessionEnded
    *   - uniquement pour le owner
    */
    function checkWinner() external inState(WorkflowStatus.VotingSessionEnded) onlyOwner {

        uint winnerProposalId = 0;
        uint maxVote = 0;

        // On parcourt la liste des votes pour trouver le gagnant
        for(uint i = 0 ; i < proposalsArray.length ; i++) {
            if ( proposalsArray[i].voteCount > maxVote ) {
                maxVote = proposalsArray[i].voteCount;
                winnerProposalId = i;
            }
        }

        // Proposition gagnante
        winningProposalId = winnerProposalId;

        // La comptabilisation a bien été effectuée
        winnerChecked = true;
    }

    /*
    *  Comptabilisation du nombre total de votes
    */
    function nbVotes() internal view returns(uint) {

        uint totalVote = 0;

        // On parcourt la liste des votes pour compter chaque vote
        for(uint i = 0 ; i < proposalsArray.length ; i++) {
            totalVote += proposalsArray[i].voteCount;
        }
    
        return totalVote;
    }

    /*
    *  retourne la proposition gagnante
    */
    function getWinner() external view inState(WorkflowStatus.VotesTallied) returns(Proposal memory) {
        return proposalsArray[winningProposalId];
    }

    /**
    *  Passage au Status Suivant du Workflow
    */
    function nextStatus() external onlyOwner {

        require(uint(state) < 5, "already in last WorkflowStatus");
    
        // Si on est sur VotingSessionEnded, on vérifie que la comptabilisation des votes a bien été effectuée
        if ( state == WorkflowStatus.VotingSessionEnded ) {
            require( winnerChecked == true, "winner not checked");
        }
        
        // Si on est sur ProposalsRegistrationStarted, on vérifie qu'il y a au moins une proposition
        if ( state == WorkflowStatus.ProposalsRegistrationStarted ) {
            require( proposalsArray.length > 0, "no propositions, nothing to vote");
        }

        // On bloque si on n'a aucun vote.
        if ( state == WorkflowStatus.VotingSessionStarted ) {
            require( nbVotes() > 0, "no votes");
        }

        WorkflowStatus previousStatus = state;

        state = WorkflowStatus(uint(state) + 1);

        // Event pour indiquer le changement de statut
        emit WorkflowStatusChange(previousStatus, state);
    }

    /**
    *  Réinitialisation du contrat, on vide la whiteList, les voters et les propositions
    */
    function resetVoting() external inState(WorkflowStatus.VotesTallied) onlyOwner {

        // On parcourt la liste des adresses des voters
        for(uint i = 0 ; i < votersAddressArray.length ; i++) {
            
            // suppression du mapping pour la whiteList
            delete whitelist[votersAddressArray[i]];

            // suppression du mapping pour les voters
            delete voters[votersAddressArray[i]];
        }
  
        // Suppression des proposals
        delete proposalsArray;

        // Suppression des voters
        delete votersArray;

        // Suppression des adresses des voters
        delete votersAddressArray;

        // Init proposition gagnante
        winningProposalId = 0;

        // Init comptabilisation non effectuée
        winnerChecked = false;
        
        // Retour au statut pour enregistrer les voters
        state = WorkflowStatus.RegisteringVoters;

        // le owner est automatiquement en whiteList
        authorize(msg.sender);
    }

}
