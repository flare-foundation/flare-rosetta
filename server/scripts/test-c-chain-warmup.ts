import { JsonRpcProvider, Wallet } from "ethers";

const LocalURL = "http://localhost:9650";
const TestCAddress = "0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC";
const TestPrivateKey =
  "0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027";

async function main() {
  const provider = new JsonRpcProvider(LocalURL + "/ext/bc/C/rpc");
  const wallet = new Wallet(TestPrivateKey, provider);

  console.log("Sending C-chain self-transfer to produce a block...");
  const tx = await wallet.sendTransaction({ to: TestCAddress, value: 0n, gasPrice: 5_000_000_000_000n }); // 5000 Gwei (10x min baseFee)
  console.log(`Transaction hash: ${tx.hash}`);
  await tx.wait();
  const block = await provider.getBlockNumber();
  console.log(`C-chain block produced, current height: ${block}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
