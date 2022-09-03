const { MerkleTree } = require("merkletreejs");
const { ethers } = require("ethers");

const leaves = [
  { address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" },
  { address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8" },
  { address: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC" },
].map((x) =>
  ethers.utils.keccak256(ethers.utils.solidityPack(["address"], [x.address]))
);
const tree = new MerkleTree(leaves, ethers.utils.keccak256, {
  sortPairs: true,
});

const root = tree.getHexRoot();
const leaf = ethers.utils.keccak256(
  ethers.utils.solidityPack(
    ["address"],
    ["0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"]
  )
);
console.log(tree.getHexProof(leaf));
console.log(tree.verify(tree.getHexProof(leaf), leaf, root));