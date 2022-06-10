// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Classe is Ownable {

    struct Student {
        string name;
        uint noteBiology;
        uint noteMath;
        uint noteFr;
    }

    // Matières - Ajout du none pour gérér le cas du mapping des professeurs s'il n'existe pas
    enum Matiere{none, bio, math, fr}

    // Mapping des professeurs avec adresse et matière
    mapping ( address => Matiere) professeurs;

    // Mapping nom de l'élève vers son id dans le tableau des élèves
    mapping ( string => uint) eleves;

    // Tableau des élèves, pour pouvoir faire des itérations pour les calculs
    Student[] studentsArray;

    constructor() {

        // Parametrage des Professeurs
        professeurs[0x972Af21d1D7a1bB9f952cC551592d1E90df80c23] = Matiere.bio;
        professeurs[0x55ea9528E32A355f6b1AF91CAb6CA323E6cC76B6] = Matiere.math;
        professeurs[0x53058B5aD303E437D7bf5D80D2b0722CB328d1cC] = Matiere.fr;

        // Ajout d'élèves pour tests
        addNote("jean1", 10,12,14);
        addNote("jean2", 8,9,10);
        addNote("jean3", 10,15,18);
    }

    /**
    *  Ajout d'un élève avec ses notes
    */
    function addNote(string memory _nom, uint _noteBio, uint _noteMath, uint _noteFr) public onlyOwner {
        studentsArray.push(Student(_nom, _noteBio, _noteMath, _noteFr));
        eleves[_nom] = studentsArray.length - 1;
    }

    /**
    *  Récupération de la note pour un élève, en fonction de la matière
    */
    function getNote(string calldata _nom, Matiere _matiere ) public view returns (uint) {

        require (uint(_matiere) > 0, "matiere not exist");
        require (uint(_matiere) < 4, "matiere not exist");

        if (_matiere == Matiere.bio) {
            return studentsArray[eleves[_nom]].noteBiology;
        }
        
        if (_matiere == Matiere.math) {
            return studentsArray[eleves[_nom]].noteMath;
        }

        if (_matiere == Matiere.fr) {
            return studentsArray[eleves[_nom]].noteFr;
        }
        return 0;
    }
    
    /**
    *  Récupération de la note pour un élève pour Biology
    */
    function getNoteBiology(string calldata _nom) public view returns (uint) {
        return getNote(_nom, Matiere.bio);
    }
    
    /**
    *  Récupération de la note pour un élève pour Math
    */
    function getNoteMath(string calldata _nom) public view returns (uint) {
        return getNote(_nom, Matiere.math);
    }

    /**
    *  Récupération de la note pour un élève pour Francais
    */
    function getNoteFrancais(string calldata _nom) public view returns (uint) {
        return getNote(_nom, Matiere.fr);
    }

    /**
    *  Ajout d'une note pour un professeur, uniquement pour la matière associée au professeur
    */
    function setNote(string calldata _nom, uint _note ) public {
        require(professeurs[msg.sender] == Matiere.bio || professeurs[msg.sender] == Matiere.math || professeurs[msg.sender] == Matiere.fr , "not a professor");
        
        if ( professeurs[msg.sender] == Matiere.bio ) {
            studentsArray[eleves[_nom]].noteBiology = _note;
        }
        if ( professeurs[msg.sender] == Matiere.math ) {
            studentsArray[eleves[_nom]].noteMath = _note;
        }
        if ( professeurs[msg.sender] == Matiere.fr ) {
            studentsArray[eleves[_nom]].noteFr = _note;
        }
    }

    /**
    *  Moyenne pour un élève
    */
    function getMoyenneEleve(string calldata _nom)  public view returns (uint) {
        //require(eleves[_nom].name != "", "Eleve not exist");
        Student memory student  = studentsArray[eleves[_nom]];
        uint moyenne = ( student.noteBiology + student.noteMath + student.noteFr) / 3;
        return moyenne;
    }
    
    /**
    *  Moyenne de la classe
    */
    function getMoyenneClasse() public view returns (uint) {

        uint nbEleves = studentsArray.length;

        uint total = 0;
        for(uint i = 0 ; i < nbEleves ; i++) {
            total += studentsArray[i].noteBiology + studentsArray[i].noteMath + studentsArray[i].noteFr;
        }
        uint moyenne = total / nbEleves / 3;
        
        return moyenne;
    }

    /**
    *  Moyenne de la classe pour une matière
    */
    function getMoyenneClasseMatiere( Matiere _matiere ) public view returns (uint) {

        require (uint(_matiere) > 0, "matiere not exist");
        require (uint(_matiere) < 4, "matiere not exist");

        uint nbEleves = studentsArray.length;

        uint total = 0;
        for(uint i = 0 ; i < nbEleves ; i++) {

            if (_matiere == Matiere.bio) {
                total += studentsArray[i].noteBiology;
            }
            if (_matiere == Matiere.math) {
                total += studentsArray[i].noteMath;
            }
            if (_matiere == Matiere.fr) {
                total += studentsArray[i].noteFr;
            }
        }
        uint moyenne = total / nbEleves;
        
        return moyenne;
    }

    /**
    *  Moyenne de la classe pour Biology
    */
    function getMoyenneClasseBiology() public view returns (uint) {
        return getMoyenneClasseMatiere(Matiere.bio);
    }

    /**
    *  Moyenne de la classe pour Math
    */
    function getMoyenneClasseMath() public view returns (uint) {
        return getMoyenneClasseMatiere(Matiere.math);
    }

    /**
    *  Moyenne de la classe pour Francais
    */
    function getMoyenneClasseFrancais() public view returns (uint) {
        return getMoyenneClasseMatiere(Matiere.fr);
    }

}
