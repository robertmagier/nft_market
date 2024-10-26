// contracts/Nft.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Nft is ERC721URIStorage {

    struct TokenConfig {
        uint256 price;
        address owner;
    }

    address public USDTTokenAddress;
    uint256 private _tokenIds;

    mapping (uint256 => TokenConfig) public tokenConfig;

    constructor(address USDT) ERC721("USDC Paid Nft", "UPN") {
        USDTTokenAddress = USDT;
    }

    function createNew(string memory tokenURI,uint256 price)
        public
    {
        _mint(msg.sender, _tokenIds);
        _setTokenURI(_tokenIds, tokenURI);
        tokenConfig[_tokenIds] = TokenConfig(price, msg.sender);
        _tokenIds++;
    }
}