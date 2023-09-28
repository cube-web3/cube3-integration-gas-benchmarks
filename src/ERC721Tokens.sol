// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "cube3/contracts/Cube3Integration.sol";

contract Cube3Nft is ERC721 {
    uint256 private _tokenIdCounter;

    mapping(address => uint256) public mintsPerAddress;

    uint256 public constant MAX_MINT = 3;

    // Instantiate the Cube3Integration contract in the constructor
    constructor() ERC721("Cube3NFT", "C3NFT") {}

    // Add the cube3Protected modifier to the safeMint function, and include the `bytes calldata cube3SecurePayload` parameter as
    // the last parameter of the function. This will allow the Cube3Integration contract to validate the payload before the mint.
    function safeMint(uint256 qty) public {
        require(mintsPerAddress[msg.sender] + qty <= MAX_MINT, "Max mint per address reached");
        mintsPerAddress[msg.sender] += qty;

        for (uint256 i; i < qty;) {
            _safeMint(msg.sender, ++_tokenIdCounter);
            unchecked {
                ++i;
            }
        }
    }

    // override ERC721 super.supportsInterface
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

contract Cube3NftProtected is ERC721, Cube3Integration {
    uint256 private _tokenIdCounter;

    mapping(address => uint256) public mintsPerAddress;

    uint256 public constant MAX_MINT = 3;

    // Instantiate the Cube3Integration contract in the constructor
    constructor() ERC721("Cube3ProtectedNFT", "CP3NFT") Cube3Integration() {}

    // Add the cube3Protected modifier to the safeMint function, and include the `bytes calldata cube3SecurePayload` parameter as
    // the last parameter of the function. This will allow the Cube3Integration contract to validate the payload before the mint.
    function safeMint(uint256 qty, bytes calldata cube3SecurePayload) public cube3Protected(cube3SecurePayload) {
        require(mintsPerAddress[msg.sender] + qty <= MAX_MINT, "Max mint per address reached");
        mintsPerAddress[msg.sender] += qty;
        for (uint256 i; i < qty;) {
            _safeMint(msg.sender, ++_tokenIdCounter);
            unchecked {
                ++i;
            }
        }
    }

    // both ERC721 and Cube3Integration implement this function, so we need to override it and call super.supportsInterface
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, Cube3Integration) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
