// contracts/Nft.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Nft is ERC721URIStorage {
  event TokenCreated(
    uint256 tokenId,
    string tokenURI,
    uint256 price,
    address owner
  );
  event TokenBought(
    uint256 tokenId,
    uint256 price,
    address seller,
    address buyer
  );

  struct TokenConfig {
    uint256 price;
    address owner;
  }

  address public USDTTokenAddress;
  uint256 private _tokenId = 1;
  uint256 private _defaultPriceIncreasePer = 10;

  mapping(uint256 => TokenConfig) public tokenConfig;

  constructor(address USDT) ERC721('USDC Paid Nft', 'UPN') {
    USDTTokenAddress = USDT;
  }

  modifier onlyTokenOwner(uint256 tokenId) {
    require(_exists(tokenId), 'Token does not exist');
    require(tokenConfig[tokenId].owner == msg.sender, 'You are not the owner');
    _;
  }

  function create(
    string memory tokenURI,
    uint256 price
  ) public returns (uint256) {
    uint256 newId = _tokenId;
    _mint(msg.sender, newId);
    _setTokenURI(newId, tokenURI);
    tokenConfig[newId] = TokenConfig(price, msg.sender);

    emit TokenCreated(newId, tokenURI, price, msg.sender);
    _tokenId++;
    return newId;
  }

  function buy(uint256 tokenId) public {
    require(_exists(tokenId), 'Token does not exist');
    require(msg.sender != tokenConfig[tokenId].owner, 'You are the owner');
    require(tokenConfig[tokenId].price > 0, 'Token not for sale');
    require(
      IERC20(USDTTokenAddress).balanceOf(msg.sender) >=
        tokenConfig[tokenId].price,
      'Insufficient USDT balance'
    );
    _collectPayment(tokenId);
    _transfer(tokenConfig[tokenId].owner, msg.sender, tokenId);
    tokenConfig[tokenId].owner = msg.sender;
  }

  function setPrice(
    uint256 tokenId,
    uint256 price
  ) public onlyTokenOwner(tokenId) {
    tokenConfig[tokenId].price = price;
  }

  function _increasePrice(uint256 tokenId) internal {
    require(_exists(tokenId), 'Token does not exist');
    require(tokenConfig[tokenId].owner == msg.sender, 'You are not the owner');
    uint256 newPrice = tokenConfig[tokenId].price +
      (tokenConfig[tokenId].price * _defaultPriceIncreasePer) /
      100;
    tokenConfig[tokenId].price = newPrice;
  }

  function _collectPayment(uint256 tokenId) internal {
    require(
      IERC20(USDTTokenAddress).transferFrom(
        msg.sender,
        tokenConfig[tokenId].owner,
        tokenConfig[tokenId].price
      ),
      'Payment failed'
    );
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < _tokenId;
  }
}
