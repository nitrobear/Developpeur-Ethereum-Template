# Tests unitaires pour le contrat Voting.sol

Les tests portent sur le fichier de correction fourni, il y juste été renommé en Voting.sol, car le nom de fichier en minuscule provoquait des warnings.

Les tests se font sur 4 parties : 

1. Registration : concerne toute la partie de l'enregistrement des Votes
2. Proposals : Concerne la partie de l'enregistrement des Proposals, ainsi que sur les Getters sur les Proposals
3. Voting : Le vote en lui même, avec la cloture et la désignation du gagnant
4. States : Des tests sur les changements d'états sur le contrat et les droits sur les différentes fonctions
--- 
## Nombre total de tests : **53**
---

# 1. Registration

- Ajout du voter1 et vérification de l'Event VoterRegistered
- Ajout du voter2 et vérification de l'Event VoterRegistered
- Ajout du voter2 une seconde fois pour tester le require 'Already registered'
- Ajout du voter3 et vérification de son statut isRegistred
- Vérification du statut isREgistred du voter3 par le owner pour tester le Revert 'not a voter'
- Passage à l'enregistrement des Proposals 
- Test de l'ajout du Voter4 en dehors de 'RegisteringVoters' => Revert 
---
# 2. Proposals
## 2.1 Ajout de proposals
- Ajout Proposition no 1 par voter1 et vérification Event ProposalRegistered
- Ajout Proposition no 2 par voter4, non enregistré => Revert 'not a voter'
- Ajout Proposition no 2 par voter2 et vérification Event ProposalRegistered 
- Ajout Proposition no 3 par voter1 et vérification Event ProposalRegistered 
- Ajout Proposition no 4 par voter3 et vérification Event ProposalRegistered 
- Ajout Proposition vide par voter2, non enregistré => Revert 'Vous ne pouvez pas ne rien proposer'
- Passage à 'ProposalsRegistrationEnded'
- Impossible d'ajouter une proposition en dehors de 'ProposalsRegistrationStarted' => Revert 'Proposals are not allowed yet' 
## 2.2 Getters sur les proposals
- Tests de différents Getters sur les Proposals ajoutées
- Test sur getter par un non voter
---
# 3. Voting : Tests sur la procédure de vote
## 3.1 Enregistrement des votes
- Impossible d'ajouter une proposition en dehors de 'ProposalsRegistrationStarted' => Revert 'Proposals are not allowed yet' 
- Impossible de voter en dehors de 'VotingSessionStarted' => Revert
- Passage à 'startVotingSession' 
- Vote pour la Proposition no 1 par voter1 et vérification Event Voted 
- Vote pour la Proposition no 2 par voter2 et vérification Event Voted 
- Vote pour la Proposition no 2 par voter3 et vérification Event Voted 
- Vote pour la Proposition no 3 par voter3  => Revert 'You have already voted' 
- Vote pour la Proposition no 4 par voter4 et vérification Event Voted 

## 3.2 Cloture des votes
- Passage à 'VotingSessionEnded'
- Vote pour la Proposition no 4 par voter4 après le cloture des votes => Revert 'Voting session havent started yet' 

## 3.3 Nombre de votes par proposals
- Getters sur les nombres de votes pour chaque proposal

## 3.4 Gagnant
- Passage à 'VotesTallied' et recherche du gagnant
- Qui a gagné => Proposition no 2

---
# 4. States : Tests sur les changements de WorkFlow

## 4.1 Seulement le Owner peut changer de states
> Ces tests peuvent sembler non nécessaires, mais cela permet de vérifier que le Ownable n'a pas été enlever sur une fonction lors de l'écriture du contrat, ou bien mis en place.

- Passage à 'ProposalsRegistrationStarted' par voter1 => Revert 'Ownable: caller is not the owner.'
- Passage à 'ProposalsRegistrationEnded' par voter2 => Revert 'Ownable: caller is not the owner.'
- Passage à 'VotingSessionStarted' par voter2 => Revert 'Ownable: caller is not the owner.' 
- Passage à 'VotingSessionEnded' par voter2 => Revert 'Ownable: caller is not the owner.'
- Passage à 'VotesTallied' par voter2 => Revert 'Ownable: caller is not the owner.' 

## 4.2 Changement de states
- Passage à 'ProposalsRegistrationStarted' 
- Passage à 'ProposalsRegistrationEnded' 
- Passage à 'VotingSessionStarted' 
- Passage à 'VotingSessionEnded'
- Passage à 'VotesTallied'

## 4.3 Changement de states non permis
- Passage à 'ProposalsRegistrationStarted' par owner => Revert 'Registering proposals cant be started now.' 
- Passage à 'ProposalsRegistrationEnded' par owner => Revert 'Registering proposals havent started yet' 
- Passage à 'VotingSessionStarted' par owner => Revert 'Registering proposals phase is not finished' 
- Passage à 'VotingSessionEnded' par owner => Revert 'Voting session havent started yet' 
- Passage à 'VotesTallied' par owner => Revert 'Current status is not voting session ended.' 

---
# Eth-gas-reporter

```
Solc version: 0.8.14+commit.80d49f37
Optimizer enabled: false
Runs: 200
Block limit: 6718946 gas 
```

| Contract  | Method                     |  Min         |  Max        |  Avg        |  # calls     |  eur (avg)  
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
| Voting |  addProposal                |       59604  |      76704  |      64734  |          10  |          -  
| Voting |  addVoter                   ·           -  |          -  |      50196  ·           8  |          -  
| Voting |  endProposalsRegistering    |           -  |          -  |      30575  |          14  |          -  
| Voting |  endVotingSession           |           -  |          -  |      30509  |           9  |          -  
| Voting |  setVote                    |       58101  |      78013  |      67888  |           9  |          -  
| Voting |  startProposalsRegistering  |           -  |          -  |      47653  |           5  |          -  
| Voting |  startVotingSession         |           -  |          -  |      30530  |           4  |          -  
| Voting |  tallyVotes                 |       34921  |      66445  |      42802  |           8  |          -  


|  Deployments |                 Min        |      Max     |     Avg                          |  % of limit  | |
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
|  Voting                                  |           -  |          -  |    2137238  |      31.8 %  |          - 