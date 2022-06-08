// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Epargne is Ownable {
    
    // Montant du dépot 
    uint public depot;

    // Date du premier dépot
    uint public startTime;

    // NUméro de la transaction
    uint public transactionNum;

    // Logs des transactions
    mapping(uint => uint) transactions;

    constructor() payable {
        depot = 0;
        transactionNum = 0;
    }
    
    /**
    *  Réception d'ether
    */
    function receiveEth() public payable {
        require (msg.value>0, "amount is 0");

        // Ajout au depot
        depot = depot + msg.value;

        // Si première transaction, on enregistre la date
        if ( transactionNum == 0 ) {
            startTime = block.timestamp;
        }

        // Log de la transaction
        transactionNum += 1;
        transactions[transactionNum] = msg.value;
    }

    /**
    *  Recupération d'une transaction
    */
    function getTransaction(uint num) public view returns(uint) {
        require (num > 0, "id transaction not exist");
        require (num <= transactionNum, "id transaction not exist");
        return (transactions[num]);
    }

    /**
    *  Libération des fonds
    */
    function release() public payable onlyOwner {

        uint delay = 3 * 31 * 24 * 60 * 60;
        bool delayOk = block.timestamp - startTime > delay;

        require (depot > 0, "depot est 0");
        require (delayOk, "not 3 month after first deposit");

         (bool sent, ) = payable(msg.sender).call{value: depot}("");
        require (sent == true,"release not ok");

        // réinitialiation du depot
        depot = 0;
    }

}
