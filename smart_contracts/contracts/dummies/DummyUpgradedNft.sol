// contracts/Nft.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { ERC721URIStorageUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @custom:security-contact N/A
contract DummyUpgradedNft is ERC721URIStorageUpgradeable, OwnableUpgradeable {
  event TokenCreated(
    uint256 indexed tokenId,
    string tokenURI,
    uint256 price,
    address indexed owner
  );
  event TokenBought(
    uint256 indexed tokenId,
    uint256 price,
    address indexed seller,
    address indexed buyer
  );

  struct TokenConfig {
    uint256 price;
    address owner;
  }

  address public USDTTokenAddress;
  uint256 public feePercentage;
  uint256 private _tokenId;
  uint256 private _defaultPriceIncreasePer;

  mapping(uint256 tokenId => TokenConfig tokenConfig) public tokenConfig;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address USDT) external initializer {
    USDTTokenAddress = USDT;
    __ERC721_init('NFT', 'NFT');
    __Ownable_init(msg.sender);
    feePercentage = 5;
    _tokenId = 1;
    _defaultPriceIncreasePer = 10;
  }

  modifier onlyTokenOwner(uint256 tokenId) {
    require(_exists(tokenId), 'Token does not exist');
    require(tokenConfig[tokenId].owner == msg.sender, 'You are not the owner');
    _;
  }

  function create(
    string memory tokenURI,
    uint256 price
  ) external returns (uint256) {
    require(bytes(tokenURI).length > 0, 'URI is empty');
    uint256 newId = _tokenId;
    _mint(msg.sender, newId);
    _setTokenURI(newId, tokenURI);
    tokenConfig[newId] = TokenConfig(price, msg.sender);

    emit TokenCreated(newId, tokenURI, price, msg.sender);
    _tokenId++;
    return newId;
  }

  function setFeePercentage(uint256 newFeePercentage) external onlyOwner {
    feePercentage = newFeePercentage;
  }

  function expectedFee(uint256 tokenId) external view returns (uint256) {
    return _expectedFee(tokenId);
  }

  function expectedBuyCost(uint256 tokenId) external view returns (uint256) {
    return tokenConfig[tokenId].price + _expectedFee(tokenId);
  }

  function buy(uint256 tokenId) external {
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

    emit TokenBought(
      tokenId,
      tokenConfig[tokenId].price,
      msg.sender,
      tokenConfig[tokenId].owner
    );

    tokenConfig[tokenId].owner = msg.sender;
    _collectFees(tokenId);
    _increasePrice(tokenId);
  }

  function setPrice(
    uint256 tokenId,
    uint256 price
  ) external onlyTokenOwner(tokenId) {
    tokenConfig[tokenId].price = price;
  }

  function transfer(
    address to,
    uint256 tokenId
  ) external onlyTokenOwner(tokenId) {
    _transfer(msg.sender, to, tokenId);
    tokenConfig[tokenId].owner = to;
  }

  function withdrawFees() external onlyOwner {
    require(
      IERC20(USDTTokenAddress).transfer(
        msg.sender,
        IERC20(USDTTokenAddress).balanceOf(address(this))
      ),
      'Withdrawal failed'
    );
  }

  function _exists(uint256 tokenId) private view returns (bool) {
    return ownerOf(tokenId) != address(0);
  }

  function _increasePrice(uint256 tokenId) private {
    require(_exists(tokenId), 'Token does not exist');
    require(tokenConfig[tokenId].owner == msg.sender, 'You are not the owner');
    uint256 newPrice = tokenConfig[tokenId].price +
      (tokenConfig[tokenId].price * _defaultPriceIncreasePer) /
      100;
    tokenConfig[tokenId].price = newPrice;
  }

  function _collectPayment(uint256 tokenId) private {
    require(
      IERC20(USDTTokenAddress).transferFrom(
        msg.sender,
        tokenConfig[tokenId].owner,
        tokenConfig[tokenId].price
      ),
      'Payment failed'
    );
  }

  function _expectedFee(uint256 tokenId) private view returns (uint256) {
    return (tokenConfig[tokenId].price * feePercentage) / 100;
  }

  function _collectFees(uint256 tokenId) private {
    require(
      IERC20(USDTTokenAddress).transferFrom(
        msg.sender,
        address(this),
        _expectedFee(tokenId)
      ),
      'Fee collection failed'
    );
  }

  function newFunction() external pure returns (string memory) {
    return 'new function';
  }
}
