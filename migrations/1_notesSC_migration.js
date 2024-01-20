const NotesContract = artifacts.require("NotesContract"); //importing class not the file!

module.exports = function (deployer) {
  deployer.deploy(NotesContract);
};
