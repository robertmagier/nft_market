import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@openzeppelin/hardhat-upgrades';
import '@nomicfoundation/hardhat-chai-matchers';
const config: HardhatUserConfig = {
  solidity: '0.8.27',
};

export default config;
