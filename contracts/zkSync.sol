// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
Admin Public Key: 0x7F0c4695Cf04Ef0d9d8812dB1F96562a3ACB6830
*/

contract TestContract {
  event ReceivedToAddress(address to);
  event RecoveredAddress(address adminWallet);
  event Checked(bool isValid);

  address public adminWallet;
  mapping (address => bool) public whitelistSigners;

  function setSigner(address _signer) public {
    whitelistSigners[_signer] = true;
  }

  function verify(address to, uint256 nonce, bytes memory signature) public pure returns (address) {
    bytes32 message = keccak256(abi.encodePacked(to, nonce));
    bytes32 hash = ECDSA.toEthSignedMessageHash(message);
    address recoveredAddress = ECDSA.recover(hash, signature);

    return recoveredAddress;
  }

  function verifyAndCheck(uint256 nonce, bytes memory signature) public returns (address) {
    address to = msg.sender;
    bytes32 message = keccak256(abi.encodePacked(to, nonce));
    bytes32 hash = ECDSA.toEthSignedMessageHash(message);
    address recoveredAddress = ECDSA.recover(hash, signature);

    emit ReceivedToAddress(to);
    emit RecoveredAddress(recoveredAddress);
    emit Checked(recoveredAddress == adminWallet);

    require(whitelistSigners[recoveredAddress], "OpenMintZk: Invalid signer");


    return recoveredAddress;
  }
}