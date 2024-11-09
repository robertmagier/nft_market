// contracts/Nft.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/// @title Dummy USDT Token Contract
/// @notice This contract is a dummy USDT token for testing purposes.
/// @dev Extends the ERC20 token standard with a fixed initial supply.
/// @custom:security-contact N/A
contract DummyUSDT is ERC20('USDC', 'USDC') {

  event Mint(address indexed to, uint256 amount);
  /// @notice Mints an initial supply of 10 USDC tokens to the deployer.
  /// @dev Calls the `_mint` function to mint tokens to the contract deployer. Emits a `Mint` event.
  constructor() {
    _mint(msg.sender, 10 * 10 ** decimals());
    emit Mint(msg.sender, 10 * 10 ** decimals());
  }

  /// @notice Returns the number of decimals used to get the token's smallest unit.
  /// @dev Overrides the default `decimals` function to set the number of decimals to 6.
  /// @return uint8 The number of decimals, set to 6 for USDC standard.
  function decimals() public pure override returns (uint8) {
    return 6;
  }
}
