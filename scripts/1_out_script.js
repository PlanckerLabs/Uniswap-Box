const hre = require("hardhat");
const univ3addresses = require("../univ3Address.json");

async function main() {
  const Out = await hre.ethers.getContractFactory("Out");
  const out = await Out.deploy(
    univ3addresses.Swap_Router,
    univ3addresses.Quter_Router,
    univ3addresses.Factory,
    univ3addresses.NFTManager
  );

  await out.deployed();

  console.log("out deployed to:", out.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
