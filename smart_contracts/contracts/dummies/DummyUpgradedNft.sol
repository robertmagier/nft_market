// contracts/Nft.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { ERC721URIStorageUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

error NonExistingToken(uint256 tokenId);
error NotTokenOwner(uint256 tokenId, address owner);
error TokenOwnerNotPermitted(uint256 tokenId, address owner);
error TokenNotForSale(uint256 tokenId);
error EmptyURI();
error PaymentCollectionFailed(address token, address owner, uint256 paymentAmount);
error FeeCollectionFailed(address token, address owner, uint256 feeAmount);
error FeeWithdrawalFailed(address token, address owner, uint256 balance);

/// @custom:security-contact N/A
/// @title NFT Contract
/// @notice This contract allows for the minting, buying, and transferring of NFTs with USDT payment and fee handling.
contract DummyUpgradedNft is ERC721URIStorageUpgradeable, OwnableUpgradeable {
  /// @notice Emitted when the contract is initialized.
  /// @param USDTTokenAddress The address of the USDT token contract.
  event Initialized(address USDTTokenAddress);
  /// @notice Emitted when a new token is created.
  /// @param tokenId The ID of the newly created token.
  /// @param tokenURI The URI of the token's metadata.
  /// @param price The price of the token in USDT.
  /// @param owner The owner of the token.
  event TokenCreated(uint256 indexed tokenId, string tokenURI, uint256 price, address indexed owner);

  /// @notice Emitted when a token is bought.
  /// @param tokenId The ID of the token being bought.
  /// @param price The price paid for the token in USDT.
  /// @param seller The address of the seller.
  /// @param buyer The address of the buyer.
  event TokenBought(uint256 indexed tokenId, uint256 price, address indexed seller, address indexed buyer);

  struct TokenConfig {
    uint256 price;
    address owner;
  }

  /// @notice Address of the USDT token contract.
  address public USDTTokenAddress;

  /// @notice The percentage fee collected on each transaction.
  uint256 public feePercentage;

  /// @notice Tracks the ID for the next token to be minted.
  uint256 private _tokenId;

  /// @notice Default percentage increase applied to the token price after each sale.
  uint256 private _defaultPriceIncreasePer;

  /// @notice Configuration mapping for each token.
  mapping(uint256 tokenId => TokenConfig config) public tokenConfig;

  modifier onlyTokenOwner(uint256 tokenId) {
    if (!_exists(tokenId)) {
      revert NonExistingToken(tokenId);
    }
    if (tokenConfig[tokenId].owner != msg.sender) {
      revert NotTokenOwner(tokenId, msg.sender);
    }
    _;
  }

  modifier tokenExists(uint256 tokenId) {
    if (!_exists(tokenId)) {
      revert NonExistingToken(tokenId);
    }
    _;
  }

  modifier notTokenOwner(uint256 tokenId) {
    if (tokenConfig[tokenId].owner == msg.sender) {
      revert TokenOwnerNotPermitted(tokenId, msg.sender);
    }
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  /// @notice Disables initializer functions for the contract.
  constructor() {
    _disableInitializers();
  }

  /// @notice Initializes the NFT contract with the specified USDT address and initial settings.
  /// @param USDT The address of the USDT token contract.
  function initialize(address USDT) external initializer {
    USDTTokenAddress = USDT;
    __ERC721_init('NFT', 'NFT');
    __Ownable_init(msg.sender);
    feePercentage = 5;
    _tokenId = 1;
    _defaultPriceIncreasePer = 10;
    emit Initialized(USDT);
  }

  /// @notice Creates a new NFT with a specified URI and price.
  /// @param tokenURI The URI for the token's metadata.
  /// @param price The initial price of the token in USDT.
  /// @return The ID of the newly created token.
  function create(string memory tokenURI, uint256 price) external returns (uint256) {
    if (bytes(tokenURI).length == 0) {
      revert EmptyURI();
    }
    uint256 newId = _tokenId;
    _mint(msg.sender, newId);
    _setTokenURI(newId, tokenURI);
    tokenConfig[newId] = TokenConfig(price, msg.sender);

    emit TokenCreated(newId, tokenURI, price, msg.sender);
    _tokenId++;
    return newId;
  }

  /// @notice Updates the fee percentage for transactions.
  /// @param newFeePercentage The new fee percentage.
  function setFeePercentage(uint256 newFeePercentage) external onlyOwner {
    feePercentage = newFeePercentage;
  }

  /// @notice Calculates the fee for a specified token.
  /// @param tokenId The ID of the token.
  /// @return The fee amount in USDT.
  function expectedFee(uint256 tokenId) external view returns (uint256) {
    return _expectedFee(tokenId);
  }

  /// @notice Calculates the total cost, including fees, to buy a specified token.
  /// @param tokenId The ID of the token.
  /// @return The total cost in USDT.
  function expectedBuyCost(uint256 tokenId) external view returns (uint256) {
    return tokenConfig[tokenId].price + _expectedFee(tokenId);
  }

  /// @notice Allows a user to buy a specified token.
  /// @param tokenId The ID of the token to buy.
  function buy(uint256 tokenId) external notTokenOwner(tokenId) tokenExists(tokenId) {
    if (tokenConfig[tokenId].price == 0) {
      revert TokenNotForSale(tokenId);
    }

    _collectPayment(tokenId);
    _transfer(tokenConfig[tokenId].owner, msg.sender, tokenId);

    emit TokenBought(tokenId, tokenConfig[tokenId].price, msg.sender, tokenConfig[tokenId].owner);

    tokenConfig[tokenId].owner = msg.sender;
    uint256 fee = _expectedFee(tokenId);
    _collectFees(fee);
    _increasePrice(tokenId);
  }

  /// @notice Sets a new price for a specified token.
  /// @param tokenId The ID of the token.
  /// @param price The new price in USDT.
  function setPrice(uint256 tokenId, uint256 price) external onlyTokenOwner(tokenId) {
    tokenConfig[tokenId].price = price;
  }

  /// @notice Transfers a specified token to another address.
  /// @param to The address to transfer the token to.
  /// @param tokenId The ID of the token to transfer.
  function transfer(address to, uint256 tokenId) external onlyTokenOwner(tokenId) {
    _transfer(msg.sender, to, tokenId);
    tokenConfig[tokenId].owner = to;
  }

  /// @notice Allows the contract owner to withdraw collected fees in USDT.
  function withdrawFees() external onlyOwner {
    if (!IERC20(USDTTokenAddress).transfer(msg.sender, IERC20(USDTTokenAddress).balanceOf(address(this)))) {
      revert FeeWithdrawalFailed(USDTTokenAddress, msg.sender, IERC20(USDTTokenAddress).balanceOf(address(this)));
    }
  }

  /// @dev Increases the price of a token after a purchase by a default percentage.
  /// @param tokenId The ID of the token.
  function _increasePrice(uint256 tokenId) private {
    uint256 newPrice = tokenConfig[tokenId].price + (tokenConfig[tokenId].price * _defaultPriceIncreasePer) / 100;
    tokenConfig[tokenId].price = newPrice;
  }

  /// @dev Checks if a token with the specified ID exists.
  /// @param tokenId The ID of the token to check.
  /// @return True if the token exists, false otherwise.
  function _exists(uint256 tokenId) private view returns (bool) {
    return ownerOf(tokenId) != address(0);
  }

  /// @dev Collects payment for a token transfer.
  /// @param tokenId The ID of the token.
  function _collectPayment(uint256 tokenId) private {
    if (!IERC20(USDTTokenAddress).transferFrom(msg.sender, tokenConfig[tokenId].owner, tokenConfig[tokenId].price)) {
      revert PaymentCollectionFailed(USDTTokenAddress, tokenConfig[tokenId].owner, tokenConfig[tokenId].price);
    }
  }

  /// @dev Calculates the fee for a specified token based on its price and fee percentage.
  /// @param tokenId The ID of the token.
  /// @return The calculated fee in USDT.
  function _expectedFee(uint256 tokenId) private view returns (uint256) {
    return (tokenConfig[tokenId].price * feePercentage) / 100;
  }

  /// @dev Collects transaction fees for a token sale.
  /// @param fee The fee amount to collect in USDT.
  function _collectFees(uint256 fee) private {
    if (!IERC20(USDTTokenAddress).transferFrom(msg.sender, address(this), fee)) {
      revert FeeCollectionFailed(USDTTokenAddress, address(this), fee);
    }
  }

  /// @dev Function added to test upgradeability.
  function newFunction() external pure returns (string memory) {
    return 'new function';
  }
}
