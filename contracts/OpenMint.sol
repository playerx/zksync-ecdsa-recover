// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * Authors: Omar Garcia <omar@game7.io>
 * GitHub: https://github.com/ogarciarevett
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OpenMint is ERC721URIStorage, ERC721Enumerable, AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    string public baseTokenURI;
    mapping(uint256 => bool) public nftRevealed;
    bool public LOCKED_CONTRACT = false;
    mapping(address => bool) private addressesMinted;
    string private constant unrevealedURI = "QmW5gVuW3YWD1WwYRY7x1fd4shGe2823WTtbWFbAN5qWXR/unreveal.json";
    mapping (address => bool) public whitelistSigners;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    modifier noLocked() {
        require(LOCKED_CONTRACT == false, "Sorry, this contract is locked");
        _;
    }

    constructor(string memory _baseTokenURI) ERC721("OpenMintZKSummon", "ZKS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        setSigner(msg.sender);
        baseTokenURI = _baseTokenURI;
    }

    function pause() public onlyRole(PAUSER_ROLE) noLocked {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) noLocked {
        _unpause();
    }

    function setSigner(address _signer) public onlyRole(DEFAULT_ADMIN_ROLE) noLocked {
        whitelistSigners[_signer] = true;
    }

    function recoverSigner(uint256 nonce, bytes memory signature) public view returns (address) {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, nonce));
        bytes32 hash = ECDSA.toEthSignedMessageHash(message);
        address receivedAddress = ECDSA.recover(hash, signature);
        return receivedAddress;
    }

    function mint(address to) private {
        require(to != address(0), "OpenMintZk: mint to the zero address");
        require(!addressesMinted[to], "OpenMintZk: Sorry, This address already has a token");
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, unrevealedURI);
        addressesMinted[to] = true;
        _tokenIdCounter.increment();
    }

    function qrFreeMint(uint256 nonce, bytes memory signature) public nonReentrant noLocked whenNotPaused {
        address signer = recoverSigner(nonce, signature);
        require(whitelistSigners[signer], "OpenMintZk: Invalid signer");
        mint(msg.sender);
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) noLocked {
        mint(to);
    }

    function freeMint(address to) public whenNotPaused nonReentrant noLocked {
        mint(to);
    }

    function reveal(uint256 tokenId, string memory tokenURL) public onlyRole(MINTER_ROLE) noLocked whenPaused {
        require(_exists(tokenId), "ERC721: URI set of nonexistent token");
        require(!nftRevealed[tokenId], "ERC721: Token already revealed");
        _setTokenURI(tokenId, tokenURL);
        nftRevealed[tokenId] = true;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function batchSetTokenURI(uint256[] memory tokenIds, string[] memory tokenURIs) public onlyRole(MINTER_ROLE) noLocked {
        require(tokenIds.length == tokenURIs.length, "OpenMintZk: tokenIds and URIs length mismatch");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_exists(tokenIds[i]), "ERC721: URI set of nonexistent token");
            _setTokenURI(tokenIds[i], tokenURIs[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batch
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batch);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) whenNotPaused nonReentrant {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused noLocked {
        baseTokenURI = _baseTokenURI;
    }

    function lockContract() public onlyRole(DEFAULT_ADMIN_ROLE) noLocked {
        LOCKED_CONTRACT = true;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
