require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();


module.exports = {
  solidity: "0.8.24",
  networks: {
		//Add extra chains as needed 
    hardhat: {
      chainId: 11155111,
    },
      sepolia: {
        url: `${process.env.ALCHEMY_SEPOLIA_URL}`,
        accounts: [`0x${process.env.PRIVATE_KEY}`],
      },
  }, 
  defaultNetwork: "hardhat",
  etherscan: {
    apiKey: "HJFG7Y2C72ZZGX68T2G3XV74V669WYQI88"
  },
  sourcify: {
    enabled: true
  }
};