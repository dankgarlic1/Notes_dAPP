// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.8;
// pragma solidity ^0.8.21;
 pragma solidity >=0.4.22 <0.9.0;

contract NotesContract {

    uint256 noteCount = 0;

    struct  Note {
        uint256 noteId;
        string title;
        string description;

    }

    mapping (uint256 => Note) notes;

    event noteCreated(uint256 id, string title, string description);
    event noteDeleted(uint256 id);

    function createNote(string memory _title, string memory _description)  public {
        notes[noteCount] = Note(noteCount,_title,_description);
        emit noteCreated(noteCount, _title, _description);
        noteCount++;
    }

    function deleteNote(uint256 _id) public {
        delete notes[_id];
        emit noteDeleted(_id);
        noteCount--;
    }


    
}