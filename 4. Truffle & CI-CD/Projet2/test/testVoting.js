const Voting = artifacts.require("./Voting.sol");

const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');

const { expect } = require('chai');

contract('Voting', accounts => {

    // Owner du contrat
    const owner = accounts[0];

    // Les différents voters
    const voter1 = accounts[1];
    const voter2 = accounts[2];
    const voter3 = accounts[3];
    const voter4 = accounts[4];
    const voter5 = accounts[5];

    let votingInstance;

    describe("1. Registration", function () {

        before(async function () {
            votingInstance = await Voting.new({from:owner});
        });

        it("Ajout Voter1 et vérification Event VoterRegistered", async () => {
            const receipt = await votingInstance.addVoter(voter1, { from: owner });
            expectEvent(receipt, "VoterRegistered" ,{voterAddress: voter1})
        });

        it("Ajout Voter2 et vérification Event VoterRegistered", async () => {
            const receipt = await votingInstance.addVoter(voter2, { from: owner });
            expectEvent(receipt, "VoterRegistered" ,{voterAddress: voter2})
        });

        it("Ajout Voter2 une seconde fois => require 'Already registered'", async () => {
            await expectRevert(votingInstance.addVoter(voter2, {from:owner}), 'Already registered');
        });

        it("Ajout Voter3 et vérification si isRegistered", async () => {
            const receipt = await votingInstance.addVoter(voter3, { from: owner });
            const voter = await votingInstance.getVoter(voter3, { from: voter3 });
            assert.isTrue(voter.isRegistered, "voter3 is registred");

            expect(voter.isRegistered).to.be.true;
        });

        it("Vérification si Voter3 isRegistered par le owner => Revert 'not a voter'", async () => {
            await expectRevert(votingInstance.getVoter(voter3, { from: owner }), "You're not a voter");
        });

        it("Passage à l'enregistrement des Proposals", async () => {
            const receipt = await votingInstance.startProposalsRegistering({ from: owner });
            expectEvent(receipt, "WorkflowStatusChange" ,{previousStatus: BN(0), newStatus: BN(1)});
        });

        it("Ajout Voter4 en dehors de 'RegisteringVoters' => Revert", async () => {
            await expectRevert(votingInstance.addVoter(voter4, { from: owner }), "Voters registration is not open yet");
        });

    });

    describe("2. Proposals", function () {

        before(async function () {
            votingInstance = await Voting.new({from:owner});
            await votingInstance.addVoter(voter1, { from: owner });
            await votingInstance.addVoter(voter2, { from: owner });
            await votingInstance.addVoter(voter3, { from: owner });
            await votingInstance.startProposalsRegistering({ from: owner });
        });


        describe("2.1 Proposals - Ajouts", function () {
            it("Ajout Proposition no 1 par voter1 et vérification Event ProposalRegistered", async () => {
                const receipt = await votingInstance.addProposal("Proposition no 1", { from: voter1 });
                expectEvent(receipt, "ProposalRegistered" ,{proposalId: BN(0)})
            });

            it("Ajout Proposition no 2 par voter4, non enregistré => Revert 'not a voter'", async () => {
                await expectRevert(votingInstance.addProposal("Proposition no 2", { from: voter4 }), "You're not a voter");
            });

            it("Ajout Proposition no 2 par voter2 et vérification Event ProposalRegistered", async () => {
                const receipt = await votingInstance.addProposal("Proposition no 2", { from: voter2 });
                expectEvent(receipt, "ProposalRegistered" ,{proposalId: BN(1)})
            });


            it("Ajout Proposition no 3 par voter1 et vérification Event ProposalRegistered", async () => {
                const receipt = await votingInstance.addProposal("Proposition no 3", { from: voter1 });
                expectEvent(receipt, "ProposalRegistered" ,{proposalId: BN(2)})
            });


            it("Ajout Proposition no 4 par voter3 et vérification Event ProposalRegistered", async () => {
                const receipt = await votingInstance.addProposal("Proposition no 4", { from: voter3 });
                expectEvent(receipt, "ProposalRegistered" ,{proposalId: BN(3)})
            });

            it("Ajout Proposition vide par voter2, non enregistré => Revert 'Vous ne pouvez pas ne rien proposer'", async () => {
                await expectRevert(votingInstance.addProposal("", { from: voter2 }), "Vous ne pouvez pas ne rien proposer");
            });

            it("Passage à 'ProposalsRegistrationEnded'", async () => {
                const receipt = await votingInstance.endProposalsRegistering({ from: owner });
                expectEvent(receipt, "WorkflowStatusChange" ,{previousStatus: BN(1), newStatus: BN(2)});
            });

            it("Impossible d'ajouter une proposition en dehors de 'ProposalsRegistrationStarted' => Revert 'Proposals are not allowed yet'", async () => {
                await expectRevert(votingInstance.addProposal("Proposition no 5", { from: voter3 }), "Proposals are not allowed yet");
            });

        });

        describe("2.2 Proposals - Getters", function () {
        
            it("Getter Proposition no 1 - description", async () => {
                const storedData = await votingInstance.getOneProposal(0, { from: voter2 });
                expect(storedData.description).to.equal("Proposition no 1");
            });
        
            it("Getter Proposition no 1 - vote", async () => {
                const storedData = await votingInstance.getOneProposal(0, { from: voter2 });
                expect(storedData.voteCount).to.be.bignumber.equal(new BN(0));    
            });

            it("Getter Proposition no 2 - description", async () => {
                const storedData = await votingInstance.getOneProposal(1, { from: voter2 });
                expect(storedData.description).to.equal("Proposition no 2");
            });
        
            it("Getter Proposition no 2 - vote", async () => {
                const storedData = await votingInstance.getOneProposal(1, { from: voter2 });
                expect(storedData.voteCount).to.be.bignumber.equal(new BN(0));    
            });

            it("Getter Proposition no 3", async () => {
                const storedData = await votingInstance.getOneProposal(2, { from: voter2 });
                expect(storedData.description).to.equal("Proposition no 3");
                expect(storedData.voteCount).to.be.bignumber.equal(new BN(0));    
            });

            it("Getter Proposition no 4", async () => {
                const storedData = await votingInstance.getOneProposal(3, { from: voter2 });
                expect(storedData.description).to.equal("Proposition no 4");
                expect(storedData.voteCount).to.be.bignumber.equal(new BN(0));    
            });

            it("Getter Proposition no 4 par non voter => Revert 'You're not a voter'", async () => {
                await expectRevert(votingInstance.getOneProposal(3, { from: voter4 }), "You're not a voter");
            });

        });
    });


    describe("3. Voting", function () {

        before(async function () {
            votingInstance = await Voting.new({from:owner});

            // Ajout des Voters
            await votingInstance.addVoter(voter1, { from: owner });
            await votingInstance.addVoter(voter2, { from: owner });
            await votingInstance.addVoter(voter3, { from: owner });
            await votingInstance.addVoter(voter4, { from: owner });
            
            // Changement de Step pour ProposalRegistrering
            await votingInstance.startProposalsRegistering({ from: owner });

            // Ajout des propoals
            await votingInstance.addProposal("Proposition no 1", { from: voter1 });
            await votingInstance.addProposal("Proposition no 2", { from: voter1 });
            await votingInstance.addProposal("Proposition no 3", { from: voter2 });
            await votingInstance.addProposal("Proposition no 4", { from: voter3 });

            // Changement de Step pour ProposalsRegistrationEnded
            await votingInstance.endProposalsRegistering({ from: owner });
        });

        describe("3.1 Enregistrement des votes", function () {
            it("Impossible d'ajouter une proposition en dehors de 'ProposalsRegistrationStarted' => Revert 'Proposals are not allowed yet'", async () => {
                await expectRevert(votingInstance.addProposal("Proposition no 2", { from: voter3 }), "Proposals are not allowed yet");
            });

            it("Impossible de voter en dehors de 'VotingSessionStarted' => Revert", async () => {
                await expectRevert(votingInstance.setVote(0, { from: voter1 }), "Voting session havent started yet");
            });

            it("Passage à 'startVotingSession'", async () => {
                const receipt = await votingInstance.startVotingSession({ from: owner });
                expectEvent(receipt, "WorkflowStatusChange" ,{previousStatus: BN(2), newStatus: BN(3)});
            });

            it("Vote pour la Proposition no 1 par voter1 et vérification Event Voted", async () => {
                const receipt = await votingInstance.setVote(0, { from: voter1 });
                expectEvent(receipt, "Voted" ,{voter: voter1, proposalId: BN(0)})
            });

            it("Vote pour la Proposition no 2 par voter2 et vérification Event Voted", async () => {
                const receipt = await votingInstance.setVote(1, { from: voter2 });
                expectEvent(receipt, "Voted" ,{voter: voter2, proposalId: BN(1)})
            });

            it("Vote pour la Proposition no 2 par voter3 et vérification Event Voted", async () => {
                const receipt = await votingInstance.setVote(1, { from: voter3 });
                expectEvent(receipt, "Voted" ,{voter: voter3, proposalId: BN(1)})
            });

            it("Vote pour la Proposition no 3 par voter3  => Revert 'You have already voted'", async () => {
                await expectRevert(votingInstance.setVote(2, { from: voter3 }), "You have already voted");
            });

            it("Vote pour la Proposition no 4 par voter4 et vérification Event Voted", async () => {
                const receipt = await votingInstance.setVote(3, { from: voter4 });
                expectEvent(receipt, "Voted" ,{voter: voter4, proposalId: BN(3)})
            });
        });

        describe("3.2 Cloture des votes", function () {

            it("Passage à 'VotingSessionEnded'", async () => {
                const receipt = await votingInstance.endVotingSession({ from: owner });
                expectEvent(receipt, "WorkflowStatusChange" ,{previousStatus: BN(3), newStatus: BN(4)});
            });

            it("Vote pour la Proposition no 4 par voter4 après le cloture des votes => Revert 'Voting session havent started yet'", async () => {
                await expectRevert(votingInstance.setVote(3, { from: voter4 }), "Voting session havent started yet");
            });
        });

      
        describe("3.3 Proposals - VoteCount", function () {
        
            it("Getter Proposition no 1 - voteCount = 1", async () => {
                const storedData = await votingInstance.getOneProposal(0, { from: voter2 });
                expect(storedData.voteCount).to.be.bignumber.equal(new BN(1));    
            });

            it("Getter Proposition no 2 - voteCount = 2", async () => {
                const storedData = await votingInstance.getOneProposal(1, { from: voter2 });
                expect(storedData.voteCount).to.be.bignumber.equal(new BN(2));    
            });

            it("Getter Proposition no 3 - voteCount = 0", async () => {
                const storedData = await votingInstance.getOneProposal(2, { from: voter2 });
                expect(storedData.voteCount).to.be.bignumber.equal(new BN(0));    
            });
            
            it("Getter Proposition no 4 - voteCount = 1", async () => {
                const storedData = await votingInstance.getOneProposal(3, { from: voter2 });
                expect(storedData.voteCount).to.be.bignumber.equal(new BN(1));    
            });

        });

        describe("3.4 Gagnant", function () {

            it("Passage à 'VotesTallied' et recherche du gagnant", async () => {
                const receipt = await votingInstance.tallyVotes({ from: owner });
                expectEvent(receipt, "WorkflowStatusChange" ,{previousStatus: BN(4), newStatus: BN(5)});
            });

            it("Qui a gagné => Proposition no 2", async () => {
                expect(await votingInstance.winningProposalID.call()).to.be.bignumber.equal(new BN(1));
            });

        });
    });

    describe("4. States", function () {

        before(async function () {
            votingInstance = await Voting.new({from:owner});
        });

        describe("4.1 Seulement le Owner peut changer de states", function () {
            it("Passage à 'ProposalsRegistrationStarted' par voter1 => Revert 'Ownable: caller is not the owner.'", async () => {
                await expectRevert(votingInstance.startProposalsRegistering({ from: voter1 }), "Ownable: caller is not the owner.");
            });

            it("Passage à 'ProposalsRegistrationEnded' par voter2 => Revert 'Ownable: caller is not the owner.'", async () => {
                await expectRevert(votingInstance.endProposalsRegistering({ from: voter2 }), "Ownable: caller is not the owner.");
            });

            it("Passage à 'VotingSessionStarted' par voter2 => Revert 'Ownable: caller is not the owner.'", async () => {
                await expectRevert(votingInstance.startVotingSession({ from: voter2 }), "Ownable: caller is not the owner.");
            });

            it("Passage à 'VotingSessionEnded' par voter2 => Revert 'Ownable: caller is not the owner.'", async () => {
                await expectRevert(votingInstance.endVotingSession({ from: voter2 }), "Ownable: caller is not the owner.");
            });

            it("Passage à 'VotesTallied' par voter2 => Revert 'Ownable: caller is not the owner.'", async () => {
                await expectRevert(votingInstance.tallyVotes({ from: voter2 }), "Ownable: caller is not the owner.");
            });

        });

        describe("4.2 Changement de states", function () {

            it("Passage à 'ProposalsRegistrationStarted'", async () => {
                const receipt = await votingInstance.startProposalsRegistering({ from: owner });
                expectEvent(receipt, "WorkflowStatusChange" ,{previousStatus: BN(0), newStatus: BN(1)});
            });

            it("Passage à 'ProposalsRegistrationEnded'", async () => {
                const receipt = await votingInstance.endProposalsRegistering({ from: owner });
                expectEvent(receipt, "WorkflowStatusChange" ,{previousStatus: BN(1), newStatus: BN(2)});
            });
            
            it("Passage à 'VotingSessionStarted'", async () => {
                const receipt = await votingInstance.startVotingSession({ from: owner });
                expectEvent(receipt, "WorkflowStatusChange" ,{previousStatus: BN(2), newStatus: BN(3)});
            });
            
            it("Passage à 'VotingSessionEnded'", async () => {
                const receipt = await votingInstance.endVotingSession({ from: owner });
                expectEvent(receipt, "WorkflowStatusChange" ,{previousStatus: BN(3), newStatus: BN(4)});
            });
            
            it("Passage à 'VotesTallied'", async () => {
                const receipt = await votingInstance.tallyVotes({ from: owner });
                expectEvent(receipt, "WorkflowStatusChange" ,{previousStatus: BN(4), newStatus: BN(5)});
            });

        });

        describe("4.3 Changement de states non permis", function () {

            it("Passage à 'ProposalsRegistrationStarted' par owner => Revert 'Registering proposals cant be started now.'", async () => {
                await expectRevert(votingInstance.startProposalsRegistering({ from: owner }), "Registering proposals cant be started now.");
            });

            it("Passage à 'ProposalsRegistrationEnded' par owner => Revert 'Registering proposals havent started yet'", async () => {
                await expectRevert(votingInstance.endProposalsRegistering({ from: owner }), "Registering proposals havent started yet");
            });

            it("Passage à 'VotingSessionStarted' par owner => Revert 'Registering proposals phase is not finished'", async () => {
                await expectRevert(votingInstance.startVotingSession({ from: owner }), "Registering proposals phase is not finished");
            });

            it("Passage à 'VotingSessionEnded' par owner => Revert 'Voting session havent started yet'", async () => {
                await expectRevert(votingInstance.endVotingSession({ from: owner }), "Voting session havent started yet");
            });

            it("Passage à 'VotesTallied' par owner => Revert 'Current status is not voting session ended.'", async () => {
                await expectRevert(votingInstance.tallyVotes({ from: owner }), "Current status is not voting session ended.");
            });
        });

    });

});