// contracts/Nft.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract DummyUSDT is ERC20('USDC', 'USDC') {
  constructor() {
    _mint(msg.sender, 10 * 10 ** decimals());
  }

  function decimals() public pure override returns (uint8) {
    return 6;
  }
}
